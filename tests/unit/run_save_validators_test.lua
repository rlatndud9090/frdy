local TestHelper = require('tests.test_helper')
local RunSaveValidators = require('src.core.run_save_validators')

local suite = {}

function suite.test_save_payload_normalizes_legacy_shape_and_clamps_values()
  local payload, err = RunSaveValidators.save_payload({
    version = 1,
    run_seed = 1234,
    checkpoint = {
      kind = 'invalid_checkpoint',
    },
    run_context_snapshot = {
      run_seed = 1234,
      streams = {
        ['gameplay.map'] = {
          seed = 12,
          state = 34,
          draw_count = 2,
        },
      },
    },
    map_progress = {
      current_floor_index = -5,
      current_node_id = '17',
      completed_node_ids = {9, '4', -1},
    },
    hero_snapshot = {
      hp = '44',
      max_hp = '60',
      attack = '9',
      defense = '3',
      speed = '7',
      level = '5',
      experience = '100',
      mental_load = '1.5',
      current_turn = '2',
      cooldown_tracker = {
        slash = '3',
      },
      action_patterns = {
        {
          id = 'slash',
          name = 'Slash',
          type = 'attack',
          priority = '2',
          condition = 'always',
          cooldown = '1',
          params = {
            damage_mult = 1.5,
          },
        },
      },
    },
    spell_book_snapshot = {
      spells = {},
      used_this_turn = {
        spark = '2',
      },
      reserved = {},
      reserved_stack = {},
    },
    mana_snapshot = {
      current_mana = 120,
      max_mana = 100,
      reserved_mana = -5,
    },
    suspicion_snapshot = {
      level = 300,
      max_level = 100,
    },
    reward_snapshot = {
      offer_queue = {
        {
          category = 'spell',
          source = 'combat',
        },
      },
      reward_control_bonus_stage = '4',
    },
  })

  TestHelper.assert_equal(err, nil)
  TestHelper.assert_equal(payload.checkpoint.kind, 'start_node_select')
  TestHelper.assert_equal(payload.systems.map_progress.current_floor_index, 1)
  TestHelper.assert_equal(payload.systems.map_progress.current_node_id, 17)
  TestHelper.assert_equal(payload.systems.map_progress.pending_target_node_id, nil)
  TestHelper.assert_equal(payload.systems.map_progress.completed_node_ids[1], 0)
  TestHelper.assert_equal(payload.systems.hero.hp, 44)
  TestHelper.assert_equal(payload.systems.hero.action_patterns[1].cooldown, 1)
  TestHelper.assert_equal(payload.systems.hero.action_patterns[1].reward_rank, nil)
  TestHelper.assert_equal(payload.systems.hero.action_patterns[1].max_reward_rank, nil)
  TestHelper.assert_equal(payload.systems.mana.current_mana, 100)
  TestHelper.assert_equal(payload.systems.mana.reserved_mana, 0)
  TestHelper.assert_equal(payload.systems.suspicion.level, 100)
  TestHelper.assert_equal(payload.systems.reward.reward_control_bonus_stage, 4)
end

---@return nil
function suite.test_save_payload_accepts_travel_start_and_pending_target_node()
  local payload, err = RunSaveValidators.save_payload({
    version = 2,
    run_seed = 1234,
    checkpoint = {
      kind = 'travel_start',
    },
    systems = {
      run_context = {
        run_seed = 1234,
        streams = {},
      },
      map_progress = {
        current_floor_index = 1,
        current_node_id = 11,
        pending_target_node_id = '22',
        completed_node_ids = { 11 },
      },
      hero = {
        hp = 50,
        max_hp = 50,
        attack = 8,
        defense = 2,
        speed = 8,
        level = 1,
        experience = 0,
        mental_load = 0,
        current_turn = 0,
        cooldown_tracker = {},
        action_patterns = {},
      },
      spell_book = {
        spells = {},
        used_this_turn = {},
        reserved = {},
        reserved_stack = {},
      },
      mana = {
        current_mana = 100,
        max_mana = 100,
        reserved_mana = 0,
      },
      suspicion = {
        level = 0,
        max_level = 100,
      },
      reward = {
        offer_queue = {},
      },
    },
  })

  TestHelper.assert_equal(err, nil)
  TestHelper.assert_equal(payload.checkpoint.kind, 'travel_start')
  TestHelper.assert_equal(payload.systems.map_progress.pending_target_node_id, 22)
end

---@return nil
function suite.test_action_pattern_rank_clamps_invalid_zero_to_one()
  local pattern = RunSaveValidators.action_pattern({
    id = 'slash',
    name = 'Slash',
    type = 'attack',
    reward_rank = 0,
    max_reward_rank = 0,
  })

  TestHelper.assert_equal(pattern.reward_rank, 1)
  TestHelper.assert_equal(pattern.max_reward_rank, 1)
end

return suite
