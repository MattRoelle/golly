
(local inspect (require :lib.inspect))

(fn load [path cell-w cell-h sheet-w sheet-h]
 (let [img (love.graphics.newImage path)
       image-w (img:getWidth)
       image-h (img:getHeight)
       quads []]
  (img:setFilter "nearest" "nearest")
  (for [y 0 sheet-h]
   (for [x 0 sheet-w]
    (table.insert quads (love.graphics.newQuad
                         (* cell-w x)
                         (* cell-h y)
                         cell-w
                         cell-h
                         image-w
                         image-h))))
  {:quads quads
   :img img
   :quads quads
   :pivot [0.5 0.5]
   :bounds [cell-w cell-h]
   :frames (length quads)
   :draw
   (fn [self ix]
    (love.graphics.push)
    (let [[ox oy] self.pivot
          [sx sy] self.bounds
          ox (* -1 ox sx)
          oy (* -1 oy sy)]
      (love.graphics.draw self.img (. quads ix) ox oy 0 1 1)
      (love.graphics.pop)))}))

(fn animation [ss props]
  (let [options (lume.merge {:loop false
                             :start 1
                             :end 2
                             :color [1 1 1 1]
                             :on-complete nil
                             :fps 60} props)
        delay (/ 1 options.fps)]
    (lume.merge 
      options
      {:timer 0 
       :ix options.start
       :drawable true
       :update
       (fn [self dt]
         (set self.timer (+ self.timer dt))
         (when (> self.timer delay)
           (set self.ix (+ self.ix 1))
           (set self.timer 0))
         (when (> self.ix options.end)
           (when options.on-complete (options.on-complete self))
           (if options.loop
             (set self.ix options.start)
             (set self.done true))))
       :draw
       (fn [self dt]
         (when (not self.done)
           (love.graphics.setColor (unpack self.color))
           (ss:draw self.ix)))})))
       

(local zscale 1)

(fn draw-spritestack [ss rot camera-angle]
 (let [xstep (* zscale (math.cos camera-angle))
       ystep (* zscale (math.sin camera-angle))]
  (love.graphics.push)
  (for [i 1 ss.frames]
   (love.graphics.translate xstep ystep)
   (ss:draw i))
  (love.graphics.pop)))

{: load
 : animation
 : draw-spritestack}
