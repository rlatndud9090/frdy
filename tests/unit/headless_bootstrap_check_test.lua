local TestHelper = require("tests.test_helper")
local HeadlessBootstrapCheck = require("src.core.headless_bootstrap_check")

---@return string
local function get_root_dir()
  local source = debug.getinfo(1, "S").source
  local script_path = source:sub(1, 1) == "@" and source:sub(2) or source
  local root_dir = script_path:match("^(.*)[/\\]tests[/\\]unit[/\\]headless_bootstrap_check_test%.lua$")
  return root_dir or "."
end

local suite = {}

function suite.test_run_bootstrap_smoke_check_in_forced_ci_mode()
  local result = HeadlessBootstrapCheck.run(get_root_dir(), {force_ci = true})

  TestHelper.assert_equal(result.window_width, 1)
  TestHelper.assert_equal(result.window_height, 1)
  TestHelper.assert_true(result.borderless)
  TestHelper.assert_true(result.minimized)
  TestHelper.assert_true(result.has_scene)
end

return suite
