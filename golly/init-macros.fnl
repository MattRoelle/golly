(fn += [x n] `(set ,x (+ ,x ,n)))
(fn -= [x n] `(set ,x (- ,x ,n)))
(fn *= [x n] `(set ,x (* ,x ,n)))
(fn /= [x n] `(set ,x (/ ,x ,n)))
(fn vec [...] `((. (require :golly.math.vector) :vec) ,...))
(fn polar-vec2 [...] `((. (require :golly.math.vector) :polar-vec2) ,...))
(fn lerp [...] `((. (require :golly.helpers) :lerp) ,...))
(fn lerpangle [...] `((. (require :golly.helpers) :lerpangle) ,...))
(fn lerpto [...] `((. (require :golly.helpers) :lerpto) ,...))
(fn lerptoangle [...] `((. (require :golly.helpers) :lerptoangle) ,...))

(fn statemachine-state [states callbacks transitions result-body expr]
  (let [[op & rest] expr
        [name & body] rest]
   (table.insert result-body `(tset states# ,name {}))
   (table.insert result-body `(tset callbacks#.on-enter ,name []))
   (table.insert result-body `(tset callbacks#.on-exit ,name []))
   (each [_ [op & rest] (ipairs body)]
      (table.insert result-body 
        (match (tostring op)
         :field
         `(tset (. states# ,name) ,(. rest 1) ,(. rest 2))
         :on-enter 
         (let [[arglist & fn-body] rest]
           `(table.insert (. callbacks#.on-enter ,name)
                          (fn ,arglist ,(unpack fn-body))))
         :on-exit
         (let [[arglist & fn-body] rest]
           `(table.insert (. callbacks#.on-exit ,name)
                          (fn ,arglist ,(unpack fn-body)))))))))

(fn statemachine [initial-state ...]
  (local result-body [])
  `(let [states# {}
         callbacks# {:on-enter [] 
                     :on-exit []}]
     (var transitions# [])
    ,(each [_ [op & rest] (ipairs [...])]
      (match (tostring op)
       :state 
       (let [[name & body] rest]
        (table.insert result-body `(tset states# ,name {}))
        (table.insert result-body `(tset callbacks#.on-enter ,name []))
        (table.insert result-body `(tset callbacks#.on-exit ,name []))
        (each [_ [op & rest] (ipairs body)]
           (table.insert result-body 
             (match (tostring op)
              :field
              `(tset (. states# ,name) ,(. rest 1) ,(. rest 2))
              :on-enter 
              (let [[arglist & fn-body] rest]
                `(table.insert (. callbacks#.on-enter ,name)
                               (fn ,arglist ,(unpack fn-body))))
              :on-exit
              (let [[arglist & fn-body] rest]
                `(table.insert (. callbacks#.on-exit ,name)
                               (fn ,arglist ,(unpack fn-body))))))))
       :transitions
       (each [_ [name conditions] (ipairs rest)]
          (assert conditions.to "Must pass conditions.to")
          (table.insert result-body 
            `(set transitions#
                  (lume.concat
                    transitions#
                    ,(if (and conditions.from (= (type conditions.from) :table))
                         (icollect [_ fromstate (ipairs conditions.from)]
                           `{:name ,(tostring name) 
                             :from ,fromstate 
                             :to ,conditions.to})
                         `[{:name ,(tostring name)
                            :from ,conditions.from
                            :to ,conditions.to}])))))))
    (unpack ,result-body)
    ((. (require :golly) :statemachine)
     ,initial-state {:transitions transitions# 
                     :states states#
                     :callbacks callbacks#})))

(fn ent-statemachine [self smname ename initial-state ...]
  (local result-body [])
  (local state-handlers {})
  `(let [states# {}
         callbacks# {:on-enter [] 
                     :on-exit []}]
     (var transitions# [])
    ,(each [_ [op & rest] (ipairs [...])]
      (match (tostring op)
       :state 
       (let [[name & body] rest]
        (table.insert result-body `(tset states# ,name {}))
        (table.insert result-body `(tset callbacks#.on-enter ,name []))
        (table.insert result-body `(tset callbacks#.on-exit ,name []))
        (each [_ [op & rest] (ipairs body)]
          (match (tostring op)
           :field
           (table.insert result-body `(tset (. states# ,name) ,(. rest 1) ,(. rest 2)))
           :on-enter 
           (table.insert result-body
             (let [[arglist & fn-body] rest]
               `(table.insert (. callbacks#.on-enter ,name)
                              (fn ,arglist ,(unpack fn-body)))))
           :on-exit
           (table.insert result-body
             (let [[arglist & fn-body] rest]
               `(table.insert (. callbacks#.on-exit ,name)
                              (fn ,arglist ,(unpack fn-body)))))
           :on 
           (let [[evtype arglist & body] rest]
             (when (not (. state-handlers evtype))
               (tset state-handlers evtype {}))
             (tset (. state-handlers evtype) name {: arglist : body})))))
       :transitions
       (each [_ [name conditions] (ipairs rest)]
          (assert conditions.to "Must pass conditions.to")
          (table.insert result-body 
            `(set transitions#
                  (lume.concat
                    transitions#
                    ,(if (and conditions.from (= (type conditions.from) :table))
                         (icollect [_ fromstate (ipairs conditions.from)]
                           `{:name ,(tostring name) 
                             :from ,fromstate 
                             :to ,conditions.to})
                         `[{:name ,(tostring name)
                            :from ,conditions.from
                            :to ,conditions.to}])))))))
     ,(each [evtype ev-handlers (pairs state-handlers)]
        (local state-handler-body [])
        (each [st handler (pairs ev-handlers)]
          (table.insert state-handler-body st)
          (table.insert state-handler-body `(let [,handler.arglist [...]]
                                              ,(unpack handler.body))))
        (table.insert result-body
           `(: ,self :on ,evtype
               (fn [...] 
                 (match (. ,self ,smname :current)
                   ,(unpack state-handler-body)))
               ,(tostring ename))))
    (do ,(unpack result-body))
    ((require :golly.statemachine)
     ,initial-state {:transitions transitions# 
                     :states states#
                     :callbacks callbacks#})))

(fn with-shader [shader ...]
  `(do
    (love.graphics.setShader ,shader)
    ,[...]
    (love.graphics.setShader)))

(fn with-color [r g b a ...]
  `(do
    (let [(_r# _g# _b# _a#) (love.graphics.getColor)]
      (love.graphics.setColor ,r ,g ,b ,a)
      ,[...]
      (love.graphics.setColor _r# _g# _b# _a#))))

(fn with-stencil [[stencilfn action value keepvalues] ...]
  `(do
    (love.graphics.stencil ,stencilfn ,action ,value ,keepvalues)
    (do ,[...])
    (love.graphics.stencil)))

(fn with-blend-mode [mode ...]
 `(let [old# (love.graphics.getBlendMode)]
    (love.graphics.setBlendMode ,mode)
    ,[...]
    (love.graphics.setBlendMode old#)))

(fn with-transform-push [...]
  `(do
    (love.graphics.push)
    ,[...]
    (love.graphics.pop)))

(fn with-origin [...]
  `(do
    (love.graphics.push)
    (love.graphics.origin)
    ,[...]
    (love.graphics.pop)))

(fn with-canvas [canvas ...]
 `(let [old# (love.graphics.getCanvas)]

    ;(love.graphics.setCanvas ,canvas)
    ,[...]
    (love.graphics.setCanvas old#)))

(fn entity-expr [self name expr]
  (let [[op & rest] expr]
    (match (tostring op)
      :statemachine
      (let [[smname initial-state & body] rest]
        `(tset ,self ,smname
               ,(ent-statemachine self smname name initial-state (unpack body))))
      :on 
      (let [[evtype arglist & body] rest]
        `(: ,self :on ,evtype (fn ,arglist ,(unpack body)) ,(tostring name)))
      ; :ref 
      ; (let [[tag] rest]
      ;   `(: ,self :on :init
      ;       (fn []
      ;         `(tset ,self ,tag (,self.scene:find ,tag)))))
      :tags
      `(tset ,self :tags [,(unpack rest)])
      :mixins
      `(doto ,self ,(unpack rest))
      :mixin
      `(doto ,self ,(unpack rest))
      :default-prop 
      (let [[k v] rest] `(tset ,self ,k (or (. ,self ,k) ,v)))
      :default-props
      (let [[tbl] rest]
        `(each [k# v# (pairs ,tbl)]
           (tset ,self k# (or (. ,self k#) v#))))
      _ expr)))

(fn mixin [name arglist ...]
  (let [self (. arglist 1)]
    `(fn ,name ,arglist
       (do 
         ,(unpack 
            (icollect [_ expr (ipairs [...])]
              (entity-expr self name expr)))))))

(fn class [name [self & arglist] ...]
  (let [proparg (. arglist 1)]
    `(fn ,name ,arglist
       (var ,self nil)
       (set ,self ((. (require :golly.core.class) :new-class) (or ,proparg {})))
       ; TODO: Separate this line from the regular class mixins so that not all classes have to be game entities
       ((. (require :golly.core.entity) :mixin-base-entity) ,self)
       (tset ,self :__name ,(tostring name))
       (do 
         ,(unpack 
            (icollect [_ expr (ipairs [...])]
              (entity-expr self name expr))))
       ,self)))

(fn def-system [name [self & arglist] ...]
  `(fn ,name ,arglist
    (local ,self {})
    (do 
     ,(icollect [_ expr (ipairs [...])]
        (let [[op & rest] expr
              strop (tostring op)
              [arglist & body] rest
              bodyfn (when (not= strop :filter) `(fn [_# ,(unpack arglist)] ,(unpack body)))]
          (match strop
            :filter `(tset ,self :filter ((. (require :lib.tiny) :requireAll) ,(unpack rest)))
            ; :process (let [entarg (. arglist 1)]
            ;            `(tset ,self :process 
            ;                   (fn [_# ,(unpack arglist)]
            ;                     (when (. ,entarg :destroyed) (lua "return"))
            ;                     ,(unpack body))))
            :process `(tset ,self :process ,bodyfn)
            :preprocess `(tset ,self :preProcess ,bodyfn)
            :postprocess `(tset ,self :postProcess ,bodyfn)
            :sort `(tset ,self :compare ,bodyfn)
            :on-add `(tset ,self :onAdd ,bodyfn)
            :on-remove `(tset ,self :onRemove ,bodyfn)
            true (error (.. "Invalid child form of def-system: " op ". Options are filter, process, pre-process, post-process, sort, on-add, on-remove")))))
     (let [ctor#
           (if (. ,self :sort)
               (. (require :lib.tiny) :sortedProcessingSystem)
               (. (require :lib.tiny) :processingSystem))]
       (ctor# ,self)))))

{: with-stencil
 : with-shader
 : with-origin
 : with-color
 : with-transform-push
 : with-blend-mode
 : with-canvas
 : def-system
 : class
 : mixin
 : statemachine
 : +=
 : -=
 : *=
 : /=
 : vec
 : polar-vec2
 : lerp 
 : lerpangle 
 : lerpto 
 : lerptoangle}
