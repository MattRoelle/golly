-- main.lua
fennel = require("lib.fennel")
table.insert(package.loaders, fennel.make_searcher({useMetadata=true, correlate=true}))

pp = function(x) print(fennel.view(x)) end
lume = require("lib.lume")
unpack = table.unpack or _G.unpack
inspect = require("lib.inspect")

dt = 1
scene = {}
_classes = {}

local make_love_searcher = function(env)
   return function(module_name)
      local path = module_name:gsub("%.", "/") .. ".fnl"
      if love.filesystem.getInfo(path) then
         return function(...)
            local code = love.filesystem.read(path)
            return fennel.eval(code, {env=env}, ...)
         end, path
      end
   end
end

table.insert(package.loaders, make_love_searcher(_G))
table.insert(fennel["macro-searchers"], make_love_searcher("_COMPILER"))

require("golly.wrap")
require("example-asteroids")

