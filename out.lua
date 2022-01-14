local g = require("golly")

local player = g.class()

player:mixin(box2d, {["body-type"] = "dynamic", ["shape-type"] = "rectangle"})
player:field("hp", 100)
player:field("transform.scale", g.vec(2, 2))

player:method("render", {on = "draw"}, function(self)

end)

player:statemachine("main", "idle", {
  jump = {from = "idle", to = "jumping"},
  land = {to = "idle"}
})

player:method("jump-update", {state = {main = "jumping"}, on = "update"}, function(self, dt)
  self:transitionState("main", "jump")
end)

player:method("enter-jumping", {on = "state-main-enter-jump"}, function(self)
end)

function main(scene)
  scene:addEntity(player({ ["transform.position"] = vec(200, 200) }))
end

g.boot({scenes = {main = main}})
