(local helpers (require :golly.helpers))
(local inspect (require :lib.inspect))
(local lume (require :lib.lume))

(local Class {:prototype {}})

(fn new-class [props]
  (let [obj (lume.merge
              {:id (helpers.uuid)
               :__handlers {}}
              (or props {}))]
    (setmetatable obj Class)))

{: new-class 
 : Class}
