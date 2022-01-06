(require-macros :golly)
(local tiny (require :lib.tiny))
(local easing (require :lib.easing))
(local systems (require :golly.core.systems))
(local input (require :golly.core.input))
(local helpers (require :golly.helpers))
(local camera (require :golly.camera))

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

(fn Scene.destroy-all! [self tag]
  (each [_ e (ipairs (self:find-all tag))]
    (when e.destroy! (e:destroy!))))

(fn Scene.destroy [self]
  (each [_ e (ipairs self.ecs-world.entities)]
    (e:destroy!)))

(fn Scene.update [self dt]
  (self.ecs-world:update dt)
  (while (> (length self.removal-queue) 0)
    (let [e (table.remove self.removal-queue 1)]
      (self.ecs-world:removeEntity e))))

(fn Scene.configure-box2d-callbacks [self options]
  (fn callback [ev a b coll normalimpulse? tangentimpulse?]
    (let [ae (self:find-by-id (a:getUserData))
          be (self:find-by-id (b:getUserData))]
      (when (and ae be)
        (let [method (.. :collision- ev)]
          (when (ae:collides? be)
            (when (. ae method) 
              (: ae method be coll normalimpulse? tangentimpulse?)))
          (when (be:collides? ae)
            (when (. be method) 
              (: be method ae coll normalimpulse? tangentimpulse?)))))))
  (self.box2d-world:setCallbacks
    (partial callback :begin-contact)
    (partial callback :end-contact)
    (partial callback :pre-contact)
    (partial callback :post-solve)))

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
   (self.ecs-world:addSystem (systems.update-system self))
   (self.ecs-world:addSystem (systems.camera-render-system self))
   (self.ecs-world:addSystem (systems.debug-render-system self))
   (self.ecs-world:addSystem (systems.window-render-system))
   ;; Set up camera
   (set self.camera (camera))
   ;; Initialize physics
   (love.physics.setMeter 100)
   (set self.box2d-world (love.physics.newWorld 0 0))
   (self:configure-box2d-callbacks options)
   self))

{: create-scene}
