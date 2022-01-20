# GOLLY

### Game Oriented Lua Lisp.

Golly is a pure Lua /gameplay/ programming library written in Fennel that can be dropped into any engine. Out of the box Golly gives you: 
- A fully featured ECS framework (on top of tiny-ecs) 
- A game logic focused OOP framework. Strong mixin support, zero support for inheritence (composition only!). Methods support metadata informing the engine /when/ to call the method (events such as update, draw, redux state change, or user defined events) 
- Redux style state management
- A timeline tool which leverages lua's coroutines for succinctly writing gameplay code. 

There are many small tools and library functions as well. The API is still experimental and undocumented. Anticipating a v0.1 alpha release soon 

#### Example

Right now, there is a minimal Love2D example showcasing a basic class and the timeline concept located at ./love-example.fnl 
To play with it, clone the repo and just run `love ./`

A REPL will open up over stdio. There is a global variable called `scene` you can play with. Try (scene:add-entity (foo))
