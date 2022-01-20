(local g (require :golly))
(local tiny (require :lib.tiny))
(local repl (require :lib.stdio))

;; Global so easily accessible from the REPL
(global scene (g.scene))

;; Love2d drawing system, golly no longer handles graphics
(scene.ecs-world:addSystem
  (tiny.processingSystem {:filter (tiny.requireAll :__handles?-draw)
                          :process (fn [self e dt]
                                     (e:dispatch :draw))}))

;; Example of classes can be seen here 
;; https://gist.github.com/MattRoelle/9fa8005bac02296259c3baacfa911c3b
(global foo (g.class))
(foo:field :position (g.vec 200 200))
(foo:field :angle 0)
(foo:field :color [0 1 0 1])

(foo:method :spin {:events [:update]}
  (fn [self dt]
    (set self.angle (+ self.angle dt))))
    
(foo:method :draw-green-foo {:events [:draw]}
  (fn [self]
    (love.graphics.push)
    (love.graphics.setColor (unpack self.color))
    (love.graphics.translate self.position.x self.position.y)
    (love.graphics.rotate self.angle)
    (love.graphics.rectangle :fill -25 -25 50 50)
    (love.graphics.pop)))

(local foo-instance (scene:add-entity (foo)))

;; Move back and forth forever
(scene:timeline
  (fn []
    (while true
      (g.timeline.tween 1 foo-instance.position (g.vec 400 400))
      (g.timeline.tween 1 foo-instance.position (g.vec 200 200)))))

;; Change colors 
(scene:timeline
  (fn []
    (while true
      (set foo-instance.color [1 0 0 1])
      (g.timeline.wait 0.5)
      (set foo-instance.color [0 1 0 1])
      (g.timeline.wait 0.5)
      (set foo-instance.color [0 0 1 1])
      (g.timeline.wait 0.5))))

;; Boilerplate love.run
(fn love.run []
 (repl.start)
 (when love.timer (love.timer.step))
 (var dt 0)
 (fn []
   (when love.event
     (love.event.pump)
     (each [name a b c d e f (love.event.poll)]
       (when (= name :quit)
         (when (or (not love.quit) (not (love.quit)))
           (let [___antifnl_rtn_1___ (or a 0)]
             (lua "return ___antifnl_rtn_1___"))))
       ((. love.handlers name) a b c d e f)))
   (when love.timer
     (set dt (love.timer.step)))
   (love.graphics.origin)
   (love.graphics.clear (love.graphics.getBackgroundColor))
   (love.graphics.setColor 1 1 1 1)
   (scene:update dt)
   (love.graphics.present)
   (when love.timer
    (love.timer.sleep 0.001))))  
