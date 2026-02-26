local SpellEffect = require('src.spell.spell_effect')

return {
  {
    id = "heal_light",
    name = "Light Heal",
    description = "Heal the hero for 10 HP.",
    cost = 15,
    suspicion_delta = 5,
    timeline_type = "insert",
    effect = SpellEffect.heal(10)
  },
  {
    id = "heal_heavy",
    name = "Heavy Heal",
    description = "Heal the hero for 25 HP.",
    cost = 25,
    suspicion_delta = 10,
    timeline_type = "insert",
    effect = SpellEffect.heal(25)
  },
  {
    id = "divine_strike",
    name = "Divine Strike",
    description = "Deal 15 damage to an enemy.",
    cost = 20,
    suspicion_delta = 8,
    timeline_type = "insert",
    effect = SpellEffect.damage(15)
  },
  {
    id = "war_cry",
    name = "War Cry",
    description = "Buff hero attack by 3.",
    cost = 15,
    suspicion_delta = 6,
    timeline_type = "insert",
    effect = SpellEffect.buff_attack(3)
  },
  {
    id = "haste_sigil",
    name = "Haste Sigil",
    description = "Increase target speed by 5.",
    cost = 10,
    suspicion_delta = 4,
    timeline_type = "insert",
    effect = SpellEffect.buff_speed(5)
  },
  {
    id = "crippling_hex",
    name = "Crippling Hex",
    description = "Reduce enemy speed by 4.",
    cost = 10,
    suspicion_delta = 3,
    timeline_type = "insert",
    effect = SpellEffect.debuff_speed(4)
  },
  {
    id = "stumble",
    name = "Stumble",
    description = "Hinder the hero for 5 damage.",
    cost = 0,
    suspicion_delta = -8,
    timeline_type = "insert",
    effect = SpellEffect.hinder(5)
  },
  {
    id = "weaken_foe",
    name = "Weaken Foe",
    description = "Debuff enemy attack by 3.",
    cost = 12,
    suspicion_delta = 3,
    timeline_type = "insert",
    effect = SpellEffect.debuff_attack(3)
  },
  {
    id = "dark_pact",
    name = "Dark Pact",
    description = "Hinder the hero for 10 damage.",
    cost = 10,
    suspicion_delta = -15,
    timeline_type = "insert",
    effect = SpellEffect.hinder(10)
  },
  {
    id = "minor_heal",
    name = "Minor Heal",
    description = "Heal the hero for 5 HP.",
    cost = 0,
    suspicion_delta = 3,
    timeline_type = "insert",
    effect = SpellEffect.heal(5)
  },
  -- Manipulation spells
  {
    id = "time_warp",
    name = "Time Warp",
    description = "Swap two actions on the timeline.",
    cost = 20,
    suspicion_delta = 8,
    timeline_type = "manipulate_swap",
    effect = SpellEffect.swap()
  },
  {
    id = "nullify",
    name = "Nullify",
    description = "Remove an action from the timeline.",
    cost = 30,
    suspicion_delta = 12,
    timeline_type = "manipulate_remove",
    effect = SpellEffect.nullify()
  },
  {
    id = "delay_strike",
    name = "Delay Strike",
    description = "Push an action back by 2 positions.",
    cost = 12,
    suspicion_delta = 5,
    timeline_type = "manipulate_delay",
    effect = SpellEffect.delay(2)
  },
  {
    id = "weaken_blow",
    name = "Weaken Blow",
    description = "Reduce an action's damage by 5.",
    cost = 12,
    suspicion_delta = 4,
    timeline_type = "manipulate_modify",
    effect = SpellEffect.modify(-5)
  },
  {
    id = "empower_strike",
    name = "Empower Strike",
    description = "Increase an action's damage by 5.",
    cost = 20,
    suspicion_delta = 7,
    timeline_type = "manipulate_modify",
    effect = SpellEffect.modify(5)
  },
  -- Global spells
  {
    id = "chaos_field",
    name = "Chaos Field",
    description = "Apply chaos to the entire timeline.",
    cost = 25,
    suspicion_delta = 7,
    timeline_type = "global",
    effect = SpellEffect.global_buff(2)
  },
  {
    id = "dark_blessing",
    name = "Dark Blessing",
    description = "Bless all hero actions on the timeline.",
    cost = 15,
    suspicion_delta = 4,
    timeline_type = "global",
    effect = SpellEffect.global_buff(1)
  }
}
