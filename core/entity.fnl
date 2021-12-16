(local inspect (require :lib.inspect))
(local lume (require :lib.lume))
(local helpers (require :golly.helpers))
(local timeline (require :golly.timeline))
(local gollymath (require :golly.math))

(local Entity {:prototype {}})

(local Handler {})
(set Handler.__index Handler)

(fn Handler.__call [self ...]
  (self.f ...))

(fn Handler.__tostring [self]
  (or self.name "anonymous"))

(fn Entity.prototype.tagged? [self tag]
  (lume.find self.tags tag))

(fn Entity.prototype.collides-with! [self tag]
  (table.insert self.__collides-with tag))

(fn Entity.prototype.collides? [self ent]
  (each [_ tag (ipairs (or ent.tags []))]
    (when (lume.find self.__collides-with tag)
      (lua "return true"))))

(fn Entity.prototype.on [self evtype handler handler-name?]
  (tset self._handlers evtype (or (. self._handlers evtype) []))
  ;(print "handler" self.__name evtype handler handler-name?)
  (table.insert (. self._handlers evtype)
                (setmetatable {:f handler
                               :name handler-name?}
                              Handler)))

(fn Entity.prototype.destroy! [self]
  (when self.destroyed (lua :return))
  (table.insert self.scene.removal-queue self)
  (set self.destroyed true))

(fn Entity.prototype.add-children [self ...]
  (each [_ child (ipairs [...])]
    (self:add-child child)))

(fn Entity.prototype.add-child [self child]
  (when (not self.children)
    (set self.children [])
    (self:on :destroy 
             (fn [self]
               (each [_ child (ipairs self.children)]
                 (child:destroy!)))))
  (self.scene:add-entity child)
  (set child.parent self)
  (table.insert self.children child)
  child)

(fn Entity.prototype.timeline [self name ...]
  (let [t (self:add-child
            (timeline ...))]
    (when name
      (when (. self.__timelines name)
        (: (. self.__timelines name) :destroy!))
      (tset self.__timelines name t)))) 

(fn Entity.prototype.apply-transform [self nested?]
  (when self.parent (self.parent:apply-transform true))
  (love.graphics.translate self.position.x self.position.y)
  (love.graphics.rotate self.angle)
  (when (not nested?) 
    (love.graphics.translate (* -1 self.pivot.x self.size.x)
                            (* -1 self.pivot.y self.size.y)))
  (love.graphics.scale (or self.scale.x 1)
                       (or self.scale.y 1)))

(fn Entity.prototype.world-transform [self nested?]
  (let [transform
        (if self.parent
          (self.parent:world-transform true)
          {:position (gollymath.vector.vec 0 0)
           :scale (gollymath.vector.vec 1 1)
           :angle 0})]
    (let [delta (self.position:rotate (- transform.angle))]
      (set transform.position (+ transform.position delta)))
    (set transform.angle (+ transform.angle self.angle))
    (when (not nested?) 
      (print "self.size" self.size)
      (let [pivot (gollymath.vector.vec
                    (* -1 self.pivot.x self.size.x)
                    (* -1 self.pivot.y self.size.y))]
        (pivot:rotate! transform.angle)
        (set transform.position (+ transform.position pivot))))
    (set transform.scale (* transform.scale self.scale))
    (print self.__name "__wt" transform.position self.position)
    transform))

(fn Entity.prototype.calculate-bounds! [self]
  (let [left (- self.position.x (* self.pivot.x self.size.x))
        top (- self.position.y (* self.pivot.y self.size.y))
        right (+ left self.size.x) 
        bottom (+ top self.size.y)]
    (set self.bounds {: left : top : right : bottom})))

(fn Entity.__index [self k b]
  (if (. Entity.prototype k)
    (. Entity.prototype k)
    (let [handlers (. self._handlers k)]
      (when handlers
        (fn [self ...]
          (when (and self.destroyed (not= k :destroy))
            (lua "return"))
          (each [_ h (ipairs handlers)]
            (let [(result err) (pcall h ...)]
              (when (not result) 
                (error (.. self.__name " " k ": " err))))))))))

(fn new-entity [props]
  (let [obj (lume.merge {:position (gollymath.vector.vec 0 0)
                         :scale (gollymath.vector.vec 1 1)
                         :pivot (gollymath.vector.vec 0 0)
                         :size (gollymath.vector.vec 0 0)
                         :angle 0
                         :parent nil
                         :z-index 0
                         :id (helpers.uuid)
                         :__collides-with []
                         :_handlers {}
                         :__timelines {}}
                    (or props {}))]
    (setmetatable obj Entity)))

{: new-entity}
