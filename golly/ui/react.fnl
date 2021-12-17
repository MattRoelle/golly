(local beholder (require :lib.beholder))
(local rendering (require :golly.ui.renderer))

;; UI
;; Very bare bones react style framework for building game UIs

;; Components
;; ----------
;; only *pure* function components, no side effects
;; function of props
;; memoized
;; return hiccup style markup that is passed to r.ui.draw

;; Input
;; ----------
;; text input etc separate / future thing

;; tight integration with input module
;; input only handled in screen space for mouse events
;; Any controller-usable interface is really a graph
;; Only 1 "active" node at a type


(local UIComponent {})
(set UIComponent.__index UIComponent)

(fn UIComponent.compute-layout [self]
 (set self.layout (self.f self.props self.context))
 (set self.dirty false))

(fn UIComponent.set-props [self props]
 (set self.props props)
 (set self.dirty true))

(fn UIComponent.handle-input [self input]
 (when (not self.focused) (lua "return"))
 ;(print "Got input!") (pp self.context) (set self.dirty true)
 (let [edges (. self.context.input-graph self.context.active-btn)]
  (when edges
    (let [destination (. edges input)]
     (set self.dirty true)
     (when destination
       (if (= (type destination) :function)
         (destination)
         (set self.context.active-btn destination)))))))

(fn UIComponent.draw [self x y w h]
 (when self.dirty (self:compute-layout))
 (rendering.draw { :width w
                   :height h
                   :x x 
                   :y y
                   :root self.layout}))

(fn UIComponent.focus [self]
 (set self.focused true))

(fn UIComponent.destroy [self]
 (beholder.stopObserving self.inputsub))

(local UIContext {})
(set UIContext.__index UIContext)

(fn UIContext.button [self id edges onclick bodyfn]
  "A 'button' is an interactive component. The bodyfn is passed
  the focus state. The onclick is fired when the user hits the primary
  input" 
 (when (not self.active-btn)
   (set self.active-btn id))
 (tset self.input-graph id (lume.merge edges {:a onclick}))
 (bodyfn (= self.active-btn id)))

(fn component [f]
 (let [c (setmetatable {: f
                        :dirty true
                        :focused false
                        :context (setmetatable {:input-graph {}
                                                :active-btn nil}
                                               UIContext)}
                       UIComponent)]
   (set c.inputsub (beholder.observe :input #(c:handle-input $2)))
   c))

 
{: component}
