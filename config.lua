-- ==============================================================================
-- 👑 DJONSTNIX BRANDING
-- ==============================================================================
-- DEVELOPED BY: DjonStNix (DjonLuc)
-- GITHUB: https://github.com/Djonluc
-- DISCORD: https://discord.gg/s7GPUHWrS7
-- YOUTUBE: https://www.youtube.com/@Djonluc
-- EMAIL: djonstnix@gmail.com
-- LICENSE: MIT License (c) 2026 DjonStNix (DjonLuc)
-- ==============================================================================

Config = {}

-- ==============================================================================
-- DRUG TOXICITY VALUES
-- ==============================================================================
-- Define how much toxicity each drug adds when consumed.
-- If a drug is NOT listed here, Config.DrugValues.default is used.
-- You can add ANY drug name here — the system handles it automatically.
--
-- Risk tiers:
--   Low (3-5)    — weed/joints (smoked cannabis)
--   Medium (10-15) — cocaine, pills, oxy
--   High (20-25) — meth, crack, LSD
-- ==============================================================================
Config.DrugValues = {
    default = 5,            -- Fallback value for any unknown/unlisted drug

    -- Joints ( drugs/joints) — Low risk
    joint1 = 3,             -- Gelatti Joint
    joint2 = 3,             -- Gary Payton Joint
    joint3 = 3,             -- Cereal Milk Joint
    joint4 = 3,             -- Cheetah Piss Joint
    joint5 = 3,             -- Snow Man Joint
    joint6 = 3,             -- Georgia Pie Joint
    joint7 = 3,             -- El Jefe

    -- Weed products ( drugs) — Low risk
    ground_weed = 5,        -- Ground Weed
    weed_brick = 5,         -- Weed Brick (1KG)

    -- Weed baggies ( drugs/baggies) — Low risk
    weed_baggy = 5,         -- Bag of Weed

    -- Cocaine ( drugs) — Medium risk
    cokebaggy = 15,         -- Bag of Coke
    cocaine = 15,           -- Generic cocaine

    -- Crack ( drugs/baggies) — High risk
    crack_baggy = 20,       -- Bag of Crack

    -- Meth ( drugs/baggies) — High risk
    meth = 25,              -- Generic meth

    -- Pills / Oxy ( drugs) — Medium risk
    oxy = 10,               -- Oxycodone

    -- LSD ( drugs) — High risk
    lsdtab = 20,            -- LSD Tab

    -- XTC / Ecstasy ( drugs/baggies) — High risk
    xtc_baggy = 20,         -- Bag of XTC
}

-- ==============================================================================
-- TOXICITY DECAY
-- ==============================================================================
-- Controls how toxicity naturally decreases over time.
-- ==============================================================================
Config.Decay = {
    enabled = true,     -- Enable/disable automatic toxicity decay
    amount = 5,         -- How much toxicity decays per tick
    interval = 60000,   -- Interval between decay ticks (in ms) — 60 seconds
}

-- ==============================================================================
-- TOXICITY THRESHOLDS
-- ==============================================================================
-- When toxicity reaches or exceeds this value, an overdose is triggered.
-- ==============================================================================
Config.Thresholds = {
    overdose = 100,     -- Toxicity level that triggers an overdose
}

-- ==============================================================================
-- OVERDOSE BEHAVIOR
-- ==============================================================================
-- Toggle individual overdose effects on/off.
-- These are ONLY used when Config.External.useExternalEffects = false.
-- ==============================================================================
Config.Overdose = {
    killPlayer = true,  -- Kill the player on overdose
    ragdoll = true,     -- Ragdoll the player before death
    fadeScreen = true,  -- Fade the screen to black during overdose
    notify = true,      -- Send a notification to the player
}

-- ==============================================================================
-- AUTO-DETECTION
-- ==============================================================================
-- When enabled, scans item registries on resource start to find drug items.
--
-- Sources scanned:
--   1. QBCore.Shared.Items (always available)
--   2. ox_inventory items (if ox_inventory is running, via server export)
--
-- Any item whose name contains one of the keywords will be registered
-- with Config.DrugValues.default if it doesn't already have a config entry.
--
-- autoRegister: If true, detected drugs are added to the internal drug list.
--               If false, detection is skipped entirely.
-- ==============================================================================
Config.Detection = {
    enabled = true,                                                             -- Enable auto-detection
    autoRegister = true,                                                        -- Register detected drugs automatically
    keywords = {                                                                -- Keywords to match against item names
        "weed", "joint", "bud",                                                 -- Cannabis
        "coke", "cocaine",                                                      -- Cocaine
        "crack",                                                                -- Crack
        "meth",                                                                 -- Methamphetamine
        "drug",                                                                 -- Generic
        "lsd", "xtc", "ecstasy",                                                -- Party drugs
        "oxy", "opium", "heroin",                                               -- Opioids
        "baggy",                                                                -- Bagged drugs (cokebaggy, crack_baggy, etc.)
    },
}

-- ==============================================================================
-- EXTERNAL COMPATIBILITY
-- ==============================================================================
-- If useExternalEffects = true, the system fires the specified event
-- instead of running built-in overdose effects.
-- This allows other scripts to handle overdose visuals/effects.
-- ==============================================================================
Config.External = {
    useExternalEffects = false,                     -- Use external event instead of built-in effects
    overdoseEvent = "myEffects:overdose",           -- Event name to trigger on overdose
}

-- ==============================================================================
-- DEBUG
-- ==============================================================================
Config.Debug = false    -- Print debug messages to F8 / server console
