(local Color {})
(set Color.__index Color)

(fn rgba [r? g? b? a?]
  (setmetatable
    (if
      (= (type r?) :number)
      {:r r? :g g? :b b? :a a?}
      (?. r? :r)
      {:r r?.r :g r?.g :b r?.b :a r?.a}
      (?. r? 1)
      {:r (. r? 1) :g (. r? 2) :b (. r? 3) :a (. r? 4)}
      (error "Invalid color arguments"))
    Color))

(fn parse-hexadecimal-number [str] (tonumber str 16))
(fn hexcolor [str]
  (let [r (parse-hexadecimal-number (string.sub str 1 2))
        g (parse-hexadecimal-number (string.sub str 3 4))
        b (parse-hexadecimal-number (string.sub str 5 6))
        a (parse-hexadecimal-number (string.sub str 7 8))]
    (rgba (/ r 255) (/ g 255) (/ b 255) (/ a 255))))

(fn Color.clone [self]
  (rgba self.r self.g self.b self.a))

(fn Color.serialize [self]
  [self.r self.g self.b self.a])

(fn Color.__tostring [self]
  (string.format "(%d, %d, %d, %d)" self.r self.g self.b self.a))

{: rgba
 : hexcolor}
