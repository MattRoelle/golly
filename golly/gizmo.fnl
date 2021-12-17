(local lume (require :lib.lume))
(local game (require :golly.core.game))
(local tiny (require :lib.tiny))

(local Gizmo {})
(set Gizmo.__index Gizmo)

(fn Gizmo.update [self dt]
 (set self.timer (+ self.timer dt))
 (when (> self.timer self.lifetime)
  (tiny.removeEntity game.scene.ecs-world self)))

(fn Gizmo.drawdebug [self]
 (love.graphics.setColor (unpack self.color))
 (love.graphics.setLineWidth self.line-width)
 (match self.shape
  :circle (love.graphics.circle "fill" 0 0 self.r)
  :rect (love.graphics.rectangle "fill" 0 0 self.w self.h)
  :polygon (love.graphics.polygon "fill" (unpack self.points))
  :line (love.graphics.line 0 0 (- self.x2 self.x) (- self.y2 self.y))))

(fn gizmo [options]
 (print "making gizmo")
 (let [self (lume.merge
             { :shape :circle
               :x 0
               :y 0
               :line-width 2
               :x2 0
               :y2 0
               :w 0
               :h 0
               :r 0
               :angle 0
               :timer 0
               :lifetime 1
               :color [0 0 1 0.5]} options)]
  (setmetatable self Gizmo)
  (game.scene.add-entity self)
  self))

gizmo
