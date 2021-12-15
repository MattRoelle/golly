(local Vector2D {})
(set Vector2D.__index Vector2D)

(fn Vector2D.clamp [self min max]
  (local x (math.min (math.max self.x min.x) max.x))
  (local y (math.min (math.max self.y min.y) max.y))
  (self:set x y)
  self)

;; TODO: Implement Vector3d
(local Vector3D {})
(set Vector3D.__index #(error "TODO: Implement Vector3D"))

;; TODO: Implement Vector4d / Quaternion / Colors
(local Vector4D {})
(set Vector4D.__index #(error "TODO: Implement Vector4D"))

(fn vec [x y z? w?]
  (setmetatable 
    {:x x 
     :y y 
     :z z? 
     :w w?}
    (if w? Vector4D 
        z? Vector3D 
        Vector2D)))

(fn polar-vec2 [theta magnitude]
  (vec (* (math.cos theta) magnitude)
       (* (math.sin theta) magnitude)))

(fn Vector2D.__unm [v] (vec (- v.x) (- v.y)))

(fn Vector2D.__add [a b] (vec (+ a.x b.x) (+ a.y b.y)))

(fn Vector2D.__sub [a b] (vec (- a.x b.x) (- a.y b.y)))

(fn Vector2D.__mul [a b]
  (if (= (type a) :number) (vec (* a b.x) (* a b.y))
      (= (type b) :number) (vec (* a.x b) (* a.y b))
      (vec (* a.x b.x) (* a.y b.y))))

(fn Vector2D.__div [a b]
  (vec (/ a.x b) (/ a.y b)))

(fn Vector2D.__eq [a b]
  (and (= a.x b.x) (= a.y b.y)))

(fn Vector2D.__tostring [self]
  (.. "(" self.x ", " self.y ")"))

(fn Vector2D.distance-to [a b]
  (math.sqrt (+ (^ (- a.x b.x) 2) (^ (- a.y b.y) 2))))

(fn Vector2D.angle-to [a b]
  (math.atan2 (- a.y b.y) (- a.x b.x)))

(fn Vector2D.angle-from [a b]
  (math.atan2 (- b.y a.y) (- b.x a.x)))

(fn Vector2D.angle [self]
  (math.atan2 self.y self.x))

(fn Vector2D.set-angle [self angle]
  (let [len (self:length)]
    (vec (* (math.cos angle) len)
         (* (math.sin angle) len))))

(fn Vector2D.set-angle! [self angle]
  (let [len (self:length)]
    (set (self.x self.y)
         (values (* (math.cos angle) len)
                 (* (math.sin angle) len)))))


(fn Vector2D.rotate! [self theta]
  (let [s (math.sin theta)
        c (math.cos theta)]
      (vec (+ (* c self.x) (* s self.y)) (+ (- (* s self.x)) (* c self.y)))))

(fn Vector2D.rotate [self theta]
  (let [s (math.sin theta)
        c (math.cos theta)]
      (vec (+ (* c self.x) (* s self.y)) (+ (- (* s self.x)) (* c self.y)))))

(fn Vector2D.unpack [self]
  (values self.x self.y))

(fn Vector2D.clone [self]
  (vec self.x self.y))

(fn Vector2D.length [self]
  (math.sqrt (+ (^ self.x 2) (^ self.y 2))))

(fn Vector2D.set-length [self len]
  (let [theta (self:angle)]
    (vec (* (math.cos theta) len)
         (* (math.sin theta) len))))

(fn Vector2D.set-length! [self len]
  (let [theta (self:angle)]
    (set (self.x self.y)
         (values (* (math.cos theta) len)
              (* (math.sin theta) len)))))

(fn Vector2D.magsq [self]
  (+ (^ self.x 2) (^ self.y 2)))

(fn Vector2D.normalize! [self]
  (let [mag (self:length)]
    (when (= mag 0)
      (set (self.x self.y)
           (values (/ self.x mag) (/ self.y mag))))))

(fn Vector2D.normalize [self]
  (let [mag (self:length)]
    (if (= mag 0)
      self
      (vec (/ self.x mag) (/ self.y mag)))))

(fn Vector2D.dot [self v]
  (+ (* self.x v.x) (* self.y v.y)))

(fn Vector2D.limit! [self max]
  (let [magsq (self:lengthsq)
        theta (self:angle)]
    (if (> magsq (^ max 2))
      (set (self.x self.y)
           (values (* (math.cos theta) max)
                   (* (math.sin theta) max))))))

(fn Vector2D.limit [self max]
  (let [magsq (self:lengthsq)
        theta (self:angle)]
    (if (> magsq (^ max 2))
      (polar-vec2 theta max)
      self)))

{: vec 
 : polar-vec2}
