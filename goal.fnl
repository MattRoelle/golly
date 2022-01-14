(local g (require :golly))

(local box2d (g.class))
(box2d:method :initialize-box2d {:on :init}
  (fn [self]
    (set self.body (love.physics.newBody ...))))

(local player (g.class))
(player:mixin g.mixins.box2d {:body-type :dynamic 
                              :shape-type :rectangle})
(player:field :hp 100)
(player:field :transform.scale (vec 2 2))

(player:method :render {:on :draw}
  (fn [self]
    (print "drawing")))

(player:statemachine :main :idle
   {:jump {:from :idle :to :jumping}
    :land {:to :idle}})

(player:method
  :jump-update
  {:state {:main :jumping} :on :update}
  (fn [self dt]
    (print "I only get called while in the jump state")))

(player:method :enter-jumping {:on :state-main-enter-jump})

(fn main [scene]
  (scene:add-entity (player {:transform.position (vec 200 200)})))

(g.boot {:scenes {: main}})
