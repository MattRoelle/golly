(local create-tween (require :golly.tween))

(local Timeline {})
(set Timeline.__index Timeline)

(fn wait [duration]
  "Wait for the given duration."
  (var timer 0)
  (while (< timer duration)
    (let [dt (coroutine.yield)]
      (set timer (+ timer dt)))))

(fn wait-until [predicate]
  "Waits until the predicate function returns true."
  (while (not (predicate))
    (coroutine.yield)))

(fn do-while [predicate f]
  "Waits until the predicate function returns true."
  (while (predicate)
    (f)
    (coroutine.yield)))

(fn end [result?]
  "Ends the timeline."
  (coroutine.yield result?))

(fn tween [duration subject target easing]
  (let [tw (create-tween duration subject target easing)]
    (while (= (tw:status) :running)
      (tw:update (coroutine.yield)))))

; (fn parallel [fns]
;   "Waits until all the timelines are done."
;   (while (accumulate [acc true _ t (ipairs fns)]
;            (and acc (t:update dt)))
;     (coroutine.yield)))

(fn Timeline.update [self dt]
  "Returns a truthy value if the timeline is finished."
  (let [(success result) (coroutine.resume self.coro dt)]
    (when (not success) (error result))
    (when (= (coroutine.status self.coro) :dead) 
      (or result true))))

(fn timeline [f]
  "Creates a timeline from the given function."
  (let [coro (coroutine.create f)]
    (setmetatable {: coro} Timeline)))

(setmetatable
  {: wait 
   : wait-until
   : do-while
   : end
   : tween}
   ;: parallel} 
  {:__call #(timeline $2)})
