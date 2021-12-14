(local module {})

(fn module.setscene [s]
  (set module.scene s))

(macro assertset [g fname]
  `(do 
     (assert (. ,g ,fname) (.. "Must pass " ,fname))
     (tset module ,fname (. ,g ,fname))))

(fn module.setgame [g]
  (assertset g :assets)
  (assertset g :scenes)
  (assertset g :initial-scene)
  (assertset g :stage-width)
  (assertset g :stage-height))

module
