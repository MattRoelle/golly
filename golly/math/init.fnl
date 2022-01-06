(local vector (require :golly.math.vector))
(local aabb (require :golly.math.aabb))

{:path (require :golly.math.path)
 :vector vector 
 :aabb aabb
 :constants {:tau (* math.pi 2)
             :angleright 0 
             :angleleft math.pi 
             :angleup (* math.pi -0.5)
             :angledown (* math.pi 0.5)
             :up (vector.vec 0 1)
             :down (vector.vec 0 -1)
             :left (vector.vec -1 0)
             :right (vector.vec 1 0)}}

