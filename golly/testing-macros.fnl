(fn assert-not-tables [a b]
  `(let [atype# (type ,a)
         btype# (type ,b)]
     (when (or (= atype# "table") (= btype# "table"))
      (error "Cannot compare table values"))))

(fn assert= [a b]
 `(do
   (assert-not-tables ,a ,b)
   (when (not= ,a ,b)
    (error (.. "Assertion Error: " ,a " != " ,b)))))

(fn assertnot= [a b]
 `(do
   (assert-not-tables ,a ,b)
   (when (= ,a ,b)
    (error (.. "Assertion Error: " ,a " != " ,b)))))

(fn assert< [a b]
 `(do
   (assert-not-tables ,a ,b)
   (when (>= ,a ,b)
    (error (.. "Assertion Error: " ,a " != " ,b)))))

(fn assert> [a b]
 `(do
   (assert-not-tables ,a ,b)
   (when (<= ,a ,b)
    (error (.. "Assertion Error: " ,a " != " ,b)))))

(fn should [desc ...]
  `{ :desc ,desc
     :fn (fn []
           (do ,...))})

(fn describe [suite-name suite-desc ...]
 `(local ,suite-name
   (fn []    
     (print "----------------------")
     (print ,suite-desc)
     (each [ix# test# (ipairs [,...])]
      (let [(status# err#) (pcall test#.fn)]
       (print
        (if status#
         (.. "\t" test#.desc " - passed")
         (.. "\t" test#.desc " - failed\n\t\t" err#))))))))

{: assert-not-tables
 : assert=
 : assertnot=
 : assert>
 : assert<
 : should
 : describe}