(local input (require :golly.core.input))
(local helpers (require :golly.helpers))
(local timeline (require :golly.timeline))
(local systems (require :golly.core.systems))
(local tiny (require :lib.tiny))
(local scene (require :golly.core.scene))
(local entity (require :golly.core.entity))
(local mixins (require :golly.core.mixins))
(local graphics (require :golly.graphics))
(local font (require :golly.font))
(local core (require :golly.core))
(local gollymath (require :golly.math))
(local assets (require :golly.assets))
(local easing (require :lib.easing))
(local statemachine (require :golly.statemachine))
(local camera (require :golly.camera))

(var last-scenefn nil)

(fn boot [options]
  (core.game.load-scene options))

{:input core.input
 : boot
 : helpers
 : timeline
 : easing
 :scene core.scene
 :entity core.entity
 :math gollymath.constants
 :path gollymath.path
 :mixins core.mixins
 :create-store core.redux.create-store
 :use-state core.redux.use-state
 : graphics
 : font
 : assets
 : camera
 :asset assets.asset
 : statemachine}
