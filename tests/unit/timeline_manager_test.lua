local TestHelper = require("tests.test_helper")
local TimelineManager = require("src.combat.timeline_manager")

local suite = {}

---@return TimelineManager, table
local function create_fixture()
  local calls = {}
  local prediction_engine = {
    recalculate_with = function(_, hero, enemies, timeline, start_index, opts)
      calls[#calls + 1] = {
        hero = hero,
        enemies = enemies,
        timeline = timeline,
        start_index = start_index,
        preserve_actor_slots = opts and opts.preserve_actor_slots or false,
      }
      return timeline
    end,
  }
  local manager = TimelineManager:new(prediction_engine)
  manager.hero = {id = "hero"}
  manager.enemies = {{id = "enemy"}}
  manager.timeline = {
    {
      slot_token = 1,
      get_source_type = function()
        return "hero"
      end,
    },
    {
      slot_token = 2,
      get_source_type = function()
        return "enemy"
      end,
    },
    {
      slot_token = 3,
      get_source_type = function()
        return "hero"
      end,
    },
  }
  return manager, calls
end

---@return nil
function suite.test_actor_slot_intervention_only_counts_suffix_changes()
  local manager = create_fixture()
  manager.interventions = {
    {type = "delay", index = 1},
    {type = "modify", index = 3},
  }

  TestHelper.assert_false(
    manager:_has_actor_slot_intervention_from(2),
    "시작 인덱스 이전 조작만 있으면 actor-slot 보존을 강제하면 안 됩니다."
  )
  TestHelper.assert_true(
    manager:_has_actor_slot_intervention_from(1),
    "suffix 안쪽의 actor-slot 조작은 여전히 감지되어야 합니다."
  )
end

---@return nil
function suite.test_recalculate_from_disables_actor_slot_preserve_for_prefix_only_changes()
  local manager, calls = create_fixture()
  manager.interventions = {
    {type = "delay", index = 1},
  }

  manager:_recalculate_from(3)

  TestHelper.assert_equal(#calls, 1, "재계산 호출이 한 번 발생해야 합니다.")
  TestHelper.assert_false(
    calls[1].preserve_actor_slots,
    "시작 인덱스 이전 actor-slot 조작만 있으면 suffix 재계산은 actor-slot을 고정하지 않아야 합니다."
  )
end

---@return nil
function suite.test_recalculate_from_preserves_actor_slot_for_suffix_delay()
  local manager, calls = create_fixture()
  manager.interventions = {
    {type = "delay", index = 3},
  }

  manager:_recalculate_from(3)

  TestHelper.assert_equal(#calls, 1, "재계산 호출이 한 번 발생해야 합니다.")
  TestHelper.assert_true(
    calls[1].preserve_actor_slots,
    "suffix에 actor-slot 조작이 있으면 기존 보존 동작을 유지해야 합니다."
  )
end

return suite
