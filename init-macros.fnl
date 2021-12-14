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

(fn defmixin [name arglist ...]
  (let [self (. arglist 1)]
    `(fn ,name ,arglist
       (do 
         ,(unpack 
            (icollect [_ expr (ipairs [...])]
              (let [[op & rest] expr]
                (match (tostring op)
                  :on 
                  (let [[evtype arglist & body] rest]
                    `(: ,self :on ,evtype (fn ,arglist ,(unpack body)) ,(tostring name)))
                  :mixin
                  `(doto ,self ,(unpack rest))
                  :prop 
                  (let [[k v] rest]
                    `(tset ,self ,k ,v))
                  _ expr))))))))

; (macro defmixin2 [name arglist ...]
;   (let [self (. arglist 1)]
;     `(fn ,name ,arglist
;        (do 
;          ,(unpack 
;             (icollect [_ expr (ipairs [...])]
;               (let [[op & rest] expr]
;                 (match (tostring op)
;                   :on 
;                   (let [[evtype arglist & body] rest]
;                     `(: ,self :on ,evtype (fn ,arglist ,body)))
;                   :mixin
;                   `(doto ,self ,(unpack rest))
;                   :prop 
;                   (let [[k v] rest]
;                     `(tset ,self ,k ,v))
;                   _ expr))))))))

; (macrodebug
;   (defmixin2 blah [self]
;     (mixin (m-2 1)
;              (m-3 1))))

(fn defentity [name [self & arglist] initial-props ...]
  (let [proparg (. arglist 1)]
    `(fn ,name ,arglist
       (var ,self nil)
       (set ,self ((. (require :golly.core.entity) :new-entity)
                   (lume.merge ,initial-props (or ,proparg {}))))
       (tset ,self :__name ,(tostring name))
       (do 
         ,(unpack 
            (icollect [_ expr (ipairs [...])]
              (let [[op & rest] expr]
                (match (tostring op)
                  :on 
                  (let [[evtype arglist & body] rest]
                    `(: ,self :on ,evtype (fn ,arglist ,(unpack body)) ,(tostring name)))
                  :mixins
                  `(doto ,self ,(unpack rest))
                  :mixin
                  `(doto ,self ,(unpack rest))
                  :prop 
                  (let [[k v] rest]
                    `(tset ,self ,k ,v))
                  _ expr)))))
       ,self)))

(fn defsystem [name [self & arglist] ...]
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
            true (error (.. "Invalid child form of defsystem: " op ". Options are filter, process, pre-process, post-process, sort, on-add, on-remove")))))
     (let [ctor#
           (if (. ,self :sort)
               (. (require :lib.tiny) :sortedProcessingSystem)
               (. (require :lib.tiny) :processingSystem))]
       (ctor# ,self)))))

(fn statemachine [initial-state ...]
  `(let [m# {:initial ,initial-state
             :events []
             :callbacks {}}]
     ,(icollect [_ expr (ipairs [...])]
                (let [[op & rest] expr]
                  (if
                    (= op (sym :event))
                    (let [[name evfields] rest]
                      ;(print "inserting event" ((require :lib.inspect) evfields))
                      `(table.insert m#.events
                                     (lume.merge {:name ,name} ,evfields)))
                    (= op (sym :callback))
                    (let [[fields & body] rest
                          _ (assert (not (and fields.from fields.to))
                                    "Can only pass either 1 from or 1 to expr")
                          k (.. "on"
                                (if fields.from :exit
                                    fields.to :enter
                                    (error "Invalid callback descriptor"))
                                (or fields.from fields.to))]
                      `(tset m#.callbacks ,k (fn [] (do ,body)))))))
     ((. (require :lib.statemachine) :create) m#)))

{: with-stencil
 : with-shader
 : with-origin
 : with-color
 : with-transform-push
 : with-blend-mode
 : with-canvas
 : defsystem
 : defentity
 : defmixin
 : statemachine}
