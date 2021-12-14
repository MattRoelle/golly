(require-macros :golly)

(local game (require :golly.core.game))
(local tiny (require :lib.tiny))

(defsystem init-system [self]
  (filter :init)
  (on-add [e]
    (e:init)
    (when (and e.pivot e.width e.height)
      (set e.left (- e.x (* e.pivot.x e.width)))
      (set e.top (- e.y (* e.pivot.y e.height)))
      (set e.right (+ e.left e.width)) 
      (set e.bottom (+ e.top e.height)))))

(defsystem destroy-system [self]
  (filter :destroy)
  (on-remove [e]
    (e:destroy)))

(defsystem update-system [self scene]
  (filter :update)
  (preprocess [dt]
    (scene.box2d-world:update dt))
  (process [e dt]
    ;(when e.destroyed (lua "return"))
    (when (and e.pivot e.width e.height)
      (set e.left (- e.x (* e.pivot.x e.width)))
      (set e.top (- e.y (* e.pivot.y e.height)))
      (set e.right (+ e.left e.width)) 
      (set e.bottom (+ e.top e.height)))
    (e:update dt)
    (when (and e.width e.height e.x e.y e.pivot)
      (set e.cx (- e.x (* e.width e.pivot.x)))
      (set e.cy (- e.y (* e.height e.pivot.y))))))
                
(defsystem camera-render-system [self canvas]
  (filter :draw)
  (sort [a b] (< (or a.z 0) (or b.z 0)))
  (preprocess [dt]
    (love.graphics.setCanvas canvas)
    (love.graphics.clear)
    (set (self.sx self.sy self.sw self.sh) (love.graphics.getScissor))
    (let [cam game.scene.camera]
       (love.graphics.setScissor (cam:getWindow))
       (love.graphics.push)
       (local scale cam.scale)
       (love.graphics.scale scale)
       (love.graphics.translate (/ (+ cam.w2 cam.l) scale)
                                (/ (+ cam.h2 cam.t) scale))
       (love.graphics.rotate (- cam.angle))
       (love.graphics.translate (- cam.x) (- cam.y))))
  (process [e dt]
    (love.graphics.push)
    (love.graphics.translate (or e.x 0) (or e.y  0))
    (love.graphics.rotate (or e.angle 0))
    (when (and e.pivot e.width e.height)
      (love.graphics.translate (* -1 e.pivot.x e.width) (* -1 e.pivot.y e.height)))
    (love.graphics.scale (or e.scaleX 1) (or e.scaleY 1))
    (e:draw)
    (love.graphics.pop))
  (postprocess [dt]
   (love.graphics.pop)
   (love.graphics.setScissor self.sx self.sy self.sw self.sh)
   (love.graphics.setCanvas)
   (set self.modified true)))

(defsystem debug-render-system [self canvas]
    (filter :drawdebug)
    (sort [a b] (< (or a.z 0) (or b.z 0)))
    (preprocess [dt]
      (set (self.sx self.sy self.sw self.sh) (love.graphics.getScissor))
      (let [cam game.scene.camera]
         (love.graphics.setScissor (cam:getWindow))
         (love.graphics.push)
         (love.graphics.setCanvas canvas)
         (local scale cam.scale)
         (love.graphics.scale scale)
         (love.graphics.translate (/ (+ cam.w2 cam.l) scale)
                                  (/ (+ cam.h2 cam.t) scale))
         (love.graphics.rotate (- cam.angle))
         (love.graphics.translate (- cam.x) (- cam.y))))
    (process [e dt]
      (when (not _G.dbg) (lua "return"))
      (love.graphics.push)
      (love.graphics.translate e.x e.y)
      (love.graphics.rotate (or e.angle 0))
      (love.graphics.scale (or e.scaleX 1) (or e.scaleY 1))
      (e:drawdebug)
      (love.graphics.pop))
    (postprocess [dt]
      (love.graphics.pop)
      (love.graphics.setCanvas)
      (love.graphics.setScissor self.sx self.sy self.sw self.sh)))

(defsystem screen-render-system [self canvas]
   (filter :drawscreen)
   (sort [a b] (< (or a.screen-z 0) (or b.screen-z 0)))
   (preprocess [dt] (love.graphics.setCanvas canvas))
   (process [e dt] (e:drawscreen))
   (postprocess [dt]
    (love.graphics.setCanvas)))

(fn window-render-system [ canvas]
  (tiny.sortedProcessingSystem 
   {:filter (tiny.requireAll :drawwindow)
    :sort
    (fn [self a b]
      (< (or a.window-z 0) (or b.window-z 0)))
    :process
    (fn [self e dt] (e:drawwindow))}))

(fn tag-system []
  (tiny.processingSystem
   {:filter (tiny.requireAll :tags)
    :onAdd
    (fn [self e]
      (each [_ tag (ipairs e.tags)]
        (tset game.scene.tagmap tag (or (. game.scene.tagmap tag) []))
        (table.insert (. game.scene.tagmap tag) e)))
    :onRemove
    (fn [self e]
      (tset game.scene.idmap e.id nil)
      (each [_ tag (ipairs e.tags)]
         (tset game.scene.tagmap tag
               (lume.filter (. game.scene.tagmap tag)
                            #(not= $1 e)))))}))

{: init-system
 : destroy-system
 : update-system
 : camera-render-system   
 : debug-render-system
 : screen-render-system
 : window-render-system
 : tag-system}
