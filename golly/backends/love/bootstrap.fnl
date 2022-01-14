(local repl (require :lib.stdio))

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

   ; (input.update)
   ; (let [scene (core.game.get-active-scene)]
   ;   (when scene (scene:update dt)))

   (love.graphics.present)
   (when love.timer
    (love.timer.sleep 0.001))))  
