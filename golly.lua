package.preload["golly.math.aabb"] = package.preload["golly.math.aabb"] or function(...)
  local AABB = {}
  AABB.__index = AABB
  local function aabb(position, size)
    local r = setmetatable({position = position, size = size}, AABB)
    r["init!"](r)
    return r
  end
  AABB.__tostring = function(self)
    return ("AABB [(" .. self.position.x .. ", " .. self.position.y .. ")" .. " " .. "(" .. self.size.x .. ", " .. self.size.y .. ")]")
  end
  AABB["init!"] = function(self)
    return self["calculate-bounds!"](self)
  end
  AABB["calculate-bounds!"] = function(self)
    self.left = self.position.x
    self.top = self.position.y
    self.right = (self.position.x + self.size.x)
    self.bottom = (self.position.y + self.size.y)
    return nil
  end
  AABB["set-position!"] = function(self, position)
    self.position = position
    return self["calculate-bounds!"](self)
  end
  AABB["set-size!"] = function(self, size)
    self.size = size
    return self["calculate-bounds!"](self)
  end
  AABB["set-left!"] = function(self, left)
    do
      local width_delta = (self.left - left)
      self.position.x = left
      self.size.x = (self.size.x + width_delta)
    end
    return self["calculate-bounds!"](self)
  end
  AABB["set-right!"] = function(self, right)
    do
      local width_delta = (right - self.right)
      self.size.x = (self.size.x + width_delta)
    end
    return self["calculate-bounds!"](self)
  end
  AABB["set-top!"] = function(self, top)
    do
      local height_delta = (self.top - top)
      self.position.y = top
      self.size.y = (self.size.y + height_delta)
    end
    return self["calculate-bounds!"](self)
  end
  AABB["set-bottom!"] = function(self, bottom)
    do
      local height_delta = (bottom - self.bottom)
      self.size.y = (self.size.y + height_delta)
    end
    return self["calculate-bounds!"](self)
  end
  AABB["intersects?"] = function(self, other)
    return not ((self.right < other.left) or (other.right < self.left) or (self.bottom < other.top) or (other.bottom < self.top))
  end
  return {aabb = aabb}
end
package.preload["golly.math.vector"] = package.preload["golly.math.vector"] or function(...)
  local Vector2D = {}
  Vector2D.__index = Vector2D
  local Vector3D = {}
  local function _1_()
    return error("TODO: Implement Vector3D")
  end
  Vector3D.__index = _1_
  local Vector4D = {}
  local function _2_()
    return error("TODO: Implement Vector4D")
  end
  Vector4D.__index = _2_
  local function vec(x, y, z_3f, w_3f)
    assert(x, "Must pass at least x and y")
    assert(y, "Must pass at least x and y")
    local function _3_()
      if w_3f then
        return Vector4D
      elseif z_3f then
        return Vector3D
      else
        return Vector2D
      end
    end
    return setmetatable({x = x, y = y, z = z_3f, w = w_3f}, _3_())
  end
  local function polar_vec2(theta, magnitude)
    return vec((math.cos(theta) * magnitude), (math.sin(theta) * magnitude))
  end
  Vector2D.__unm = function(v)
    return vec(( - v.x), ( - v.y))
  end
  Vector2D.__add = function(a, b)
    return vec((a.x + b.x), (a.y + b.y))
  end
  Vector2D.__sub = function(a, b)
    return vec((a.x - b.x), (a.y - b.y))
  end
  Vector2D.__mul = function(a, b)
    if (type(a) == "number") then
      return vec((a * b.x), (a * b.y))
    elseif (type(b) == "number") then
      return vec((a.x * b), (a.y * b))
    else
      return vec((a.x * b.x), (a.y * b.y))
    end
  end
  Vector2D.__div = function(a, b)
    return vec((a.x / b), (a.y / b))
  end
  Vector2D.__eq = function(a, b)
    return ((a.x == b.x) and (a.y == b.y))
  end
  Vector2D.__tostring = function(self)
    return ("(" .. self.x .. ", " .. self.y .. ")")
  end
  Vector2D.clamp = function(self, min, max)
    return vec(math.min(math.max(self.x, min.x), max.x), math.min(math.max(self.y, min.y), max.y))
  end
  Vector2D["clamp!"] = function(self, min, max)
    self.x, self.y = math.min(math.max(self.x, min.x), max.x), math.min(math.max(self.y, min.y), max.y)
    return nil
  end
  Vector2D["distance-to"] = function(a, b)
    return math.sqrt((((a.x - b.x) ^ 2) + ((a.y - b.y) ^ 2)))
  end
  Vector2D["angle-from"] = function(a, b)
    return math.atan2((a.y - b.y), (a.x - b.x))
  end
  Vector2D["angle-to"] = function(a, b)
    return math.atan2((b.y - a.y), (b.x - a.x))
  end
  Vector2D.angle = function(self)
    return math.atan2(self.y, self.x)
  end
  Vector2D["set-angle"] = function(self, angle)
    local len = self:length()
    return vec((math.cos(angle) * len), (math.sin(angle) * len))
  end
  Vector2D["set-angle!"] = function(self, angle)
    local len = self:length()
    self.x, self.y = (math.cos(angle) * len), (math.sin(angle) * len)
    return nil
  end
  Vector2D.rotate = function(self, theta)
    local s = math.sin(theta)
    local c = math.cos(theta)
    return vec(((c * self.x) + (s * self.y)), (( - (s * self.x)) + (c * self.y)))
  end
  Vector2D["rotate!"] = function(self, theta)
    local s = math.sin(theta)
    local c = math.cos(theta)
    return vec(((c * self.x) + (s * self.y)), (( - (s * self.x)) + (c * self.y)))
  end
  Vector2D.unpack = function(self)
    return self.x, self.y
  end
  Vector2D.clone = function(self)
    return vec(self.x, self.y)
  end
  Vector2D.length = function(self)
    return math.sqrt(((self.x ^ 2) + (self.y ^ 2)))
  end
  Vector2D["set-length"] = function(self, len)
    local theta = self:angle()
    return vec((math.cos(theta) * len), (math.sin(theta) * len))
  end
  Vector2D["set-length!"] = function(self, len)
    local theta = self:angle()
    self.x, self.y = (math.cos(theta) * len), (math.sin(theta) * len)
    return nil
  end
  Vector2D.lengthsq = function(self)
    return ((self.x ^ 2) + (self.y ^ 2))
  end
  Vector2D.normalize = function(self)
    local mag = self:length()
    if (mag == 0) then
      return self
    else
      return vec((self.x / mag), (self.y / mag))
    end
  end
  Vector2D["normalize!"] = function(self)
    local mag = self:length()
    if (mag == 0) then
      self.x, self.y = (self.x / mag), (self.y / mag)
      return nil
    else
      return nil
    end
  end
  Vector2D.dot = function(self, v)
    return ((self.x * v.x) + (self.y * v.y))
  end
  Vector2D.limit = function(self, max)
    local magsq = self:lengthsq()
    local theta = self:angle()
    if (magsq > (max ^ 2)) then
      return polar_vec2(theta, max)
    else
      return self
    end
  end
  Vector2D["limit!"] = function(self, max)
    local magsq = self:lengthsq()
    local theta = self:angle()
    if (magsq > (max ^ 2)) then
      self.x, self.y = (math.cos(theta) * max), (math.sin(theta) * max)
      return nil
    else
      return self
    end
  end
  Vector2D.lerp = function(a, b, t)
    return vec(((a.x * (1 - t)) + (b.x * t)), ((a.y * (1 - t)) + (b.y * t)))
  end
  Vector2D["lerp!"] = function(a, b, t)
    a.x, a.y = ((a.x * (1 - t)) + (b.x * t)), ((a.y * (1 - t)) + (b.y * t))
    return nil
  end
  Vector2D.midpoint = function(a, b)
    return ((a + b) / 2)
  end
  return {vec = vec, line = line, ["polar-vec2"] = polar_vec2}
end
package.preload["golly.math"] = package.preload["golly.math"] or function(...)
  local vector = require("golly.math.vector")
  local aabb = require("golly.math.aabb")
  return {vector = require("golly.math.vector"), aabb = require("golly.math.aabb")}
end
return {math = require("golly.math")}
