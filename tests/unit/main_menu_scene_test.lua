local TestHelper = require('tests.test_helper')
local RunSave = require('src.core.run_save')
local Game = require('src.core.game')

local suite = {}

local original_run_save_exists = RunSave.exists
local original_run_save_load = RunSave.load
local original_run_save_clear = RunSave.clear
local original_run_save_invalidate = RunSave.invalidate
local original_game_get_instance = Game.getInstance
local original_game_static_get_instance = Game.static and Game.static.getInstance or nil

local original_game_scene_module = nil

function suite.before_each()
  package.loaded['src.scene.main_menu_scene'] = nil
  original_game_scene_module = package.loaded['src.scene.game_scene']
end

function suite.after_each()
  RunSave.exists = original_run_save_exists
  RunSave.load = original_run_save_load
  RunSave.clear = original_run_save_clear
  RunSave.invalidate = original_run_save_invalidate
  Game.getInstance = original_game_get_instance
  if Game.static then
    Game.static.getInstance = original_game_static_get_instance
  end
  package.loaded['src.scene.main_menu_scene'] = nil
  package.loaded['src.scene.game_scene'] = original_game_scene_module
end

function suite.test_new_game_with_existing_save_opens_confirmation_before_clearing()
  local cleared = false
  local switched_scene = nil

  RunSave.exists = function()
    return true
  end
  RunSave.clear = function()
    cleared = true
    return true, nil
  end
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
  package.loaded['src.scene.game_scene'] = {
    new = function()
      return {
        kind = 'fake_game_scene',
      }
    end,
  }

  local MainMenuScene = require('src.scene.main_menu_scene')
  local scene = MainMenuScene:new()

  scene:_start_new_game()
  TestHelper.assert_true(scene.confirmation_modal:is_open())
  TestHelper.assert_false(cleared)

  scene.confirmation_modal:_confirm()
  TestHelper.assert_true(cleared)
  TestHelper.assert_equal(switched_scene.kind, 'fake_game_scene')
end

function suite.test_continue_run_load_failure_keeps_save_and_shows_feedback()
  local cleared = false
  local invalidated_reason = nil

  RunSave.exists = function()
    return true
  end
  RunSave.load = function()
    return nil, 'broken'
  end
  RunSave.invalidate = function(_, reason)
    invalidated_reason = reason
    return true, nil
  end
  RunSave.clear = function()
    cleared = true
    return true, nil
  end

  local MainMenuScene = require('src.scene.main_menu_scene')
  local scene = MainMenuScene:new()

  scene:_continue_run()

  TestHelper.assert_false(cleared)
  TestHelper.assert_true(scene.feedback_text ~= nil)
  TestHelper.assert_equal(invalidated_reason, 'load_failed')
  TestHelper.assert_false(scene.has_continue)
  TestHelper.assert_equal(scene.buttons[1].text, 'ui.new_game')
end

function suite.test_initialize_can_hide_continue_after_cleanup_failure()
  RunSave.exists = function()
    return true
  end

  local MainMenuScene = require('src.scene.main_menu_scene')
  local scene = MainMenuScene:new({
    suppress_continue = true,
    feedback_text = 'cleanup warning',
  })

  TestHelper.assert_false(scene.has_continue)
  TestHelper.assert_equal(scene.buttons[1].text, 'ui.new_game')
  TestHelper.assert_equal(scene.feedback_text, 'cleanup warning')
end

return suite
