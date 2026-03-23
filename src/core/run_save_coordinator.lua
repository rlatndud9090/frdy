local class = require('lib.middleclass')
local RunSave = require('src.core.run_save')
local RunSaveValidators = require('src.core.run_save_validators')

---@class RunSaveCoordinatorConfig
---@field registry RunStateRegistry
---@field get_run_seed fun(): number
---@field save_store? RunSave
---@field payload_validator? table
---@field expected_system_keys? string[]

---@class RunSaveCoordinator
---@field registry RunStateRegistry
---@field get_run_seed fun(): number
---@field save_store RunSave
---@field payload_validator table
---@field expected_system_keys string[]|nil
local RunSaveCoordinator = class('RunSaveCoordinator')

---@param config RunSaveCoordinatorConfig
---@return nil
function RunSaveCoordinator:initialize(config)
  self.registry = config.registry
  self.get_run_seed = config.get_run_seed
  self.save_store = config.save_store or RunSave
  self.payload_validator = config.payload_validator or RunSaveValidators
  self.expected_system_keys = config.expected_system_keys
end

---@return boolean
---@return string|nil
function RunSaveCoordinator:_assert_registry_manifest()
  if not self.expected_system_keys then
    return true, nil
  end

  local actual = self.registry:list_keys()
  if #actual ~= #self.expected_system_keys then
    return false, '저장 participant 목록이 예상과 다릅니다.'
  end

  for index, key in ipairs(self.expected_system_keys) do
    if actual[index] ~= key then
      return false, '저장 participant 목록이 예상과 다릅니다.'
    end
  end

  return true, nil
end

---@param checkpoint_kind string
---@return table|nil
---@return string|nil
function RunSaveCoordinator:build_payload(checkpoint_kind)
  local manifest_ok, manifest_err = self:_assert_registry_manifest()
  if not manifest_ok then
    return nil, manifest_err
  end

  local systems, err = self.registry:snapshot_all()
  if not systems then
    return nil, err
  end

  return {
    version = 2,
    run_seed = self.get_run_seed(),
    checkpoint = {
      kind = checkpoint_kind,
    },
    systems = systems,
  }, nil
end

---@param checkpoint_kind string
---@return boolean
---@return string|nil
function RunSaveCoordinator:save_checkpoint(checkpoint_kind)
  local payload, payload_err = self:build_payload(checkpoint_kind)
  if not payload then
    return false, payload_err
  end

  return self.save_store:write(payload)
end

---@param save_data table
---@return table|nil
---@return string|nil
function RunSaveCoordinator:restore_payload(save_data)
  local normalized, normalize_err = self.payload_validator.save_payload(save_data)
  if not normalized then
    return nil, normalize_err
  end

  local restored, restore_err = self.registry:restore_all(normalized.systems)
  if not restored then
    return nil, restore_err
  end

  return normalized, nil
end

---@return boolean
---@return string|nil
function RunSaveCoordinator:clear_active_run()
  return self.save_store:clear()
end

---@param reason? string
---@return boolean
---@return string|nil
function RunSaveCoordinator:invalidate_active_run(reason)
  if type(self.save_store.invalidate) ~= 'function' then
    return false, '세이브 저장소가 무효화 마커를 지원하지 않습니다.'
  end

  return self.save_store:invalidate(reason)
end

return RunSaveCoordinator
