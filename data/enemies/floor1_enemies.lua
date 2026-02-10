---@class Floor1Enemies
---1층 적 데이터 정의
local floor1_enemies = {
  slime = {
    name = "슬라임",
    stats = {hp = 20, attack = 4, defense = 0},
    action_patterns = {
      {type = "attack", damage_mult = 1.0},
      {type = "attack", damage_mult = 0.8},
    },
  },

  goblin = {
    name = "고블린",
    stats = {hp = 30, attack = 6, defense = 1},
    action_patterns = {
      {type = "attack", damage_mult = 1.0},
      {type = "defend", defense_bonus = 3},
      {type = "attack", damage_mult = 1.2},
    },
  },

  skeleton = {
    name = "스켈레톤",
    stats = {hp = 25, attack = 8, defense = 2},
    action_patterns = {
      {type = "attack", damage_mult = 1.0},
      {type = "attack", damage_mult = 1.5},
      {type = "defend", defense_bonus = 2},
    },
  },

  wolf = {
    name = "늑대",
    stats = {hp = 18, attack = 7, defense = 0},
    action_patterns = {
      {type = "attack", damage_mult = 1.0},
      {type = "attack", damage_mult = 1.3},
    },
  },

  boss_dark_knight = {
    name = "암흑기사",
    stats = {hp = 80, attack = 12, defense = 4},
    action_patterns = {
      {type = "attack", damage_mult = 1.0},
      {type = "defend", defense_bonus = 5},
      {type = "attack", damage_mult = 1.5},
      {type = "attack", damage_mult = 2.0},
    },
  },
}

return floor1_enemies
