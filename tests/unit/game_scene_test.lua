local TestHelper = require('tests.test_helper')
local flux = require('lib.flux')
local EventBus = require('src.core.event_bus')
local GameScene = require('src.scene.game_scene')
local Game = require('src.core.game')

local suite = {}

---@return table
local function create_fake_scene()
  local switched_scene = nil
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
    _unsubscribe_called = 0,
    map = {
      current_floor_index = 2,
    },
    hero = {
      get_level = function()
        return 4
      end,
    },
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

  function scene:_unsubscribe_runtime_events()
    self._unsubscribe_called = self._unsubscribe_called + 1
  end

  local game_instance = {
    switch_scene = function(_, next_scene)
      switched_scene = next_scene
    end,
  }
  scene._game_instance = game_instance
  scene._get_switched_scene = function()
    return switched_scene
  end

  return setmetatable(scene, {__index = GameScene})
end

function suite.before_each()
  suite._original_flux_to = flux.to
  suite._original_game_static_get_instance = Game.static and Game.static.getInstance or nil

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
  if Game.static then
    Game.static.getInstance = suite._original_game_static_get_instance
  end
end

---@return nil
function suite.test_on_combat_ended_defeat_finishes_run_once()
  local scene = create_fake_scene()
  if Game.static then
    Game.static.getInstance = function()
      return scene._game_instance
    end
  end

  scene:_on_combat_ended("defeat")

  local switched_scene = scene._get_switched_scene()
  TestHelper.assert_true(scene._combat_deactivated == true, "전투 핸들러 비활성화가 필요합니다.")
  TestHelper.assert_equal(scene._mana_recovered, 30, "전투 종료 마나 회복량이 유지되어야 합니다.")
  TestHelper.assert_equal(scene._clear_active_run_called, 1, "패배 시 세이브 정리는 한 번만 호출되어야 합니다.")
  TestHelper.assert_equal(scene._settlement_called, 0, "패배 시 정산/다음 이동으로 진행되면 안 됩니다.")
  TestHelper.assert_equal(scene._unsubscribe_called, 1, "런 종료 시 런타임 이벤트 구독을 해제해야 합니다.")
  TestHelper.assert_true(switched_scene ~= nil, "패배 후 런 종료 씬으로 전환되어야 합니다.")
  TestHelper.assert_equal(switched_scene.reason, "death", "패배 시 death 사유로 런 종료가 기록되어야 합니다.")
  TestHelper.assert_equal(switched_scene.summary.floor, 2, "런 종료 요약에 현재 층이 반영되어야 합니다.")
  TestHelper.assert_equal(switched_scene.summary.level, 4, "런 종료 요약에 현재 레벨이 반영되어야 합니다.")
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
function suite.test_on_suspicion_max_finishes_run_with_detected_reason()
  local finished_reason = nil
  local close_calls = 0
  local scene = create_fake_scene()
  scene.phase = "EVENT"
  scene.run_end_locked = false
  scene.settings_overlay = {
    close = function()
      close_calls = close_calls + 1
    end,
  }
  scene._finish_run = function(_, reason)
    finished_reason = reason
  end

  scene:_on_suspicion_max()
  scene:_on_suspicion_max()

  TestHelper.assert_true(scene._combat_deactivated == true, "의심 최대치 도달 시 전투 핸들러를 비활성화해야 합니다.")
  TestHelper.assert_equal(finished_reason, "detected", "의심 최대치는 detected 사유로 런 종료되어야 합니다.")
  TestHelper.assert_equal(close_calls, 1, "의심 최대치 처리 중 설정 오버레이는 한 번만 닫혀야 합니다.")
end

---@return nil
function suite.test_exit_unsubscribes_runtime_events()
  local event_bus = EventBus:new()
  local handled = false
  local scene = {}
  scene._on_suspicion_max = function()
    handled = true
  end
  setmetatable(scene, {__index = GameScene})

  scene:_subscribe_runtime_events(event_bus)
  scene:exit()
  event_bus:emit("suspicion_max", {level = 100})

  TestHelper.assert_false(handled, "씬 종료 후에는 suspicion_max 구독이 해제되어야 합니다.")
end

return suite
