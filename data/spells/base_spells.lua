local SpellEffect = require('src.spell.spell_effect')

---@param path string
---@param value number
---@param min number|nil
---@param round string|nil
---@return table
local function patch_add(path, value, min, round)
  local patch = {
    path = path,
    mode = "add",
    value = value,
  }
  if min ~= nil then
    patch.min = min
  end
  if round then
    patch.round = round
  end
  return patch
end

---@param path string
---@param value number
---@return table
local function patch_signed(path, value)
  return {
    path = path,
    mode = "signed_add",
    value = value,
  }
end

---@param patches table[]
---@param max_rank number|nil
---@return table
local function make_upgrade(patches, max_rank)
  return {
    max_rank = max_rank or 5,
    patches = patches,
  }
end

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
    effect = SpellEffect.heal(10),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 2),
    })
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
    effect = SpellEffect.heal(22),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 3),
    })
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
    effect = SpellEffect.damage(14),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 2),
    })
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
    effect = SpellEffect.apply_status("attack_up_flat", {
      payload = {attack_bonus = 2},
      preview_amount = 2,
    }),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 1),
      patch_add("effect.status_spec.preview_amount", 1),
      patch_add("effect.status_spec.payload.attack_bonus", 1),
    })
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
    effect = SpellEffect.apply_status("speed_up_flat", {
      payload = {speed_bonus = 4},
      preview_amount = 4,
    }),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 1),
      patch_add("effect.status_spec.preview_amount", 1),
      patch_add("effect.status_spec.payload.speed_bonus", 1),
    })
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
    effect = SpellEffect.apply_status("speed_down_flat", {
      payload = {speed_penalty = 4},
      preview_amount = 4,
    }),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 1),
      patch_add("effect.status_spec.preview_amount", 1),
      patch_add("effect.status_spec.payload.speed_penalty", 1),
    })
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
    effect = SpellEffect.hinder(5),
    upgrade = make_upgrade({
      patch_add("effect.amount", 1),
    })
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
    effect = SpellEffect.apply_status("attack_down_flat", {
      payload = {attack_penalty = 2},
      preview_amount = 2,
    }),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 1),
      patch_add("effect.status_spec.preview_amount", 1),
      patch_add("effect.status_spec.payload.attack_penalty", 1),
    })
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
    effect = SpellEffect.hinder(10),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 2),
    })
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
    effect = SpellEffect.heal(5),
    upgrade = make_upgrade({
      patch_add("effect.amount", 1),
    })
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
    effect = SpellEffect.apply_status("speed_up_flat", {
      payload = {speed_bonus = 3},
      preview_amount = 3,
    }),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 1),
      patch_add("effect.status_spec.preview_amount", 1),
      patch_add("effect.status_spec.payload.speed_bonus", 1),
    })
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
    effect = SpellEffect.action_block(1),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("target_n", 1, 1, "floor"),
      patch_add("effect.amount", 1, 1, "floor"),
    })
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
    effect = SpellEffect.apply_status("speed_down_flat", {
      payload = {speed_penalty = 3},
      preview_amount = 3,
    }),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_add("effect.amount", 1),
      patch_add("effect.status_spec.preview_amount", 1),
      patch_add("effect.status_spec.payload.speed_penalty", 1),
    })
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
    effect = SpellEffect.action_delta(-3),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_signed("effect.amount", 1),
    })
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
    effect = SpellEffect.action_delta(3),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_signed("effect.amount", 1),
    })
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
    effect = SpellEffect.action_delta(-2),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_signed("effect.amount", 1),
    })
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
    effect = SpellEffect.action_delta(2),
    upgrade = make_upgrade({
      patch_add("cost", -1, 0),
      patch_signed("effect.amount", 1),
    })
  }
}
