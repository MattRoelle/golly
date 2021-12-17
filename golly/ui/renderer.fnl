(local lume (require :lib.lume))
(local inpsect (require :lib.inspect))

;; Sample UI
;; [:view { :style { :margin 10 :padding 10 :background-color [1 1 1]}}
;;  [:text { :style { :font-size 16 :color [0 0 0] } "Hello"}]

(local default-style-prop { :margin-top 0
                            :margin-bottom 0
                            :margin-left 0
                            :margin-right 0
                            :padding-top 0
                            :padding-bottom 0
                            :padding-left 0
                            :font nil
                            :padding-right 0
                            :width 1
                            :position :relative
                            :x 0
                            :y 0
                            :height 1
                            :border-width 0
                            :border-color [0 0 0]
                            :flex-direction :row
                            :background-color nil
                            :color [1 1 1]})

(fn expand-styles [styles]
 (let [styles (or styles {})
       out (lume.merge default-style-prop styles)]
  (when styles.margin
   (when (not styles.margin-top) (set out.margin-top styles.margin))
   (when (not styles.margin-bottom) (set out.margin-bottom styles.margin))
   (when (not styles.margin-left) (set out.margin-left styles.margin))
   (when (not styles.margin-right) (set out.margin-right styles.margin)))
  (when styles.padding
   (when (not styles.padding-top) (set out.padding-top styles.padding))
   (when (not styles.padding-bottom) (set out.padding-bottom styles.padding))
   (when (not styles.padding-left) (set out.padding-left styles.padding))
   (when (not styles.padding-right) (set out.padding-right styles.padding)))
  out))

(fn render-node [node parent-w parent-h]
 (let [[node-type props] node
       children [(select 3 (unpack node))]
       ; _ (pp node-type)
       ; _ (pp props)
       ; _ (pp children)
       proptype (type props)
       style (expand-styles (if (= proptype :function) {} props.style))
       width (* style.width (- parent-w style.margin-left style.margin-right))
       height (* style.height (- parent-h style.margin-top style.margin-bottom))
       content-width (- width style.padding-left style.padding-right)
       content-height (- height style.padding-top style.padding-bottom)
       n-children (length children)]
  (love.graphics.push)
  (love.graphics.translate style.margin-left style.margin-top)
  (when style.background-color
   (love.graphics.setColor (unpack style.background-color))
   (love.graphics.rectangle "fill" 0 0 width height))
  (when (> style.border-width 0)
   (love.graphics.setColor (unpack style.border-color))
   (love.graphics.setLineWidth style.border-width)
   (love.graphics.rectangle "line" 0 0 width height))
  (love.graphics.translate style.padding-left style.padding-top)
  (match node-type 
      :view
      (match style.position
        ; :absolute
        ; (do
        ;   (love.graphics.push)
        ;   (love.graphics.translate style.x style.y)
        ;   (render-node child style.width style.height)
        ;   (love.graphics.pop))
        :relative
        (let [child-width (if (or (= style.flex-direction :row)
                                  (= style.flex-direction :row-reverse))
                              (/ content-width n-children)
                              content-width)
              child-height (if (or (= style.flex-direction :column)
                                   (= style.flex-direction :column-reverse))
                               (/ content-height n-children)
                               content-height)]
          (love.graphics.push)
          ; (when (= style.flex-direction :row-reverse)
          ;   (love.graphics.translate width) 0)
          (when (= style.flex-direction :column-reverse)
            (love.graphics.translate 0 200))
          (each [ix child (ipairs children)]
           (let [i (- ix 1)
                 x (match style.flex-direction
                     :row (* i child-width)
                     :row-reverse (* -1 i child-width)
                     :column 0
                     :column-reverse 0)
                 y (match style.flex-direction
                     :row 0 
                     :row-reverse 0 
                     :column (* i child-height)
                     :column-reverse (* i child-height))
                       
                 y (if (= style.flex-direction :column) (* i child-height) 0)]
            (love.graphics.push)
            (love.graphics.translate x y)
            (render-node child child-width child-height)
            (love.graphics.pop)))
          (love.graphics.pop)))
      :custom-draw
      (props width height)
      :text
      (do
       (love.graphics.setColor (unpack style.color))
       (when style.font (love.graphics.setFont style.font))
       (love.graphics.printf children 0 0 content-width)))
  (love.graphics.pop)))

(fn draw [uidef]
  (assert uidef.width "Must pass width")
  (assert uidef.height "Must pass height")
  (assert uidef.root "Must pass root")
  (love.graphics.push)
  (love.graphics.translate (or uidef.x 0) (or uidef.y 0))
  (render-node uidef.root uidef.width uidef.height)
  (love.graphics.pop))

{: draw}
