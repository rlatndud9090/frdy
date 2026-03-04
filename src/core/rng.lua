local class = require('lib.middleclass')

local MODULUS = 2147483647
local MULTIPLIER = 48271
local MAX_SEED = MODULUS - 1

---@class RNGSnapshot
---@field seed number
---@field state number
---@field draw_count number

---@class RNG
---@field _seed number
---@field _state number
---@field _draw_count number
local RNG = class('RNG')

---@param raw_seed number|string|nil
---@return number
local function normalize_seed(raw_seed)
  local numeric = tonumber(raw_seed) or 1
  numeric = math.floor(math.abs(numeric))
  numeric = numeric % MAX_SEED
  if numeric == 0 then
    numeric = 1
  end
  return numeric
end

---@param raw_seed number|string|nil
---@return number
function RNG.static.normalize_seed(raw_seed)
  return normalize_seed(raw_seed)
end

---@param text string|nil
---@param base_seed number|string|nil
---@return number
function RNG.static.seed_from_string(text, base_seed)
  local seed = normalize_seed(base_seed or 1)
  local source = tostring(text or "")
  for i = 1, #source do
    seed = (seed * 131 + string.byte(source, i)) % MAX_SEED
    if seed == 0 then
      seed = 1
    end
  end
  return seed
end

---@param seed number|string|nil
---@return nil
function RNG:initialize(seed)
  self._seed = normalize_seed(seed)
  self._state = self._seed
  self._draw_count = 0
end

---@return number
function RNG:get_seed()
  return self._seed
end

---@return number
function RNG:get_state()
  return self._state
end

---@return number
function RNG:get_draw_count()
  return self._draw_count
end

---@return number
function RNG:_advance()
  self._state = (self._state * MULTIPLIER) % MODULUS
  self._draw_count = self._draw_count + 1
  return self._state
end

---@return number
function RNG:next_float()
  local state = self:_advance()
  return (state - 1) / MAX_SEED
end

---@param min_val number
---@param max_val number
---@return number
function RNG:next_int(min_val, max_val)
  local lo = math.floor(min_val or 0)
  local hi = math.floor(max_val or lo)
  if hi < lo then
    lo, hi = hi, lo
  end

  local span = (hi - lo) + 1
  if span <= 1 then
    self:_advance()
    return lo
  end

  local roll = self:next_float()
  local offset = math.floor(roll * span)
  if offset >= span then
    offset = span - 1
  end
  return lo + offset
end

---@param probability number|nil
---@return boolean
function RNG:chance(probability)
  local p = tonumber(probability) or 0
  if p < 0 then
    p = 0
  elseif p > 1 then
    p = 1
  end
  return self:next_float() < p
end

---@generic T
---@param list T[]
---@return T|nil
---@return number|nil
function RNG:pick(list)
  if type(list) ~= 'table' or #list == 0 then
    return nil, nil
  end
  local index = self:next_int(1, #list)
  return list[index], index
end

---@generic T
---@param list T[]
---@return T[]
function RNG:shuffle(list)
  local copied = {}
  for i = 1, #list do
    copied[i] = list[i]
  end

  for i = #copied, 2, -1 do
    local j = self:next_int(1, i)
    copied[i], copied[j] = copied[j], copied[i]
  end

  return copied
end

---@param stream_name string|nil
---@return RNG
function RNG:fork(stream_name)
  local stream_seed = RNG.seed_from_string(stream_name, self._seed + self._draw_count * 37)
  return RNG:new(stream_seed)
end

---@return RNGSnapshot
function RNG:snapshot()
  return {
    seed = self._seed,
    state = self._state,
    draw_count = self._draw_count,
  }
end

---@param snapshot RNGSnapshot|nil
---@return boolean
function RNG:restore(snapshot)
  if type(snapshot) ~= 'table' then
    return false
  end

  self._seed = normalize_seed(snapshot.seed or self._seed)
  self._state = normalize_seed(snapshot.state or self._seed)
  self._draw_count = math.max(0, math.floor(snapshot.draw_count or 0))
  return true
end

return RNG
