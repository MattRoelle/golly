(require-macros :golly)
(local tiny (require :lib.tiny))
(local easing (require :lib.easing))
(local systems (require :golly.core.systems))
(local game (require :golly.core.game))
(local gamera (require :lib.gamera))
(local ui (require :golly.ui))
(local input (require :golly.core.input))
(local helpers (require :golly.helpers))

(local Scene {})
(set Scene.__index Scene)

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

(fn Scene.destroy [self]
  (each [_ e (ipairs self.ecs-world.entities)]
    (e:destroy!)))

(fn Scene.update [self dt]
  (self.ecs-world:update dt)
  (while (> (length self.removal-queue) 0)
    (let [e (table.remove self.removal-queue 1)]
      (self.ecs-world:removeEntity e))))

(fn Scene.configure-box2d-callbacks [self]
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

(fn Scene.init [self]
 (set self.idmap {})
 (set self.tagmap {})
 (set self.removal-queue [])
 (let [{: stage-width : stage-height} (game.get-game)]
   (set self.camera (gamera.new 0 0 stage-width stage-height))
   (self.camera:setWorld (* 0.5 stage-width) 0 stage-width (* 2 stage-height)))
 (set self.ecs-world (tiny.world))  
 (self.ecs-world:addSystem (systems.init-system))
 (self.ecs-world:addSystem (systems.destroy-system))
 (self.ecs-world:addSystem (systems.tag-system))
 (self.ecs-world:addSystem (systems.update-system self))
 (set self.canvas (love.graphics.newCanvas game.stage-width game.stage-height))
 (self.ecs-world:addSystem (systems.camera-render-system self self.canvas))
 (self.ecs-world:addSystem (systems.debug-render-system self self.canvas))
 ;(self.ecs-world:addSystem (systems.screen-render-system self.canvas))
 (self.ecs-world:addSystem (systems.window-render-system))
 (set self.scene-time 0)
 (love.physics.setMeter 100)
 (set self.box2d-world (love.physics.newWorld 0 0))
 (self:configure-box2d-callbacks))
 ; (self.ecs-world:addSystem (systems.box2d-system)))

(fn create-scene []
 (let [self (setmetatable {:idmap {} :tagmap {}} Scene)]
   (self:init)
   self))

(fn draw-game-frame [scene]
  (set scene.shake-timer 1)
  (set scene.shake-duration 0.1)
  (set scene.shake-intensity 1)
  (set scene.shake 
       (fn [self duration intensity]
         (set self.shake-timer 0)
         (set self.shake-duration duration)
         (set self.shake-intensity intensity)))
  (let [game (game.get-game)]
    (set scene.framedrawer
         (scene:add-entity
           {:window-z -1
            :update
            (fn [self dt]
              (set self.scene.shake-timer (+ self.scene.shake-timer dt)))
            :drawwindow
            (fn [self]
              (love.graphics.setCanvas)
              (love.graphics.clear)
              (let [[x y] (if (< self.scene.shake-timer self.scene.shake-duration)
                            [(* (math.random) self.scene.shake-intensity)
                             (* (math.random) self.scene.shake-intensity)]
                            [0 0])
                    width (love.graphics.getWidth)
                    height (love.graphics.getHeight)]
                (ui.draw {: width 
                          : height
                          : x : y
                          :root [:custom-draw
                                 (fn [width height]
                                   (let [sx (/ width game.stage-width)
                                         sy (/ height game.stage-height)
                                         s (math.min sx sy)
                                         w (* s game.stage-width)
                                         h (* s game.stage-height)]
                                     (love.graphics.push)
                                     (love.graphics.translate (- width w)
                                                              (* 0.5 (- height h)))
                                     (love.graphics.scale s s)
                                     (love.graphics.setColor 1 1 1 1)
                                     (love.graphics.draw game.scene.canvas 0 0)
                                     (love.graphics.pop)))]})))}))))

{: create-scene
 : draw-game-frame}
