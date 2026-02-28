local StatusRegistry = {}

---@class StatusDefinition
---@field id string
---@field domain string "character"|"field"
---@field stack_mode string "refresh"|"stack"|"independent"
---@field max_stacks number|nil
---@field default_duration_turns number|nil
---@field default_duration_actions number|nil
---@field default_payload table|nil
---@field title_key string|nil
---@field description_key string|nil
---@field preview_params fun(payload: table|nil, stacks: number|nil, spec: table|nil): table|nil
---@field hooks table<string, fun(instance: table, ctx: table)>

---@type table<string, StatusDefinition>
local definitions = {}

---@param def StatusDefinition
local function normalize_definition(def)
  if not def or not def.id then
    return
  end

  if not def.domain then
    def.domain = "character"
  end
  if not def.stack_mode then
    def.stack_mode = "refresh"
  end
  if not def.hooks then
    def.hooks = {}
  end
end

---@param list StatusDefinition[]
function StatusRegistry.register_many(list)
  for _, def in ipairs(list or {}) do
    normalize_definition(def)
    definitions[def.id] = def
  end
end

---@param def StatusDefinition
function StatusRegistry.register(def)
  normalize_definition(def)
  definitions[def.id] = def
end

---@param status_id string
---@return StatusDefinition|nil
function StatusRegistry.get(status_id)
  return definitions[status_id]
end

---@return table<string, StatusDefinition>
function StatusRegistry.get_all()
  return definitions
end

StatusRegistry.register_many(require("data.statuses.base_statuses"))

return StatusRegistry
