(local EventBus {})
(set EventBus.__index EventBus)

(var __id 0)
(fn get-id []
  (set __id (+ __id 1))
  __id)

(fn EventBus.subscribe [self f]
  (let [id (get-id)]
    (tset self.__handlers id f)
    id))

(fn EventBus.unsubscribe [self id]
  (tset self.__handlers id nil))

(fn EventBus.dispatch [self ...]
  (each [_ f (pairs (. self.__handlers))]
    (f ...)))

(fn event-bus []
  (setmetatable
    {:__handlers {}}
    EventBus))

event-bus
