(local gollymath (require :golly.math))

(local Spritesheet {})
(set Spritesheet.__index Spritesheet)

(fn Spritesheet.get-frame-index [self p]
  (+ p.x (* (- p.y 1) (+ self.width 1))))

(fn Spritesheet.draw [self frame-ix]
  (love.graphics.push)
  (love.graphics.draw self.img (. self.quads frame-ix) 0 0 0 1 1)
  (love.graphics.pop))

(fn spritesheet [path cell-w cell-h sheet-w sheet-h]
 (let [img (love.graphics.newImage path)
       image-w (img:getWidth)
       image-h (img:getHeight)
       quads []]
  (img:setFilter "nearest" "nearest")
  (for [y 0 (- sheet-h 1)]
   (for [x 0 (- sheet-w 1)]
    (table.insert quads
                  (love.graphics.newQuad
                   (* cell-w x) (* cell-h y)
                   cell-w cell-h
                   image-w image-h))))
  (setmetatable 
    {: img
     : quads
     :width sheet-w 
     :height sheet-h
     :frames (length quads)}
    Spritesheet)))

spritesheet
