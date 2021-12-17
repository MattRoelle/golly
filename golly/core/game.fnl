(local module {})

(var __game {})
(fn module.get-game []
  __game)

(fn module.set-scene [s]
  (set __game.scene s))

(macro assert-field [g fname]
  `(assert (. ,g ,fname) (.. "Must pass " ,fname)))

(fn module.set-game [g]
  (assert-field g :main)
  (assert-field g :stage-width)
  (assert-field g :stage-height)
  (set __game g))

module
