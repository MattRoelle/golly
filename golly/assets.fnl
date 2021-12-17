(local spritesheet (require :golly.assets.spritesheet))

(var asset-registry {})
(var assets {})

(local asset-loaders
 { :spritesheet spritesheet.load-spritesheet
   :image #(love.graphics.newImage $1)})

(fn defasset [name type ...]
 (tset asset-registry name [type [...]]))

(fn asset [name] (. assets name))
(fn assetref [name] { :assetref name})

(fn load-assets []
 (each [k [t args] (pairs asset-registry)]
  (tset assets k ((. asset-loaders t) (unpack args)))))

{: asset
 : assetref
 : defasset
 : load-assets}
