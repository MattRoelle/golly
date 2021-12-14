(local lume (require :lib.lume))

;;; 
;; VFX Engine spec
;; ---------------------------------

;; The output should be a function that when called adds itself to the active scene.
;; (explode 10 10) ;; Adds an effect entity to the scene

;; VFX
;; Always have
;; - A layer hierarchy
;; - A root transform
;; - update/draw methods that drive the whole effect
;; Can have
;; 1 motion attachment

;; Layer
;; Always have
;; - A local-to-the-vfx transform
;; - An order within the effect
;; Can have
;; - Children
;; - 1 particle system
;; - 1 image
;; - 1 motion attachment
;; - Custom shaders and blend modes

;; Motion
;; Motions are always of a specific enumerated type,
;; - Path
;; - - The transform will follow the specified path 
;; - - Has an easing and duration component
;; - - Can be linear or bezier
;; - Lerpto
;; - - The transform will constantly lerp towards a "target"

(fn newps [img props]
 (let [ps (love.graphics.newParticleSystem
           (love.graphics.newImage img)
           (or props.buffer 100))]
  (ps:setEmitterLifetime -1)
  (ps:start)
  (when props.colors (ps:setColors (unpack props.colors)))
  (when props.linearAcceleration (ps:setLinearAcceleration (unpack props.linearAcceleration)))
  (when props.emissionRate (ps:setEmissionRate props.emissionRate))
  (when props.particleLifetime (ps:setParticleLifetime (unpack props.particleLifetime)))
  (when props.sizes (ps:setSizes (unpack props.sizes)))
  ps))

(fn draw-vfxlayer [self]
  (love.graphics.push)
  (love.graphics.setBlendMode self.props.blendMode self.props.blendAlphaMode)
  (when self.props.ps (love.graphics.draw self.props.ps 0 0))
  (each [ix child (ipairs self.children)]
     (child:draw))
  (love.graphics.pop))

(fn update-vfxlayer [self dt x y]
 (let [nx (+ x self.props.x)
       ny (+ y self.props.y)]
  (when self.props.ps
   (self.props.ps:moveTo nx ny)
   (self.props.ps:update dt))
  (each [ix child (ipairs self.children)]
      (child:update dt nx ny))))

(fn play-vfxlayer [self]
 (when self.props.ps
  (self.props.ps:start))
 (each [ix child (ipairs self.children)]
  (child:play)))

(fn pause-vfxlayer [self]
 (when self.props.ps
  (self.props.ps:stop))
 (each [ix child (ipairs self.children)]
  (child:pause)))

(fn vfxlayer [props ...]
 { :props (lume.merge { :x 0 :y 0 :blendMode :alpha :blendAlphaMode :alphamultiply} props)
   :children [...]
   :update update-vfxlayer
   :draw draw-vfxlayer
   :play play-vfxlayer
   :pause pause-vfxlayer})

(fn draw-vfx [self dt]
 (self.rootlayer:draw 0 0))

(fn update-vfx [self dt]
 (self.rootlayer:update dt 0 0))

(fn play-vfx [self]
 (self.rootlayer:play))

(fn pause-vfx [self]
 (self.rootlayer:pause))
 
(fn vfx [props ...]
 { :props props
   :rootlayer (vfxlayer {} ...)
   :update update-vfx
   :draw draw-vfx
   :play play-vfx
   :pause pause-vfx})

{ : vfx
  : vfxlayer
  : newps}
 
