return {
  {
    id = "hero_attack",
    name = "pattern.hero_attack.name",
    type = "attack",
    priority = 1,
    condition = "fallback",
    cooldown = 0,
    params = {
      damage_mult = 1.0,
    },
  },
  {
    id = "hero_guard",
    name = "pattern.hero_guard.name",
    type = "defend",
    priority = 20,
    condition = "hp_below",
    condition_params = {
      threshold = 0.6,
    },
    cooldown = 2,
    params = {
      defense_bonus = 3,
    },
  },
  {
    id = "hero_power_slash",
    name = "pattern.hero_power_slash.name",
    type = "attack",
    priority = 18,
    condition = "always",
    cooldown = 2,
    params = {
      damage_mult = 1.35,
    },
  },
  {
    id = "hero_execute",
    name = "pattern.hero_execute.name",
    type = "attack",
    priority = 35,
    condition = "target_hp_below",
    condition_params = {
      threshold = 0.4,
    },
    cooldown = 2,
    params = {
      damage_mult = 1.6,
    },
  },
  {
    id = "hero_guard_wall",
    name = "pattern.hero_guard_wall.name",
    type = "defend",
    priority = 24,
    condition = "enemy_count_above",
    condition_params = {
      count = 1,
    },
    cooldown = 2,
    params = {
      defense_bonus = 5,
    },
  },
  {
    id = "hero_second_wind",
    name = "pattern.hero_second_wind.name",
    type = "heal",
    priority = 40,
    condition = "hp_below",
    condition_params = {
      threshold = 0.45,
    },
    cooldown = 3,
    params = {
      amount = 10,
    },
  },
  {
    id = "hero_steady_strike",
    name = "pattern.hero_steady_strike.name",
    type = "attack",
    priority = 8,
    condition = "always",
    cooldown = 1,
    params = {
      damage_mult = 1.15,
    },
  },
  {
    id = "hero_iron_barrier",
    name = "pattern.hero_iron_barrier.name",
    type = "defend",
    priority = 28,
    condition = "hp_below",
    condition_params = {
      threshold = 0.35,
    },
    cooldown = 3,
    params = {
      defense_bonus = 8,
    },
  },
}
