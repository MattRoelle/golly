(local entity (require :golly.core.entity))
(local mixins (require :golly.core.mixins))
;(local machine (require :lib.statemachine))
(local easing (require :lib.easing))
(local game (require :golly.core.game))
(local graphics (require :golly.graphics))
(local beholder (require :lib.beholder))

(require-macros :golly)

(var base-styles
  {:btn {:background-color [0 0 0 1]
         :border-width 4
         :border-color [1 1 1 1]
         :padding 10
         :margin 20}
   :btn-active { :background-color [1 1 1 1]}
   :btn-label {:color [1 1 1 1]}
   :btn-label-active { :color [0 0 0 1]}})

(fn setstyles [styles]
  (set base-styles (lume.deepmerge base-styles styles)))

(fn btn [props active]
  [:view { :style (lume.merge base-styles.btn (if active base-styles.btn-active {}))}
   (when props.label [:text { :style (lume.merge base-styles.btn-label (if active base-styles.btn-label-active {}))} props.label])
   (when (and props.children (= (type props.children) :table))
     props.children)])
  
  
(fn btn-grid [ctx id ...]
  (fn get-id [x y] (.. id "-" x "-" y))
  (let [rows [...]
        h (length rows)]
   [:view {:style { :flex-direction :column}}
    (unpack (icollect [rowix row (ipairs rows)]
              (let [w (length row)]
               [:view {:style {}} 
                (unpack (icollect [colix col (ipairs row)]
                         (ctx:button (get-id colix rowix)
                                     { :up (when (> rowix 1) (get-id colix (- rowix 1)))
                                       :down (when (< rowix h) (get-id colix (+ rowix 1)))
                                       :left (when (> colix 1) (get-id (- colix 1) rowix))
                                       :right (when (< colix w) (get-id (+ colix 1) rowix))}
                                     col.fn
                                     #(btn col $1))))])))]))

(fn progress-bar [pct label color]
  [:view {:style {:padding 4 :border-width 1 :border-color [1 1 1 1] :flex-direction :row}}
   [:view {:style {:width pct :background-color (or color [1 0 0 1])}}]])

;(fn button [props]
;  (local self 
;    (doto (entity.new-entity (lume.merge { :pivot {:x 0.5 :y 0.5}} props))
;          (mixins.mouse-interaction)
;          (mixins.timer :focus {:duration 0.2})))
;  (set self.buttonstate (machine.create {:initial :inactive 
;                                         :events [{:name :focus :from :inactive :to :active}
;                                                  {:name :blur :from :active :to :inactive}]
;                                         :callbacks {:onenteractive #(self:hover)
;                                                     :onenterinactive #(self:blur)}}))
;  (set self.inputsub
;       (beholder.observe :input 1 :mousepress
;                         #(when (= self.buttonstate.current :active)
;                            (self:on-press))))
       
;  (self:on :hover #(self.timers.focus:reset))
;  (self:on :blur (fn [self]))
;  (self:on :draw 
;           (fn []
;             (match self.buttonstate.current 
;               :active 
;               (let [t self.timers.focus.pct
;                     s (+ 1 (* 0.25 t))]
;                 (with-transform-push
;                   ;(love.graphics.scale s s)
;                    (love.graphics.setColor 1 1 1 1)
;                    (love.graphics.rectangle :line 0 0 self.width self.height)
;                    (love.graphics.setColor 0.35 0.35 0.35 1)
;                    (love.graphics.rectangle :fill 0 0 self.width self.height)))
;               :inactive 
;               (do
;                (love.graphics.setColor 0.5 0.5 0.5 1)
;                (love.graphics.rectangle :line 0 0 self.width self.height)
;                (love.graphics.setColor 0.2 0.2 0.2 1)
;                (love.graphics.rectangle :fill 0 0 self.width self.height)))
;             (love.graphics.setColor 1 1 1 1)
;             (when self.label
;               (let [printf (if self.drops-shadow 
;                              graphics.print-centered-dropshadow 
;                              graphics.print-centered)]
;                 (printf
;                   (match (type self.label) :string self.label :function (self.label))
;                   (or self.font game.assets.font-sm)
;                   (/ self.width 2) (/ self.height 2)
;                   0 
;                   1 1 
;                   0 0)))))
;  (self:on :hover 
;           (fn [self]))
;  (self:on :mouseover #(self.buttonstate:focus))
;  (self:on :mouseout #(self.buttonstate:blur))
;  (self:on :destroy #(beholder.stopObserving self.inputsub))
;  self) 

{: setstyles
 : btn-grid
 : progress-bar}
 ;: btn}
 ;: button}
