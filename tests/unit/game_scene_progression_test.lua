local TestHelper = require('tests.test_helper')
local GameScene = require('src.scene.game_scene')

local suite = {}

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

return suite
