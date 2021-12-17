# GOLLY

### Game Oriented Lua Lisp.

Golly is a game library made in the Fennel programming language that runs on top of Love2D. Primarily it includes an opinionated object system with custom `class` and `mixin` macros for defining game entities.

This code is extremely experimental and undocumented, the API is changing daily. Working on an indie game project in parallel and building the parts of this engine when the game project necessitates them. If you're brave and want to play with the code please reach out to me for help. 

## Examples

For right now, the repo is just a love project. The main entry point to the example is [example-asteroids/init.fnl](example-asteroids/init.fnl). Run using `love ./`.

The example game is a basic asteroids implementation, but it shows off all the main major features of Golly.

![Example Screenshot](./example.png)
