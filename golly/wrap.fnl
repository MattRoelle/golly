(local input (require :golly.core.input))
(local core (require :golly.core))
(local repl (require :lib.stdio))

(global dbg false)

(fn render-dbg []
  (love.graphics.print (love.timer.getFPS)))

(fn love.joystickpressed [joystick key] (input.joystickpressed joystick key))
(fn love.gamepadpressed [joystick key] (input.gamepadpressed joystick key))
(fn love.gamepadreleased [joystick key] (input.gamepadreleased joystick key))
(fn love.keyreleased [...] (input.keyreleased ...))

(fn love.keypressed [key]
  (input.keypressed key)
  (when (= key "f5") (set _G.dbg (not _G.dbg))))

(fn love.mousepressed [x y btn istouch press] (input.mousepressed x y btn istouch press))
(fn love.mousereleased [x y btn istouch press] (input.mousereleased x y btn istouch press))
(fn love.wheelmoved [x y] (input.wheelmoved x y))

(fn love.run []
 (repl.start)
 (input.sync-joysticks)

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
   (input.update)
   (let [scene (core.game.get-active-scene)]
     (when scene (scene:update dt)))
   (when dbg (render-dbg))
   (love.graphics.present)
   (when love.timer
    (love.timer.sleep 0.001))))  
