local class = require('lib.middleclass')

---@class RunStateParticipant
---@field key string
---@field snapshot fun(): any
---@field validate fun(snapshot: any): any, string|nil
---@field restore fun(snapshot: any): boolean|nil, string|nil
---@field required boolean|nil

---@class RunStateRegistry
---@field _entries RunStateParticipant[]
local RunStateRegistry = class('RunStateRegistry')

---@return nil
function RunStateRegistry:initialize()
  self._entries = {}
end

---@param participant RunStateParticipant
---@return nil
function RunStateRegistry:register(participant)
  self._entries[#self._entries + 1] = participant
end

---@return string[]
function RunStateRegistry:list_keys()
  local keys = {}
  for index, participant in ipairs(self._entries) do
    keys[index] = participant.key
  end
  return keys
end

---@return table|nil
---@return string|nil
function RunStateRegistry:snapshot_all()
  local snapshots = {}
  for _, participant in ipairs(self._entries) do
    local ok, result = pcall(participant.snapshot)
    if not ok then
      return nil, string.format("상태 저장 중 '%s' participant가 실패했습니다: %s", participant.key, tostring(result))
    end
    snapshots[participant.key] = result
  end
  return snapshots, nil
end

---@param raw_snapshots table|nil
---@return boolean
---@return string|nil
function RunStateRegistry:restore_all(raw_snapshots)
  if type(raw_snapshots) ~= "table" then
    return false, "저장된 participant 상태가 올바르지 않습니다."
  end

  for _, participant in ipairs(self._entries) do
    local snapshot = raw_snapshots[participant.key]
    if snapshot == nil and participant.required ~= false then
      return false, string.format("필수 participant '%s' 상태가 없습니다.", participant.key)
    end

    if snapshot ~= nil and participant.validate then
      local ok, validated, err = pcall(participant.validate, snapshot)
      if not ok then
        return false, string.format("participant '%s' 검증 중 오류가 발생했습니다: %s", participant.key, tostring(validated))
      end
      if validated == nil then
        return false, err or string.format("participant '%s' 상태 검증에 실패했습니다.", participant.key)
      end
      snapshot = validated
    end

    if snapshot ~= nil then
      local ok, restored, err = pcall(participant.restore, snapshot)
      if not ok then
        return false, string.format("participant '%s' 복원 중 오류가 발생했습니다: %s", participant.key, tostring(restored))
      end
      if restored == false then
        return false, err or string.format("participant '%s' 복원에 실패했습니다.", participant.key)
      end
    end
  end

  return true, nil
end

return RunStateRegistry
