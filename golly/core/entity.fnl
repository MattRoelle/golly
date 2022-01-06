(local inspect (require :lib.inspect))
(local lume (require :lib.lume))
(local helpers (require :golly.helpers))
(local timeline (require :golly.timeline))
(local gollymath (require :golly.math))
(local class (require :golly.core.class))

(local entity-prototype {})
(fn entity-prototype.tagged? [self tag]
  (lume.find self.tags tag))

(fn entity-prototype.collides-with! [self tag]
  (table.insert self.__collides-with tag))

(fn entity-prototype.collides? [self ent]
  (each [_ tag (ipairs (or ent.tags []))]
    (when (lume.find self.__collides-with tag)
      (lua "return true"))))

(fn entity-prototype.lerpto! [self v t]
  (self.position:lerp! v t))


(fn entity-prototype.destroy! [self]
  (when self.destroyed (lua :return))
  (table.insert self.scene.removal-queue self)
  (set self.destroyed true))

(fn entity-prototype.add-children [self ...]
  (each [_ child (ipairs [...])]
    (self:add-child child)))

(fn entity-prototype.add-child [self child]
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

(fn entity-prototype.timeline [self name ...]
  (let [t (self:add-child (timeline ...))]
    (when name
      (set t.name name)
      (when (. self.__timelines name)
        (: (. self.__timelines name) :destroy!))
      (tset self.__timelines name t)))) 

(fn entity-prototype.apply-transform [self nested?]
  (when self.parent (self.parent:apply-transform true))
  (love.graphics.translate self.position.x self.position.y)
  (love.graphics.rotate self.angle)
  (love.graphics.scale (or self.scale.x 1)
                       (or self.scale.y 1))
  (when (not nested?) 
    (love.graphics.translate (* -1 self.pivot.x self.size.x)
                            (* -1 self.pivot.y self.size.y))))

(fn entity-prototype.world-transform [self nested?]
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
    ;(print self.__name "__wt" transform.position self.position)
    (lume.merge
     transform
     (let [left (- transform.position.x (* self.pivot.x self.size.x))
           top (- transform.position.y (* self.pivot.y self.size.y))
           right (+ left self.size.x) 
           bottom (+ top self.size.y)]
      {:bounds {: left : top : right : bottom}}))))

(fn entity-prototype.calculate-bounds! [self]
  (let [left (- self.position.x (* self.pivot.x self.size.x))
        top (- self.position.y (* self.pivot.y self.size.y))
        right (+ left self.size.x) 
        bottom (+ top self.size.y)]
    (set self.bounds {: left : top : right : bottom})))

(local base-entity
 {:position #(gollymath.vector.vec 0 0)
  :scale #(gollymath.vector.vec 1 1)
  :pivot #(gollymath.vector.vec 0.5 0.5)
  :size #(gollymath.vector.vec 1 1)
  :angle #0
  :parent #nil
  :z-index #0
  :__collides-with #[]
  :__timelines #{}})

(fn mixin-base-entity [self props]
  (each [k v (pairs base-entity)]
    (tset self k (or (. self k) (v))))
  (each [k v (pairs entity-prototype)]
    (tset self k v)))

{: mixin-base-entity}
