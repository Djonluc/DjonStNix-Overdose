# DjonStNix-Overdose

Lightweight, fully configurable drug overdose system for FiveM QBCore servers.

---

## Installation

1. Place `DjonStNix-Overdose` in your resources folder
2. Add `ensure DjonStNix-Overdose` to your `server.cfg` (after `qb-core`)
3. Configure `config.lua` to your liking
4. Restart your server

---

## How It Works

1. **On startup**, the system scans `QBCore.Shared.Items` and `ox_inventory` items for drug keywords
2. **When a player uses an item**, the system auto-detects if it's a drug and adds toxicity
3. **Toxicity decays** naturally over time based on config
4. **When toxicity hits the threshold**, an overdose is triggered

**No manual setup needed for most servers** — drugs are detected automatically.

---

## Auto-Hook (Zero Config)

The system automatically hooks into item use events:

| Inventory System | Event Hooked |
|---|---|
| QBCore / qb-inventory | `QBCore:Client:OnUseItem` |
| ox_inventory | `ox_inventory:usedItem` |

When a player uses a detected drug item, toxicity is added **automatically**. No code changes needed in your drug scripts.

---

## Manual Integration

If auto-hook doesn't cover your use case, trigger manually from **client-side**:

### Export (Recommended)
```lua
exports['DjonStNix-Overdose']:AddDrugUse('cocaine')
```

### Event
```lua
TriggerEvent('DjonStNix-Overdose:addDrugUse', 'cocaine')
```

Both accept **any string** as the drug name. If the drug is in `Config.DrugValues`, that value is used. Otherwise, `Config.DrugValues.default` is applied.

---

## Utility Exports

```lua
-- Read current toxicity
local tox = exports['DjonStNix-Overdose']:GetToxicity()

-- Force reset toxicity
exports['DjonStNix-Overdose']:ResetToxicity()

-- Check if an item is recognized as a drug
local isDrug = exports['DjonStNix-Overdose']:IsDrug('weed_joint')

-- Server-side: get all detected drugs
local drugs = exports['DjonStNix-Overdose']:GetDetectedDrugs()
```

---

## External Effects

If you have another script that handles overdose effects, set:

```lua
Config.External = {
    useExternalEffects = true,
    overdoseEvent = "yourScript:overdoseTriggered"
}
```

The system fires that event instead of built-in effects. Your script listens:

```lua
RegisterNetEvent('yourScript:overdoseTriggered', function()
    -- Your custom overdose effects here
end)
```

---

## Configuration Reference

| Config Key | Purpose |
|---|---|
| `Config.DrugValues` | Toxicity per drug + default fallback |
| `Config.Decay` | Auto-decay settings (enabled, amount, interval) |
| `Config.Thresholds` | Overdose trigger threshold |
| `Config.Overdose` | Toggle kill, ragdoll, fade, notify |
| `Config.Detection` | Auto-detect drugs from QBCore + ox_inventory |
| `Config.External` | Defer overdose to external scripts |
| `Config.Debug` | Print debug logs to F8 / server console |

---

## File Structure

```
DjonStNix-Overdose/
├── config.lua       -- All configuration
├── client.lua       -- Toxicity tracking, effects, auto-hooks
├── server.lua       -- Server-side drug detection (ox_inventory)
├── fxmanifest.lua   -- Resource manifest
└── README.md        -- This file
```
