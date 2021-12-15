(local game (require :golly.core.game))
(local colors (require :golly.colors))
(local helpers (require :golly.helpers))
(local input (require :golly.core.input))
(local beholder (require :lib.beholder))
(local machine (require :lib.statemachine))
(local graphics (require :golly.graphics))

(require-macros :golly)

(defmixin litsprite [self img color]
  (field :flashtimer 1)
  (field :colorkey color)
  (field :color (colors.lookup-color color 1))
  (field :flashduration 0.07)
  (field :asset (. game.assets img))
  (field :width (self.asset:getWidth))
  (field :height (self.asset:getHeight))
  (on :update [dt]
    (set self.flashtimer (+ self.flashtimer dt))
    (let [t (math.min 1 (/ self.flashtimer self.flashduration))
          s (+ 1 (* 0.2 (- 1 t)))]
      (set self.scaleX (* (or self.scale 1) s))
      (set self.scaleY (* (or self.scale 1) s))))
  (on :init []
     (set self.shader (love.graphics.newShader "assets/shaders/lit-sprite.glsl")))
  (on :draw []
     (love.graphics.push)
     (love.graphics.setColor 0 0 0 1)
     (love.graphics.rotate (- self.angle))
     (love.graphics.translate -2 2)
     (love.graphics.rotate self.angle)
     (love.graphics.draw self.asset)
     (love.graphics.pop)
     (with-shader self.shader
      (self.shader:send :flashing
                        (< (or self.flashtimer 1)
                           (or self.flashduration 0.07))
       (love.graphics.setColor (unpack (or self.color [1 1 1 1])))
       (love.graphics.setColor (colors.lookup-color color 1))
       (love.graphics.draw self.asset)))))

(defmixin box2d [self props]
  (on :init []
    (set self.body
         (love.physics.newBody self.scene.box2d-world
                               self.position.x self.position.y
                               props.body-type))
    (set self.shape
         (match props.shape-type
           :rectangle (love.physics.newRectangleShape 0 0 self.width self.height)
           :circle (love.physics.newCircleShape self.r)))
    (set self.fixture 
         (love.physics.newFixture self.body self.shape (or props.mass 5)))
    (self.fixture:setUserData self.id)
    (self.body:setAngularDamping (or props.angular-damping 0))
    (self.body:setLinearDamping (or props.linear-damping 0))
    (self.fixture:setRestitution (or props.restitution 0))
    (when props.filter (self.fixture:setFilterData (unpack props.filter)))
    (when self.initial-velocity
      (self.body:applyLinearImpulse self.initial-velocity.x self.initial-velocity.y)))
  (on :destroy []
    (self.body:destroy))
  (on :drawdebug []
    (with-origin
      (love.graphics.setColor 1 0.5 0.5 0.5)
      (match props.shape-type
        :rectangle (love.graphics.polygon :fill (self.body:getWorldPoints (self.shape:getPoints)))
        :circle (love.graphics.circle :fill (self.body:getX) (self.body:getY) self.r))))
  (on :update [dt]
    (set (self.position.x self.position.y self.angle)
         (values 
           (self.body:getX)
           (self.body:getY)
           (self.body:getAngle)))))

;(fn car [self props]
;  (box2d self {:body-type :dynamic
;               :shape-type :rectangle
;               ;:filter [(bit.bor box2d-layers.cannon) (bit.bor box2d-layers.wall box2d-layers.enemy) 0]
;               :restitution 0.75}) 
;  (set self.get-directional-velocity 
;       (fn [self.position.x y]
;         (let [(nx ny) (self.body:getWorldVector x y)
;               (vx vy) (self.body:getLinearVelocity)
;               dot (helpers.dot nx ny vx vy)]
;           [(* dot nx) (* dot ny)])))
;  (self:on :update 
;           (fn [self dt]
;             (let [[mx my] (input.movement)
;                   (upx upy) (self.body:getWorldVector 0 1)
;                   [horizontal-velx horizontal-vely] (self:get-directional-velocity 1 0)
;                   [vert-velx vert-vely] (self:get-directional-velocity 0 1)
;                   direction (math.atan2 vert-vely vert-velx)
;                   speed (+ (* vert-velx vert-velx) (* vert-vely vert-vely))
;                   [dirx diry] [(math.cos direction) (math.sin direction)]
;                   drag-force (* speed -0.01)
;                   accel (if (> my 0) 1 (< my 0) -1 0)
;                   accel-force (if (< speed 16000) (* accel 150) 0)
;                   turn (if (> mx 0) 1 (< mx 0) -1 0)
;                   mass (self.body:getMass)
;                   [hforcex hforcey] [(* -0.02 mass horizontal-velx) (* -0.02 mass horizontal-vely)]]
;                 (self.body:applyAngularImpulse (* -0.1 (self.body:getInertia) (self.body:getAngularVelocity)))
;                 (self.body:applyForce (* dirx drag-force) (* diry drag-force))
;                 (self.body:applyLinearImpulse hforcex hforcey)
;                 (when (not self.driveable) (lua "return"))
;                 (self.body:applyTorque (* mx 800))
;                 (self.body:applyForce (* upx accel-force) (* upy accel-force))))))

(local Timer {}) (set Timer.__index Timer)

(fn Timer.play [self] (set self.paused false))
(fn Timer.pause [self] (set self.paused true))

(fn Timer.reset [self]
  (set self.completed false)
  (set self.t 0))

(fn Timer.reset-and-play [self]
  (self:reset)
  (self:play))

(fn Timer.reset-and-pause [self]
  (self:reset)
  (self:pause))

(fn Timer.update [self dt]
  (when self.paused (lua "return"))
  (set self.t (+ self.t dt))
  (set self.pct (math.max 0 (math.min 1 (/ self.t self.duration))))
  (when (and self.duration (> self.t self.duration))
    (when (not self.completed)
      (set self.completed true)
      (when self.on-complete (self.on-complete self)))))

(fn new-timer [props]
  (setmetatable (lume.merge {:t 0
                             :pct 0
                             :paused false
                             :completed false
                             :duration 1}
                           props)
                Timer))

(defmixin timer [self name props]
  (when (not self.timers)
    (set self.timers {})
    (self:on :update
             (fn [dt]
               (each [_ t (pairs self.timers)] 
                 (t:update dt)))))
  (tset self.timers name
                (new-timer (lume.merge {:on-complete #(let [k (.. :timer- name)]
                                                        (when (. self k)
                                                          (: self k $1)))}
                                       props))))

(defmixin m-input [self ...]
  (set self.__inputsub
       (beholder.observe :input ...
                         #(self:input $...)))
  (on :destroy []
      (beholder.stopObserving self.__inputsub)))

(defmixin mouse-interaction [self props]
  (field :mousestate 
         (statemachine :idle
                       (transitions 
                         (hover {:from :idle :to :hovered})
                         (mouseout {:from :hovered :to :idle}))
                       (state :hovered 
                         (on-enter [] (when self.mouseover (self:mouseover)))
                         (on-exit [] (when self.mouseout (self:mouseout))))))

  (set self.inputsub
       (beholder.observe :input 1 :mousepress
                         (fn [btn]
                           (when (and self.mousepress
                                      (= self.mousestate.current :hovered))
                             (self:mousepress)))))
  (on :destroy [] (beholder.stopObserving self.inputsub))
  (on :drawdebug []
   (love.graphics.setColor 0 1 0 1)
   (graphics.dashed-rectangle 0 0 self.width self.height 1 4 1))
  (on :update [dt]
   (set self.padding (or self.padding 0))
   (let [[mx my] (input.mouse-position)
         left (- self.bounds.left self.padding)
         top (- self.bounds.top self.padding)
         right (+ self.bounds.right self.padding)
         bottom (+ self.bounds.bottom self.padding)]
     (when self.bounds.left
        (if (and (> mx left)
                 (> my top)
                 (< mx right)
                 (< my bottom))
          (self.mousestate:hover)
          (self.mousestate:mouseout))))))

(defmixin bullet [self props]
  (set self.speed (or props.speed 30))
  (on :hit [] (self:destroy!))
  (on :init [] (self.body:applyLinearImpulse (* self.speed (math.cos self.direction))
                                             (* self.speed (math.sin self.direction))))
  (set self.color (or props.color [1 1 1 1]))
  (set self.direction (or props.direction 0))
  (on :update [dt]
     (self.body:applyForce (* self.speed (math.cos self.direction))
                           (* self.speed (math.sin self.direction)))
     (let [(dx dy) (self.body:getLinearVelocity)
           angle (math.atan2 dy dx)]
       (self.body:setAngle angle)
       (self.body:setAngularVelocity 0))
     (when (or (> self.position.x (+ game.stage-width 100))
               (> self.position.y (+ game.stage-height 100))
               (< self.position.x -100)
               (< self.position.y -100))
       (self:destroy!))))

{: litsprite
 : box2d
 ;: car
 : timer
 : mouse-interaction
 : bullet
 :input m-input}
