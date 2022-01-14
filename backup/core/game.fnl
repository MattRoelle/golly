(local scene (require :golly.core.scene))

(var __scene nil)
(fn get-active-scene [] __scene)

(fn load-scene [options]
  (set __scene (scene.create-scene options))
  (options.main __scene))

{: get-active-scene
 : load-scene} 
