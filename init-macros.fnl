(fn += [x n] `(set ,x (+ ,x ,n)))
(fn -= [x n] `(set ,x (- ,x ,n)))
(fn *= [x n] `(set ,x (* ,x ,n)))
(fn /= [x n] `(set ,x (/ ,x ,n)))

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
; (macrodebug
;   (statemachine :idle
;      (transitions
;        (jump {:from :idle :to :airborn})
;        (land {:from :airborn :to :idle})
;        (die {:to :dead}))
;      (state :idle
;        (field :x 100)
;        (on-enter [] (print "enter idle 22"))
;        (on-exit [] (print "exit idle 22")))))

; (local smtest2 
;  (statemachine :idle
;   (transitions
;     (jump {:from :idle :to :airborn})
;     (land {:from :airborn :to :idle})
;     (die {:to :dead}))
;   (state :idle
;     (field :x 100)
;     (on-enter [] (print "enter idle 22"))
;     (on-exit [] (print "exit idle 22")))
;   (state :airborn
;     (field :x 200))))

; (print "test 2")
; (print smtest2.x)
; (smtest2:jump)
; (print smtest2.x)
; (smtest2:land)

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
                  :mixins
                  `(doto ,self ,(unpack rest))
                  :mixin
                  `(doto ,self ,(unpack rest))
                  :field 
                  (let [[k v] rest]
                    `(tset ,self ,k ,v))
                  _ expr))))))))

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
                  :field 
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
 : statemachine
 : +=
 : -=
 : *=
 : /=}
