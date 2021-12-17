(local renderer (require :golly.ui.renderer))
(local react (require :golly.ui.react))
(local components (require :golly.ui.components))

{:draw renderer.draw
 :component react.component
 :setstyles components.setstyles
 :btn-grid components.btn-grid
 :btn components.btn
 :progress-bar components.progress-bar
 :button components.button}
