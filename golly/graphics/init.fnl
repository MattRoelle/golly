(require-macros :golly)

(fn dashed-line [x1 y1 x2 y2 dash-size gap-size line-width]
  (when line-width (love.graphics.setLineWidth line-width))
  (local (dx dy) (values (- x2 x1) (- y2 y1)))
  (local (an st) (values (math.atan2 dy dx) (+ dash-size gap-size)))
  (local len (math.sqrt (+ (* dx dx) (* dy dy))))
  (local nm (/ (- len dash-size) st))
  (love.graphics.push)
  (love.graphics.translate x1 y1)
  (love.graphics.rotate an)
  (for [i 0 nm 1] (love.graphics.line (* i st) 0 (+ (* i st) dash-size) 0))
  (love.graphics.line (* nm st) 0 (+ (* nm st) dash-size) 0)
  (love.graphics.pop))  

(fn dashed-rectangle [x y w h dash-size gap-size line-width]
  (dashed-line (- x (/ w 2)) (- y (/ h 2)) (+ x (/ w 2)) (- y (/ h 2)) dash-size gap-size line-width)
  (dashed-line (- x (/ w 2)) (- y (/ h 2)) (- x (/ w 2)) (+ y (/ h 2)) dash-size gap-size line-width)
  (dashed-line (- x (/ w 2)) (+ y (/ h 2)) (+ x (/ w 2)) (+ y (/ h 2)) dash-size gap-size line-width)
  (dashed-line (+ x (/ w 2)) (- y (/ h 2)) (+ x (/ w 2)) (+ y (/ h 2)) dash-size gap-size line-width))

(fn drop-shadow [draw-fn x y]
  (with-transform-push
    (with-color 0 0 0 1
      (love.graphics.translate (or x -1) (or y -1))
      (draw-fn)))
  (draw-fn))

(fn print-centered [text font x y r sx sy ox oy]
  (love.graphics.print text font.font x y (or r 0) (or sx 1) (or sy 1)
                       (+ (or ox 0) (/ (font:get_text_width text) 2))
                       (+ (or oy 0) (/ font.h 2))))

(fn print-centered-dropshadow [text font x y r sx sy ox oy]
  (with-transform-push
    (love.graphics.translate -2 2)
    (with-color 0 0 0 1
      (love.graphics.print text font.font x y (or r 0) (or sx 1) (or sy 1)
                           (+ (or ox 0) (/ (font:get_text_width text) 2))
                           (+ (or oy 0) (/ font.h 2)))))
  (love.graphics.print text font.font x y (or r 0) (or sx 1) (or sy 1)
                       (+ (or ox 0) (/ (font:get_text_width text) 2))
                       (+ (or oy 0) (/ font.h 2))))

{: dashed-line
 : dashed-rectangle
 : print-centered
 : print-centered-dropshadow}
