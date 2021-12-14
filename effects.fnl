(local entity (require :golly.core.entity))
(local game (require :golly.core.game))
(local mixins (require :golly.core.mixins))

(fn physics-particle [props]  
  (local self (entity.new-entity (lume.merge {:width 9 :z 10 :height 9 :pivot {:x 0.5 :y 0.5}} props)))
  (set self.r (+ 2 (* 2 (math.random)))) 
  (mixins.box2d self {:body-type :dynamic
                      :shape-type :circle 
                      :restitution 1
                      :linear-damping 8
                      :angular-damping 20
                      :filter [32 0 0]
                      :mass 0.5
                      :r self.r})
  (mixins.timer self :die {:duration (+ 0.25 (* 0.25 (math.random)))})
  (set self.scale 0.75)

  (mixins.litsprite self (lume.randomchoice [:particle1 :particle2 :particle3]) (or self.colorkey :white))
  (self:on :timer-die #(self:destroy!)) 
  (self:on :update (fn [dt] (set self.scale (* 0.75 (- 1 self.timers.die.pct)))))

  (local direction (* (math.random) 2 math.pi))
  (local force (+ 0.5 (* (math.random) 0.1)))

  (self:on :init #(self.body:applyLinearImpulse (* (math.cos direction) force)
                                                (* (math.sin direction) force)))

                  
  self)

(fn explode [scene x y intensity props]
  (for [i 1 (love.math.random (* intensity 0.5) intensity)]
    (scene:add-entity (physics-particle (lume.merge {: x : y} props)))))

(fn prompt [scene t duration]
  (let [existing (scene:find :prompt)]
    (when existing (existing:destroy!)))
  (local self (entity.new-entity {:x 10 :y (- game.stage-height 100)}))
  (mixins.timer self :destroy {:duration (or duration 5)})
  (self:on :timer-destroy #(scene:destroy-entity self))
  (self:on :draw (fn [self] 
                   (love.graphics.setColor 1 1 1 1)
                   (love.graphics.print t)))
  (scene:add-entity self))


(fn img-flash [scene x y img color duration flasht]
  (local self (entity.new-entity {: x : y}))
  (mixins.timer self :destroy {:duration (or duration 5)})
  (mixins.timer self :flash {:duration (or flasht 0.07)})
  (self:on :timer-destroy #(self:destroy!))
  (self:on :timer-flash #(do
                           (set self.alpha (- 1 self.alpha))
                           (self.timers.flash:reset)))
  (set self.alpha 1)
  (self:on :draw (fn [] 
                   (let [[_r _g _b] (or color [1 1 1])]
                     (love.graphics.setColor _r _g _b self.alpha)
                     (love.graphics.draw (. game.assets img)))))
  (scene:add-entity self))

{: explode
 : prompt
 : img-flash}
