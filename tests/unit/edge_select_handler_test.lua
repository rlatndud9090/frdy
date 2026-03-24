local TestHelper = require('tests.test_helper')

local suite = {}

local original_button_module = nil
local original_edge_selector_module = nil
local original_i18n_module = nil
local original_path_control_module = nil
local original_rng_module = nil

function suite.before_each()
  package.loaded['src.handler.edge_select_handler'] = nil
  original_button_module = package.loaded['src.ui.button']
  original_edge_selector_module = package.loaded['src.ui.edge_selector']
  original_i18n_module = package.loaded['src.i18n.init']
  original_path_control_module = package.loaded['data.interventions.path_control']
  original_rng_module = package.loaded['src.core.rng']

  package.loaded['src.ui.button'] = {
    new = function()
      return {
        set_on_click = function(self, callback)
          self.on_click = callback
        end,
        update = function() end,
        draw = function() end,
        hit_test = function()
          return false
        end,
        mousepressed = function() end,
      }
    end,
  }

  package.loaded['src.ui.edge_selector'] = {
    new = function(_, _, _, _, on_click)
      return {
        set_visual_state = function() end,
        update = function() end,
        draw = function() end,
        mousepressed = function(_, _, _, _)
          on_click(nil, 1)
        end,
      }
    end,
  }

  package.loaded['src.i18n.init'] = {
    t = function(key)
      return key
    end,
  }

  package.loaded['data.interventions.path_control'] = {
    max_mental_stage = 3,
    mental_increase = 2,
  }

  package.loaded['src.core.rng'] = {
    new = function()
      return {
        next_int = function()
          return 1
        end,
      }
    end,
  }
end

function suite.after_each()
  package.loaded['src.handler.edge_select_handler'] = nil
  package.loaded['src.ui.button'] = original_button_module
  package.loaded['src.ui.edge_selector'] = original_edge_selector_module
  package.loaded['src.i18n.init'] = original_i18n_module
  package.loaded['data.interventions.path_control'] = original_path_control_module
  package.loaded['src.core.rng'] = original_rng_module
end

function suite.test_confirm_selection_rolls_back_intervention_when_callback_rejects()
  local EdgeSelectHandler = require('src.handler.edge_select_handler')
  local mental_load_increase_count = 0
  local mental_load_during_callback = nil
  local callback_count = 0
  local hero = {
    can_be_controlled = function()
      return true
    end,
    increase_mental_load = function(_, amount)
      mental_load_increase_count = mental_load_increase_count + amount
      return mental_load_increase_count
    end,
    get_mental_load = function()
      return mental_load_increase_count
    end,
    get_mental_stage = function()
      return 0
    end,
    get_max_mental_stage = function()
      return 5
    end,
  }
  local edges = {
    {get_to_node = function() return {get_type = function() return 'combat' end} end},
    {get_to_node = function() return {get_type = function() return 'event' end} end},
  }
  local rng = {
    next_int = function()
      return 1
    end,
  }
  local handler = EdgeSelectHandler:new(edges, function()
    callback_count = callback_count + 1
    mental_load_during_callback = hero:get_mental_load()
    return false
  end, {
    hero = hero,
  }, rng)

  handler:activate()
  handler.selected_index = 2
  handler.hero_choice_index = 1

  handler:_confirm_selection()

  TestHelper.assert_equal(callback_count, 1)
  TestHelper.assert_true(handler.active)
  TestHelper.assert_equal(mental_load_during_callback, 2)
  TestHelper.assert_equal(mental_load_increase_count, 0)
end

function suite.test_confirm_selection_applies_intervention_before_callback_accepts()
  local EdgeSelectHandler = require('src.handler.edge_select_handler')
  local mental_load_increase_count = 0
  local mental_load_during_callback = nil
  local callback_count = 0
  local hero = {
    can_be_controlled = function()
      return true
    end,
    increase_mental_load = function(_, amount)
      mental_load_increase_count = mental_load_increase_count + amount
      return mental_load_increase_count
    end,
    get_mental_load = function()
      return mental_load_increase_count
    end,
    get_mental_stage = function()
      return 0
    end,
    get_max_mental_stage = function()
      return 5
    end,
  }
  local edges = {
    {get_to_node = function() return {get_type = function() return 'combat' end} end},
    {get_to_node = function() return {get_type = function() return 'event' end} end},
  }
  local rng = {
    next_int = function()
      return 1
    end,
  }
  local handler = EdgeSelectHandler:new(edges, function()
    callback_count = callback_count + 1
    mental_load_during_callback = hero:get_mental_load()
    return true
  end, {
    hero = hero,
  }, rng)

  handler:activate()
  handler.selected_index = 2
  handler.hero_choice_index = 1

  handler:_confirm_selection()

  TestHelper.assert_equal(callback_count, 1)
  TestHelper.assert_false(handler.active)
  TestHelper.assert_equal(mental_load_during_callback, 2)
  TestHelper.assert_equal(mental_load_increase_count, 2)
end

return suite
