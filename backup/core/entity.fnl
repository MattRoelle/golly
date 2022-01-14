(local inspect (require :lib.inspect))
(local lume (require :lib.lume))
(local helpers (require :golly.helpers))
(local timeline (require :golly.timeline))
(local gollymath (require :golly.math))
(local class (require :golly.core.class))

(local Handler {})
(set Handler.__index Handler)
(fn Handler.__call [self ...] (self.f ...))
(fn Handler.__tostring [self] (or self.name "anonymous"))

(local EntityEventBus {})
(set EntityEventBus.__index EntityEventBus)
(fn EntityEventBus.__newindex [self k f]
  (assert (and (= (type k) "string")
               (= (type f) "function"))
          "Invalid event handler types")
  (when (not . self.__handlers k)
    (tset self.__handlers k []))
  (table.insert (. self.__handlers k)
                (setmetatable {: f} Handler)))

(fn new-entity-event-bus [entity]
  (setmetatable {:__entity entity :__handlers []}
                EntityEventBus))

(local Entity {:prototype {}})

(fn Entity.prototype.send [self k ...]
  (when (and self.destroyed (not= k :destroy))
    (lua "return"))
  (let [handlers (. self.__handlers k)]
    (when handlers
      (each [_ h (ipairs handlers)]
        (let [(result err) (pcall h ...)]
          (when (not result) 
            (error (.. "(class=" (or self.__name "anonymous")
                       ", mixin=" (tostring h)
                       ", event=" k
                       ", args= " (inspect ... {:depth 1})
                       "): "
                       err))))))))

(fn Entity.__index [self k]
  (when (. Entity.prototype k)
    (. Entity.prototype k)))

(fn Entity.prototype.tagged? [self tag]
  (lume.find self.tags tag))

(fn Entity.prototype.collides-with! [self tag]
  (table.insert self.__collides-with tag))

(fn Entity.prototype.collides? [self ent]
  (each [_ tag (ipairs (or ent.tags []))]
    (when (lume.find self.__collides-with tag)
      (lua "return true"))))

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
      (fn []
        (each [_ child (ipairs self.children)]
          (child:destroy!)))))
  (self.scene:add-entity child)
  (set child.parent self)
  (table.insert self.children child)
  child)

(fn Entity.prototype.timeline [self name ...]
  (let [t (self:add-child (timeline ...))]
    (when name
      (set t.name name)
      (when (. self.__timelines name)
        (: (. self.__timelines name) :destroy!))
      (tset self.__timelines name t)))) 

(fn Entity.prototype.apply-transform [self nested?]
  (when self.parent (self.parent:apply-transform true))
  (love.graphics.translate self.position.x self.position.y)
  (love.graphics.rotate self.angle)
  (love.graphics.scale (or self.scale.x 1)
                       (or self.scale.y 1))
  (when (not nested?) 
    (love.graphics.translate (* -1 self.pivot.x self.size.x)
                            (* -1 self.pivot.y self.size.y))))

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
    (set transform.scale (* transform.scale self.scale))
    (lume.merge
     transform
     (let [left (- transform.position.x (* self.pivot.x self.size.x))
           top (- transform.position.y (* self.pivot.y self.size.y))
           right (+ left self.size.x) 
           bottom (+ top self.size.y)]
      {:bounds {: left : top : right : bottom}}))))

(fn Entity.prototype.calculate-bounds! [self]
  (let [left (- self.position.x (* self.pivot.x self.size.x))
        top (- self.position.y (* self.pivot.y self.size.y))
        right (+ left self.size.x) 
        bottom (+ top self.size.y)]
    (set self.bounds {: left : top : right : bottom})))

(fn game-class [] 
 (fn [initial-field-values]
   (let [obj (lume.merge
               {:position (gollymath.vector.vec 0 0)
                :scale (gollymath.vector.vec 1 1)
                :pivot (gollymath.vector.vec 0.5 0.5)
                :size (gollymath.vector.vec 1 1)
                :angle 0
                :parent nil
                :z-index 0
                :__collides-with []
                :__timelines {}}
               initial-field-values)]
     (setmetatable obj Entity))))

{: game-class}
