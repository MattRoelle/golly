(local game (require :golly.core.game))

{;:spine (require :golly.assets.spine)
 :spritesheet (require :golly.assets.spritesheet)
 :asset
 (fn [k]
   (let [game (game.get-game)]
     (assert k "Must pass asset name")
     (assert (. game.assets k)
             (.. "No asset found for given key: " k))
     (. game.assets k)))}

