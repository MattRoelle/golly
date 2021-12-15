(require-macros :golly)

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

(fn Store.dispatch [self action]
  (let [new-state (self.__reducer self.__state action)]
    (set self.__state new-state)
    (each [_ sub (ipairs self.__subscribers)]
      (sub new-state))))

(fn Store.get-state [self] self.__state)
  
(fn create-store [reducer]
  (setmetatable {:__subscribers {}
                 :__state (reducer nil nil)
                 :__reducer reducer} Store))

(defmixin use-state [self store evname p]
  (on :init []
      (when (not self.__state-subs)
        (set self.__state-subs {}))
      (tset self.__state-subs evname
            (store:__subscribe
              #(when (p $1) (self:send evname $1))))) 
  (on :destroy []
      (store:unsubscribe (. self.__state-subs evname))))

{: use-state 
 : create-store}

;;----- testing

;(local initial-state {:s "not set"})

;(fn reducer [state action]
;  (match action 
;    {:type :test1} (lume.merge state {:s action.s})
;    _ initial-state))

;(local store (create-store reducer))
;(print (inspect store))
;(local sub (store:subscribe (fn [new-state] (print "Got new store!" (inspect new-state)))))
;(store:dispatch {:type :test1 :s "Dispatched!"})
;(store:unsubscribe sub)
;(store:dispatch {:type :test1 :s "Dispatched 2222!"})
;(print (inspect (store:get-state)))

