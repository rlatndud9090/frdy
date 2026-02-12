local SpellEffect = require('src.spell.spell_effect')

return {
  {
    id = "heal_light",
    name = "Light Heal",
    description = "Heal the hero for 10 HP.",
    cost = 1,
    suspicion_delta = 5,
    effect = SpellEffect.heal(10)
  },
  {
    id = "heal_heavy",
    name = "Heavy Heal",
    description = "Heal the hero for 25 HP.",
    cost = 2,
    suspicion_delta = 10,
    effect = SpellEffect.heal(25)
  },
  {
    id = "divine_strike",
    name = "Divine Strike",
    description = "Deal 15 damage to an enemy.",
    cost = 2,
    suspicion_delta = 8,
    effect = SpellEffect.damage(15)
  },
  {
    id = "war_cry",
    name = "War Cry",
    description = "Buff hero attack by 3.",
    cost = 1,
    suspicion_delta = 6,
    effect = SpellEffect.buff_attack(3)
  },
  {
    id = "stumble",
    name = "Stumble",
    description = "Hinder the hero for 5 damage.",
    cost = 0,
    suspicion_delta = -8,
    effect = SpellEffect.hinder(5)
  },
  {
    id = "weaken_foe",
    name = "Weaken Foe",
    description = "Debuff enemy attack by 3.",
    cost = 1,
    suspicion_delta = 3,
    effect = SpellEffect.debuff_attack(3)
  },
  {
    id = "dark_pact",
    name = "Dark Pact",
    description = "Hinder the hero for 10 damage.",
    cost = 1,
    suspicion_delta = -15,
    effect = SpellEffect.hinder(10)
  },
  {
    id = "minor_heal",
    name = "Minor Heal",
    description = "Heal the hero for 5 HP.",
    cost = 0,
    suspicion_delta = 3,
    effect = SpellEffect.heal(5)
  }
}
