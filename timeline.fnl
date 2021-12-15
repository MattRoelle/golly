(local tween (require :lib.tween))
(local inspect (require :lib.inspect))

; (timeline :spin
;   [:repeat :infinite [:tween 1 self { :angle (+ self.angle 360)}]])
;
; (timeline :swing
;  [:wait 0.5]
;  [:tween self 1 { :x 100}]
;  #(self:transition :player :idle))

(fn convert-timeline-stage-wait [[_ duration]]
  {:type :wait
   :duration duration
   :start-time -1
   :t 0
   :reset #(set $1.t 0)
   :update
   (fn [self dt]
     (set self.t (+ self.t dt))
     (if (> self.t self.duration) nil true))})

(fn convert-timeline-stage-tween [[_ duration subject target easing]]
  {:type :tween
   :tween (tween.new duration subject target easing)
   :reset #(set $1.tween (tween.new duration subject target easing))
   :update
   (fn [self dt]
     (if (self.tween:update dt) nil true))})

(fn convert-timeline-stage [stage]
  (match (. stage 1)
    :tween (convert-timeline-stage-tween stage)
    :wait (convert-timeline-stage-wait stage)))

(fn convert-timeline-stages [stages]
  (icollect [ix stg (ipairs stages)]
   (do
     (if (= (type stg) "table") ; TODO: figure out why `sequence?` is undefined
         (convert-timeline-stage stg)
         {:type :funcall :update (fn [self dt]
                                  (stg self dt)
                                  nil)}))))

(local Timeline {})
(set Timeline.__index Timeline)

(fn Timeline.destroy! [self]
  (when self.destroyed (lua :return))
  (table.insert self.scene.removal-queue self)
  (set self.destroyed true))

(fn Timeline.update [self dt]
  (when self.destroyed (lua :return))
  (when (> self.ix (length self.stages))
      (lua "return nil"))
  (let [current-stage (. self.stages self.ix)
         done-executing-stage (= nil (current-stage:update dt))]
   (when done-executing-stage
     (self:next-stage)))
  (if (> self.ix (length self.stages)) nil self))

(fn Timeline.next-stage [self]
  (set self.ix (+ self.ix 1)))

(local RepeatTimeline {:update Timeline.update})
(set RepeatTimeline.__index RepeatTimeline)

(fn RepeatTimeline.next-stage [self]
  (set self.ix (+ self.ix 1))
  (when (and (self:can-continue?)
             (> self.ix (length self.stages)))
    (set self.ix 1)
    (set self.iteration (+ self.iteration 1))
    (each [_ stg (ipairs self.stages)]
      (stg:reset))))

(fn repeat [...]
  (let [input [...]
        [times & rest] input
        typeof-times (type times)
        stages (convert-timeline-stages
                 (if (= typeof-times :number) rest input))]
    (setmetatable {:ix 1
                   :stages stages
                   :can-continue?
                   #(and (or (= $1.times nil) 
                             (< $1.iteration $1.times)))
                   :iteration 1
                   :times times
                   :type :timeline}
                  RepeatTimeline)))

(fn t-while [...]
  (let [input [...]
        [f & rest] input
        stages (convert-timeline-stages rest rest)]
    (setmetatable {:ix 1
                   :stages stages
                   :can-continue? #(f $1.scene)
                   :iteration 1
                   :type :timeline}
                  RepeatTimeline)))

(fn timeline [...]
  (let [stages (convert-timeline-stages [...])]
    (setmetatable {:ix 1
                   :stages stages
                   :type :timeline}
                  Timeline)))

(local TweenTimeline {})
(set TweenTimeline.__index TweenTimeline)
(fn TweenTimeline.update [self dt]
 (if (self.tween:update dt) nil self))

(fn wrap-tween [tween]
    (setmetatable {:tween tween}
                  TweenTimeline))

(local module {: wrap-tween
               : repeat
               :while t-while})
(setmetatable module {:__call timeline})
