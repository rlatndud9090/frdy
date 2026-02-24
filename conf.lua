local function is_ci_check_mode()
  local env = os.getenv("FRDY_CI_CHECK")
  return env == "1" or env == "true" or env == "TRUE"
end

function love.conf(t)
  t.title = "Demon Lord's Secret Assistance"
  t.window.width = 1280
  t.window.height = 720
  t.window.vsync = 1
  t.console = true

  -- CI 검증 시에는 창 방해를 줄이기 위해 1x1 borderless + off-screen 배치.
  if is_ci_check_mode() then
    t.window.width = 1
    t.window.height = 1
    t.window.borderless = true
    t.window.resizable = false
    t.window.vsync = 0
    t.window.x = -32000
    t.window.y = -32000
  end
end
