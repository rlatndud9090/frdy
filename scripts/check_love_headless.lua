---@class HeadlessCheckScript
local HeadlessCheckScript = {}

---@return string
local function get_root_dir()
  local source = debug.getinfo(1, "S").source
  local script_path = source:sub(1, 1) == "@" and source:sub(2) or source
  local root_dir = script_path:match("^(.*)[/\\]scripts[/\\]check_love_headless%.lua$")
  return root_dir or "."
end

---@param root_dir string
---@return nil
local function extend_package_path(root_dir)
  local path_entries = {
    root_dir .. "/?.lua",
    root_dir .. "/?/init.lua",
  }
  package.path = table.concat(path_entries, ";") .. ";" .. package.path
end

---@return nil
function HeadlessCheckScript.run()
  local root_dir = get_root_dir()
  extend_package_path(root_dir)

  local HeadlessBootstrapCheck = require("src.core.headless_bootstrap_check")
  HeadlessBootstrapCheck.run(root_dir, {force_ci = true})
end

local ok, err = xpcall(HeadlessCheckScript.run, debug.traceback)
if not ok then
  io.stderr:write(tostring(err), "\n")
  os.exit(1)
end
