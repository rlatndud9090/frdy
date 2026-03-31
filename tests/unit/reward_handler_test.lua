local TestHelper = require('tests.test_helper')

local suite = {}

local original_button_module = nil
local original_i18n_module = nil
local original_rng_module = nil

function suite.before_each()
  package.loaded['src.handler.reward_handler'] = nil
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
  package.loaded['src.handler.reward_handler'] = nil
  package.loaded['src.ui.button'] = original_button_module
  package.loaded['src.i18n.init'] = original_i18n_module
  package.loaded['src.core.rng'] = original_rng_module
end

---@param option_count number
---@return table
local function create_offer(option_count)
  local options = {}
  for index = 1, option_count do
    options[index] = {
      display_text = 'option-' .. index,
      description = 'desc-' .. index,
    }
  end

  return {
    title_key = 'reward.title',
    options = options,
    control = {
      max_stage = 3,
      mental_increase = 0.25,
    },
  }
end

---@return nil
function suite.test_start_offer_rolls_deterministic_hero_choice_from_rng()
  local RewardHandler = require('src.handler.reward_handler')
  local rng_calls = {}
  local rng = {
    next_int = function(_, min_value, max_value)
      rng_calls[#rng_calls + 1] = {min_value = min_value, max_value = max_value}
      return 2
    end,
  }
  local handler = RewardHandler:new(rng)
  local offer = create_offer(3)

  handler:start_offer(offer, {hero = nil}, function() end)

  TestHelper.assert_equal(#rng_calls, 1)
  TestHelper.assert_equal(rng_calls[1].min_value, 1)
  TestHelper.assert_equal(rng_calls[1].max_value, 3)
  TestHelper.assert_equal(handler.hero_choice_index, 2)
  TestHelper.assert_equal(handler.selected_choice_index, 2)
  TestHelper.assert_equal(#handler.option_buttons, 3)
  TestHelper.assert_true(handler.active)
end

---@return nil
function suite.test_on_choice_clicked_blocks_intervention_above_mental_limit()
  local RewardHandler = require('src.handler.reward_handler')
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
  local handler = RewardHandler:new({
    next_int = function()
      return 1
    end,
  })
  local offer = create_offer(2)

  handler:start_offer(offer, {hero = hero}, function() end)
  handler:_on_choice_clicked(2)

  TestHelper.assert_equal(handler.selected_choice_index, 1)
  TestHelper.assert_equal(handler.feedback_text, 'control.blocked_by_mental')
end

---@return nil
function suite.test_confirm_selected_choice_applies_mental_load_before_callback_and_passes_option()
  local RewardHandler = require('src.handler.reward_handler')
  local callback_option = nil
  local callback_mental_load = nil
  local mental_load = 0
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
  local handler = RewardHandler:new({
    next_int = function()
      return 1
    end,
  })
  local offer = create_offer(2)

  handler:start_offer(offer, {hero = hero}, function(selected_option)
    callback_option = selected_option
    callback_mental_load = hero:get_mental_load()
  end)
  handler.selected_choice_index = 2
  handler.hero_choice_index = 1

  handler:_confirm_selected_choice()

  TestHelper.assert_equal(callback_option, offer.options[2])
  TestHelper.assert_equal(callback_mental_load, 0.25)
  TestHelper.assert_equal(mental_load, 0.25)
  TestHelper.assert_false(handler.active)
  TestHelper.assert_equal(handler.offer, nil)
  TestHelper.assert_equal(#handler.option_buttons, 0)
end

return suite
