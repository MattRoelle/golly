(local lume (require :lib.lume))
(local inspect (require :lib.inspect))

(local VirtualMethodTable {})
(set VirtualMethodTable.__index VirtualMethodTable)

(fn VirtualMethodTable.register [self k f]
  (when (not (. self.__methods k))
    (tset self.__methods k []))
  (table.insert (. self.__methods k) f))

(fn VirtualMethodTable.make-dispatch-f [self k]
  (fn [...]
    (each [_ f (ipairs (. self.__methods k))]
      (f ...))))

(fn VirtualMethodTable.compile [self]
  (collect [k v (pairs self.__methods)]
           (values k (self:make-dispatch-f k))))

(fn new-vtable []
  (setmetatable {:__methods {}} VirtualMethodTable))

(local MethodBlock {})

(fn MethodBlock.__newindex [self k f]
  (assert (= (type k) "string") "Invalid method definition. Name expected to be a string")
  (assert (= (type f) "function") "Invalid method definition. Function expected")
  (self.__vtable:register k f))

(fn new-method-block [vtable]
  (setmetatable {:__vtable vtable} MethodBlock))

(local Class {})
(set Class.__index Class)

(fn Class.compile! [self]
  (each [k v (pairs self.__mt.__index)]
    (tset self.__mt.__index k nil))
  (each [k v (pairs (self.__vtable:compile))]
    (tset self.__mt.__index k v))
  (set self.__dirty? false))

(fn Class.__call [self fields ...]
  (when self.__dirty? (self:compile!))
  (let [inst (setmetatable (or fields {}) self.__mt)]
    ;; TODO: Call ctor
    inst))

(fn class []
  (let [vtable (new-vtable)
        root-method-block (new-method-block vtable)]
    (setmetatable {:__vtable vtable 
                   :__dirty? true
                   :__mt {:__index {}}
                   :on root-method-block} Class)))

(let [my-thing (class)]
  (fn my-thing.on.blah [] (print "hi 1"))
  (fn my-thing.on.blah [] (print "hi 2"))
  (let [inst (my-thing)]
    (print (inspect inst))
    (inst:blah)))

class
