(local class (require :golly.class))

(var _id 0)

(local Store {})
(set Store.__index Store)

(fn Store.subscribe [self f]
  (let [id (+ _id 1)]
    (tset self.__subscribers id f)
    (set _id id)
    id))

(fn Store.unsubscribe [self id]
  (tset self.__subscribers id nil))

(fn Store.dispatch [self ...]
  (print :dispatch self.mutex self.__state (. [...] 1))
  (assert (not self.mutex) "Illegal nested dispatch")
  (set self.mutex true)
  (let [old-state self.__state 
        new-state (self.__reducer self.__state ...)]
    (set self.mutex false)
    (set self.__state new-state)
    (each [_ sub (ipairs self.__subscribers)]
      (sub old-state new-state))
    new-state))

(fn Store.get-state [self] self.__state)
  
(fn create-store [reducer]
  (setmetatable {:mutex false 
                 :__subscribers {}
                 :__state (reducer nil nil)
                 :__reducer reducer}
    Store))

{: create-store}

