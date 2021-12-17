;(require-macros :golly)
;(local r (require :golly))
;(local lume (require :lib.lume))
;(local tiny (require :lib.tiny))
;(local beholder (require :lib.beholder))
;(local machine (require :lib.statemachine))
;(local path2dbezier (require :lib.path2d_bezier))

;(local path (require :golly.path))

;(fn ease [t]
;  (- 1 (* (- 1 t) (- 1 t))))

;(local handle
;  (r.defentity {:color [1 0 0 1] :r 5}
;               {:init 
;                (fn [self]
;                  (table.insert r.game.scene.handles self)
;                  (set self.ix (length r.game.scene.handles))
;                  (set self.state (machine.create {:initial :idle
;                                                   :events [{:name :grab :from :idle :to :moving}
;                                                            {:name :release :from :moving :to :idle}]
;                                                   :callbacks {:onenteridle
;                                                               (fn []
;                                                                 (let [first (. r.game.scene.handles 1)
;                                                                       ox first.x 
;                                                                       oy first.y]
;                                                                  (print (.. "[" (accumulate [acc "" _ v (ipairs r.game.scene.handles)] (.. acc " [" (- v.x ox) " " (- v.y oy) "]")) "]"))))}})))
;                :drawscreen
;                (fn [self]
;                  (love.graphics.setColor (unpack (if (= self.state.current :moving) [1 1 0 1] self.color)))
;                  (love.graphics.circle :fill self.x self.y self.r)
;                  (love.graphics.setColor 1 1 1 1)
;                  (love.graphics.print self.ix (+ 10 self.x) self.y))
;                :update
;                (fn [self]
;                  (let [(mx my) (love.mouse.getPosition)
;                        clicking (love.mouse.isDown 1)  
;                        over-handle (< (r.helpers.distance {:x mx :y my} self) self.r)]
;                    (if (and over-handle clicking)
;                      (self.state:grab)
;                      (self.state:release))
;                    (when (= self.state.current :moving)
;                      (set (self.x self.y) (values mx my)))))}))

;(fn curve-editor-scene [scene]
;  (scene.camera:setWorld 0 0 3000 3000)
;  (set scene.handles [])
;  (r.add-entity { :x 0
;                  :y 0
;                  :handles [(r.add-entity (handle {:x 200 :y 200}))
;                            (r.add-entity (handle {:x 300 :y 500 :color [1 1 0 1]}))
;                            (r.add-entity (handle {:x 400 :y 400}))]
;                  :timer 0
;                  :drawscreen
;                  (fn [self]
;                    (love.graphics.setColor 1 1 1 1)
;                    ; (for [i 0 100]
;                    ;   (let [[{: x : y}] (path.catmullrom (/ i 100) self.path)]
;                    ;     (love.graphics.circle :fill x y 2)))
;                    (for [i 0 100]
;                      (let [(x y) (path2dbezier.bezier (/ i 100) (unpack self.path))]
;                        (love.graphics.circle :fill x y 2))))
;                    ; (love.graphics.push)
;                    ; (love.graphics.translate self.shipx self.shipy)
;                    ; (love.graphics.rotate self.shipangle)
;                    ; (love.graphics.polygon :fill -10 -10 -10 10 10 0)
;                    ; (love.graphics.pop))
;                  :update
;                  (fn [self dt]
;                    (set self.timer (+ self.timer (* 0.25 dt)))
;                    (set self.path [])
;                    (each [_ h (ipairs self.handles)]
;                      (table.insert self.path h.x)
;                      (table.insert self.path h.y))
;                    (when (> self.timer 1)
;                      (set self.timer 0)))}))
;                    ;(let [[{: x : y} direction] (path.catmullrom (ease self.timer) self.path)]
;                    ; (let [[{: x : y} direction] (path.catmullrom (ease self.timer) self.path)]
;                    ;  (set (self.shipx self.shipy self.shipangle) (values x y direction))))}))


;curve-editor-scene
