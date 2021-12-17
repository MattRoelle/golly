(require-macros :golly)

(local entity (require :golly.core.entity))
(local game (require :golly.core.game))
(local mixins (require :golly.core.mixins))

(class physics-particle [self props]
  (set self.size (vec 9 9))
  (set self.pivot (vec 0.5 0.5))
  (set self.z-index 10)
  (set self.r (+ 2 (* 2 (math.random)))) 
  (mixin (mixins.box2d {:body-type :dynamic
                        :shape-type :circle 
                        :restitution 1
                        :linear-damping 8
                        :angular-damping 20
                        :filter [32 0 0]
                        :mass 0.5
                        :r self.r})
         (mixins.timer :die {:duration (+ 0.25 (* 0.25 (math.random)))})
         (mixins.litsprite (lume.randomchoice [:particle1 :particle2 :particle3]) (or self.colorkey :white)))
  (set self.scale 0.75)
  (on :timer-die []
      (self:destroy!)) 
  (on :update [dt]
      (set self.scale (* (vec 1 1) (* 0.75 (- 1 self.timers.die.pct)))))

  (on :init []
    (let [direction (* (math.random) 2 math.pi)
          force (+ 0.5 (* (math.random) 0.1))]
      (self.body:applyLinearImpulse (* (math.cos direction) force)
                                    (* (math.sin direction) force))))

                  
  self)

(fn explode [scene x y intensity props]
  (for [i 1 (love.math.random (* intensity 0.5) intensity)]
    (scene:add-entity (physics-particle (lume.merge {:position (vec x y) } props)))))

(fn prompt [scene t duration]
  (let [existing (scene:find :prompt)]
    (when existing (existing:destroy!)))
  (local self (entity.new-entity {:position (vec 10 (- game.stage-height 100))}))
  (mixins.timer self :destroy {:duration (or duration 5)})
  (self:on :timer-destroy #(scene:destroy-entity self))
  (self:on :draw (fn [self] 
                   (love.graphics.setColor 1 1 1 1)
                   (love.graphics.print t)))
  (scene:add-entity self))


(fn img-flash [scene x y img color duration flasht]
  (local self (entity.new-entity {:position (vec x y)}))
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
