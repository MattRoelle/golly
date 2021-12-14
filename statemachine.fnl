(local inspect (require :lib.inspect))
(local lume (require :lib.lume))

(local StateMachine {:prototype {}})

(fn StateMachine.prototype.get-transition [self k]
  (let [transitions (. self.__transitions self.current)
        global-transitions (. self.__transitions :*)]
    (or (?. transitions k)
        (?. global-transitions k))))

(fn StateMachine.__index [self k]
  (if (. StateMachine.prototype k)
    (. StateMachine.prototype k)
    (let [transition (self:get-transition k)]
      (if transition
        #(self:transition transition $2 $3 $4 $5 $6 $7 $8 $9)
        (let [state (. self.__states self.current)]
          (?. state k))))))

(fn StateMachine.prototype.transition [self to ...]
  (let [exit-callbacks  (. self.__callbacks.on-exit self.current)
        enter-callbacks (. self.__callbacks.on-enter to)]
    (each [_ cb (ipairs (or exit-callbacks []))] (cb ...))
    (each [_ cb (ipairs (or enter-callbacks []))] (cb ...)))
  (set self.current to))

(fn create-statemachine [initial-state props]
  (assert props.transitions "Must pass transitions to the state machine")
  (let [transitions {:* {}}]
    (each [_ {: name : from : to} (ipairs props.transitions)]
      (assert name "Must pass transition name")
      (assert to "Must pass transition to")
      (tset transitions (or from :*) (or (. transitions from) {}))
      (if from
        (tset (. transitions from) name to)
        (tset (. transitions :*) name to)))
    (setmetatable
      {:__transitions transitions
       :current initial-state
       :__callbacks (or props.callbacks {})
       :__states (or props.states {})}
      StateMachine)))

; (local smtest 
;   (create-statemachine :idle
;    {:transitions [{:name :jump :from :idle :to :in-air}
;                   {:name :land :from :in-air :to :idle}]
;     :callbacks {:on-enter {:in-air [#(print "jumping!" $1)]}
;                 :on-exit {:in-air [#(print "landing!" $1)]}}
;     :states {:idle {:x 1001
;                     :update (fn [dt] (print "update!" dt))}
;              :in-air {:x 2001}}}))

; (smtest:jump)
; (print smtest.x)
; (smtest:land 100)
; (smtest:update 5)
; (print smtest.x)

(macro statemachine [initial-state ...]
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
    (create-statemachine ,initial-state {:transitions transitions# 
                                         :states states#
                                         :callbacks callbacks#})))
(macrodebug
  (statemachine :idle
     (transitions
       (jump {:from :idle :to :airborn})
       (land {:from :airborn :to :idle})
       (die {:to :dead}))
     (state :idle
       (field :x 100)
       (on-enter [] (print "enter idle 22"))
       (on-exit [] (print "exit idle 22")))))

(local smtest2 
 (statemachine :idle
  (transitions
    (jump {:from :idle :to :airborn})
    (land {:from :airborn :to :idle})
    (die {:to :dead}))
  (state :idle
    (field :x 100)
    (on-enter [] (print "enter idle 22"))
    (on-exit [] (print "exit idle 22")))
  (state :airborn
    (field :x 200))))

(print "test 2")
(print smtest2.x)
(smtest2:jump)
(print smtest2.x)
(smtest2:land)

