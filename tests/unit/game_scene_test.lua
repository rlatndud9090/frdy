local TestHelper = require('tests.test_helper')
local flux = require('lib.flux')
local EventBus = require('src.core.event_bus')
local GameScene = require('src.scene.game_scene')

local suite = {}

---@return table
local function create_fake_scene()
  local scene = {
    phase = "COMBAT",
    hero_world_x = 120,
    current_node = {id = "node-1"},
    combat_handler = {
      enemy_world_x = 0,
      ui_offset_y = 0,
    },
    mana_manager = {},
    reward_manager = {},
    overlay_alpha = 0.3,
    _settlement_called = 0,
    _checkpoint_called = 0,
    _clear_active_run_called = 0,
  }

  function scene.combat_handler:deactivate()
    scene._combat_deactivated = true
  end

  function scene.mana_manager:recover_after_combat(amount)
    scene._mana_recovered = amount
  end

  function scene.reward_manager:prepare_combat_settlement(result, node)
    scene._prepared_result = result
    scene._prepared_node = node
  end

  function scene:_enter_settlement_or_continue()
    self._settlement_called = self._settlement_called + 1
  end

  function scene:_checkpoint_post_resolution()
    self._checkpoint_called = self._checkpoint_called + 1
  end

  function scene:_clear_active_run()
    self._clear_active_run_called = self._clear_active_run_called + 1
    return true
  end

  return setmetatable(scene, {__index = GameScene})
end

function suite.before_each()
  suite._original_flux_to = flux.to
  flux.to = function()
    local tween = {}

    function tween:ease()
      return self
    end

    function tween:oncomplete(callback)
      if callback then
        callback()
      end
      return self
    end

    return tween
  end
end

function suite.after_each()
  flux.to = suite._original_flux_to
end

---@return nil
function suite.test_on_combat_ended_defeat_enters_game_over_state()
  local scene = create_fake_scene()

  scene:_on_combat_ended("defeat")

  TestHelper.assert_true(scene._combat_deactivated == true, "전투 핸들러 비활성화가 필요합니다.")
  TestHelper.assert_equal(scene._mana_recovered, 30, "전투 종료 마나 회복량이 유지되어야 합니다.")
  TestHelper.assert_equal(scene._clear_active_run_called, 1, "패배 시 세이브 정리가 호출되어야 합니다.")
  TestHelper.assert_equal(scene.phase, "GAME_OVER", "패배 후 GAME_OVER 상태로 전환되어야 합니다.")
  TestHelper.assert_equal(scene._settlement_called, 0, "패배 시 정산/다음 이동으로 진행되면 안 됩니다.")
end

---@return nil
function suite.test_on_combat_ended_victory_keeps_settlement_flow()
  local scene = create_fake_scene()

  scene:_on_combat_ended("victory")

  TestHelper.assert_true(scene._combat_deactivated == true, "전투 핸들러 비활성화가 필요합니다.")
  TestHelper.assert_equal(scene._mana_recovered, 30, "전투 종료 마나 회복량이 유지되어야 합니다.")
  TestHelper.assert_equal(scene._checkpoint_called, 1, "승리 시 체크포인트 후처리가 호출되어야 합니다.")
  TestHelper.assert_equal(scene._prepared_result, "victory", "승리 정산 준비가 호출되어야 합니다.")
  TestHelper.assert_equal(scene._prepared_node, scene.current_node, "정산 준비에 현재 노드가 전달되어야 합니다.")
  TestHelper.assert_equal(scene._settlement_called, 1, "승리 시 정산/다음 이동 흐름으로 진행되어야 합니다.")
end

---@return nil
function suite.test_on_suspicion_max_enters_game_over_state()
  local scene = create_fake_scene()
  scene.phase = "EVENT"

  scene:_on_suspicion_max({level = 100})

  TestHelper.assert_true(scene._combat_deactivated == true, "의심 최대치 도달 시 전투 핸들러를 비활성화해야 합니다.")
  TestHelper.assert_equal(scene._clear_active_run_called, 1, "의심 최대치 도달 시 세이브 정리가 호출되어야 합니다.")
  TestHelper.assert_equal(scene.phase, "GAME_OVER", "의심 최대치 도달 시 GAME_OVER 상태로 전환되어야 합니다.")
  TestHelper.assert_equal(scene.game_over_reason, "suspicion_max", "게임 오버 원인이 의심 최대치로 기록되어야 합니다.")
end

---@return nil
function suite.test_subscribe_runtime_events_wires_suspicion_max_to_game_over()
  local scene = create_fake_scene()
  local event_bus = EventBus:new()

  scene:_subscribe_runtime_events(event_bus)
  event_bus:emit("suspicion_max", {level = 100})

  TestHelper.assert_equal(scene.phase, "GAME_OVER", "의심 최대치 이벤트가 GAME_OVER 전이로 연결되어야 합니다.")
  TestHelper.assert_equal(scene.game_over_reason, "suspicion_max", "이벤트 기반 게임 오버 원인이 보존되어야 합니다.")
end

return suite
