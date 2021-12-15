(local beholder (require :lib.beholder))
(local game (require :golly.core.game))
(local gollymath (require :golly.math))

(var joysticks [])
(var keystates [{} {} {} {}])

(fn pressed [player key]
  (?. (?. keystates player) key))

(fn kbd-movement []
 [(if (love.keyboard.isDown "a") -1 (love.keyboard.isDown "d") 1 0)
  (if (love.keyboard.isDown "w") -1 (love.keyboard.isDown "s") 1 0)])

(fn movement [joystick-num?]
 (let [joystick (. joysticks (or joystick-num? 1))]
  (if (not joystick)
   (kbd-movement)
   (let [dx (joystick:getAxis 1)
         dy (joystick:getAxis 2)
         mag (+ (* dx dx) (* dy dy))]
     (if (< mag 0.3)
      (kbd-movement)
      [dx dy])))))

(fn aim [joystick-num?]
 (let [joystick (. joysticks (or joystick-num? 1))]
  (if (not joystick)
   [1 0]
   (let [dx (joystick:getAxis 4)
         dy (joystick:getAxis 5)
         mag (+ (* dx dx) (* dy dy))]
     ;(if (< mag 0.3)
      ;(kbd-movement)
     [dx dy]))))
     
(fn sync-joysticks []
 (set joysticks (love.joystick.getJoysticks))
 (pp joysticks))
  
(fn set-keystate [player key v]
  (when v (beholder.trigger :input player key))
  (tset keystates player (lume.merge (. keystates player) { key v})))

(fn update []
 (let [joystick (. joysticks 1)]
   (when joystick
    (let [newstate (> (joystick:getAxis 6) 0)]
     (when (not= newstate (pressed :rshoulder))
       (set-keystate 1 :rshoulder newstate))))))

(fn joystickpressed [joystick key]
  (match key
    6 (beholder.trigger :input 1 :rshoulder)
    5 (beholder.trigger :input 1 :lshoulder)))

(fn gamepadpressed [joystick key]
  (match key
   :dpdown (set-keystate 1 :down true)
   :dpup (set-keystate 1 :up true)
   :dpleft (set-keystate 1 :left true)
   :dpright (set-keystate 1 :right true)
   :a (set-keystate 1 :a true)
   :b (set-keystate 1 :b true)
   :x (set-keystate 1 :x true)
   :y (set-keystate 1 :y true)
   :start (set-keystate 1 :start true)))

(fn gamepadreleased [joystick key]
  (match key
   :dpdown (set-keystate 1 :down false)
   :dpup (set-keystate 1 :up false)
   :dpleft (set-keystate 1 :left false)
   :dpright (set-keystate 1 :right false)
   :a (set-keystate 1 :a false)
   :b (set-keystate 1 :b false)
   :x (set-keystate 1 :x false)
   :y (set-keystate 1 :y false)
   :start (set-keystate 1 :start false)))

(fn keypressed [key]
 (match key
   :down (set-keystate 1 :down true)
   :up (set-keystate 1 :up true)
   :left (set-keystate 1 :left true)
   :right (set-keystate 1 :right true)
   :s (set-keystate 1 :down true)
   :w (set-keystate 1 :up true)
   :a (set-keystate 1 :left true)
   :d (set-keystate 1 :right true)
   :space (set-keystate 1 :a true)
   :f (set-keystate 1 :b true)))

(fn keyreleased [joystick key]
  (match key
   :dpdown (set-keystate 1 :down false)
   :dpup (set-keystate 1 :up false)
   :dpleft (set-keystate 1 :left false)
   :dpright (set-keystate 1 :right false)
   :a (set-keystate 1 :a false)
   :b (set-keystate 1 :b false)
   :x (set-keystate 1 :x false)
   :y (set-keystate 1 :y false)
   :start (set-keystate 1 :start false)))

(fn mousepressed [x y btn istouch press]
  (beholder.trigger :input 1 :mousepress btn))

(fn mousereleased [x y btn istouch press]
  (beholder.trigger :input 1 :mousereleased btn))

(fn mouse-position []
  (let [(x y) (love.mouse.getPosition)]
    (gollymath.vector.vec
      (/ x (/ (love.graphics.getWidth) game.stage-width))
      (/ y (/ (love.graphics.getHeight) game.stage-height)))))

{: sync-joysticks
 : movement
 : aim
 : keypressed
 : gamepadpressed
 : keypressed
 : joystickpressed 
 : gamepadreleased
 : mousepressed
 : mousereleased
 : keyreleased
 : update 
 : pressed
 : mouse-position}
