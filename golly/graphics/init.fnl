(require-macros :golly)

(fn dashed-line [p1 p2 dash-size gap-size line-width]
  (when line-width (love.graphics.setLineWidth line-width))
  (local (dx dy) (values (- p2.x p1.x) (- p2.y p1.y)))
  (local (an st) (values (math.atan2 dy dx) (+ dash-size gap-size)))
  (local len (math.sqrt (+ (* dx dx) (* dy dy))))
  (local nm (/ (- len dash-size) st))
  (love.graphics.push)
  (love.graphics.translate p1.x p1.y)
  (love.graphics.rotate an)
  (for [i 0 nm 1] (love.graphics.line (* i st) 0 (+ (* i st) dash-size) 0))
  (love.graphics.line (* nm st) 0 (+ (* nm st) dash-size) 0)
  (love.graphics.pop))  

(fn dashed-rectangle [position w h dash-size gap-size line-width]
  (dashed-line (- position.x (/ w 2)) (- position.y (/ h 2)) (+ position.x (/ w 2)) (- position.y (/ h 2)) dash-size gap-size line-width)
  (dashed-line (- position.x (/ w 2)) (- position.y (/ h 2)) (- position.x (/ w 2)) (+ position.y (/ h 2)) dash-size gap-size line-width)
  (dashed-line (- position.x (/ w 2)) (+ position.y (/ h 2)) (+ position.x (/ w 2)) (+ position.y (/ h 2)) dash-size gap-size line-width)
  (dashed-line (+ position.x (/ w 2)) (- position.y (/ h 2)) (+ position.x (/ w 2)) (+ position.y (/ h 2)) dash-size gap-size line-width))

(fn print-centered [text font position r scale offset]
  (love.graphics.print text font.font position.x position.y (or r 0) (or scale.x 1) (or scale.y 1)
                       (+ (or offset.x 0) (/ (font:get_text_width text) 2))
                       (+ (or offset.y 0) (/ font.h 2))))

(fn print-centered-dropshadow [text font position r scale offset]
  (with-transform-push
    (love.graphics.translate -2 2)
    (with-color [0 0 0 1]
      (love.graphics.print text font.font position.x position.y (or r 0) (or scale.x 1) (or scale.y 1)
                           (+ (or offset.x 0) (/ (font:get_text_width text) 2))
                           (+ (or offset.y 0) (/ font.h 2)))))
  (love.graphics.print text font.font position.x position.y (or r 0) (or scale.x 1) (or scale.y 1)
                       (+ (or offset.x 0) (/ (font:get_text_width text) 2))
                       (+ (or offset.y 0) (/ font.h 2))))

(fn draw-triangle [x y w h]
  (love.graphics.polygon :fill 
                         (vec 0 (- (/ h 2)))
                         (vec 0 (/ h 2))
                         (vec w 0)))

{: dashed-line
 : dashed-rectangle
 : print-centered
 : print-centered-dropshadow
 : draw-triangle
 :animation (require :golly.graphics.animation)}
