return {
  {
    id = "mysterious_spring",
    title = "event.mysterious_spring.title",
    description = "event.mysterious_spring.description",
    intervention = {
      max_mental_stage = 4,
      mental_increase = 0.25,
    },
    choices = {
      {
        text = "event.mysterious_spring.choice1",
        effects = {
          {type = "heal_hero", amount = 20},
          {type = "grant_hero_exp", amount = 35},
        },
      },
      {
        text = "event.mysterious_spring.choice2",
        effects = {
          {type = "grant_reward_offer", category = "hero_pattern", count = 1},
        },
      },
      {
        text = "event.mysterious_spring.choice3",
        effects = {
          {type = "damage_hero", amount = 10},
          {type = "remove_owned_reward", category = "hero_pattern", count = 1, mode = "random"},
        },
      },
    },
  },
  {
    id = "wandering_merchant",
    title = "event.wandering_merchant.title",
    description = "event.wandering_merchant.description",
    intervention = {
      max_mental_stage = 3,
      mental_increase = 0.35,
    },
    choices = {
      {
        text = "event.wandering_merchant.choice1",
        effects = {
          {type = "buff_attack", amount = 2},
          {type = "grant_reward_offer", category = "demon_spell", count = 1},
        },
      },
      {
        text = "event.wandering_merchant.choice2",
        effects = {
          {type = "grant_hero_exp", amount = 20},
        },
      },
    },
  },
  {
    id = "trapped_chest",
    title = "event.trapped_chest.title",
    description = "event.trapped_chest.description",
    intervention = {
      max_mental_stage = 3,
      mental_increase = 0.4,
    },
    choices = {
      {
        text = "event.trapped_chest.choice1",
        effects = {
          {type = "buff_attack", amount = 4},
          {type = "grant_reward_offer", category = "legendary_item", count = 1},
        },
      },
      {
        text = "event.trapped_chest.choice2",
        effects = {
          {type = "grant_hero_exp", amount = 15},
        },
      },
      {
        text = "event.trapped_chest.choice3",
        effects = {
          {type = "damage_hero", amount = 5},
          {type = "remove_owned_reward", category = "legendary_item", count = 1, mode = "random"},
        },
      },
    },
  },
  {
    id = "old_hermit",
    title = "event.old_hermit.title",
    description = "event.old_hermit.description",
    intervention = {
      max_mental_stage = 5,
      mental_increase = 0.2,
    },
    choices = {
      {
        text = "event.old_hermit.choice1",
        effects = {
          {type = "heal_hero", amount = 30},
          {type = "grant_hero_exp", amount = 25},
        },
      },
      {
        text = "event.old_hermit.choice2",
        effects = {
          {type = "grant_reward_offer", category = "hero_pattern", count = 1},
        },
      },
    },
  },
  {
    id = "dark_altar",
    title = "event.dark_altar.title",
    description = "event.dark_altar.description",
    intervention = {
      max_mental_stage = 2,
      mental_increase = 0.5,
    },
    choices = {
      {
        text = "event.dark_altar.choice1",
        effects = {
          {type = "buff_attack", amount = 8},
          {type = "damage_hero", amount = 15},
          {type = "grant_reward_offer", category = "demon_spell", count = 1},
        },
      },
      {
        text = "event.dark_altar.choice2",
        effects = {
          {type = "damage_hero", amount = 5},
          {type = "grant_reward_offer", category = "legendary_item", count = 1},
        },
      },
      {
        text = "event.dark_altar.choice3",
        effects = {
          {type = "remove_owned_reward", category = "demon_spell", count = 1, mode = "random"},
          {type = "grant_hero_exp", amount = 30},
        },
      },
    },
  },
}
