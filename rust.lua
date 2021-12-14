local ffi = require 'ffi'

ffi.cdef[[
void hello();
]]

-- Windows
if love.system.getOS() == 'Windows' then
  return ffi.load('./target/debug/loverust.dll')
end
-- POSIX
return ffi.load('./target/debug/libloverust.so');
