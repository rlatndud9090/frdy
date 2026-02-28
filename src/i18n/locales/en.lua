return {
  -- Locale self-name
  ["locale.self"] = "English",

  -- UI common
  ["ui.close"] = "Close",
  ["ui.full_map"] = "Full Map",
  ["ui.minimap"] = "Minimap",
  ["ui.end_turn"] = "End Turn",
  ["ui.select_next_path"] = "Select your next path",
  ["ui.path_prediction_hint"] = "Check the hero's predicted path and intervene with mind control if needed",
  ["ui.event_prediction_hint"] = "Check the hero's predicted choice and intervene with mind control if needed",
  ["ui.hero_predicted_path"] = "Hero predicted path: {label}",
  ["ui.hero_predicted_choice"] = "Hero predicted choice: {label}",
  ["ui.mental_stage"] = "Hero mental stage: {stage}/{max}",
  ["ui.close_hint"] = "Press M to close",
  ["ui.settings"] = "Settings",
  ["ui.language"] = "Language",

  -- Gauges
  ["gauge.suspicion"] = "Suspicion",
  ["gauge.mana"] = "Mana",
  ["gauge.hero_hp"] = "Hero HP: {current}/{max}",

  -- Combat
  ["combat.in_combat"] = "In Combat",
  ["combat.demon_lord_turn"] = "Demon Lord's Turn (Turn {turn})",
  ["combat.hero_turn"] = "Hero's Turn",
  ["combat.enemy_turn"] = "Enemy's Turn",
  ["combat.mana_display"] = "Mana: {current}/{max}",
  ["combat.hero_intent"] = "Hero: {desc} ({damage} dmg)",
  ["combat.demon_lord_used_spell"] = "Demon Lord used [{spell}]!",
  ["combat.hero_acts"] = "Hero acts!",
  ["combat.enemy_acts"] = "Enemy acts!",
  ["combat.demon_lord_turn_log"] = "--- Demon Lord's Turn (Turn {turn}) ---",
  ["combat.planning_phase"] = "Evil Eye Vision (Turn {turn})",
  ["combat.execution_phase"] = "Executing...",
  ["combat.planning_phase_log"] = "--- Evil Eye Vision (Turn {turn}) ---",
  ["combat.execution_start"] = "Execution begins!",
  ["combat.planning_reset"] = "Planning reset",
  ["combat.spell_placed"] = "[{spell}] placed",
  ["combat.suspicion_preview"] = "Suspicion change: {value}",
  ["combat.select_target"] = "Select action to manipulate",
  ["combat.select_destination"] = "Select swap destination",
  ["combat.select_insert_target"] = "Select a target",
  ["combat.select_insert_faction"] = "Select a faction target (hero/enemy)",
  ["combat.select_insert_timing"] = "Select intervention timing (between actions)",
  ["combat.back_hint"] = "Right click or ESC: go back",
  ["combat.no_valid_target"] = "No valid target: cancelled [{spell}] placement",
  ["combat.manipulate_applied"] = "[{spell}] manipulation applied!",
  ["combat.global_applied"] = "[{spell}] global effect applied!",
  ["combat.floor_cleared"] = "Floor cleared!",
  ["combat.defeat"] = "Defeat! Game Over",

  -- Entities
  ["entity.hero"] = "Hero",
  ["intent.attack"] = "Attack",
  ["intent.defense"] = "Defense",

  -- UI buttons
  ["ui.confirm"] = "Confirm",
  ["ui.reset"] = "Reset",

  -- Spell status
  ["spell.used"] = "Used",
  ["spell.reserved"] = "Placed",
  ["spell.statuses"] = "Statuses",
  ["spell.keywords"] = "Keywords",
  ["spell.no_keyword"] = "No keywords",
  ["spell.suspicion_per_action"] = "susp: ±{value}/act",

  -- Spell tabs
  ["spell.tab.all"] = "All",
  ["spell.tab.insert"] = "Insert",

  -- Spell descriptions
  ["spell.desc.heal_light"] = "Heal target for {amount} HP.",
  ["spell.desc.heal_heavy"] = "Heal target for {amount} HP.",
  ["spell.desc.divine_strike"] = "Deal {amount} damage to target.",
  ["spell.desc.war_cry"] = "Increase a faction's attack by {amount}.",
  ["spell.desc.haste_sigil"] = "Increase target speed by {amount}.",
  ["spell.desc.crippling_hex"] = "Reduce target speed by {amount}.",
  ["spell.desc.stumble"] = "Deal {amount} damage to target.",
  ["spell.desc.weaken_foe"] = "Reduce a faction's attack by {amount}.",
  ["spell.desc.dark_pact"] = "Deal {amount} damage to target.",
  ["spell.desc.minor_heal"] = "Heal target for {amount} HP.",
  ["spell.desc.time_warp"] = "Increase a faction's speed by {amount}.",
  ["spell.desc.nullify"] = "Block the next {count} action(s).",
  ["spell.desc.delay_strike"] = "Reduce a faction's speed by {amount}.",
  ["spell.desc.weaken_blow"] = "Reduce the next {count} action values by {amount_abs}.",
  ["spell.desc.empower_strike"] = "Increase the next {count} action values by {amount}.",
  ["spell.desc.chaos_field"] = "Reduce all following action values by {amount_abs}.",
  ["spell.desc.dark_blessing"] = "Increase all following action values by {amount}.",

  -- Spell keywords
  ["spell.keyword.char_single.title"] = "Single",
  ["spell.keyword.char_single.description"] = "Targets one character.",
  ["spell.keyword.char_faction.title"] = "Faction",
  ["spell.keyword.char_faction.description"] = "Targets either the hero side or all enemies.",
  ["spell.keyword.char_all.title"] = "All",
  ["spell.keyword.char_all.description"] = "Targets the hero and all enemies.",
  ["spell.keyword.next_n.title"] = "Next N Actions",
  ["spell.keyword.next_n.description"] = "Affects the next N actions after insertion timing.",
  ["spell.keyword.next_all.title"] = "All Following Actions",
  ["spell.keyword.next_all.description"] = "Affects every action after insertion timing.",
  ["spell.keyword.block.title"] = "Block",
  ["spell.keyword.block.description"] = "The action is attempted but its effect does not resolve.",
  ["spell.keyword.speed.title"] = "Speed",
  ["spell.keyword.speed.description"] = "Speed changes alter turn-order prediction in following turns.",
  ["spell.keyword.action_value.title"] = "Action Value",
  ["spell.keyword.action_value.description"] = "Modifies the value of targeted actions (damage/defense/heal).",

  -- Statuses
  ["status.attack_up_flat.title"] = "Empower",
  ["status.attack_up_flat.description"] = "Attack increases by {amount}.",
  ["status.attack_down_flat.title"] = "Weakened",
  ["status.attack_down_flat.description"] = "Attack decreases by {amount}.",
  ["status.speed_up_flat.title"] = "Haste",
  ["status.speed_up_flat.description"] = "Speed increases by {amount}.",
  ["status.speed_down_flat.title"] = "Slow",
  ["status.speed_down_flat.description"] = "Speed decreases by {amount}.",
  ["status.weaken.title"] = "Frailty",
  ["status.weaken.description"] = "Attack is reduced by {ratio_percent}%.",
  ["status.haste.title"] = "Quickened",
  ["status.haste.description"] = "Speed increases by {amount}.",
  ["status.berserker.title"] = "Berserker",
  ["status.berserker.description"] = "Gain {amount} attack whenever damaged.",
  ["status.floating_thorns.title"] = "Floating Thorns",
  ["status.floating_thorns.description"] = "After any action, all characters take {amount} damage.",

  -- Suspicion
  ["suspicion.increase"] = "Suspicion +{value}",
  ["suspicion.decrease"] = "Suspicion {value}",

  -- Mind control
  ["control.blocked_by_mental"] = "Mind control blocked ({stage} / allowed up to {max})",
  ["control.path_intervened"] = "Path changed by mind control",
  ["control.event_intervened"] = "Choice changed by mind control",
  ["control.selection_reset"] = "Reverted to hero's original choice",

  -- Enemies
  ["enemy.slime"] = "Slime",
  ["enemy.goblin"] = "Goblin",
  ["enemy.skeleton"] = "Skeleton",
  ["enemy.wolf"] = "Wolf",
  ["enemy.dark_knight"] = "Dark Knight",

  -- Edge types
  ["node.combat"] = "Combat",
  ["node.event"] = "Event",

  -- Events
  ["event.mysterious_spring.title"] = "Mysterious Spring",
  ["event.mysterious_spring.description"] = "Deep in the forest, you discover a spring glowing with silver light. An unknown energy emanates from the clear water.",
  ["event.mysterious_spring.choice1"] = "Drink from the spring",
  ["event.mysterious_spring.choice2"] = "Ignore and move on",
  ["event.mysterious_spring.choice3"] = "Dip your hand in the spring",

  ["event.wandering_merchant.title"] = "Wandering Merchant",
  ["event.wandering_merchant.description"] = "A merchant in a tattered coat has set up shop by the roadside. Suspicious, but the goods look useful.",
  ["event.wandering_merchant.choice1"] = "Purchase goods",
  ["event.wandering_merchant.choice2"] = "Pass by",

  ["event.trapped_chest.title"] = "Trapped Chest",
  ["event.trapped_chest.description"] = "A mossy chest sits by the path. Fine threads seem to be connected around the lock.",
  ["event.trapped_chest.choice1"] = "Carefully disarm the trap",
  ["event.trapped_chest.choice2"] = "Leave it alone",
  ["event.trapped_chest.choice3"] = "Throw a stone from afar",

  ["event.old_hermit.title"] = "Hermit's Cabin",
  ["event.old_hermit.description"] = "Deep in the forest, a white-haired elder tends herbs in a small cabin. They gaze at you with gentle eyes.",
  ["event.old_hermit.choice1"] = "Ask for healing",
  ["event.old_hermit.choice2"] = "Greet and move on",

  ["event.dark_altar.title"] = "Dark Altar",
  ["event.dark_altar.description"] = "An altar of black stone emanates an ominous aura. A purple crystal glows faintly atop it.",
  ["event.dark_altar.choice1"] = "Absorb the crystal's power",
  ["event.dark_altar.choice2"] = "Destroy the altar",
  ["event.dark_altar.choice3"] = "Leave without touching it",
}
