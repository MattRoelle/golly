(local SpritesheetAnimation {})
(set SpritesheetAnimation.__index SpritesheetAnimation)

(fn SpritesheetAnimation.update [self dt]
  (set self.timer (+ self.timer dt))
  (when (> self.timer self.delay)
    (set self.ix (+ self.ix 1))
    (set self.timer 0))
  (when (> self.ix self.options.end)
    (when self.options.on-complete (self.options.on-complete self))
    (if self.options.loop
      (set self.ix self.options.start)
      (set self.done true))))

(fn SpritesheetAnimation.draw [self]
  (when (not self.done)
    (love.graphics.setColor (unpack self.options.color))
    (self.spritesheet:draw self.ix)))

(fn spritesheet-animation [spritesheet options?]
  (let [options (lume.merge {:loop false
                             :start 1
                             :end 2
                             :color [1 1 1 1]
                             :on-complete nil
                             :fps 8} (or options? {}))
        delay (/ 1 options.fps)]
    (setmetatable 
       {:timer 0 
        :ix options.start
        : delay
        : options
        : spritesheet
        :drawable true}
      SpritesheetAnimation)))

(fn animation-set [ defs]
  (collect [k [spritesheet start end options?] (pairs defs)]
    (let [options (lume.merge {:loop true :fps 8} (or options? {}))]
      (values k (spritesheet-animation spritesheet
                  {: start 
                   : end
                   :loop options.loop
                   :fps options.fps
                   :color [1 1 1 1]})))))

{: spritesheet-animation
 : animation-set}
