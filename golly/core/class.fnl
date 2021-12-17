(local helpers (require :golly.helpers))
(local inspect (require :lib.inspect))
(local lume (require :lib.lume))

(local Handler {})
(set Handler.__index Handler)

(fn Handler.__call [self ...]
  (self.f ...))

(fn Handler.__tostring [self]
  (or self.name "anonymous"))

(local Class {:prototype {}})
(fn Class.__index [self k]
  (if (. Class.prototype k)
    (. Class.prototype k)
    (let [handlers (. self.__handlers k)]
      (when handlers
        (fn [self ...]
          (when (and self.destroyed (not= k :destroy))
            (lua "return"))
          (each [_ h (ipairs handlers)]
            (let [(result err) (pcall h ...)]
              (when (not result) 
                (error (.. "(class=" (or self.__name "anonymous") ", mixin=" (tostring h) ", event=" k ", args= " (inspect ... {:depth 1}) "): " err))))))))))

(fn Class.prototype.on [self evtype handler handler-name?]
  (tset self.__handlers evtype (or (. self.__handlers evtype) []))
  (table.insert (. self.__handlers evtype)
                (setmetatable {:f handler
                               :name handler-name?}
                              Handler)))

(fn new-class [props]
  (let [obj (lume.merge
              {:id (helpers.uuid)
               :__handlers {}}
              (or props {}))]
    (setmetatable obj Class)))

{: new-class 
 : Class}
