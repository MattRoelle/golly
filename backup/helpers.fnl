(fn uuid []
  (let [template :xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx]
    (string.gsub template "[xy]"
                 (fn [c]
                   (let [v (or (and (= c :x) (math.random 0 15)) (math.random 8 11))]
                     (string.format "%x" v))))))

{: uuid}
