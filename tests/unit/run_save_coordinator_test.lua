local TestHelper = require('tests.test_helper')
local RunStateRegistry = require('src.core.run_state_registry')
local RunSaveCoordinator = require('src.core.run_save_coordinator')

local suite = {}

function suite.test_save_checkpoint_uses_registry_and_store()
  local registry = RunStateRegistry:new()
  registry:register({
    key = 'reward',
    snapshot = function()
      return {
        value = 10,
      }
    end,
    validate = function(snapshot)
      return snapshot, nil
    end,
    restore = function()
      return true, nil
    end,
  })
  registry:register({
    key = 'hero',
    snapshot = function()
      return {
        ready = true,
      }
    end,
    validate = function(snapshot)
      return snapshot, nil
    end,
    restore = function()
      return true, nil
    end,
  })

  local written_payload = nil
  local coordinator = RunSaveCoordinator:new({
    registry = registry,
    get_run_seed = function()
      return 777
    end,
    expected_system_keys = {'reward', 'hero'},
    save_store = {
      write = function(_, payload)
        written_payload = payload
        return true, nil
      end,
    },
  })

  local ok, err = coordinator:save_checkpoint('combat_start')
  TestHelper.assert_true(ok)
  TestHelper.assert_equal(err, nil)
  TestHelper.assert_equal(written_payload.version, 2)
  TestHelper.assert_equal(written_payload.run_seed, 777)
  TestHelper.assert_equal(written_payload.checkpoint.kind, 'combat_start')
  TestHelper.assert_equal(written_payload.systems.reward.value, 10)
  TestHelper.assert_true(written_payload.systems.hero.ready)
end

function suite.test_save_checkpoint_fails_when_registry_manifest_is_incomplete()
  local registry = RunStateRegistry:new()
  registry:register({
    key = 'alpha',
    snapshot = function()
      return {}
    end,
    validate = function(snapshot)
      return snapshot, nil
    end,
    restore = function()
      return true, nil
    end,
  })

  local write_called = false
  local coordinator = RunSaveCoordinator:new({
    registry = registry,
    get_run_seed = function()
      return 1
    end,
    expected_system_keys = {'alpha', 'beta'},
    save_store = {
      write = function()
        write_called = true
        return true, nil
      end,
    },
  })

  local ok, err = coordinator:save_checkpoint('start_node_select')
  TestHelper.assert_false(ok)
  TestHelper.assert_true(err ~= nil)
  TestHelper.assert_false(write_called)
end

function suite.test_restore_payload_normalizes_legacy_shape_and_restores_registered_systems()
  local restored = {
    hero = nil,
    mana = nil,
  }

  local registry = RunStateRegistry:new()
  registry:register({
    key = 'hero',
    snapshot = function()
      return {}
    end,
    validate = function(snapshot)
      return snapshot, nil
    end,
    restore = function(snapshot)
      restored.hero = snapshot
      return true, nil
    end,
  })
  registry:register({
    key = 'mana',
    snapshot = function()
      return {}
    end,
    validate = function(snapshot)
      return snapshot, nil
    end,
    restore = function(snapshot)
      restored.mana = snapshot
      return true, nil
    end,
  })

  local coordinator = RunSaveCoordinator:new({
    registry = registry,
    get_run_seed = function()
      return 1234
    end,
  })

  local normalized, err = coordinator:restore_payload({
    version = 1,
    run_seed = 1234,
    checkpoint = {
      kind = 'path_ready',
    },
    hero_snapshot = {
      hp = 42,
      max_hp = 50,
      attack = 8,
      defense = 2,
      speed = 8,
      level = 3,
      experience = 70,
      mental_load = 1.2,
      current_turn = 1,
      cooldown_tracker = {},
      action_patterns = {},
    },
    mana_snapshot = {
      current_mana = 75,
      max_mana = 100,
      reserved_mana = 5,
    },
  })

  TestHelper.assert_equal(err, nil)
  TestHelper.assert_equal(normalized.checkpoint.kind, 'path_ready')
  TestHelper.assert_equal(restored.hero.level, 3)
  TestHelper.assert_equal(restored.mana.current_mana, 75)
end

return suite
