(local lume (require :lib.lume))
(local inspect (require :lib.inspect))

(local StateMachine {})
(set StateMachine.__index StateMachine)

(fn StateMachine.dispatch [self transition-name ...]
  (let [t (. self.__transitions transition-name)]
    (when (and t
               (not= t.to self.current) 
               (or (= t.from nil) (= t.from self.current)))
      (self.on-transition self.current t.to ...)
      (set self.current t.to))))

(fn statemachine [initial transitions on-transition]
  (let [inst {:current initial : on-transition :__transitions transitions}]
    (each [k _ (pairs transitions)]
      (tset inst k (fn [self ...] (self:dispatch k ...))))
    (setmetatable inst StateMachine)))

(local ClassMethod {})
(set ClassMethod.__index ClassMethod)

(fn ClassMethod.__call [self ...]
  ((. self.source self.name) ...))

(fn class-method [name source meta]
  (setmetatable {: name : source : meta} ClassMethod))

(local Class {})
(set Class.__index Class)

(fn Class.statemachine [self name initial transitions]
  (tset self.__statemachines name [initial transitions]))

; (fn Class.redux [self name store]
;   (tset self.__stores name store))

(fn Class.field [self k v]
  (tset self.__fields k v))

(fn Class.mixin [self other ...]
  (if other.__applymixin
    (other:__applymixin self ...)
    (do
      (each [k v (pairs other.__fields)]
        (self:field k v))
      (each [name [initial transitions] (pairs other.__statemachines)]
        (self:statemachine name initial transitions))
      (each [fname method (pairs other.__mt)]
        (when (= (getmetatable method) ClassMethod)
          (self:__mixin-method other fname method.meta)))
      (self:__compile-metadata))))

(fn Class.__remove-method [self name]
  (let [method (. self.__mt name)]
    (assert (= method.source self.__mt.__method-functions)
            (.. "Method collision, " name " has already been defined by another class"))
    (each [ix ev (ipairs method.meta.events)]
      (each [_ vtable (ipairs (. self.__mt.__event-handlers ev))]
        (each [_ plist (ipairs vtable)]
          (tset plist name nil))))))

(fn Class.__index-method [self name]
  (let [method (. (. self.__mt name)) 
        {: events} method.meta
        priority (or method.meta.priority 0)]
    (each [_ ev (ipairs events)]
      (let [handlers (or (. self.__mt.__event-handlers ev) [])]
        (table.insert handlers method)
        (tset self.__mt.__event-handlers ev 
              (lume.sort handlers 
                         #(< (or $1.meta.priority 0)
                             (or $2.meta.priority 0))))))))

(fn Class.__compile-metadata [self]
  (each [k v (pairs self.__mt)]
    (when (= (string.sub k 1 10) :__handles?)
      (tset self.__mt k nil)))
  (each [_ method (pairs self.__mt)]
    (when (= (getmetatable method) ClassMethod)
      (each [_ ev (ipairs method.meta.events)]
        (tset self.__mt (.. :__handles?- ev) true)))))

(fn Class.__mixin-method [self source name meta]
  (when (. self.__mt name) (self:__remove-method name))
  (tset self.__mt name (class-method name source.__mt.__method-functions meta))
  (self:__index-method name))

(fn Class.method [self name meta f]
  (when (. self.__mt name) (self:__remove-method name))
  (tset self.__mt.__method-functions name f)
  (tset self.__mt name (class-method name self.__mt.__method-functions meta))
  (self:__index-method name)
  (self:__compile-metadata))
  
(fn Class.__call [self fields ...]
  (let [o (lume.merge (collect [k v (pairs self.__fields)]
                              (values k (if (and (= (type v) :table) v.clone) (v:clone) v)))
                      (or fields {}))
        inst (setmetatable o self.__mt)]
    (assert (not o.state) "state is a reserved member name")
    (set o.state
      (collect [name [initial transitions] (pairs self.__statemachines)]
        (values name (statemachine 
                       initial transitions
                       (fn [from to ...]
                         (o:dispatch (.. :state- name :- :exit- from) ...)
                         (o:dispatch (.. :state- name :- :enter- to) ...))))))
    ; (each [name store (pairs self.__stores)]
    ;   (let [id (store:subscribe 
    ;             (fn [new-state]
    ;               (self:dispatch (.. :state- name :-change)
    ;                              new-state)))]
    ;     (o:on :destroy (store:unsubscribe id))))
    inst))

(fn instance-dispatch [self ev ...]
  (each [_ method (pairs (or (. self.__event-handlers ev) []))]
    (when (or (not method.meta.state)
              (accumulate [acc true k v (pairs method.meta.state)]
                          (and acc (= (. self.state k :current) v))))
      (: self method.name ...))))

(fn instance-state-dispatch [self sname transition ...]
  (: (. self.state sname) :dispatch transition ...))
  
(fn class []
  (let [mt {:__method-functions {}
            :__event-handlers {}
            :dispatch instance-dispatch
            :state-dispatch instance-state-dispatch}]
    (set mt.__index mt)
    (setmetatable {:__mt mt
                   :__fields {}
                   :__statemachines {}} Class
                   :__stores {})))

;; --- testing


;; Classes are created via the class function

; (local greeter (class))
; ;; :method is used to define a method on the class with a given name and some optional metadata
; (greeter:method :say-hi {:on :update}
;   (fn [] (print "Hi")))

; ;; Classes can be mixed in to other classes
; (local player (class))
; (player:mixin greeter)
; (player:method :say-hello {:on :update}
;   (fn [] (print "Hello")))

; ;; Classes implement __call to create instances
; (local instance (player))

; ;; Methods can be called like regular functions
; (instance:say-hi) ;; prints "Hi"
; (instance:say-hello) ;; prints "Hello"

; ;; Events can be dispatched and all subscribed methods will be called
; (instance:dispatch :update) ;; prints "Hi" and "Hello"

; ;; Methods can be redefined at runtime, the instance metatable is automatically updated.'
; ;; This allows for frictionless REPL driven development without lume.hotswap etc
; (player:method :say-hello {:on :update}
;   (fn [] (print "Hello!!!!!")))

; (instance:dispatch :update) ;; prints "Hi" and "Hello!!!!!"

; ;; This raises a method collision error. Only 1 class can define a method with a given name
; (greeter:method :say-hello {}
;   (fn [] (print "Salutations")))

class
