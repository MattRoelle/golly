(local game (require :golly.core.game))
(local helpers (require :golly.helpers))
(local input (require :golly.core.input))
(local beholder (require :lib.beholder))
(local graphics (require :golly.graphics))
(local assets (require :golly.assets))

(require-macros :golly)

(mixin box2d [self props]
  (on :init [] (self:box2d-init))
  (on :box2d-init []
    (when self.body (lua :return))
    (set self.body
         (love.physics.newBody self.scene.box2d-world
                               self.position.x self.position.y
                               props.body-type))
    (set self.shape
         (match props.shape-type
           :rectangle (love.physics.newRectangleShape 0 0 self.size.x self.size.y)
           :circle (love.physics.newCircleShape self.r)
           :polygon (love.physics.newPolygonShape (unpack self.points))))
    (set self.fixture 
         (love.physics.newFixture self.body self.shape (or props.mass 5)))
    (self.fixture:setDensity (or props.density 1))
    (self.fixture:setUserData self.id)
    (self.body:setAngularDamping (or props.angular-damping 0))
    (self.body:setLinearDamping (or props.linear-damping 0))
    (self.fixture:setRestitution (or props.restitution 0))
    (when props.filter
      (self.fixture:setFilterData (unpack props.filter)))
    (when self.initial-velocity
      (self.body:applyLinearImpulse self.initial-velocity.x self.initial-velocity.y)))
  (on :destroy []
    (self.body:destroy))
  (fn self.draw-box2d-shape [type]
      (match props.shape-type
        :rectangle (love.graphics.polygon type
                      (self.body:getWorldPoints (self.shape:getPoints)))
        :circle (love.graphics.circle type (self.body:getX) (self.body:getY) self.r)
        :polygon 
        (let [points [(self.body:getWorldPoints (self.shape:getPoints))]]
          (love.graphics.polygon type (unpack points)))))
  (on :drawdebug []
    (with-origin
      (love.graphics.setColor 0.5 0.5 0.5 0.5)
      (self.draw-box2d-shape :fill)
      (love.graphics.setColor 0.5 0.5 1 0.5)
      (love.graphics.setLineWidth 2)
      (self.draw-box2d-shape :line)))
  (on :update [dt]
    (when self.body
      (set (self.position.x self.position.y self.angle)
           (values 
             (self.body:getX)
             (self.body:getY)
             (self.body:getAngle))))))

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

(mixin timer [self name props]
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

(mixin m-input [self ...]
  (set self.__inputsub
       (beholder.observe :input ...
                         #(self:input $...)))
  (on :destroy []
      (beholder.stopObserving self.__inputsub)))

(mixin mouse-interaction [self props]
  (statemachine :mouse-interaction-state :idle
    (transitions 
      (hover {:from :idle :to :hovered})
      (mouseout {:from :hovered :to :idle}))
    (state :hovered 
      (on-enter [] (when self.mouseover (self:mouseover)))
      (on-exit [] (when self.mouseout (self:mouseout)))))

  (set self.inputsub
       (beholder.observe :input 1 :mousepress
                         (fn [btn]
                           (when (and self.mousepress
                                      (= self.mouse-interaction-state.current :hovered))
                             (self:mousepress)))))
  (on :destroy [] (beholder.stopObserving self.inputsub))
  (on :drawdebug []
   (love.graphics.setColor 0 1 0 1)
   (love.graphics.rectangle :line 0 0 self.size.x self.size.y)
   (love.graphics.setColor 1 0 0 0.5)
   (with-origin
     (let [wt (self:world-transform)
           bounds wt.bounds]
       (love.graphics.rectangle :fill bounds.left bounds.top self.size.x self.size.y))))
  (on :update [dt]
   (set self.padding (or self.padding 0))
   (when self.bounds
     (let [wt (self:world-transform)]
       (let [bounds wt.bounds
             {:x mx :y my} (input.mouse-position)
             left (- bounds.left self.padding)
             top (- bounds.top self.padding)
             right (+ bounds.right self.padding)
             bottom (+ bounds.bottom self.padding)]
          (when self.bounds.left
             (if (and (> mx left)
                      (> my top)
                      (< mx right)
                      (< my bottom))
               (self.mouse-interaction-state:hover)
               (self.mouse-interaction-state:mouseout))))))))

{: box2d
 : timer
 : mouse-interaction
 :input m-input}
