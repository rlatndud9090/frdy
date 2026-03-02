local class = require('lib.middleclass')
local RNG = require('src.core.rng')

---@class RunContextSnapshot
---@field run_seed number
---@field streams table<string, RNGSnapshot>

---@class RunContext
---@field run_seed number
---@field _streams table<string, RNG>
local RunContext = class('RunContext')

---@param raw_seed number|string|nil
---@return number
function RunContext.static.normalize_seed(raw_seed)
  return RNG.normalize_seed(raw_seed)
end

---@param run_seed number|string|nil
---@return nil
function RunContext:initialize(run_seed)
  self.run_seed = RunContext.normalize_seed(run_seed)
  self._streams = {}
end

---@return number
function RunContext:get_run_seed()
  return self.run_seed
end

---@param stream_name string
---@return number
function RunContext:_derive_stream_seed(stream_name)
  return RNG.seed_from_string(stream_name, self.run_seed)
end

---@param stream_name string|nil
---@return RNG
function RunContext:get_stream(stream_name)
  local name = tostring(stream_name or 'default')
  local stream = self._streams[name]
  if stream then
    return stream
  end

  stream = RNG:new(self:_derive_stream_seed(name))
  self._streams[name] = stream
  return stream
end

---@param stream_name string
---@return boolean
function RunContext:has_stream(stream_name)
  return self._streams[stream_name] ~= nil
end

---@return RunContextSnapshot
function RunContext:snapshot()
  local streams = {}
  for name, rng in pairs(self._streams) do
    streams[name] = rng:snapshot()
  end
  return {
    run_seed = self.run_seed,
    streams = streams,
  }
end

---@param snapshot RunContextSnapshot|nil
---@return boolean
function RunContext:restore(snapshot)
  if type(snapshot) ~= 'table' then
    return false
  end

  self.run_seed = RunContext.normalize_seed(snapshot.run_seed or self.run_seed)
  local previous_streams = self._streams or {}
  local next_streams = {}

  local stream_snapshots = snapshot.streams
  if type(stream_snapshots) == 'table' then
    for name, stream_snapshot in pairs(stream_snapshots) do
      local stream = previous_streams[name] or RNG:new(self:_derive_stream_seed(name))
      stream:restore(stream_snapshot)
      next_streams[name] = stream
    end
  end

  for name, stream in pairs(previous_streams) do
    if not next_streams[name] then
      local seed = self:_derive_stream_seed(name)
      stream:restore({
        seed = seed,
        state = seed,
        draw_count = 0,
      })
      next_streams[name] = stream
    end
  end

  self._streams = next_streams
  return true
end

return RunContext
