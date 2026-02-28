local SpellEffect = require('src.spell.spell_effect')

return {
  {
    id = "heal_light",
    name = "Light Heal",
    description = "Heal target for 10 HP.",
    desc_key = "spell.desc.heal_light",
    cost = 12,
    suspicion_abs = 4,
    timeline_type = "insert",
    target_mode = "char_single",
    effect = SpellEffect.heal(10)
  },
  {
    id = "heal_heavy",
    name = "Heavy Heal",
    description = "Heal target for 22 HP.",
    desc_key = "spell.desc.heal_heavy",
    cost = 22,
    suspicion_abs = 8,
    timeline_type = "insert",
    target_mode = "char_single",
    effect = SpellEffect.heal(22)
  },
  {
    id = "divine_strike",
    name = "Divine Strike",
    description = "Deal 14 damage to target.",
    desc_key = "spell.desc.divine_strike",
    cost = 16,
    suspicion_abs = 6,
    timeline_type = "insert",
    target_mode = "char_single",
    effect = SpellEffect.damage(14)
  },
  {
    id = "war_cry",
    name = "War Cry",
    description = "Buff a faction's attack by 2.",
    desc_key = "spell.desc.war_cry",
    cost = 14,
    suspicion_abs = 5,
    timeline_type = "insert",
    target_mode = "char_faction",
    effect = SpellEffect.buff_attack(2)
  },
  {
    id = "haste_sigil",
    name = "Haste Sigil",
    description = "Increase target speed by 4.",
    desc_key = "spell.desc.haste_sigil",
    cost = 9,
    suspicion_abs = 4,
    timeline_type = "insert",
    target_mode = "char_single",
    effect = SpellEffect.buff_speed(4)
  },
  {
    id = "crippling_hex",
    name = "Crippling Hex",
    description = "Reduce target speed by 4.",
    desc_key = "spell.desc.crippling_hex",
    cost = 9,
    suspicion_abs = 3,
    timeline_type = "insert",
    target_mode = "char_single",
    effect = SpellEffect.debuff_speed(4)
  },
  {
    id = "stumble",
    name = "Stumble",
    description = "Deal 5 damage to target.",
    desc_key = "spell.desc.stumble",
    cost = 0,
    suspicion_abs = 6,
    timeline_type = "insert",
    target_mode = "char_single",
    effect = SpellEffect.hinder(5)
  },
  {
    id = "weaken_foe",
    name = "Weaken Foe",
    description = "Debuff a faction's attack by 2.",
    desc_key = "spell.desc.weaken_foe",
    cost = 11,
    suspicion_abs = 3,
    timeline_type = "insert",
    target_mode = "char_faction",
    effect = SpellEffect.debuff_attack(2)
  },
  {
    id = "dark_pact",
    name = "Dark Pact",
    description = "Deal 10 damage to target.",
    desc_key = "spell.desc.dark_pact",
    cost = 8,
    suspicion_abs = 12,
    timeline_type = "insert",
    target_mode = "char_single",
    effect = SpellEffect.hinder(10)
  },
  {
    id = "minor_heal",
    name = "Minor Heal",
    description = "Heal target for 5 HP.",
    desc_key = "spell.desc.minor_heal",
    cost = 0,
    suspicion_abs = 2,
    timeline_type = "insert",
    target_mode = "char_single",
    effect = SpellEffect.heal(5)
  },
  -- Insert spells: action-target variants
  {
    id = "time_warp",
    name = "Time Warp",
    description = "Increase a faction's speed by 3.",
    desc_key = "spell.desc.time_warp",
    cost = 17,
    suspicion_abs = 7,
    timeline_type = "insert",
    target_mode = "char_faction",
    effect = SpellEffect.buff_speed(3)
  },
  {
    id = "nullify",
    name = "Nullify",
    description = "Block the next action once.",
    desc_key = "spell.desc.nullify",
    cost = 22,
    suspicion_abs = 9,
    timeline_type = "insert",
    target_mode = "action_next_n",
    target_n = 1,
    effect = SpellEffect.action_block(1)
  },
  {
    id = "delay_strike",
    name = "Delay Strike",
    description = "Reduce a faction's speed by 3.",
    desc_key = "spell.desc.delay_strike",
    cost = 12,
    suspicion_abs = 5,
    timeline_type = "insert",
    target_mode = "char_faction",
    effect = SpellEffect.debuff_speed(3)
  },
  {
    id = "weaken_blow",
    name = "Weaken Blow",
    description = "Reduce the next 2 action values by 3.",
    desc_key = "spell.desc.weaken_blow",
    cost = 14,
    suspicion_abs = 5,
    timeline_type = "insert",
    target_mode = "action_next_n",
    target_n = 2,
    effect = SpellEffect.action_delta(-3)
  },
  {
    id = "empower_strike",
    name = "Empower Strike",
    description = "Increase the next 2 action values by 3.",
    desc_key = "spell.desc.empower_strike",
    cost = 18,
    suspicion_abs = 7,
    timeline_type = "insert",
    target_mode = "action_next_n",
    target_n = 2,
    effect = SpellEffect.action_delta(3)
  },
  -- Insert spells: all following actions
  {
    id = "chaos_field",
    name = "Chaos Field",
    description = "Reduce all following action values by 2.",
    desc_key = "spell.desc.chaos_field",
    cost = 23,
    suspicion_abs = 6,
    timeline_type = "insert",
    target_mode = "action_next_all",
    effect = SpellEffect.action_delta(-2)
  },
  {
    id = "dark_blessing",
    name = "Dark Blessing",
    description = "Increase all following action values by 2.",
    desc_key = "spell.desc.dark_blessing",
    cost = 28,
    suspicion_abs = 9,
    timeline_type = "insert",
    target_mode = "action_next_all",
    effect = SpellEffect.action_delta(2)
  }
}
