(require-macros :golly)

(local game (require :golly.core.game))
(local tiny (require :lib.tiny))

(defsystem init-system [self]
  (filter :init)
  (on-add [e]
    (e:init)
    (when e.calculate-bounds! (e:calculate-bounds!))))

(defsystem destroy-system [self]
  (filter :destroy)
  (on-remove [e]
    (e:destroy)))

(defsystem update-system [self scene]
  (filter :update)
  (preprocess [dt]
    (scene.box2d-world:update dt))
  (process [e dt]
    (e:update dt)
    (when e.calculate-bounds! (e:calculate-bounds!))))
                
(defsystem camera-render-system [self canvas]
  (filter :draw)
  (sort [a b] (< (or a.z-index 0) (or b.z-index 0)))
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
    (e:apply-transform)
    (e:draw)
    (love.graphics.pop))
  (postprocess [dt]
   (love.graphics.pop)
   (love.graphics.setScissor self.sx self.sy self.sw self.sh)
   (love.graphics.setCanvas)
   (set self.modified true)))

(defsystem debug-render-system [self canvas]
    (filter :drawdebug)
    (sort [a b] (< (or a.z-index 0) (or b.z-index 0)))
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
      (e:apply-transform)
      (e:drawdebug)
      (love.graphics.pop))
    (postprocess [dt]
      (love.graphics.pop)
      (love.graphics.setCanvas)
      (love.graphics.setScissor self.sx self.sy self.sw self.sh)))

(defsystem window-render-system [self canvas]
  (filter :drawwindow)
  (sort [a b] (< (or a.window-z 0) (or b.window-z 0)))
  (process [e dt] (e:drawwindow)))

(defsystem tag-system [self]
   (filter :tags)
   (on-add [e]
    (each [_ tag (ipairs e.tags)]
      (tset e.scene.tagmap tag (or (. e.scene.tagmap tag) []))
      (table.insert (. e.scene.tagmap tag) e)))
   (on-remove [e]
     (tset e.scene.idmap e.id nil)
     (each [_ tag (ipairs e.tags)]
       (tset e.scene.tagmap tag
             (lume.filter (. e.scene.tagmap tag)
                          #(not= $1 e))))))

{: init-system
 : destroy-system
 : update-system
 : camera-render-system   
 : debug-render-system
 : window-render-system
 : tag-system}
