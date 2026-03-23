local TestHelper = require('tests.test_helper')
local GameScene = require('src.scene.game_scene')
local Game = require('src.core.game')

local suite = {}
local original_game_get_instance = Game.getInstance
local original_game_static_get_instance = Game.static and Game.static.getInstance or nil
local original_run_end_scene_module = nil

function suite.before_each()
  original_run_end_scene_module = package.loaded['src.scene.run_end_scene']
end

function suite.after_each()
  Game.getInstance = original_game_get_instance
  if Game.static then
    Game.static.getInstance = original_game_static_get_instance
  end
  package.loaded['src.scene.run_end_scene'] = original_run_end_scene_module
end

local function build_fake_scene(edge_count, has_pending_offers)
  local finished_reason = nil
  local wrote_checkpoint = false
  local checked_next_move = false

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
  }

  local scene = {
    current_node = {
      id = 10,
    },
    map = {
      get_current_floor = function()
        return floor
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
    _write_checkpoint = function()
      wrote_checkpoint = true
      return true
    end,
    _check_next_move = function()
      checked_next_move = true
    end,
  }
  setmetatable(scene, {__index = GameScene})

  return scene, function()
    return finished_reason, wrote_checkpoint, checked_next_move
  end
end

---@return nil
function suite.test_continue_after_settlement_finishes_run_without_path_checkpoint_on_last_node()
  local scene, result = build_fake_scene(0, false)

  scene:_enter_settlement_or_continue()

  local finished_reason, wrote_checkpoint, checked_next_move = result()
  TestHelper.assert_equal(finished_reason, 'victory')
  TestHelper.assert_false(wrote_checkpoint)
  TestHelper.assert_false(checked_next_move)
end

---@return nil
function suite.test_continue_after_settlement_writes_path_checkpoint_when_next_edge_exists()
  local scene, result = build_fake_scene(1, false)

  scene:_enter_settlement_or_continue()

  local finished_reason, wrote_checkpoint, checked_next_move = result()
  TestHelper.assert_equal(finished_reason, nil)
  TestHelper.assert_true(wrote_checkpoint)
  TestHelper.assert_true(checked_next_move)
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
function suite.test_finish_run_keeps_current_scene_when_save_clear_fails()
  local switched_scene = nil
  local clear_calls = 0
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
      clear_calls = clear_calls + 1
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

  TestHelper.assert_equal(clear_calls, 1)
  TestHelper.assert_equal(switched_scene, nil)
end

return suite
