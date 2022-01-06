;; TODO: This file was translated via antifennel from https://github.com/a327ex/STALKER-X then modified. Need to figure out license stuff

(local gollymath (require :golly.math))

(fn lerp [a b x] (+ a (* (- b a) x)))
(fn csnap [v x] (- (* (math.ceil (/ v x)) x) (/ x 2)))

(fn new-shake [amplitude duration frequency]
  (let [self {:amplitude (or amplitude 0)
              :duration (or duration 0)
              :frequency (or frequency 60)
              :samples {}
              :start_time (* (love.timer.getTime) 1000)
              :t 0
              :shaking true}
        sample-count (* (/ self.duration 1000) self.frequency)]
    (for [i 1 sample-count 1]
      (tset self.samples i (- (* 2 (love.math.random)) 1)))
    self))

(fn update-shake [self dt]
  (set self.t (- (* (love.timer.getTime) 1000) self.start_time))
  (when (> self.t self.duration)
    (set self.shaking false)))

(fn shake-noise [self s]
  (when (>= s (length self.samples))
    (lua "return 0"))
  (or (. self.samples s) 0))

(fn shake-decay [self t]
  (when (> t self.duration)
    (lua "return 0"))
  (/ (- self.duration t) self.duration))

(fn get-shake-amplitude [self t]
  (when (not t)
    (when (not self.shaking)
      (lua "return 0"))
    (set-forcibly! t self.t))
  (local s (* (/ t 1000) self.frequency))
  (local s0 (math.floor s))
  (local s1 (+ s0 1))
  (local k (shake-decay self t))
  (* (* self.amplitude
        (+ (shake-noise self s0)
           (* (- s s0) (- (shake-noise self s1) (shake-noise self s0)))))
     k))

(local Camera {})
(set Camera.__index Camera)

(fn camera [x y w h scale rotation]
  (setmetatable {:x (or x (/ (or w (love.graphics.getWidth)) 2))
                 :y (or y (/ (or h (love.graphics.getHeight)) 2))
                 :mx (or x (/ (or w (love.graphics.getWidth)) 2))
                 :my (or y (/ (or h (love.graphics.getHeight)) 2))
                 :screen_x (or x (/ (or w (love.graphics.getWidth)) 2))
                 :screen_y (or y (/ (or h (love.graphics.getHeight)) 2))
                 :w (or w (love.graphics.getWidth))
                 :h (or h (love.graphics.getHeight))
                 :scale (or scale 1)
                 :rotation (or rotation 0)
                 :horizontal_shakes {}
                 :vertical_shakes {}
                 :target_x nil
                 :target_y nil
                 :scroll_x 0
                 :scroll_y 0
                 :last_target_x nil
                 :last_target_y nil
                 :follow_lerp_x 1
                 :follow_lerp_y 1
                 :follow_lead_x 0
                 :follow_lead_y 0
                 :deadzone nil
                 :bound nil
                 :draw_deadzone false
                 :flash_duration 1
                 :flash_timer 0
                 :flash_color {1 0 2 0 3 0 4 1}
                 :last_horizontal_shake_amount 0
                 :last_vertical_shake_amount 0
                 :fade_duration 1
                 :fade_timer 0
                 :fade_color {1 0 2 0 3 0 4 0}} Camera))

(fn Camera.attach [self]
  (love.graphics.push)
  (love.graphics.translate (/ self.w 2) (/ self.h 2))
  (love.graphics.scale self.scale)
  (love.graphics.rotate self.rotation)
  (love.graphics.translate (- self.x) (- self.y)))

(fn Camera.detach [self]
  (love.graphics.pop))

(fn Camera.move [self dx dy]
  (set-forcibly! (self.x self.y) (values (+ self.x dx) (+ self.y dy))))

(fn Camera.toWorldCoords [self x y]
  (let [(c s) (values (math.cos self.rotation) (math.sin self.rotation))]
    (set-forcibly! (x y)
                   (values (/ (- x (/ self.w 2)) self.scale)
                           (/ (- y (/ self.h 2)) self.scale)))
    (set-forcibly! (x y) (values (- (* c x) (* s y)) (+ (* s x) (* c y))))
    (gollymath.vector.vec (+ x self.x) (+ y self.y))))

(fn Camera.toCameraCoords [self x y]
  (let [(c s) (values (math.cos self.rotation) (math.sin self.rotation))]
    (set-forcibly! (x y) (values (- x self.x) (- y self.y)))
    (set-forcibly! (x y) (values (- (* c x) (* s y)) (+ (* s x) (* c y))))
    (values (+ (* x self.scale) (/ self.w 2)) (+ (* y self.scale) (/ self.h 2)))))

(fn Camera.getMousePosition [self]
  (self:toWorldCoords (love.mouse.getPosition)))

(fn Camera.shake [self intensity duration frequency axes]
  (when (not axes)
    (set-forcibly! axes :XY))
  (set-forcibly! axes (string.upper axes))
  (when (string.find axes :X)
    (table.insert self.horizontal_shakes
                  (new-shake intensity (* duration 1000) frequency)))
  (when (string.find axes :Y)
    (table.insert self.vertical_shakes
                  (new-shake intensity (* duration 1000) frequency))))

(fn Camera.update [self dt]
  (set-forcibly! (self.mx self.my)
                 (self:toWorldCoords (love.mouse.getPosition)))
  (when self.flashing
    (set self.flash_timer (+ self.flash_timer dt))
    (when (> self.flash_timer self.flash_duration)
      (set self.flash_timer 0)
      (set self.flashing false)))
  (when self.fading
    (set self.fade_timer (+ self.fade_timer dt))
    (set self.fade_color
         {1 (lerp (. self.base_fade_color 1) (. self.target_fade_color 1)
                  (/ self.fade_timer self.fade_duration))
          2 (lerp (. self.base_fade_color 2) (. self.target_fade_color 2)
                  (/ self.fade_timer self.fade_duration))
          3 (lerp (. self.base_fade_color 3) (. self.target_fade_color 3)
                  (/ self.fade_timer self.fade_duration))
          4 (lerp (. self.base_fade_color 4) (. self.target_fade_color 4)
                  (/ self.fade_timer self.fade_duration))})
    (when (> self.fade_timer self.fade_duration)
      (set self.fade_timer 0)
      (set self.fading false)
      (when self.fade_action
        (self.fade_action))))
  (var (horizontal-shake-amount vertical-shake-amount) (values 0 0))
  (for [i (length self.horizontal_shakes) 1 (- 1)]
    (update-shake (. self.horizontal_shakes i) dt)
    (set horizontal-shake-amount
         (+ horizontal-shake-amount
            (get-shake-amplitude (. self.horizontal_shakes i))))
    (when (not (. (. self.horizontal_shakes i) :shaking))
      (table.remove self.horizontal_shakes i)))
  (for [i (length self.vertical_shakes) 1 (- 1)]
    (update-shake (. self.vertical_shakes i) dt)
    (set vertical-shake-amount
         (+ vertical-shake-amount
            (get-shake-amplitude (. self.vertical_shakes i))))
    (when (not (. (. self.vertical_shakes i) :shaking))
      (table.remove self.vertical_shakes i)))
  (set-forcibly! (self.x self.y)
                 (values (- self.x self.last_horizontal_shake_amount)
                         (- self.y self.last_vertical_shake_amount)))
  (self:move horizontal-shake-amount vertical-shake-amount)
  (set-forcibly! (self.last_horizontal_shake_amount self.last_vertical_shake_amount)
                 (values horizontal-shake-amount vertical-shake-amount))
  (when (and (not self.target_x) (not self.target_y))
    (lua "return "))
  (if (= self.follow_style :LOCKON)
      (let [(w h) (values (/ self.w 16) (/ self.w 16))]
        (self:setDeadzone (/ (- self.w w) 2) (/ (- self.h h) 2) w h))
      (= self.follow_style :PLATFORMER)
      (let [(w h) (values (/ self.w 8) (/ self.h 3))]
        (self:setDeadzone (/ (- self.w w) 2) (- (/ (- self.h h) 2) (* h 0.25))
                          w h)) (= self.follow_style :TOPDOWN)
      (let [s (/ (math.max self.w self.h) 4)]
        (self:setDeadzone (/ (- self.w s) 2) (/ (- self.h s) 2) s s))
      (= self.follow_style :TOPDOWN_TIGHT)
      (let [s (/ (math.max self.w self.h) 8)]
        (self:setDeadzone (/ (- self.w s) 2) (/ (- self.h s) 2) s s))
      (= self.follow_style :SCREEN_BY_SCREEN) (self:setDeadzone 0 0 0 0)
      (= self.follow_style :NO_DEADZONE) (set self.deadzone nil))
  (when (not self.deadzone)
    (set-forcibly! (self.x self.y) (values self.target_x self.target_y))
    (when self.bound
      (set self.x
           (math.min (math.max self.x (+ self.bounds_min_x (/ self.w 2)))
                     (- self.bounds_max_x (/ self.w 2))))
      (set self.y
           (math.min (math.max self.y (+ self.bounds_min_y (/ self.h 2)))
                     (- self.bounds_max_y (/ self.h 2)))))
    (lua "return "))
  (local (dx1 dy1 dx2 dy2)
         (values self.deadzone_x self.deadzone_y
                 (+ self.deadzone_x self.deadzone_w)
                 (+ self.deadzone_y self.deadzone_h)))
  (var (scroll-x scroll-y) (values 0 0))
  (local (target-x target-y) (self:toCameraCoords self.target_x self.target_y))
  (local (x y) (self:toCameraCoords self.x self.y))
  (if (= self.follow_style :SCREEN_BY_SCREEN)
      (do
        (if self.bound
            (do
              (when (and (> self.x (+ self.bounds_min_x (/ self.w 2)))
                         (< target-x 0))
                (set self.screen_x
                     (csnap (- self.screen_x (/ self.w self.scale))
                            (/ self.w self.scale))))
              (when (and (< self.x (- self.bounds_max_x (/ self.w 2)))
                         (>= target-x self.w))
                (set self.screen_x
                     (csnap (+ self.screen_x (/ self.w self.scale))
                            (/ self.w self.scale))))
              (when (and (> self.y (+ self.bounds_min_y (/ self.h 2)))
                         (< target-y 0))
                (set self.screen_y
                     (csnap (- self.screen_y (/ self.h self.scale))
                            (/ self.h self.scale))))
              (when (and (< self.y (- self.bounds_max_y (/ self.h 2)))
                         (>= target-y self.h))
                (set self.screen_y
                     (csnap (+ self.screen_y (/ self.h self.scale))
                            (/ self.h self.scale)))))
            (do
              (when (< target-x 0)
                (set self.screen_x
                     (csnap (- self.screen_x (/ self.w self.scale))
                            (/ self.w self.scale))))
              (when (>= target-x self.w)
                (set self.screen_x
                     (csnap (+ self.screen_x (/ self.w self.scale))
                            (/ self.w self.scale))))
              (when (< target-y 0)
                (set self.screen_y
                     (csnap (- self.screen_y (/ self.h self.scale))
                            (/ self.h self.scale))))
              (when (>= target-y self.h)
                (set self.screen_y
                     (csnap (+ self.screen_y (/ self.h self.scale))
                            (/ self.h self.scale))))))
        (set self.x (lerp self.x self.screen_x self.follow_lerp_x))
        (set self.y (lerp self.y self.screen_y self.follow_lerp_y))
        (when self.bound
          (set self.x
               (math.min (math.max self.x (+ self.bounds_min_x (/ self.w 2)))
                         (- self.bounds_max_x (/ self.w 2))))
          (set self.y
               (math.min (math.max self.y (+ self.bounds_min_y (/ self.h 2)))
                         (- self.bounds_max_y (/ self.h 2))))))
      (do
        (when (< target-x (+ x (- (+ dx1 dx2) x)))
          (local d (- target-x dx1))
          (when (< d 0)
            (set scroll-x d)))
        (when (> target-x (- x (- (+ dx1 dx2) x)))
          (local d (- target-x dx2))
          (when (> d 0)
            (set scroll-x d)))
        (when (< target-y (+ y (- (+ dy1 dy2) y)))
          (local d (- target-y dy1))
          (when (< d 0)
            (set scroll-y d)))
        (when (> target-y (- y (- (+ dy1 dy2) y)))
          (local d (- target-y dy2))
          (when (> d 0)
            (set scroll-y d)))
        (when (and (not self.last_target_x) (not self.last_target_y))
          (set-forcibly! (self.last_target_x self.last_target_y)
                         (values self.target_x self.target_y)))
        (set scroll-x (+ scroll-x
                         (* (- self.target_x self.last_target_x)
                            self.follow_lead_x)))
        (set scroll-y (+ scroll-y
                         (* (- self.target_y self.last_target_y)
                            self.follow_lead_y)))
        (set-forcibly! (self.last_target_x self.last_target_y)
                       (values self.target_x self.target_y))
        (set self.x (lerp self.x (+ self.x scroll-x) self.follow_lerp_x))
        (set self.y (lerp self.y (+ self.y scroll-y) self.follow_lerp_y))
        (when self.bound
          (set self.x
               (math.min (math.max self.x (+ self.bounds_min_x (/ self.w 2)))
                         (- self.bounds_max_x (/ self.w 2))))
          (set self.y
               (math.min (math.max self.y (+ self.bounds_min_y (/ self.h 2)))
                         (- self.bounds_max_y (/ self.h 2))))))))

(fn Camera.draw [self]
  (when (and self.draw_deadzone self.deadzone)
    (local n (love.graphics.getLineWidth))
    (love.graphics.setLineWidth 2)
    (love.graphics.line (- self.deadzone_x 1) self.deadzone_y
                        (+ self.deadzone_x 6) self.deadzone_y)
    (love.graphics.line self.deadzone_x self.deadzone_y self.deadzone_x
                        (+ self.deadzone_y 6))
    (love.graphics.line (- self.deadzone_x 1)
                        (+ self.deadzone_y self.deadzone_h)
                        (+ self.deadzone_x 6)
                        (+ self.deadzone_y self.deadzone_h))
    (love.graphics.line self.deadzone_x (+ self.deadzone_y self.deadzone_h)
                        self.deadzone_x
                        (- (+ self.deadzone_y self.deadzone_h) 6))
    (love.graphics.line (+ (+ self.deadzone_x self.deadzone_w) 1)
                        (+ self.deadzone_y self.deadzone_h)
                        (- (+ self.deadzone_x self.deadzone_w) 6)
                        (+ self.deadzone_y self.deadzone_h))
    (love.graphics.line (+ self.deadzone_x self.deadzone_w)
                        (+ self.deadzone_y self.deadzone_h)
                        (+ self.deadzone_x self.deadzone_w)
                        (- (+ self.deadzone_y self.deadzone_h) 6))
    (love.graphics.line (+ (+ self.deadzone_x self.deadzone_w) 1)
                        self.deadzone_y
                        (- (+ self.deadzone_x self.deadzone_w) 6)
                        self.deadzone_y)
    (love.graphics.line (+ self.deadzone_x self.deadzone_w) self.deadzone_y
                        (+ self.deadzone_x self.deadzone_w)
                        (+ self.deadzone_y 6))
    (love.graphics.setLineWidth n))
  (when self.flashing
    (local (r g b a) (love.graphics.getColor))
    (love.graphics.setColor self.flash_color)
    (love.graphics.rectangle :fill 0 0 self.w self.h)
    (love.graphics.setColor r g b a))
  (local (r g b a) (love.graphics.getColor))
  (love.graphics.setColor self.fade_color)
  (love.graphics.rectangle :fill 0 0 self.w self.h)
  (love.graphics.setColor r g b a))

(fn Camera.follow [self x y]
  (set-forcibly! (self.target_x self.target_y) (values x y)))

(fn Camera.setDeadzone [self x y w h]
  (set self.deadzone true)
  (set self.deadzone_x x)
  (set self.deadzone_y y)
  (set self.deadzone_w w)
  (set self.deadzone_h h))

(fn Camera.setBounds [self x y w h]
  (set self.bound true)
  (set self.bounds_min_x x)
  (set self.bounds_min_y y)
  (set self.bounds_max_x (+ x w))
  (set self.bounds_max_y (+ y h)))

(fn Camera.setFollowStyle [self follow-style]
  (set self.follow_style follow-style))

(fn Camera.setFollowLerp [self x y]
  (set self.follow_lerp_x x)
  (set self.follow_lerp_y (or y x)))

(fn Camera.setFollowLead [self x y]
  (set self.follow_lead_x x)
  (set self.follow_lead_y (or y x)))

(fn Camera.flash [self duration color]
  (set self.flash_duration duration)
  (set self.flash_color (or color self.flash_color))
  (set self.flash_timer 0)
  (set self.flashing true))

(fn Camera.fade [self duration color action]
  (set self.fade_duration duration)
  (set self.base_fade_color self.fade_color)
  (set self.target_fade_color color)
  (set self.fade_timer 0)
  (set self.fade_action action)
  (set self.fading true))

camera
