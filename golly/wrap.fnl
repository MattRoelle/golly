;(local profiler (require :lib.profiler))
(local input (require :golly.core.input))
(local ui (require :golly.ui))
(local r (require :golly.core))


(local repl (require :lib.stdio))

;(local editor (require :polywell))
;(require :editorconfig)

(global dbg false)

(var editoropen? false)
(var is-profiling false)

(fn render-dbg []
  (let [game (r.game.get-game)]
   (when game.scene
    (ui.draw {:width (love.graphics.getWidth)
              :height 30
              :root [:view {:style {:padding 4 :background-color [1 0 0 0.5]}}
                     [:view {} [:text {:color :white} (.. "FPS: " (love.timer.getFPS))]]]}))))
                   ;[:view {} [:text {:color :white} (.. "ECS Entities: " (r.game.scene.ecs-world.getEntityCount))]]
                   ;[:view {} [:text {:color :white} (.. "Bump Rects: " (length r.game.scene.bump-world.rects))]]]})))

(fn love.joystickpressed [joystick key]
 (input.joystickpressed joystick key))

(fn love.gamepadpressed [joystick key]
 (input.gamepadpressed joystick key))

(fn love.gamepadreleased [joystick key]
 (input.gamepadreleased joystick key))

(fn love.keyreleased [...]
 (input.keyreleased ...))

(fn love.keypressed [key]
 (input.keypressed key))
 ;(when editoropen?
  ;(editor.handlers.keypressed key))

 ;(when (= key "f5") (set _G.dbg (not _G.dbg)))
 ;;(when (= key "f1") (set editoropen? (not editoropen?)))
 ;(when (= key "f2") (love.window.setFullscreen true "exclusive"))
 ;(when (and is-profiling (= key "f6"))
 ;   (print "Ending profile session. Writing to ./profile.txt")
 ;   (set is-profiling false)
 ;   (profiler.stop)
 ;   (profiler.report "profile.txt"))
 ;(when (and (not is-profiling) (= key "f6"))
 ;   (print "Beginning profile")
 ;   (set is-profiling true)
 ;   (profiler.start)))

 ;(when editoropen?
  ;(editor.handlers.keyreleased key))

(fn love.textinput [t])
 ;(when editoropen?
  ;(editor.handlers.textinput t))

(fn love.mousepressed [x y btn istouch press]
  (r.input.mousepressed x y btn istouch press))

(fn love.mousereleased [x y btn istouch press]
  (r.input.mousereleased x y btn istouch press))

(love.graphics.setDefaultFilter :nearest :nearest)

(fn love.run []
 (repl.start)
 ;(local editorfont (love.graphics.newFont "FSEX300.ttf" 20))
 (input.sync-joysticks)
 (love.keyboard.setTextInput true)
 (love.keyboard.setKeyRepeat true)
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
   ;(love.graphics.clear 1 0 0 1)
   (love.graphics.clear (love.graphics.getBackgroundColor))
   (love.graphics.setColor 1 1 1 1)

   (input.update)

   (let [game (r.game.get-game)]
     (when (and game game.scene)
       (set game.scene.scene-time (+ game.scene.scene-time dt))
       (game.scene:update dt)))

   ; (when editor.internal.coroutines
   ;  (each [_ c (pairs editor.internal.coroutines)]
   ;    (let [[ok val] (coroutine.resume c)]
   ;       (if (not ok)
   ;         (print val))))

   ;  (each [i c (lume.ripairs editor.internal.coroutines)]
   ;    (when (= (coroutine.status c) "dead")
   ;        (table.remove editor.internal.coroutines i))))

   ; (when editoropen?
   ;  (love.graphics.setFont editorfont)
   ;  (editor.draw))
    
   (when dbg (render-dbg))
   (love.graphics.present)

   ;(coroutine.resume jcoro)

   (when love.timer
    (love.timer.sleep 0.001))))  

