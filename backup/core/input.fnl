(local event-bus (require :golly.core.event-bus))
(local {: vec} (require :golly.math.vector))

(local input-events (event-bus))
(var joysticks [])
(var keystates [{} {} {} {}])

(fn pressed? [player key]
  (?. (?. keystates player) key))

(fn kbd-movement [player]
 (let [ix (or player 1)]
   (vec (if (pressed? ix :left) -1 (pressed? ix :right) 1 0)
        (if (pressed? ix :up) -1 (pressed? ix :down) 1 0))))

(fn movement [joystick-num?]
 (let [joystick (. joysticks (or joystick-num? 1))]
  (if (not joystick)
   (kbd-movement)
   (let [dx (joystick:getAxis 1)
         dy (joystick:getAxis 2)
         mag (+ (* dx dx) (* dy dy))]
     (if (< mag 0.3)
      (kbd-movement)
      (vec dx dy))))))

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
  (when v (input-events:dispatch key))
  (tset keystates player (lume.merge (. keystates player) { key v})))

(fn update []
 (let [joystick (. joysticks 1)]
   (when joystick
    (let [newstate (> (joystick:getAxis 6) 0)]
     (when (not= newstate (pressed? :rshoulder))
       (set-keystate 1 :rshoulder newstate))))))

(fn joystickpressed [joystick key]
  (match key
    6 (input-events:dispatch :rshoulder)
    5 (input-events:dispatch :lshoulder)))

(fn gamepadpressed [joystick key]
  (match key
   :dpdown (set-keystate :down true)
   :dpup (set-keystate :up true)
   :dpleft (set-keystate :left true)
   :dpright (set-keystate :right true)
   :a (set-keystate :a true)
   :b (set-keystate :b true)
   :x (set-keystate :x true)
   :y (set-keystate :y true)
   :start (set-keystate :start true)))

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
   :q (set-keystate 1 :lshoulder true)
   :e (set-keystate 1 :rshoulder true)
   :space (set-keystate 1 :a true)
   :f (set-keystate 1 :b true)))

(fn keyreleased [joystick key]
  (match key
   :down (set-keystate 1 :down false)
   :up (set-keystate 1 :up false)
   :left (set-keystate 1 :left false)
   :right (set-keystate 1 :right false)
   :s (set-keystate 1 :down false)
   :w (set-keystate 1 :up false)
   :a (set-keystate 1 :left false)
   :d (set-keystate 1 :right false)
   :space (set-keystate 1 :a false)
   :f (set-keystate 1 :b false)
   :q (set-keystate 1 :lshoulder false)
   :e (set-keystate 1 :rshoulder false)))

(fn mousepressed [x y btn istouch press]
  (input-events:dispatch :mousepress btn))

(fn mousereleased [x y btn istouch press]
  (input-events:dispatch :mousereleased btn))

(fn mouse-position []
  (let [(x y) (love.mouse.getPosition)]
    (vec x y))) 

(fn wheelmoved [x y]
  (input-events:dispatch :wheelmove x y))

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
 : pressed?
 : mouse-position
 : wheelmoved
 : input-events}
