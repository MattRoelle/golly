require("love.event")
local function prompt(cont_3f)
  local function _1_()
    if cont_3f then
      return ".."
    else
      return ">> "
    end
  end
  io.write(_1_())
  io.flush()
  return (io.read() .. "\n")
end
local function looper(event, channel)
  do
    local _2_ = channel:demand()
    if ((_G.type(_2_) == "table") and ((_2_)[1] == "write") and (nil ~= (_2_)[2])) then
      local vals = (_2_)[2]
      io.write(table.concat(vals, "\9"))
      io.write("\n")
    elseif ((_G.type(_2_) == "table") and ((_2_)[1] == "read") and (nil ~= (_2_)[2])) then
      local cont_3f = (_2_)[2]
      love.event.push(event, prompt(cont_3f))
    end
  end
  return looper(event, channel)
end
do
  local _4_, _5_ = ...
  if ((nil ~= _4_) and (nil ~= _5_)) then
    local event = _4_
    local channel = _5_
    looper(event, channel)
  end
end
local function start_repl()
  local code = love.filesystem.read("lib/stdio.fnl")
  local luac
  if code then
    luac = love.filesystem.newFileData(fennel.compileString(code), "io")
  else
    luac = love.filesystem.read("lib/stdio.lua")
  end
  local thread = love.thread.newThread(luac)
  local io_channel = love.thread.newChannel()
  local coro = coroutine.create(fennel.repl)
  local options
  local function _10_(_8_)
    local _arg_9_ = _8_
    local stack_size = _arg_9_["stack-size"]
    io_channel:push({"read", (0 < stack_size)})
    return coroutine.yield()
  end
  local function _11_(vals)
    return io_channel:push({"write", vals})
  end
  local function _12_(errtype, err)
    return io_channel:push({"write", {err}})
  end
  options = {readChunk = _10_, onValues = _11_, onError = _12_, moduleName = "lib.fennel"}
  coroutine.resume(coro, options)
  thread:start("eval", io_channel)
  local function _13_(input)
    return coroutine.resume(coro, input)
  end
  love.handlers.eval = _13_
  return nil
end
return {start = start_repl}
