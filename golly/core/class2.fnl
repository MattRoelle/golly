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

(fn Class.field [self k v]
  (tset self.__fields k v))

(fn Class.mixin [self other ...]
  (each [k v (pairs other.__fields)]
    (self:field k v))
  (each [name [initial transitions] (pairs other.__statemachines)]
    (self:statemachine name initial transitions))
  (each [fname meta (pairs other.__mt.__methods)]
    (let [f (. other.__mt fname)]
      (self:method fname {:on meta.events :source other :state meta.state} f))))

(fn Class.__remove-method [self name]
  (let [method (. self.__mt.__methods name)]
    (assert (= method.source self)
            (.. "Method collision, " name " has already been defined by another class"))
    (each [ix ev (ipairs method.meta.events)]
      (table.remove (. self.__mt.__event-handlers ev) ix))))

(fn Class.method [self name meta f]
  (when (. self.__mt name)
    (self:__remove-method name))
    ;; Clean up existing method definition
  (let [events (or (when meta.on (if (= (type meta.on) "table") meta.on [meta.on])) [])
        state meta.state]
    (tset self.__mt.__methods name f)
    (tset self.__mt name (class-method name self.__mt.__methods {: events : state}))
    (when meta.on
      (each [_ ev (ipairs events)]
        (when (not (. self.__mt.__event-handlers ev))
          (tset self.__mt.__event-handlers ev []))
        (table.insert (. self.__mt.__event-handlers ev) name)))))
  
(fn Class.__call [self fields ...]
  (let [o (lume.merge self.__fields (or fields {}))
        inst (setmetatable o self.__mt)]
    (assert (not o.state) "state is a reserved member name")
    (set o.state
      (collect [name [initial transitions] (pairs self.__statemachines)]
        (values name (statemachine 
                       initial transitions
                       (fn [from to ...]
                         (o:dispatch (.. :state- name :- :exit- from) ...)
                         (o:dispatch (.. :state- name :- :enter- to) ...))))))
    (o:dispatch :init ...)
    inst))

(fn instance-dispatch [self ev ...]
  (each [_ fname (ipairs (or (. self.__event-handlers ev) []))]
    (let [meta (. self.__methods fname)]
      (when (or (not meta.state)
                (accumulate [acc true k v (pairs meta.state)]
                            (and acc (= (. self.state k :current) v))))
        (: self fname ...)))))

(fn instance-state-dispatch [self sname transition ...]
  (: (. self.state sname) :dispatch transition ...))
  
(fn class []
  (let [mt {:__methods {}
            :__event-handlers {}
            :dispatch instance-dispatch
            :state-dispatch instance-state-dispatch}]
    (set mt.__index mt)
    (setmetatable {:__mt mt
                   :__fields {}
                   :__statemachines {}} Class)))

;; --- testing


(local mixin-test (class))
(mixin-test:method :foo {:on :update} (fn [] (print :mixin-update)))

(local my-class (class))

(my-class:mixin mixin-test)

; (my-class:method :foo {:on :update}
;   (fn [] (print :update-1)))

(local inst (my-class))

(inst:dispatch :update 1)

; (my-class:method :foo {:on :update}
;   (fn [] (print :update-2)))

(mixin-test:method :foo {:on :update}
                   (fn [] (print :mixin-update-2)))

(inst:dispatch :update 1)

class
