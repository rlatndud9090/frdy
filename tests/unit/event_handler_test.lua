local TestHelper = require('tests.test_helper')

local suite = {}

local original_button_module = nil
local original_i18n_module = nil
local original_rng_module = nil

function suite.before_each()
  package.loaded['src.handler.event_handler'] = nil
  original_button_module = package.loaded['src.ui.button']
  original_i18n_module = package.loaded['src.i18n.init']
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

  package.loaded['src.i18n.init'] = {
    t = function(key)
      return key
    end,
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
  package.loaded['src.handler.event_handler'] = nil
  package.loaded['src.ui.button'] = original_button_module
  package.loaded['src.i18n.init'] = original_i18n_module
  package.loaded['src.core.rng'] = original_rng_module
end

---@param choice_count number
---@param apply_hook? fun(choice_index: number, context: table)
---@return table
local function create_event(choice_count, apply_hook)
  local choices = {}
  for index = 1, choice_count do
    choices[index] = {
      get_text = function()
        return 'choice-' .. index
      end,
      apply = function(_, context)
        if apply_hook then
          apply_hook(index, context)
        end
      end,
    }
  end

  return {
    get_choice_count = function()
      return choice_count
    end,
    get_choices = function()
      return choices
    end,
    get_intervention_max_mental_stage = function()
      return 3
    end,
    get_intervention_mental_increase = function()
      return 2
    end,
  }
end

---@return nil
function suite.test_start_event_rolls_deterministic_hero_choice_from_rng()
  local EventHandler = require('src.handler.event_handler')
  local rng_calls = {}
  local rng = {
    next_int = function(_, min_value, max_value)
      rng_calls[#rng_calls + 1] = {min_value = min_value, max_value = max_value}
      return 2
    end,
  }
  local handler = EventHandler:new(rng)
  local event = create_event(3)

  handler:start_event(event, {hero = nil})

  TestHelper.assert_equal(#rng_calls, 1)
  TestHelper.assert_equal(rng_calls[1].min_value, 1)
  TestHelper.assert_equal(rng_calls[1].max_value, 3)
  TestHelper.assert_equal(handler.hero_choice_index, 2)
  TestHelper.assert_equal(handler.selected_choice_index, 2)
  TestHelper.assert_equal(#handler.choice_buttons, 3)
end

---@return nil
function suite.test_on_choice_clicked_blocks_intervention_above_mental_limit()
  local EventHandler = require('src.handler.event_handler')
  local hero = {
    can_be_controlled = function()
      return false
    end,
    get_mental_stage = function()
      return 4
    end,
    get_max_mental_stage = function()
      return 5
    end,
    increase_mental_load = function()
      error('increase_mental_load should not be called')
    end,
  }
  local handler = EventHandler:new({
    next_int = function()
      return 1
    end,
  })
  local event = create_event(2)

  handler:start_event(event, {hero = hero})
  handler:_on_choice_clicked(2)

  TestHelper.assert_equal(handler.selected_choice_index, 1)
  TestHelper.assert_equal(handler.feedback_text, 'control.blocked_by_mental')
end

---@return nil
function suite.test_confirm_selected_choice_applies_mental_load_before_choice_and_callback()
  local EventHandler = require('src.handler.event_handler')
  local callback_order = {}
  local applied_choice_index = nil
  local applied_context = nil
  local mental_load = 0
  local mental_load_during_apply = nil
  local mental_load_during_callback = nil
  local hero = {
    can_be_controlled = function()
      return true
    end,
    increase_mental_load = function(_, amount)
      mental_load = mental_load + amount
      return mental_load
    end,
    get_mental_load = function()
      return mental_load
    end,
    get_mental_stage = function()
      return 0
    end,
    get_max_mental_stage = function()
      return 5
    end,
  }
  local event = create_event(2, function(choice_index, context)
    callback_order[#callback_order + 1] = 'apply'
    applied_choice_index = choice_index
    applied_context = context
    mental_load_during_apply = context.hero:get_mental_load()
  end)
  local handler = EventHandler:new({
    next_int = function()
      return 1
    end,
  })

  handler:set_on_event_end(function()
    callback_order[#callback_order + 1] = 'event_end'
    mental_load_during_callback = hero:get_mental_load()
  end)

  handler:start_event(event, {
    hero = hero,
    marker = 'context',
  })
  handler.selected_choice_index = 2
  handler.hero_choice_index = 1

  handler:_confirm_selected_choice()

  TestHelper.assert_equal(applied_choice_index, 2)
  TestHelper.assert_equal(applied_context.marker, 'context')
  TestHelper.assert_equal(mental_load, 2)
  TestHelper.assert_equal(mental_load_during_apply, 2)
  TestHelper.assert_equal(mental_load_during_callback, 2)
  TestHelper.assert_equal(callback_order[1], 'apply')
  TestHelper.assert_equal(callback_order[2], 'event_end')
end

return suite
