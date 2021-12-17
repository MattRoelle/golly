(require "love.event")

;; This module exists in order to expose stdio over a channel so that it
;; can be used in a non-blocking way from another thread.

(fn prompt [cont?]
  (io.write (if cont? ".." ">> ")) (io.flush) (.. (io.read) "\n"))

;; This module is loaded twice: initially in the main thread where ... is nil,
;; and then again in a separate thread where ... contains the channel used to
;; communicate with the main thread.

(fn looper [event channel]
  (match (channel:demand)
    [:write vals] (do (io.write (table.concat vals "\t"))
                      (io.write "\n"))
    [:read cont?] (love.event.push event (prompt cont?)))
  (looper event channel))

(match ...
  (event channel) (looper event channel))

{:start (fn start-repl []
          (let [code (love.filesystem.read "lib/stdio.fnl")
                luac (if code
                         (love.filesystem.newFileData
                          (fennel.compileString code) "io")
                         (love.filesystem.read "lib/stdio.lua"))
                thread (love.thread.newThread luac)
                io-channel (love.thread.newChannel)
                coro (coroutine.create fennel.repl)
                options {:readChunk (fn [{: stack-size}]
                                      (io-channel:push [:read (< 0 stack-size)])
                                      (coroutine.yield))
                         :onValues (fn [vals]
                                     (io-channel:push [:write vals]))
                         :onError (fn [errtype err]
                                    (io-channel:push [:write [err]]))
                         :moduleName "lib.fennel"}]
            ;; this thread will send "eval" events for us to consume:
            (coroutine.resume coro options)
            (thread:start "eval" io-channel)
            (set love.handlers.eval
                 (fn [input]
                   (coroutine.resume coro input)))))}
