---@class TestHelper
local TestHelper = {}

---@param value any
---@return string
local function to_s(value)
  if type(value) == "table" then
    local parts = {}
    for k, v in pairs(value) do
      parts[#parts + 1] = tostring(k) .. "=" .. tostring(v)
    end
    table.sort(parts)
    return "{" .. table.concat(parts, ", ") .. "}"
  end
  return tostring(value)
end

---@param condition boolean
---@param message string|nil
---@return nil
function TestHelper.assert_true(condition, message)
  if not condition then
    error(message or "조건이 true여야 합니다.", 2)
  end
end

---@param condition boolean
---@param message string|nil
---@return nil
function TestHelper.assert_false(condition, message)
  if condition then
    error(message or "조건이 false여야 합니다.", 2)
  end
end

---@param actual any
---@param expected any
---@param message string|nil
---@return nil
function TestHelper.assert_equal(actual, expected, message)
  if actual ~= expected then
    local prefix = message and (message .. " - ") or ""
    error(prefix .. "expected=" .. to_s(expected) .. ", actual=" .. to_s(actual), 2)
  end
end

---@param actual number
---@param expected number
---@param epsilon number|nil
---@param message string|nil
---@return nil
function TestHelper.assert_near(actual, expected, epsilon, message)
  local eps = epsilon or 1e-6
  if math.abs(actual - expected) > eps then
    local prefix = message and (message .. " - ") or ""
    error(prefix .. string.format("expected %.6f, actual %.6f (eps=%.6f)", expected, actual, eps), 2)
  end
end

return TestHelper
