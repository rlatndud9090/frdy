local TestHelper = require('tests.test_helper')
local GameScene = require('src.scene.game_scene')
local Game = require('src.core.game')
local EventBus = require('src.core.event_bus')
local flux = require('lib.flux')

local suite = {}
local original_game_get_instance = Game.getInstance
local original_game_static_get_instance = Game.static and Game.static.getInstance or nil
local original_run_end_scene_module = nil

function suite.before_each()
  original_run_end_scene_module = package.loaded['src.scene.run_end_scene']
  flux.tweens = {}
end

function suite.after_each()
  Game.getInstance = original_game_get_instance
  if Game.static then
    Game.static.getInstance = original_game_static_get_instance
  end
  package.loaded['src.scene.run_end_scene'] = original_run_end_scene_module
  flux.tweens = {}
end

local function build_fake_scene(edge_count, has_pending_offers, current_floor_index, total_floors)
  local finished_reason = nil
  local wrote_checkpoint = false
  local checked_next_move = false
  local checkpoint_kind = nil
  local start_select_shown = false
  local advanced_floor = false
  local reset_world = false
  local call_order = {}

  local floor = {
    get_edges_from = function()
      local edges = {}
      for index = 1, edge_count do
        edges[index] = {
          get_to_node = function()
            return {
              id = index,
            }
          end,
        }
      end
      return edges
    end,
    get_start_nodes = function()
      return {
        {
          id = 101,
          get_position = function()
            return {x = 0, y = 0}
          end,
        },
      }
    end,
  }

  local scene = {
    current_node = {
      id = 10,
    },
    map = {
      current_floor_index = current_floor_index or 1,
      get_current_floor = function()
        return floor
      end,
      get_total_floors = function()
        return total_floors or 1
      end,
      advance_floor = function(map)
        call_order[#call_order + 1] = 'advance_floor'
        map.current_floor_index = map.current_floor_index + 1
        advanced_floor = true
      end,
    },
    reward_manager = {
      has_pending_offers = function()
        return has_pending_offers
      end,
      peek_offer = function()
        return nil
      end,
    },
    _finish_run = function(_, reason)
      finished_reason = reason
    end,
    _write_checkpoint = function(_, kind)
      call_order[#call_order + 1] = kind
      wrote_checkpoint = true
      checkpoint_kind = kind
      return true
    end,
    _check_next_move = function()
      checked_next_move = true
    end,
    _reset_world_position_for_current_floor = function()
      reset_world = true
    end,
    _show_start_node_select = function()
      call_order[#call_order + 1] = 'show_start_node_select'
      start_select_shown = true
    end,
  }
  setmetatable(scene, {__index = GameScene})

  return scene, function()
    return {
      finished_reason = finished_reason,
      wrote_checkpoint = wrote_checkpoint,
      checkpoint_kind = checkpoint_kind,
      checked_next_move = checked_next_move,
      start_select_shown = start_select_shown,
      advanced_floor = advanced_floor,
      reset_world = reset_world,
      current_floor_index = scene.map.current_floor_index,
      call_order = call_order,
    }
  end
end

---@return nil
function suite.test_continue_after_settlement_finishes_run_without_path_checkpoint_on_last_node()
  local scene, result = build_fake_scene(0, false, 3, 3)

  scene:_enter_settlement_or_continue()

  local state = result()
  TestHelper.assert_equal(state.finished_reason, 'victory')
  TestHelper.assert_false(state.wrote_checkpoint)
  TestHelper.assert_false(state.checked_next_move)
  TestHelper.assert_false(state.advanced_floor)
end

---@return nil
function suite.test_continue_after_settlement_writes_path_checkpoint_when_next_edge_exists()
  local scene, result = build_fake_scene(1, false, 1, 3)

  scene:_enter_settlement_or_continue()

  local state = result()
  TestHelper.assert_equal(state.finished_reason, nil)
  TestHelper.assert_true(state.wrote_checkpoint)
  TestHelper.assert_equal(state.checkpoint_kind, 'path_ready')
  TestHelper.assert_true(state.checked_next_move)
end

---@return nil
function suite.test_continue_after_settlement_advances_to_next_floor_when_current_floor_is_not_final()
  local scene, result = build_fake_scene(0, false, 1, 3)

  scene:_enter_settlement_or_continue()

  local state = result()
  TestHelper.assert_equal(state.finished_reason, nil)
  TestHelper.assert_true(state.wrote_checkpoint)
  TestHelper.assert_equal(state.checkpoint_kind, 'start_node_select')
  TestHelper.assert_true(state.advanced_floor)
  TestHelper.assert_true(state.reset_world)
  TestHelper.assert_true(state.start_select_shown)
  TestHelper.assert_equal(state.current_floor_index, 2)
  TestHelper.assert_equal(state.call_order[1], 'advance_floor')
  TestHelper.assert_equal(state.call_order[2], 'start_node_select')
end

---@return nil
function suite.test_checkpoint_post_resolution_prefers_reward_offer_checkpoint()
  local checkpoints = {}
  local scene = {
    reward_manager = {
      has_pending_offers = function()
        return true
      end,
    },
    _write_checkpoint = function(_, checkpoint_kind)
      checkpoints[#checkpoints + 1] = checkpoint_kind
      return true
    end,
    _clear_active_run = function()
      error('clear_active_run should not be called')
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_checkpoint_post_resolution()

  TestHelper.assert_equal(#checkpoints, 1)
  TestHelper.assert_equal(checkpoints[1], 'reward_offer_presented')
end

---@return nil
function suite.test_checkpoint_post_resolution_clears_active_run_when_node_flow_is_terminal()
  local cleared = false
  local scene = {
    reward_manager = {
      has_pending_offers = function()
        return false
      end,
    },
    current_node = { id = 1 },
    map = {
      current_floor_index = 1,
      get_total_floors = function()
        return 1
      end,
      get_current_floor = function()
        return {
          get_edges_from = function()
            return {}
          end,
        }
      end,
    },
    _write_checkpoint = function()
      error('_write_checkpoint should not be called')
    end,
    _clear_active_run = function()
      cleared = true
      return true
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_checkpoint_post_resolution()

  TestHelper.assert_true(cleared)
end

---@return nil
function suite.test_checkpoint_post_resolution_writes_floor_transition_checkpoint_for_next_floor_start()
  local checkpoints = {}
  local cleared = false
  local scene = {
    reward_manager = {
      has_pending_offers = function()
        return false
      end,
    },
    current_node = { id = 1 },
    map = {
      current_floor_index = 1,
      get_total_floors = function()
        return 3
      end,
      get_current_floor = function()
        return {
          get_edges_from = function()
            return {}
          end,
        }
      end,
    },
    _write_checkpoint = function(_, checkpoint_kind)
      checkpoints[#checkpoints + 1] = checkpoint_kind
      return true
    end,
    _clear_active_run = function()
      cleared = true
      return true
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_checkpoint_post_resolution()

  TestHelper.assert_false(cleared)
  TestHelper.assert_equal(#checkpoints, 1)
  TestHelper.assert_equal(checkpoints[1], 'floor_transition_pending')
end

---@return nil
function suite.test_resume_from_floor_transition_pending_advances_to_next_floor()
  local advanced = false
  local scene = {
    _advance_to_next_floor = function()
      advanced = true
    end,
    map = {
      get_current_floor = function()
        return {
          get_start_nodes = function()
            return {}
          end,
        }
      end,
    },
  }
  setmetatable(scene, {__index = GameScene})

  scene:_resume_from_checkpoint('floor_transition_pending')

  TestHelper.assert_true(advanced)
end

---@return nil
function suite.test_on_edge_selected_writes_travel_checkpoint_before_traveling()
  local call_order = {}
  local target_node = { id = 22 }
  local edge = {
    get_to_node = function()
      return target_node
    end,
  }
  local scene = {
    _write_checkpoint = function(_, checkpoint_kind)
      call_order[#call_order + 1] = checkpoint_kind
      return true
    end,
    _start_traveling = function(_, target)
      call_order[#call_order + 1] = target.id
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_on_edge_selected(edge)

  TestHelper.assert_equal(scene.pending_target_node_id, 22)
  TestHelper.assert_equal(call_order[1], 'travel_start')
  TestHelper.assert_equal(call_order[2], 22)
end

---@return nil
function suite.test_on_edge_selected_does_not_start_travel_when_travel_checkpoint_fails()
  local call_order = {}
  local target_node = { id = 22 }
  local edge = {
    get_to_node = function()
      return target_node
    end,
  }
  local scene = {
    _write_checkpoint = function(_, checkpoint_kind)
      call_order[#call_order + 1] = checkpoint_kind
      return false
    end,
    _start_traveling = function(_, target)
      call_order[#call_order + 1] = target.id
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_on_edge_selected(edge)

  TestHelper.assert_equal(scene.pending_target_node_id, nil)
  TestHelper.assert_equal(call_order[1], 'travel_start')
  TestHelper.assert_equal(call_order[2], nil)
end

---@return nil
function suite.test_check_next_move_single_edge_uses_travel_checkpoint_flow()
  local call_order = {}
  local target_node = { id = 27 }
  local scene = {
    current_node = { id = 10 },
    map = {
      get_current_floor = function()
        return {
          get_edges_from = function()
            return {
              {
                get_to_node = function()
                  return target_node
                end,
              },
            }
          end,
        }
      end,
    },
    _write_checkpoint = function(_, checkpoint_kind)
      call_order[#call_order + 1] = checkpoint_kind
      return true
    end,
    _start_traveling = function(_, target)
      call_order[#call_order + 1] = target.id
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_check_next_move()

  TestHelper.assert_equal(scene.pending_target_node_id, 27)
  TestHelper.assert_equal(call_order[1], 'travel_start')
  TestHelper.assert_equal(call_order[2], 27)
end

---@return nil
function suite.test_check_next_move_single_edge_falls_back_to_selector_when_travel_commit_fails()
  local showed_selector = false
  local target_node = { id = 27 }
  local scene = {
    current_node = { id = 10 },
    map = {
      get_current_floor = function()
        return {
          get_edges_from = function()
            return {
              {
                get_to_node = function()
                  return target_node
                end,
              },
            }
          end,
        }
      end,
    },
    _on_edge_selected = function()
      return false
    end,
    _show_edge_select = function(_, edges)
      showed_selector = edges[1] ~= nil
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_check_next_move()

  TestHelper.assert_true(showed_selector)
end

---@return nil
function suite.test_resume_from_travel_checkpoint_enters_selected_target_node()
  local entered = false
  local scene
  scene = {
    map = {
      get_current_floor = function()
        return {
          get_start_nodes = function()
            return {}
          end,
        }
      end,
    },
    pending_target_node_id = 33,
    _find_node_by_id = function(_, node_id)
      if node_id == 33 then
        return { id = 33 }
      end
      return nil
    end,
    _set_current_node = function(_, node)
      scene.current_node = node
    end,
    _enter_current_node = function()
      entered = true
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_resume_from_checkpoint('travel_start')

  TestHelper.assert_equal(scene.current_node.id, 33)
  TestHelper.assert_true(entered)
  TestHelper.assert_equal(scene.pending_target_node_id, nil)
end

---@return nil
function suite.test_restore_from_save_returns_error_when_checkpoint_resume_raises()
  local scene = {
    restoring = false,
    save_coordinator = {
      restore_payload = function()
        return {
          checkpoint = {
            kind = 'path_ready',
          },
        }, nil
      end,
    },
    _resume_from_checkpoint = function()
      error('resume crashed')
    end,
  }
  setmetatable(scene, {__index = GameScene})

  local ok, err = scene:_restore_from_save({
    checkpoint = {
      kind = 'path_ready',
    },
  })

  TestHelper.assert_false(ok)
  TestHelper.assert_true(string.find(err, 'resume crashed', 1, true) ~= nil)
  TestHelper.assert_false(scene.restoring)
end

---@return nil
function suite.test_finish_run_passes_save_cleanup_failure_to_run_end_scene()
  local switched_scene = nil
  local fake_game = {
    switch_scene = function(_, scene)
      switched_scene = scene
    end,
  }
  Game.getInstance = function()
    return fake_game
  end
  if Game.static then
    Game.static.getInstance = function()
      return fake_game
    end
  end
  package.loaded['src.scene.run_end_scene'] = {
    new = function(_, options)
      return {
        kind = 'run_end_scene',
        options = options,
      }
    end,
  }

  local scene = {
    _clear_active_run = function()
      return false
    end,
    _build_run_end_summary = function()
      return {
        floor = 1,
        level = 2,
      }
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_finish_run('victory')

  TestHelper.assert_true(switched_scene ~= nil)
  TestHelper.assert_equal(switched_scene.kind, 'run_end_scene')
  TestHelper.assert_equal(switched_scene.options.reason, 'victory')
  TestHelper.assert_true(switched_scene.options.save_cleanup_failed)
  TestHelper.assert_equal(switched_scene.options.summary.floor, 1)
  TestHelper.assert_equal(switched_scene.options.summary.level, 2)
end

---@return nil
function suite.test_subscribe_runtime_events_routes_suspicion_max_event_to_handler()
  local event_bus = EventBus:new()
  local handled = false
  local scene = {
    _on_suspicion_max = function()
      handled = true
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_subscribe_runtime_events(event_bus)
  event_bus:emit('suspicion_max', {level = 100})

  TestHelper.assert_true(handled)
end

---@return nil
function suite.test_unsubscribe_runtime_events_detaches_suspicion_max_listener()
  local event_bus = EventBus:new()
  local handled = false
  local scene = {
    _on_suspicion_max = function()
      handled = true
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_subscribe_runtime_events(event_bus)
  scene:_unsubscribe_runtime_events()
  event_bus:emit('suspicion_max', {level = 100})

  TestHelper.assert_false(handled)
end

---@return nil
function suite.test_on_suspicion_max_finishes_run_once_with_detected_reason()
  local deactivate_calls = 0
  local close_calls = 0
  local finished_reason = nil
  local scene = {
    run_end_locked = false,
    combat_handler = {
      deactivate = function()
        deactivate_calls = deactivate_calls + 1
      end,
    },
    settings_overlay = {
      close = function()
        close_calls = close_calls + 1
      end,
    },
    _finish_run = function(_, reason)
      finished_reason = reason
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_on_suspicion_max()
  scene:_on_suspicion_max()

  TestHelper.assert_equal(finished_reason, 'detected')
  TestHelper.assert_equal(deactivate_calls, 1)
  TestHelper.assert_equal(close_calls, 1)
end

---@return nil
function suite.test_on_combat_ended_ignores_reentry_after_run_end_lock()
  local deactivated = false
  local recovered = false
  local checkpointed = false
  local cleared = false
  local scene = {
    run_end_locked = true,
    combat_handler = {
      deactivate = function()
        deactivated = true
      end,
    },
    mana_manager = {
      recover_after_combat = function()
        recovered = true
      end,
    },
    reward_manager = {
      prepare_combat_settlement = function()
        checkpointed = true
      end,
    },
    _checkpoint_post_resolution = function()
      checkpointed = true
    end,
    _clear_active_run = function()
      cleared = true
      return true
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_on_combat_ended('victory')

  TestHelper.assert_false(deactivated)
  TestHelper.assert_false(recovered)
  TestHelper.assert_false(checkpointed)
  TestHelper.assert_false(cleared)
end

---@return nil
function suite.test_on_event_ended_enters_game_over_on_lethal_event_damage()
  local deactivated = false
  local checkpointed = false
  local entered_settlement = false
  local cleared_run = false
  local finished_reason = nil
  local scene = {
    hero = {
      is_alive = function()
        return false
      end,
    },
    event_handler = {
      panel_alpha = 1,
      panel_y = 0,
      deactivate = function()
        deactivated = true
      end,
    },
    _checkpoint_post_resolution = function()
      checkpointed = true
    end,
    _enter_settlement_or_continue = function()
      entered_settlement = true
    end,
    _clear_active_run = function()
      cleared_run = true
      return true
    end,
    _finish_run = function(_, reason)
      finished_reason = reason
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_on_event_ended()
  flux.update(1)

  TestHelper.assert_true(deactivated)
  TestHelper.assert_false(checkpointed)
  TestHelper.assert_false(entered_settlement)
  TestHelper.assert_false(cleared_run)
  TestHelper.assert_equal(finished_reason, 'death')
end

---@return nil
function suite.test_on_event_ended_preserves_existing_flow_when_hero_survives()
  local deactivated = false
  local checkpointed = false
  local entered_settlement = false
  local cleared_run = false
  local scene = {
    hero = {
      is_alive = function()
        return true
      end,
    },
    event_handler = {
      panel_alpha = 1,
      panel_y = 0,
      deactivate = function()
        deactivated = true
      end,
    },
    _checkpoint_post_resolution = function()
      checkpointed = true
    end,
    _enter_settlement_or_continue = function()
      entered_settlement = true
    end,
    _clear_active_run = function()
      cleared_run = true
      return true
    end,
  }
  setmetatable(scene, {__index = GameScene})

  scene:_on_event_ended()
  flux.update(1)

  TestHelper.assert_true(deactivated)
  TestHelper.assert_true(checkpointed)
  TestHelper.assert_true(entered_settlement)
  TestHelper.assert_false(cleared_run)
end

---@return nil
function suite.test_clear_active_run_invalidates_save_when_cleanup_fails()
  local invalidated_reason = nil
  local feedback_text = nil
  local scene = {
    restoring = false,
    save_coordinator = {
      clear_active_run = function()
        return false, 'remove failed'
      end,
      invalidate_active_run = function(_, reason)
        invalidated_reason = reason
        return true, nil
      end,
    },
    _set_save_feedback = function(_, text)
      feedback_text = text
    end,
  }
  setmetatable(scene, {__index = GameScene})

  local ok = scene:_clear_active_run()

  TestHelper.assert_false(ok)
  TestHelper.assert_equal(invalidated_reason, 'ended')
  TestHelper.assert_true(feedback_text ~= nil)
end

return suite
