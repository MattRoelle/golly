(local lume (require :lib.lume))

(local Vec2 {})
(set Vec2.__index Vec2)
(fn vec2 [x y]
  (setmetatable {: x : y } Vec2))

(fn Vec2.__unm [self]
 (vec2 (* -1 self.x) (* -1 self.y)))

(fn Vec2.__mul [self s]
  (if (= (type s) "number")
      (vec2 (* self.x s) (* self.y s))
      (vec2 (* self.x s.x) (* self.y s.y))))

(fn Vec2.__div [self s]
  (if (= (type s) "number")
      (vec2 (/ self.x s) (/ self.y s))
      (vec2 (/ self.x s.x) (/ self.y s.y))))

(fn Vec2.__add [self s]
  (if (= (type s) "number")
      (vec2 (+ self.x s) (+ self.y s))
      (vec2 (+ self.x s.x) (+ self.y s.y))))

(fn Vec2.__sub [self s]
  (if (= (type s) "number")
      (vec2 (- self.x s) (- self.y s))
      (vec2 (- self.x s.x) (- self.y s.y))))

(fn convert-path [...]
  (let [rest [...]
        first (. rest 1)]
    (if (= (getmetatable first) Vec2) rest
        (icollect [_ p (ipairs rest)]
                  (vec2 (. p 1) (. p 2))))))

(fn distance [p1 p2]
    (let [dx (- p1.x p2.x)
          dy (- p1.y p2.y)]
        (math.sqrt (+ (* dx dx) (* dy dy)))))

(fn get-cmrom-seg [t path]
  (let [sz (length path)
        step (/ 1 (- sz 3))
        i (math.min (- sz 3) (+ 1 (math.floor (/ t step))))
        j (+ i 3)
        points (lume.slice path i j)
        tt (/ (- t (* (- i 1) step)) step)] 
    ;(pp {: i : t : tt})
    [tt points]))

(fn cmrom-val [t path]
  (let [[p1 p2 p3 p4] path]
   (/ (+ (+ (+ (* p2 2) (* (+ (- p1) p3) t))
            (* (- (+ (- (* p1 2) (* p2 5)) (* p3 4)) p4) (^ t 2)))
         (* (+ (- (+ (- p1) (* p2 3)) (* p3 3)) p4) (^ t 3))) 2)))
  
(fn catmullrom [t input]
  "Compute the point at given t along a Catmull-Rom Spline"
  (assert (>= (length input) 4) "Must pass at least 4 control points")
  (let [fullpath (convert-path (unpack input))
        [t path] (get-cmrom-seg t fullpath)]
   (let [a (cmrom-val t path)
         b (cmrom-val (- t 0.0001) path)
         direction (math.atan2 (- a.y b.y) (- a.x b.x))]
     [a direction])))

{: catmullrom}





