(local game (require :golly.core.game))
(local input (require :golly.core.input))
(local helpers (require :golly.helpers))
(local ui (require :golly.ui))
(local vfx (require :golly.vfx))
(local gizmo (require :golly.gizmo))
(local timeline (require :golly.timeline))
(local systems (require :golly.core.systems))
(local tiny (require :lib.tiny))
(local scene (require :golly.core.scene))
;(local bump (require :lib.bump))
(local entity (require :golly.core.entity))
(local mixins (require :golly.core.mixins))
(local effects (require :golly.effects))
(local colors (require :golly.colors))
(local graphics (require :golly.graphics))
(local font (require :golly.font))
(local core (require :golly.core))
(local gollymath (require :golly.math))
(local assets (require :golly.assets))
(local easing (require :lib.easing))
(local statemachine (require :golly.statemachine))

(var last-scenefn nil)

(local module 
  {:game core.game
   :input core.input
   : helpers
   : gizmo
   : timeline
   : ui
   : vfx
   : easing
   :scene core.scene
   :entity core.entity
   :math gollymath.constants
   :path gollymath.path
   :mixins core.mixins
   :create-store core.redux.create-store
   :use-state core.redux.use-state
   : effects
   : colors
   : graphics
   : font
   : assets
   : statemachine})

(fn module.restart []
 (let [inst (game.get-game)]
   (game.set-scene (inst.main (scene.create-scene)))))

(fn module.set-game [g]
  (game.set-game g)
  (module.restart))

module
