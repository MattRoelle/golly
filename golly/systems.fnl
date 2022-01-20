(local lume (require :lib.lume))
(local tiny (require :lib.tiny))

(fn init-system [scene]
 (tiny.processingSystem {:filter (tiny.requireAll :__handles?-init)
                         :onAdd (fn [self e] (e:dispatch :init))}))

(fn destroy-system [scene]
 (tiny.processingSystem {:filter (tiny.requireAll :__handles?-destroy)
                         :onRemove (fn [self e] (e:dispatch :destroy))}))

(fn update-system [scene]
 (tiny.processingSystem {:filter (tiny.requireAll :__handles?-update)
                         :process (fn [self e dt] (e:dispatch :update dt))}))

(fn timeline-system [scene]
 (tiny.processingSystem {:filter (tiny.requireAll :timeline)
                         :process (fn [self e dt]
                                    (when (e.timeline:update dt)
                                      (scene:destroy-entity e)))}))

(fn tag-system [scene]
  (tiny.processingSystem
   {:filter (tiny.requireAll :tags)
    :onAdd
    (fn [self e]
      (each [_ tag (ipairs e.tags)]
        (tset e.scene.tagmap tag (or (. e.scene.tagmap tag) {}))
        (tset (. e.scene.tagmap tag) e.id e)))
    :onRemove 
    (fn [self e]
      (tset e.scene.idmap e.id nil)
      (each [_ tag (ipairs e.tags)]
        (tset (. e.scene.tagmap tag) e.id nil)))}))

{: init-system
 : destroy-system
 : update-system
 : timeline-system
 : tag-system}
