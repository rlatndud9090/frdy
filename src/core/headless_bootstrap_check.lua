---@class HeadlessBootstrapCheckOptions
---@field force_ci boolean|nil

---@class HeadlessBootstrapCheckResult
---@field window_width number
---@field window_height number
---@field borderless boolean
---@field minimized boolean
---@field has_scene boolean

---@class LoveFontStub
---@field size number
---@field getWidth fun(self: LoveFontStub, text: string): number
---@field getHeight fun(self: LoveFontStub): number

---@class HeadlessBootstrapCheck
local HeadlessBootstrapCheck = {}

local DEFAULT_SCREEN_WIDTH = 1280
local DEFAULT_SCREEN_HEIGHT = 720

---@param size number
---@return LoveFontStub
local function new_font_stub(size)
  local font = {size = size}

  ---@param self LoveFontStub
  ---@param text string
  ---@return number
  function font:getWidth(text)
    local content = tostring(text or "")
    return #content * math.max(1, math.floor((self.size or 16) * 0.5))
  end

  ---@param self LoveFontStub
  ---@return number
  function font:getHeight()
    return self.size or 16
  end

  return font
end

---@return table
---@return fun(): boolean
local function install_love_stub()
  local current_font = new_font_stub(16)
  local minimized = false

  local graphics = {
    newFont = function(_, size)
      return new_font_stub(size or 16)
    end,
    setFont = function(font)
      current_font = font or current_font
    end,
    getFont = function()
      return current_font
    end,
    getWidth = function()
      return DEFAULT_SCREEN_WIDTH
    end,
    getHeight = function()
      return DEFAULT_SCREEN_HEIGHT
    end,
    clear = function(...) end,
    setColor = function(...) end,
    rectangle = function(...) end,
    circle = function(...) end,
    line = function(...) end,
    polygon = function(...) end,
    print = function(...) end,
    printf = function(...) end,
    setLineWidth = function(...) end,
    push = function(...) end,
    pop = function(...) end,
    origin = function(...) end,
    translate = function(...) end,
    setScissor = function(...) end,
  }

  local love_stub = {
    graphics = graphics,
    mouse = {
      getPosition = function()
        return 0, 0
      end,
      isDown = function()
        return false
      end,
    },
    window = {
      minimize = function()
        minimized = true
      end,
    },
  }

  return love_stub, function()
    return minimized
  end
end

---@param root_dir string
---@return string
local function extend_package_path(root_dir)
  local original_path = package.path
  local path_entries = {
    root_dir .. "/?.lua",
    root_dir .. "/?/init.lua",
  }
  package.path = table.concat(path_entries, ";") .. ";" .. package.path
  return original_path
end

---@param config table
---@return nil
local function assert_ci_window_config(config)
  assert(config.window.width == 1, "CI 검증 창 너비가 1이 아닙니다.")
  assert(config.window.height == 1, "CI 검증 창 높이가 1이 아닙니다.")
  assert(config.window.borderless == true, "CI 검증 창이 borderless가 아닙니다.")
  assert(config.window.vsync == 0, "CI 검증 vsync가 0이 아닙니다.")
  assert(config.window.x == -32000, "CI 검증 창 x 오프셋이 예상과 다릅니다.")
  assert(config.window.y == -32000, "CI 검증 창 y 오프셋이 예상과 다릅니다.")
end

---@param root_dir string
---@return HeadlessBootstrapCheckResult
local function run_inner(root_dir)
  local was_minimized
  local config = {window = {}}

  _G.love, was_minimized = install_love_stub()
  dofile(root_dir .. "/conf.lua")
  assert(type(love.conf) == "function", "love.conf가 정의되지 않았습니다.")
  love.conf(config)
  assert_ci_window_config(config)

  dofile(root_dir .. "/main.lua")
  assert(type(love.load) == "function", "love.load가 정의되지 않았습니다.")

  love.load()
  if type(love.update) == "function" then
    love.update(0)
  end
  if type(love.draw) == "function" then
    love.draw()
  end

  local Game = require("src.core.game")
  local scene_manager = Game:getInstance().scene_manager
  local has_scene = scene_manager ~= nil and scene_manager:peek() ~= nil
  assert(has_scene, "초기 scene이 생성되지 않았습니다.")

  return {
    window_width = config.window.width or 0,
    window_height = config.window.height or 0,
    borderless = config.window.borderless == true,
    minimized = was_minimized(),
    has_scene = has_scene,
  }
end

---Run a headless bootstrap smoke check for CI environments without a display.
---@param root_dir string
---@param options? HeadlessBootstrapCheckOptions
---@return HeadlessBootstrapCheckResult
function HeadlessBootstrapCheck.run(root_dir, options)
  assert(type(root_dir) == "string" and root_dir ~= "", "root_dir가 필요합니다.")

  local previous_love = _G.love
  local previous_getenv = os.getenv
  local original_path = extend_package_path(root_dir)
  local opts = options or {}

  if opts.force_ci then
    os.getenv = function(name)
      if name == "FRDY_CI_CHECK" then
        return "1"
      end
      return previous_getenv(name)
    end
  end

  local ok, result_or_err = xpcall(function()
    return run_inner(root_dir)
  end, debug.traceback)

  package.path = original_path
  os.getenv = previous_getenv
  _G.love = previous_love

  if not ok then
    error(result_or_err, 0)
  end

  return result_or_err
end

return HeadlessBootstrapCheck
