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
        },
        suspicion_delta = 5,
        intervention_suspicion_delta = 6,
      },
      {
        text = "event.mysterious_spring.choice2",
        effects = {},
        suspicion_delta = 0,
        intervention_suspicion_delta = -1,
      },
      {
        text = "event.mysterious_spring.choice3",
        effects = {
          {type = "damage_hero", amount = 10},
        },
        suspicion_delta = -5,
        intervention_suspicion_delta = -4,
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
          {type = "buff_attack", amount = 3},
        },
        suspicion_delta = 10,
        intervention_suspicion_delta = 8,
      },
      {
        text = "event.wandering_merchant.choice2",
        effects = {},
        suspicion_delta = 0,
        intervention_suspicion_delta = -3,
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
          {type = "buff_attack", amount = 5},
        },
        suspicion_delta = 15,
        intervention_suspicion_delta = 10,
      },
      {
        text = "event.trapped_chest.choice2",
        effects = {},
        suspicion_delta = 0,
        intervention_suspicion_delta = -2,
      },
      {
        text = "event.trapped_chest.choice3",
        effects = {
          {type = "damage_hero", amount = 5},
        },
        suspicion_delta = -3,
        intervention_suspicion_delta = -3,
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
        },
        suspicion_delta = 10,
        intervention_suspicion_delta = 7,
      },
      {
        text = "event.old_hermit.choice2",
        effects = {},
        suspicion_delta = -5,
        intervention_suspicion_delta = -4,
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
        },
        suspicion_delta = 20,
        intervention_suspicion_delta = 5,
      },
      {
        text = "event.dark_altar.choice2",
        effects = {
          {type = "damage_hero", amount = 5},
        },
        suspicion_delta = -10,
        intervention_suspicion_delta = -5,
      },
      {
        text = "event.dark_altar.choice3",
        effects = {},
        suspicion_delta = 0,
        intervention_suspicion_delta = -2,
      },
    },
  },
}
