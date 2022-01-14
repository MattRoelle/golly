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

(fn StateMachine.prototype.add-callback [self t state f]
  (table.insert (. (. self.__callbacks t) state) f))

(fn StateMachine.__index [self k]
  (if (. StateMachine.prototype k)
      (. StateMachine.prototype k)
      (let [state (. self.__states self.current)
            sval (?. state k)]
        (if sval
            sval
            #(self:send k $...)))))

(fn StateMachine.prototype.transition [self to ...]
  (when (= self.current to) (lua :return))
  (let [previous self.current]
    (set self.current to)
    (let [exit-callbacks  (. self.__callbacks.on-exit previous)
          enter-callbacks (. self.__callbacks.on-enter to)]
      (each [_ cb (ipairs (or exit-callbacks []))] (cb ...))
      (each [_ cb (ipairs (or enter-callbacks []))] (cb ...)))))

(fn StateMachine.prototype.add-transition [self {: name : from : to}]
  (assert name "Must pass transition name")
  (assert to "Must pass transition to")
  (let [from-k (or from :*)]
    (tset self.__transitions from-k (or (. self.__transitions from-k) {}))
    (tset (. self.__transitions from-k) name to)
    (tset self.__states to (or (. self.__states to) {}))))

(fn statemachine [initial-state ?options]
  (let [transitions {:* {}}]
    (let [sm (setmetatable
              {:__transitions {:* {}}
               :__callbacks {:on-enter {} :on-exit {}}
               :__states {}
               :current initial-state}
              StateMachine)]
      (each [_ transition (ipairs (or (?. ?options :transitions) []))]
        (sm:add-transition transition))
      sm)))

(local smtest2 (statemachine :a))
(smtest2:add-transition {:name :to-b :from :a :to :b})
(smtest2:add-transition {:name :to-a :from :b :to :a})
(smtest2:add-callback :on-enter :b #(print "Entering b"))
(smtest2:to-a)

statemachine
