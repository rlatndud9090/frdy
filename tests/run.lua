---@class TestCaseResult
---@field file string
---@field name string
---@field ok boolean
---@field err string|nil

---@return string
local function get_root_dir()
  local source = debug.getinfo(1, "S").source
  local script_path = source:sub(1, 1) == "@" and source:sub(2) or source
  local tests_dir = script_path:match("^(.*)[/\\]tests[/\\]run%.lua$")
  return tests_dir or "."
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

---@param root_dir string
---@return string[]
local function discover_test_files(root_dir)
  local tests_dir = root_dir .. "/tests"
  local command = string.format("find %q -type f -name '*_test.lua' | sort", tests_dir)
  local handle = io.popen(command)
  if not handle then
    error("테스트 파일 탐색에 실패했습니다: " .. command)
  end

  local files = {}
  for line in handle:lines() do
    if line ~= "" then
      files[#files + 1] = line
    end
  end
  handle:close()
  return files
end

---@param suite table
---@return string[]
local function list_test_names(suite)
  local names = {}
  for name, fn in pairs(suite) do
    if type(fn) == "function" and name:match("^test_") then
      names[#names + 1] = name
    end
  end
  table.sort(names)
  return names
end

---@param file string
---@param suite table
---@return TestCaseResult[]
local function run_suite(file, suite)
  local results = {}
  local test_names = list_test_names(suite)
  local before_each = type(suite.before_each) == "function" and suite.before_each or nil
  local after_each = type(suite.after_each) == "function" and suite.after_each or nil

  if #test_names == 0 then
    results[#results + 1] = {
      file = file,
      name = "<suite>",
      ok = false,
      err = "테스트 함수(test_*)가 없습니다.",
    }
    return results
  end

  for _, name in ipairs(test_names) do
    if before_each then
      local ok_before, err_before = xpcall(before_each, debug.traceback)
      if not ok_before then
        results[#results + 1] = {
          file = file,
          name = name,
          ok = false,
          err = "before_each 실패: " .. tostring(err_before),
        }
        goto continue
      end
    end

    local ok, err = xpcall(suite[name], debug.traceback)
    results[#results + 1] = {
      file = file,
      name = name,
      ok = ok,
      err = ok and nil or tostring(err),
    }

    if after_each then
      local ok_after, err_after = xpcall(after_each, debug.traceback)
      if not ok_after then
        results[#results + 1] = {
          file = file,
          name = name .. " (after_each)",
          ok = false,
          err = tostring(err_after),
        }
      end
    end

    ::continue::
  end

  return results
end

---@param file string
---@return TestCaseResult[]
local function run_test_file(file)
  local chunk, load_err = loadfile(file)
  if not chunk then
    return {
      {
        file = file,
        name = "<load>",
        ok = false,
        err = tostring(load_err),
      }
    }
  end

  local ok_suite, suite_or_err = xpcall(chunk, debug.traceback)
  if not ok_suite then
    return {
      {
        file = file,
        name = "<suite>",
        ok = false,
        err = tostring(suite_or_err),
      }
    }
  end

  if type(suite_or_err) ~= "table" then
    return {
      {
        file = file,
        name = "<suite>",
        ok = false,
        err = "테스트 파일은 test_* 함수를 가진 table을 반환해야 합니다.",
      }
    }
  end

  return run_suite(file, suite_or_err)
end

---@param results TestCaseResult[]
---@return nil
local function print_results(results)
  local passed = 0
  local failed = 0

  for _, result in ipairs(results) do
    if result.ok then
      passed = passed + 1
      print(string.format("[PASS] %s :: %s", result.file, result.name))
    else
      failed = failed + 1
      print(string.format("[FAIL] %s :: %s", result.file, result.name))
      print("       " .. (result.err or "unknown error"))
    end
  end

  print(string.format("\nTest Summary: %d passed, %d failed, %d total", passed, failed, passed + failed))
  if failed > 0 then
    os.exit(1)
  end
end

local root_dir = get_root_dir()
extend_package_path(root_dir)

local files = discover_test_files(root_dir)
if #files == 0 then
  print("테스트 파일을 찾지 못했습니다.")
  os.exit(1)
end

local all_results = {}
for _, file in ipairs(files) do
  local file_results = run_test_file(file)
  for _, result in ipairs(file_results) do
    all_results[#all_results + 1] = result
  end
end

print_results(all_results)
