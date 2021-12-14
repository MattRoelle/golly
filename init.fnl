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
(local bump (require :lib.bump))
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
   :path gollymath.path
   :mixins core.mixins
   : effects
   : colors
   : graphics
   : font
   : assets
   : statemachine})

(fn module.load-raw-scene [f name]
 (set last-scenefn f)
 (when game.scene
   (each [_ entity (ipairs game.scene.ecs-world.entities)]
    (when entity.destroy (entity:destroy))))
 (f (scene.create-scene)))

(fn module.restart-scene []
  (module.load-raw-scene last-scenefn nil))

(fn module.setscene [s]
  (let [scenefn (. game.scenes s)]
    (module.load-raw-scene scenefn s)))

(fn module.defentity [default-props ...]
  (local mt (lume.merge (unpack [...])))
  (set mt.__index mt)
  (fn [props]
   (let [e (setmetatable (lume.merge {:x 0 :y 0 :angle 0} default-props (or props {})) mt)]
    ;(when e.init (e:init))
    e)))

(fn module.setgame [g]
  (game.setgame g)
  (module.setscene g.initial-scene))

module
