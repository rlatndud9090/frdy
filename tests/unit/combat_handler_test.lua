local TestHelper = require('tests.test_helper')
local CombatHandler = require('src.handler.combat_handler')

local suite = {}

---@return nil
function suite.test_non_insert_awakening_accumulates_after_execution_start()
  local handler = CombatHandler:new()
  local events = {}
  local interventions = {
    {type = "global", spell = {get_cost = function() return 40 end}},
    {type = "insert", spell = {get_cost = function() return 20 end}},
  }
  local timeline_manager = {
    interventions = interventions,
  }

  function timeline_manager:get_interventions()
    table.insert(events, "get_interventions")
    return self.interventions
  end

  function timeline_manager:confirm()
    table.insert(events, "timeline_confirm")
    self.interventions = {}
  end

  local execution_started = false
  local received_interventions = nil

  handler.combat_manager = {
    get_timeline_manager = function()
      return timeline_manager
    end,
    start_execution = function()
      execution_started = true
      table.insert(events, "start_execution")
    end,
  }
  handler.spell_book = {
    confirm = function()
      table.insert(events, "spell_book_confirm")
    end,
  }
  handler.suspicion_manager = nil
  handler.reward_manager = {
    on_non_insert_spells_confirmed = function(_, confirmed_interventions)
      TestHelper.assert_true(execution_started, "각성 누적은 실행 시작 이후여야 합니다.")
      received_interventions = confirmed_interventions
      table.insert(events, "reward_confirmed")
    end,
  }

  handler:_confirm_planning()

  TestHelper.assert_equal(received_interventions, interventions, "개입 스냅샷이 전달되어야 합니다.")
  TestHelper.assert_equal(#timeline_manager.interventions, 0, "타임라인 개입 목록은 확정 후 비워져야 합니다.")
  TestHelper.assert_equal(table.concat(events, " > "), "get_interventions > spell_book_confirm > timeline_confirm > start_execution > reward_confirmed")
end

return suite
