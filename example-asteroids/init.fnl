(require-macros :golly)

(local golly (require :golly))
(local bit (require :bit))

(local stage-width 640)
(local stage-height 360)
(local stage-center-x (/ stage-width 2))
(local stage-center-y (/ stage-height 2))

(local box2d-layers 
  {:wall 1 :player 2 :asteroid 4 :bullet 8 :powerup 16})

;; `mixin` macro creates a function that adds fields to the self table.
;; `on` macro is equivalent to (self:on :draw (fn [] ...))
;; This mixin will draw a flat fill of the box2d shpae attached to the entity
(mixin box2d-shape-fill [self props]
  (on :draw []
    (with-origin
      (with-color (or props.color [1 1 1 1])
        (self.draw-box2d-shape :fill)))))

(mixin destroy-out-of-bounds [self props]
  (on :update [] 
      (when (or (< self.position.x -100)
                (< self.position.y -100)
                (> self.position.x (+ stage-width 100))
                (> self.position.y (+ stage-height 100)))
        (self:destroy!))))
       

;; `class` macro creates a constructor function
;; takes single props object
;; `mixins` macro will `doto` the body on to self
(class bullet [self props]
  ;; Entites are indexed in a given scene by their tag 
  ;; in such a way to support common entity access patterns.
  ;; Could also be written as;
  ;; (set self.tags [:bullet])
  (tags :bullet)
  (set self.size (vec 10 5))
  (mixins (box2d-shape-fill {:color [1 1 1 1]})
          (destroy-out-of-bounds)
          (golly.mixins.box2d {:body-type :dynamic 
                               :shape-type :rectangle
                               :linear-damping 0
                               :restitution 1
                               :filter 
                               [box2d-layers.bullet (bit.bor box2d-layers.asteroid) 0]}))
  ; lock rotation
  (on :update [dt]
    (let [(vx vy) (self.body:getLinearVelocity)
          v (vec vx vy)]
      (self.body:setAngle (v:angle))
      (self.body:setAngularVelocity 0)))
  (self:collides-with! :asteroid)
  (on :collision-begin-contact [other coll]
    (when (other:tagged? :asteroid)
      (self.scene:shake 0.3 7)
      (self:destroy!)
      (other:destroy!))))
   
(class asteroid [self props]
  (tags :asteroid)
  (set self.points [])
  (let [vertcount (love.math.random 8 12)
        radius (or self.r (love.math.random 15 30))]
    (set self.r radius)
    (for [i 1 vertcount]
      (let [theta (* math.pi 2 (/ i vertcount))
            r (+ radius (love.math.random -4 4))]
        (table.insert self.points (* (math.cos theta) r))
        (table.insert self.points (* (math.sin theta) r)))))
  (mixins (golly.mixins.box2d {:body-type :dynamic 
                               :shape-type :circle
                               :linear-damping 0
                               :restitution 1
                               :filter 
                               [box2d-layers.asteroid (bit.bor box2d-layers.player
                                                               box2d-layers.asteroid
                                                               box2d-layers.bullet) 0]})
          (destroy-out-of-bounds))
  (on :draw []
    (with-color 1 1 1 1
      (love.graphics.polygon :fill (unpack self.points))))
  (on :destroy []
    (when (> self.r 15)
      (for [i 1 2]
        (self.scene:add-entity (asteroid {:position (self.position:clone)
                                          :r (/ self.r 2)
                                          :initial-velocity (polar-vec2 (* 2 math.pi (math.random))
                                                                        (love.math.random 50 110))}))))))

(class player [self props]
  (print "got here player")
  (tags :player)
  (set self.points [-5 5 -5 -5 9 0])
  (mixins (box2d-shape-fill {:color [0 1 1 1]}) 
          (golly.mixins.box2d {:body-type :dynamic 
                               :shape-type :polygon
                               :linear-damping 2
                               :restitution 1
                               :mass 20
                               :angular-damping 5
                               :filter 
                               [box2d-layers.player (bit.bor box2d-layers.wall box2d-layers.asteroid) 0]}))

  (on :update [dt]
    ;; movement function returns a normalized vector
    ;; Data comes from either gamepad left analog stick, gamepad d pad, WASD, or arrow keys
    (let [input (golly.input.movement)]
      (self.body:applyTorque (* input.x 60)
        (let [force (* input.y -50)
              ;; vec and polar-vec2 comes from golly.math.vector, fennel friendly vector lib
              direction (polar-vec2 (self.body:getAngle) 1)
              {: x : y} (* force direction)]
          (self.body:applyForce x y))))
    ;; golly.input.pressed? takes 2 parameters
    ;; First is what player, 1 refers to player 1
    ;; "a" is referring to the symbolic a button, not the a on the keyboard.
    ;; Sometimes the "a" button on a gamepad
    ;; It is triggered by spacebar on a keyboardc
    ;; This is so code works with controllers as well as keyboards out of the box
    ;; TODO: Support customizable button/key mapping
    (when (and (golly.input.pressed? 1 :a) (not self.reloading))
      (set self.reloading true)
      ;; Reference current scene via self.scene
      (self.scene:add-entity 
        (bullet {:position (self.position:clone) 
                 :initial-velocity (polar-vec2 (self.body:getAngle) 10)}))
      ;; Timelines are a core part of Golly, used for representing anything that takes place 
      ;; Over time.  This timeline prevents another shot from being fired for some time after shooting
      (self:timeline :shoot
        [:wait 0.25]
       #(set self.reloading false)))))

(class wall [self props]
  (tags :wall)
  (mixins (golly.mixins.box2d {:body-type :kinematic 
                               :shape-type :rectangle})))

(class starfield [self props]
  (set self.ps
     (let [ps (love.graphics.newParticleSystem (. (golly.game.get-game) :assets :circle))]
        (ps:setParticleLifetime 2 4)
        (ps:setSpread 100)
        (ps:setEmissionArea :normal stage-width stage-height)
        (ps:setSizes 0.02 0.02 0)
        (ps:setSpeed 10 20)
        (ps:setDirection 10 10)
        (ps:setEmissionRate 100)
        (ps:start)
        ps))
  (on :update [dt] (self.ps:update dt))
  (on :draw [] (love.graphics.draw self.ps)))

(class director [self props]
  (on :init [] 
      (self:add-children
        (starfield)
        (player {:position (vec stage-center-x stage-center-y)})
        (wall {:position (vec stage-center-x -25) :size (vec stage-width 50)})
        (wall {:position (vec stage-center-x (+ stage-height 25)) :size (vec stage-width 50)})
        (wall {:position (vec -25 stage-center-y) :size (vec 50 stage-height)})
        (wall {:position (vec (+ stage-width 25) stage-center-y) :size (vec 50 stage-height)}))
      ;; This timeline says: Every 0.1 seconds, checkif there are no asteroids, spawn one.
      ;; Randomly sometimes spawn more
      ;; repeat with no count parameter goes forever
      (self:timeline :main 
        (golly.timeline.repeat
          #(let [asteroids (self.scene:find-all :asteroid)
                 count (length asteroids)]
             (when (or (< count 2)
                       (and (< count 8) (< (love.math.random 0 100) 5)))
               (self.scene:add-entity
                 (let [spawn-location (lume.randomchoice
                                        [{:position (vec (+ (* 0.2 stage-width)
                                                            (love.math.random 0 (* 0.8 stage-width)))
                                                        -25)
                                          :initial-velocity (polar-vec2 (+ (love.math.random -1 1) golly.math.angledown) 100)}
                                         {:position (vec (+ (* 0.2 stage-width)
                                                            (love.math.random 0 (* 0.8 stage-width)))
                                                        (+ stage-height 25))
                                          :initial-velocity (polar-vec2 (+ (love.math.random -1 1) golly.math.angleup) 100)}])]
                   (asteroid spawn-location)))))
          [:wait 0.1]))))


(fn main [scene]
  ; This scales the frame size up to the window size and handles black bars etc
  ; Thinking about scene middleware using functional composition and threading macros. ->
  (golly.scene.draw-game-frame scene)
  (scene:add-entity (director))
  scene)

(golly.set-game {: main
                 : stage-width 
                 : stage-height
                 :assets {:circle (love.graphics.newImage "example-assets/circle.png")}})

