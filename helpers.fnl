(local game (require :golly.core.game))
(local tween (require :lib.tween))
(local gizmo (require :golly.gizmo))
(local inspect (require :lib.inspect))
(local lume (require :lib.lume))
(local path2d_catmullrom (require :lib.path2d_catmullrom))

(fn distance [e1 e2]
  (e1.position:distance-to e2.position))

(fn closest [self entities]
 (let [by-dist (icollect [_ ent (ipairs (or entities []))]
                         [ent (distance self ent)])
       sorted (lume.sort by-dist #(< (. $1 2) (. $2 2)))]
    (or (. sorted 1) [nil 0])))

(fn distance-tween [self x y speed]
  (let [dist (distance self.x self.y x y)
        duration (/ dist speed)]
    (tween.new duration self { :x x :y y})))

(fn move-towards [self ent speed]
 (let [dx (- ent.position.x self.position.x)
       dy (- ent.position.y self.position.y)
       theta (math.atan2 dy dx)
       stepx (* speed (math.cos theta))
       stepy (* speed (math.sin theta))]
   (tset self :angle theta)
   (when self.move (self:move stepx stepy))
   (when self.body (self.body:applyLinearImpulse stepx stepy))))

;; Rotation about origin
;; x1 = x0cos(θ) – y0sin(θ)
;; y1 = x0sin(θ) + y0cos(θ)
(fn rotate-about-origin [x y theta]
 [(- (* x (math.cos theta))) (* y (math.sin theta))
  (- (* x (math.sin theta))) (* y (math.cos theta))])

(fn entities-in-front-of [self offset gap w h step filter]
 (let [hits []]
  (for [i 0 w step]
   (let [r (+ gap i)
         theta (+ self.angle offset)
         originx (+ self.x (* r (math.cos theta)))
         originy (+ self.y (* r (math.sin theta)))
         x1 (+ originx (* h (math.cos (+ (/ math.pi 2) theta))))
         y1 (+ originy (* h (math.sin (+ (/ math.pi 2) theta))))
         x2 (- originx (* h (math.cos (+ (/ math.pi 2) theta))))
         y2 (- originy (* h (math.sin (+ (/ math.pi 2) theta))))]
    (gizmo { :x x1 :y y1 :x2 x2 :y2 y2 :shape :line})
    (let [result (game.scene.bump-world:querySegment x1 y1 x2 y2 filter)]
     (each [ix hit (ipairs result)]
      (when (not (lume.match hits #(= $1.id hit.id)))
       (table.insert hits hit))))))
  hits))

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

(fn camfollow [target dt]
  (game.scene.camera:setPosition (lerp game.scene.camera.x target.x dt)
                                 (lerp game.scene.camera.y target.y dt)))
       

(fn lerpto [self f target t]
 (tset self f (lerp (. self f) target t)))

(fn lerptoangle [self f target t]
 (tset self f (lerpangle (. self f) target t)))

(fn follow [self target t]
 (lerpto self :x target.x t)
 (lerpto self :y target.y t)
 (let [dx (- target.x self.x)
       dy (- target.y self.y)
       theta (math.atan2 dy dx)]
  (lerptoangle self :angle theta (* 4 t))))

(fn relative-path [angle originx originy ...]
  (let [ret []
        rest [...]]
    (for [i 1 (length rest) 2]
      (let [x (. rest i)
            y (. rest (+ i 1))
            [rx ry] (rotate-about-origin x y angle)]
        (table.insert ret (+ originx rx))
        (table.insert ret (+ originy ry))))
    ret))

(fn cmrom [t path]
  (assert (> (length path) 8) "Minimum of 4 points required for catull-rom spline")
  (assert (= 0 (% (length path) 2)) "Expected even number of data points for spline")
  (let [size (/ (length path) 2)
        i (- size 3)
        i0 (- i 1)
        i1 i 
        i2 (+ i 1)
        i3 (+ i 2)
        tt (- (* (- size 1) t) (math.floor (* t (- size 1))))
        p0 (* i0 2)
        p1 (* i1 2)
        p2 (* i2 2)
        p3 (* i3 2)
        (x1 y1) (values (. path p0) (. path (+ p0 1)))
        (x2 y2) (values (. path p1) (. path (+ p1 1)))
        (x3 y3) (values (. path p2) (. path (+ p2 1)))
        (x4 y4) (values (. path p3) (. path (+ p3 1)))]
    ;(pp {: i : j : points})
    (path2d_catmullrom.point tt 0 x1 y1 x2 y2 x3 y3 x4 y4)))

(fn color-constant [k]
  (match k :red [1 0 0 1]
           :green [0 1 0 1]
           :blue [0 0 1 1]))

(fn draw-debug-rect [x y w h color]
  (love.graphics.setColor (unpack (color-constant color)))
  (love.graphics.rectangle :fill x y w h))

(fn draw-debug-circle [x y r color]
  (love.graphics.setColor (unpack (color-constant color)))
  (love.graphics.circle :fill x y r))

(fn angle-between [e1 e2]
  (math.atan2 (- e2.y e1.y) (- e2.x e1.x)))

(fn dot [x1 y1 x2 y2]
  (+ (* x1 x2) (* y1 y2)))

(fn uuid []
  (let [template :xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx]
    (string.gsub template "[xy]"
                 (fn [c]
                   (let [v (or (and (= c :x) (math.random 0 15)) (math.random 8 11))]
                     (string.format "%x" v))))))

{ : distance
  : distance-tween
  : move-towards
  : rotate-about-origin
  : entities-in-front-of
  : lerp
  : lerpto
  : lerpangle
  : follow
  : camfollow
  : lerptoangle
  : relative-path
  : cmrom
  : closest
  : draw-debug-rect
  : draw-debug-circle
  : angle-between
  : dot
  : uuid}

