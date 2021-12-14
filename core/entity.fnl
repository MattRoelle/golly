(local inspect (require :lib.inspect))
(local lume (require :lib.lume))
(local helpers (require :golly.helpers))

(local Entity {:prototype {}})

(local Handler {})
(set Handler.__index Handler)

(fn Handler.__call [self ...]
  (self.f ...))

(fn Handler.__tostring [self]
  (or self.name "anonymous"))

(fn Entity.prototype.on [self evtype handler handler-name?]
  (tset self._handlers evtype (or (. self._handlers evtype) []))
  ;(print "handler" self.__name evtype handler handler-name?)
  (table.insert (. self._handlers evtype)
                (setmetatable {:f handler
                               :name handler-name?}
                              Handler)))

(fn Entity.prototype.destroy! [self]
  (table.insert self.scene.removal-queue self)
  (set self.destroyed true))

(fn Entity.prototype.add-child [self child]
  (when (not self.children)
    (set self.children [])
    (self:on :destroy 
             (fn [self]
               (each [_ child (ipairs self.children)]
                 (child:destroy!)))))
  (self.scene:add-entity child)
  (table.insert self.children child)
  child)


(fn Entity.__index [self k b]
  (if (. Entity.prototype k)
    (. Entity.prototype k)
    (let [handlers (. self._handlers k)]
      (when handlers
        (fn [self ...]
          (when (and self.destroyed (not= k :destroy))
            (lua "return"))
          (each [_ h (ipairs handlers)]
            (h ...)))))))

(fn new-entity [props]
  (setmetatable (lume.merge {:_handlers {}
                             :x 0 
                             :y 0 
                             :z 0
                             :screen-z 0
                             :scaleX 1 
                             :scaleY 1
                             :angle 0 
                             :id (helpers.uuid)
                             :pivot {:x 0.5 :y 0.5}}
                            (or props {}))
                Entity))

{: new-entity}
  
