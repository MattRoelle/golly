(local AABB {})
(set AABB.__index AABB)

(fn aabb [position size]
  "Create a new AABB."
  (let [r (setmetatable {: position : size} AABB)]
    (r:init!)
    r))

(fn AABB.__tostring [self]
  (.. "AABB [(" self.position.x ", " self.position.y ")"
      " " 
      "(" self.size.x ", " self.size.y ")]"))

(fn AABB.init! [self]
  "Initialize the AABB."
  (self:calculate-bounds!))

(fn AABB.calculate-bounds! [self]
  "Calculate the bounds and sets the left, right, top, and bottom properties."
  (set self.left self.position.x)
  (set self.top self.position.y)
  (set self.right (+ self.position.x self.size.x))
  (set self.bottom (+ self.position.y self.size.y)))

(fn AABB.set-position! [self position]
  "Set the position of the AABB and calculates the bounds."
  (set self.position position)
  (self:calculate-bounds!))

(fn AABB.set-size! [self size]
  "Set the size of the AABB and calculates the bounds."
  (set self.size size)
  (self:calculate-bounds!))

(fn AABB.set-left! [self left]
  "Set the left of the AABB and calculates the bounds."
  (let [width-delta (- self.left left)]
    (set self.position.x left)
    (set self.size.x (+ self.size.x width-delta)))
  (self:calculate-bounds!))

(fn AABB.set-right! [self right]
  "Set the right side of the AABB and calculates the bounds."
  (let [width-delta (- right self.right)]
    (set self.size.x (+ self.size.x width-delta)))
  (self:calculate-bounds!))

(fn AABB.set-top! [self top]
  "Set the top of the AABB and calculates the bounds."
  (let [height-delta (- self.top top)]
    (set self.position.y top)
    (set self.size.y (+ self.size.y height-delta)))
  (self:calculate-bounds!))

(fn AABB.set-bottom! [self bottom]
  "Set the bottom of the AABB and calculates the bounds."
  (let [height-delta (- bottom self.bottom)]
    (set self.size.y (+ self.size.y height-delta)))
  (self:calculate-bounds!))

(fn AABB.intersects? [self other]
 "Check if the AABB intersects other."
 (not (or (< self.right other.left)
         (< other.right self.left)
         (< self.bottom other.top)
         (< other.bottom self.top))))

{: aabb}
