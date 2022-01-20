(local lume (require :lib.lume))
(local inspect (require :lib.inspect))

(fn lerp [a b t]
 (+ (* a (- 1 t)) (* b t)))

(fn lerpangle [a b t]
 (let [dx1 (math.cos a)
       dy1 (math.sin a)
       dx2 (math.cos b)
       dy2 (math.sin b)
       x (lerp dx1 dx2 t)
       y (lerp dy1 dy2 t)]
  (math.atan2 y x)))


(fn lerpto [self f target t]
 (tset self f (lerp (. self f) target t)))

(fn lerptoangle [self f target t]
 (tset self f (lerpangle (. self f) target t)))

(fn uuid []
  (let [template :xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx]
    (string.gsub template "[xy]"
                 (fn [c]
                   (let [v (or (and (= c :x) (math.random 0 15)) (math.random 8 11))]
                     (string.format "%x" v))))))

{ : lerp
  : lerpto
  : lerpangle
  : uuid}

