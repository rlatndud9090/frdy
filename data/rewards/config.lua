---@class RewardConfigHeroXP
---@field normal number
---@field elite number
---@field boss number

---@class RewardConfigHeroLevel
---@field base_threshold number
---@field milestone_interval number
---@field hp_per_level number
---@field attack_per_level number
---@field speed_per_level number

---@class RewardConfigDemonAwakening
---@field threshold number

---@class RewardConfigRewardControl
---@field max_stage number
---@field mental_increase number

---@class RewardConfigMinHoldings
---@field spells number
---@field patterns number

---@class RewardConfigSpellUpgrade
---@field max_rank number
---@field cost_reduction number
---@field effect_amount_delta number

---@class RewardConfigPatternUpgrade
---@field max_rank number
---@field attack_mult_delta number
---@field defense_bonus_delta number
---@field heal_amount_delta number

---@class RewardConfig
---@field hero_xp RewardConfigHeroXP
---@field hero_level RewardConfigHeroLevel
---@field demon_awakening RewardConfigDemonAwakening
---@field reward_control RewardConfigRewardControl
---@field min_holdings RewardConfigMinHoldings
---@field spell_upgrade RewardConfigSpellUpgrade
---@field pattern_upgrade RewardConfigPatternUpgrade

---@type RewardConfig
local reward_config = {
  hero_xp = {
    normal = 30,
    elite = 45,
    boss = 60,
  },

  hero_level = {
    base_threshold = 100,
    milestone_interval = 5,
    hp_per_level = 5,
    attack_per_level = 1,
    speed_per_level = 0.5,
  },

  demon_awakening = {
    threshold = 100,
  },

  reward_control = {
    max_stage = 3,
    mental_increase = 0.25,
  },

  min_holdings = {
    spells = 6,
    patterns = 2,
  },

  spell_upgrade = {
    max_rank = 5,
    cost_reduction = 1,
    effect_amount_delta = 1,
  },

  pattern_upgrade = {
    max_rank = 5,
    attack_mult_delta = 0.15,
    defense_bonus_delta = 1,
    heal_amount_delta = 2,
  },
}

return reward_config
