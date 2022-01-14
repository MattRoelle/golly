(require-macros :golly)

(local tiny (require :lib.tiny))

(def-system init-system [self]
  (filter :init)
  (on-add [e]
    (e:init)
    (when e.calculate-bounds! (e:calculate-bounds!))))

(def-system destroy-system [self]
  (filter :destroy)
  (on-remove [e]
    (e:destroy)))

(def-system update-system [self scene]
  (filter :update)
  (preprocess [dt]
    (scene.box2d-world:update dt))
  (process [e dt]
    (e:update dt)
    (when e.calculate-bounds! (e:calculate-bounds!))))

(def-system box2d-system [self scene]
  (filter :body))
                
(def-system camera-render-system [self scene]
  (filter :draw)
  (sort [a b] (< (or a.z-index 0) (or b.z-index 0)))
  (preprocess [dt]
    (love.graphics.clear)
    (scene.camera:update dt)
    (scene.camera:attach))
  (process [e dt]
    (love.graphics.push)
    (e:apply-transform)
    (e:draw)
    (love.graphics.pop))
  (postprocess [dt]
    (scene.camera:detach)))

(def-system debug-render-system [self scene]
    (filter :drawdebug)
    (sort [a b] (< (or a.z-index 0) (or b.z-index 0)))
    (preprocess [dt]
      (scene.camera:attach))
    (process [e dt]
      (when (not _G.dbg) (lua "return"))
      (print :dbgdraw)
      (love.graphics.push)
      (e:apply-transform)
      (e:drawdebug)
      (love.graphics.pop))
    (postprocess [dt]
      (scene.camera:detach)))

(def-system window-render-system [self]
  (filter :drawwindow)
  (sort [a b] (< (or a.window-z 0) (or b.window-z 0)))
  (process [e dt] (e:drawwindow)))

(def-system tag-system [self]
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
 : tag-system
 : box2d-system}
