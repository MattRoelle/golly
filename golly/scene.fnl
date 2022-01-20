(local tiny (require :lib.tiny))
(local systems (require :golly.systems))
(local helpers (require :golly.helpers))
(local timeline (require :golly.timeline))

(local Scene {})
(fn Scene.__index [self k]
  (. Scene k))

(fn Scene.add-entity [self entity]
  (set entity.scene self)
  (set entity.id (or entity.id (helpers.uuid)))
  (tset self.idmap entity.id entity)
  (tiny.addEntity self.ecs-world entity)
  entity)

(fn Scene.find-by-id [self id]
  (. self.idmap id))

(fn Scene.find [self tag]
  (. (or (. self.tagmap tag) []) 1))

(fn Scene.find-all [self tag]
  (or (. self.tagmap tag) []))

(fn Scene.destroy-entity [self e]
  (set e.destroyed true)
  (table.insert self.removal-queue e))

(fn Scene.destroy-all [self tag]
  (each [id e (pairs (self:find-all tag))]
    (self:destroy-entity e)))

(fn Scene.destroy [self]
  (each [_ e (ipairs self.ecs-world.entities)]
    (self:destroy-entity e)))

(fn Scene.timeline [self f]
  (self:add-entity {:dispatch #nil :timeline (timeline f)}))

(fn Scene.update [self dt]
  (self.ecs-world:update dt)
  (while (> (length self.removal-queue) 0)
    (let [e (table.remove self.removal-queue 1)]
      (self.ecs-world:removeEntity e))))

(fn create-scene [options]
 (let [self (setmetatable
              {:idmap {} :tagmap {}
               :removal-queue []} Scene)]
   ;; Initialize Tiny ECS
   (set self.ecs-world (tiny.world))  
   ;; Add the core systems
   (self.ecs-world:addSystem (systems.init-system))
   (self.ecs-world:addSystem (systems.destroy-system))
   (self.ecs-world:addSystem (systems.tag-system))
   (self.ecs-world:addSystem (systems.timeline-system self))
   (self.ecs-world:addSystem (systems.update-system self))
   self))

create-scene
