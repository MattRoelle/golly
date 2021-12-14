(local base-color-palette
  {:black [0 0 0]
   :grey [40 40 40]
   :white [255 255 255]
   :dark [18  28  35]
   :color1 [241  34  111]
   :color2 [47  230  222]
   :color3 [24  242  178]
   :color4 [136  73  143]})

(var current-color-palette base-color-palette)

(fn lookup-color [k alpha]
  (let [[r g b] (. current-color-palette k)]
    [(/ r 255) (/ g 255) (/ b 255) (or alpha 1)]))

{: lookup-color}
