(local inspect (require :lib.inspect))
(local lume (require :lib.lume))
(local helpers (require :golly.helpers))

(local StateMachine {:prototype {}})

(fn StateMachine.prototype.get-transition [self k]
  (let [transitions (. self.__transitions self.current)
        global-transitions (. self.__transitions :*)]
    (or (?. transitions k)
        (?. global-transitions k))))

(fn StateMachine.prototype.send [self evtype ...]
  (let [transition (self:get-transition evtype)]
    (when transition
      (self:transition transition ...))))

(fn StateMachine.__index [self k]
  (if (. StateMachine.prototype k)
      (. StateMachine.prototype k)
      ;#(self:send k $...)
      (let [state (. self.__states self.current)
            sval (?. state k)]
        (if sval
            sval
            #(self:send k $...)))))

(fn StateMachine.prototype.transition [self to ...]
  (when (= self.current to) (lua :return))
  (set self.current to)
  (let [exit-callbacks  (. self.__callbacks.on-exit self.current)
        enter-callbacks (. self.__callbacks.on-enter to)]
    (each [_ cb (ipairs (or exit-callbacks []))] (cb ...))
    (each [_ cb (ipairs (or enter-callbacks []))] (cb ...))))
  ; (each [k v (pairs (or (. self.__states to) {}))]
  ;   (print k (inspect v))
  ;   (tset self k v))

(fn create-statemachine [initial-state props]
  (assert props.transitions "Must pass transitions to the state machine")
  (let [transitions {:* {}}]
    (each [_ {: name : from : to} (ipairs props.transitions)]
      (assert name "Must pass transition name")
      (assert to "Must pass transition to")
      (let [from-k (or from :*)]
        (tset transitions from-k (or (. transitions from-k) {}))
        (tset (. transitions from-k) name to)))
    (let [sm (setmetatable
              {:__transitions transitions
               :__callbacks (or props.callbacks {})
               :__states (or props.states {})
               :current initial-state}
              StateMachine)]
      ;(sm:transition initial-state)
      sm)))

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

create-statemachine
