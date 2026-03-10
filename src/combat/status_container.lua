local class = require("lib.middleclass")
local StatusRegistry = require("src.combat.status_registry")

---@class StatusInstance
---@field uid string
---@field status_id string
---@field definition StatusDefinition
---@field owner any
---@field source any
---@field stacks number
---@field remaining_turns number|nil
---@field remaining_actions number|nil
---@field payload table

---@class StatusContainer
---@field owner any
---@field domain string
---@field statuses StatusInstance[]
---@field _status_by_uid table<string, StatusInstance>
---@field _next_uid number
local StatusContainer = class("StatusContainer")

---@param value any
---@return any
local function deep_copy(value)
  if type(value) ~= "table" then
    return value
  end
  local copied = {}
  for k, v in pairs(value) do
    copied[k] = deep_copy(v)
  end
  return copied
end

---@param owner any
---@param domain string
function StatusContainer:initialize(owner, domain)
  self.owner = owner
  self.domain = domain or "character"
  self.statuses = {}
  self._status_by_uid = {}
  self._next_uid = 1
end

---@return string
function StatusContainer:_allocate_uid()
  local uid = self.domain .. ":" .. tostring(self._next_uid)
  self._next_uid = self._next_uid + 1
  return uid
end

---@param status_id string
---@return StatusInstance|nil
function StatusContainer:_find_by_status_id(status_id)
  for _, instance in ipairs(self.statuses) do
    if instance.status_id == status_id then
      return instance
    end
  end
  return nil
end

---@param instance StatusInstance
---@param spec table|nil
---@return nil
function StatusContainer:_refresh_instance(instance, spec)
  spec = spec or {}
  local def = instance.definition
  local turns = spec.duration_turns
  if turns == nil then
    turns = def.default_duration_turns
  end
  local actions = spec.duration_actions
  if actions == nil then
    actions = def.default_duration_actions
  end

  if turns ~= nil then
    if instance.remaining_turns == nil then
      instance.remaining_turns = turns
    else
      instance.remaining_turns = math.max(instance.remaining_turns, turns)
    end
  end
  if actions ~= nil then
    if instance.remaining_actions == nil then
      instance.remaining_actions = actions
    else
      instance.remaining_actions = math.max(instance.remaining_actions, actions)
    end
  end

  if spec.payload ~= nil then
    instance.payload = deep_copy(spec.payload)
  end
  if spec.source ~= nil then
    instance.source = spec.source
  end
end

---@param def StatusDefinition
---@param spec table|nil
---@return StatusInstance
function StatusContainer:_build_instance(def, spec)
  spec = spec or {}
  local stacks = math.max(1, math.floor(spec.stacks or 1))
  local max_stacks = def.max_stacks or stacks
  stacks = math.min(stacks, max_stacks)

  local turns = spec.duration_turns
  if turns == nil then
    turns = def.default_duration_turns
  end
  local actions = spec.duration_actions
  if actions == nil then
    actions = def.default_duration_actions
  end

  return {
    uid = self:_allocate_uid(),
    status_id = def.id,
    definition = def,
    owner = self.owner,
    source = spec.source,
    stacks = stacks,
    remaining_turns = turns,
    remaining_actions = actions,
    payload = deep_copy(spec.payload or def.default_payload or {}),
  }
end

---@param instance StatusInstance
---@return nil
function StatusContainer:_call_hook(instance, hook_name, ctx)
  local def = instance.definition
  if not def or not def.hooks then
    return
  end
  local fn = def.hooks[hook_name]
  if type(fn) == "function" then
    fn(instance, ctx or {})
  end
end

---@param instance StatusInstance
---@return nil
function StatusContainer:_remove_instance(instance)
  for i = #self.statuses, 1, -1 do
    if self.statuses[i] == instance then
      local uid_key = instance.uid
      self:_call_hook(instance, "on_remove", {owner = self.owner})
      table.remove(self.statuses, i)
      self._status_by_uid[uid_key] = nil
      return
    end
  end
end

---@param status_id string
---@param spec? table
---@return StatusInstance|nil
function StatusContainer:add(status_id, spec)
  local def = StatusRegistry.get(status_id)
  if not def or def.domain ~= self.domain then
    return nil
  end

  spec = spec or {}
  local mode = def.stack_mode or "refresh"
  local max_stacks = def.max_stacks or math.huge
  local add_stacks = math.max(1, math.floor(spec.stacks or 1))

  if mode ~= "independent" then
    local existing = self:_find_by_status_id(status_id)
    if existing then
      if mode == "stack" then
        existing.stacks = math.min(max_stacks, existing.stacks + add_stacks)
      elseif mode == "refresh" then
        existing.stacks = math.min(max_stacks, math.max(existing.stacks, add_stacks))
      end
      self:_refresh_instance(existing, spec)
      self:_call_hook(existing, "on_refresh", {owner = self.owner})
      return existing
    end
  end

  local instance = self:_build_instance(def, spec)
  self.statuses[#self.statuses + 1] = instance
  self._status_by_uid[instance.uid] = instance
  self:_call_hook(instance, "on_apply", {owner = self.owner})
  return instance
end

---@param uid string
---@return boolean
function StatusContainer:remove(uid)
  local instance = self._status_by_uid[uid]
  if instance then
    self:_remove_instance(instance)
    return true
  end
  return false
end

---@param status_id string
---@return boolean
function StatusContainer:has(status_id)
  return self:_find_by_status_id(status_id) ~= nil
end

---@param hook_name string
---@param ctx table|nil
---@return nil
function StatusContainer:emit(hook_name, ctx)
  local snapshot = {}
  for i = 1, #self.statuses do
    snapshot[i] = self.statuses[i]
  end

  for _, instance in ipairs(snapshot) do
    -- emit 중 제거될 수 있으므로 uid 인덱스로 O(1) 생존 확인
    if self._status_by_uid[instance.uid] == instance then
      self:_call_hook(instance, hook_name, ctx)
    end
  end
end

---@return nil
function StatusContainer:consume_turn()
  for i = #self.statuses, 1, -1 do
    local instance = self.statuses[i]
    if instance.remaining_turns ~= nil then
      instance.remaining_turns = instance.remaining_turns - 1
      if instance.remaining_turns <= 0 then
        self:_remove_instance(instance)
      end
    end
  end
end

---@return nil
function StatusContainer:consume_action()
  for i = #self.statuses, 1, -1 do
    local instance = self.statuses[i]
    if instance.remaining_actions ~= nil then
      instance.remaining_actions = instance.remaining_actions - 1
      if instance.remaining_actions <= 0 then
        self:_remove_instance(instance)
      end
    end
  end
end

---@return table
function StatusContainer:snapshot()
  local list = {}
  for i, instance in ipairs(self.statuses) do
    list[i] = {
      uid = instance.uid,
      status_id = instance.status_id,
      stacks = instance.stacks,
      remaining_turns = instance.remaining_turns,
      remaining_actions = instance.remaining_actions,
      payload = deep_copy(instance.payload),
      source = instance.source,
    }
  end
  return {
    next_uid = self._next_uid,
    statuses = list,
  }
end

---@param snap table|nil
---@return nil
function StatusContainer:restore(snap)
  self.statuses = {}
  self._status_by_uid = {}
  self._next_uid = 1
  if not snap then
    return
  end

  self._next_uid = snap.next_uid or 1
  for _, item in ipairs(snap.statuses or {}) do
    local def = StatusRegistry.get(item.status_id)
    if def and def.domain == self.domain then
      local restored = {
        uid = item.uid or self:_allocate_uid(),
        status_id = item.status_id,
        definition = def,
        owner = self.owner,
        source = item.source,
        stacks = item.stacks or 1,
        remaining_turns = item.remaining_turns,
        remaining_actions = item.remaining_actions,
        payload = deep_copy(item.payload or {}),
      }
      self.statuses[#self.statuses + 1] = restored
      self._status_by_uid[restored.uid] = restored
    end
  end
end

---@return StatusInstance[]
function StatusContainer:get_all()
  return self.statuses
end

return StatusContainer
