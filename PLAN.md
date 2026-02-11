# Plan: Fix Korean Text Rendering + i18n Architecture

## Problem
- Love2D's default font (8px bitmap) does NOT support Korean (Hangul) glyphs
- All Korean text renders as blank/broken characters at runtime
- All UI strings are hardcoded in Korean throughout the codebase
- No i18n infrastructure exists

## Solution Overview
3 phases: (1) Add Korean-capable font, (2) Build i18n module + convert all strings to English default, (3) Add Korean as secondary locale

---

## Phase 1: Font Setup

### 1.1 Download Noto Sans KR font (SIL OFL license, free for commercial use)
- Add `assets/fonts/NotoSansKR-Regular.ttf` to the project
- This font covers all 11,172 modern Hangul syllables + Latin

### 1.2 Create a font manager module `src/core/font_manager.lua`
- Load the font once in `love.load()` via `love.graphics.newFont()`
- Set as global default font with `love.graphics.setFont()`
- Provide multiple sizes (small=12, medium=16, large=20, title=24)

### 1.3 Initialize font in `main.lua` → `love.load()`
- Load font before `Game:init()` so all UI uses it

---

## Phase 2: i18n Module + Convert to English Default

### 2.1 Create `src/i18n/init.lua` - Core i18n module
Simple Lua-table approach (no external dependencies):
```lua
local i18n = {}
local current_locale = "en"
local strings = {}

function i18n.load(locale, data)
  strings[locale] = data
end

function i18n.set_locale(locale)
  current_locale = locale
end

function i18n.t(key)
  local locale_strings = strings[current_locale]
  if locale_strings and locale_strings[key] then
    return locale_strings[key]
  end
  -- Fallback to English
  if strings["en"] and strings["en"][key] then
    return strings["en"][key]
  end
  return key  -- Return key itself as last resort
end
```

### 2.2 Create locale files
- `src/i18n/locales/en.lua` - English strings (DEFAULT)
- `src/i18n/locales/ko.lua` - Korean strings (secondary)

### 2.3 String key structure (flat, dot-notation convention):
```
ui.close, ui.full_map, ui.minimap, ui.end_turn
ui.select_next_path, ui.close_hint
gauge.suspicion, gauge.mana, gauge.hero_hp
combat.in_combat, combat.demon_lord_turn, combat.hero_turn, combat.enemy_turn
combat.mana_display, combat.hero_intent, combat.demon_lord_used_card
combat.hero_acts, combat.enemy_acts, combat.demon_lord_turn_log
combat.floor_cleared, combat.defeat
entity.hero, intent.attack, intent.defense
suspicion.increase, suspicion.decrease
enemy.slime, enemy.goblin, enemy.skeleton, enemy.wolf, enemy.dark_knight
event.mysterious_spring.title, event.mysterious_spring.description, ...
event.mysterious_spring.choice1, event.mysterious_spring.choice2, ...
(same pattern for all 5 events)
```

### 2.4 Replace all hardcoded strings in source files
Files to modify:
- `conf.lua` - window title
- `src/scene/game_scene.lua` - gauge labels, HP display
- `src/handler/combat_handler.lua` - turn text, mana display, combat log
- `src/handler/edge_select_handler.lua` - instruction text
- `src/handler/event_handler.lua` - suspicion display
- `src/ui/map_overlay.lua` - title, close button, hint text
- `src/ui/minimap.lua` - minimap label
- `src/ui/edge_selector.lua` - combat/event labels
- `src/ui/card_hand.lua` - suspicion display
- `src/combat/hero.lua` - hero name, attack intent
- `src/combat/enemy.lua` - attack/defense intents
- `data/enemies/floor1_enemies.lua` - enemy names → use i18n keys
- `data/events/floor1_events.lua` - event titles, descriptions, choices → use i18n keys

### 2.5 Initialize i18n in `main.lua`
- Load both locale files
- Set default locale to "en"

---

## Phase 3: Settings Overlay + Language Dropdown

### 3.1 Create `src/ui/dropdown.lua` - Reusable dropdown UI component
- Displays current selection as a button
- On click, expands to show options list
- On option click, fires callback with selected value and collapses
- Supports arbitrary key-label pairs (e.g., `{key="en", label="English"}`)

### 3.2 Create `src/ui/settings_overlay.lua` - Settings overlay
- Full-screen overlay (similar pattern to MapOverlay)
- Fade-in/out animation
- Title: "Settings" (i18n key: `ui.settings`)
- Contains: Language dropdown (`ui.language` label)
- Close button + ESC key to close
- Toggle via `Tab` key in GameScene

### 3.3 Integrate into GameScene
- Add `settings_overlay` field to GameScene
- `Tab` key toggles settings overlay
- Settings overlay takes input priority when open (like MapOverlay)
- Language change via dropdown calls `i18n.set_locale()` → immediate effect

### 3.4 Add i18n keys for settings UI
```
ui.settings, ui.language
locale.en ("English"), locale.ko ("한국어")
```

---

## Phase 4: Future-Proof Architecture Notes

The i18n module design supports:
- **Adding new languages**: Just create a new locale file (e.g., `ja.lua`) + add entry to dropdown
- **Interpolation**: `i18n.t("combat.mana_display", {current=3, max=5})` → "Mana: 3/5"
- **Locale switching at runtime**: `i18n.set_locale("ko")` via settings dropdown
- **Fallback chain**: requested locale → "en" → raw key
- **Data-driven content**: Enemy names, event text etc. use i18n keys, so game data files stay language-agnostic
