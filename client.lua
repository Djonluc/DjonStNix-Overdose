-- ==============================================================================
-- 👑 DJONSTNIX OVERDOSE SYSTEM — CLIENT
-- ==============================================================================
-- Lightweight, config-driven drug overdose system.
-- Tracks per-player toxicity, supports any drug dynamically,
-- and handles overdose effects based on config toggles.
--
-- Integration methods:
--   1. Export:  exports['DjonStNix-Overdose']:AddDrugUse('cocaine')
--   2. Event:  TriggerEvent('DjonStNix-Overdose:addDrugUse', 'cocaine')
--   3. Auto:   Hooks into QBCore item use events for detected drugs
-- ==============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ==============================================================================
-- STATE
-- ==============================================================================
local toxicity = 0              -- Current toxicity level (0–max)
local isOverdosing = false      -- Prevent re-triggering during overdose
local detectedDrugs = {}        -- Auto-detected drugs (received from server + local scan)

-- ==============================================================================
-- DEBUG HELPER
-- ==============================================================================
local function DebugPrint(...)
    if Config.Debug then
        print('[DjonStNix-Overdose]', ...)
    end
end

-- ==============================================================================
-- KEYWORD MATCH CHECK
-- ==============================================================================
local function MatchesKeyword(itemName)
    local lowerName = string.lower(itemName)
    for _, keyword in ipairs(Config.Detection.keywords) do
        if string.find(lowerName, string.lower(keyword)) then
            return true
        end
    end
    return false
end

-- ==============================================================================
-- LOCAL QBCORE ITEMS SCAN (CLIENT-SIDE)
-- ==============================================================================
-- Scans QBCore.Shared.Items available on the client.
-- This supplements the server-side scan.
-- ==============================================================================
local function ScanQBCoreItemsLocal()
    if not Config.Detection.enabled or not Config.Detection.autoRegister then
        return
    end

    local items = QBCore.Shared.Items
    if not items then
        DebugPrint('QBCore.Shared.Items not available on client.')
        return
    end

    local count = 0
    for itemName, _ in pairs(items) do
        if MatchesKeyword(itemName) and not Config.DrugValues[itemName] and not detectedDrugs[itemName] then
            detectedDrugs[itemName] = true
            count = count + 1
            DebugPrint('Client detected drug: ' .. itemName)
        end
    end
    DebugPrint('Client scan complete. Found ' .. count .. ' new drug(s).')
end

-- ==============================================================================
-- RECEIVE DETECTED DRUGS FROM SERVER
-- ==============================================================================
-- Server scans ox_inventory and QBCore items, then sends results here.
-- Merges with any local detections.
-- ==============================================================================
RegisterNetEvent('DjonStNix-Overdose:receiveDetectedDrugs', function(serverDrugs)
    if not serverDrugs then return end

    local count = 0
    for itemName, _ in pairs(serverDrugs) do
        if not detectedDrugs[itemName] then
            detectedDrugs[itemName] = true
            count = count + 1
        end
    end
    DebugPrint('Received ' .. count .. ' drug(s) from server.')
end)

-- ==============================================================================
-- IS DRUG CHECK
-- ==============================================================================
-- Returns true if the item is recognized as a drug (either configured or detected).
-- ==============================================================================
local function IsDrug(itemName)
    if Config.DrugValues[itemName] then
        return true
    end
    if detectedDrugs[itemName] then
        return true
    end
    return false
end

-- ==============================================================================
-- GET DRUG VALUE
-- ==============================================================================
-- Returns the toxicity value for a given drug type.
-- Priority: Config.DrugValues[drugType] > fallback default
-- ==============================================================================
local function GetDrugValue(drugType)
    if Config.DrugValues[drugType] then
        return Config.DrugValues[drugType]
    end
    return Config.DrugValues.default
end

-- ==============================================================================
-- OVERDOSE EFFECTS (BUILT-IN)
-- ==============================================================================
-- Runs the internal overdose sequence based on Config.Overdose toggles.
-- Only executes when Config.External.useExternalEffects = false.
-- ==============================================================================
local function RunOverdoseEffects()
    local ped = PlayerPedId()

    -- Notification
    if Config.Overdose.notify then
        QBCore.Functions.Notify('You are overdosing...', 'error', 5000)
    end

    -- Fade screen to black
    if Config.Overdose.fadeScreen then
        DoScreenFadeOut(1000)
        Wait(1000)
    end

    -- Ragdoll
    if Config.Overdose.ragdoll then
        SetPedToRagdoll(ped, 5000, 5000, 0, false, false, false)
        Wait(3000)
    end

    -- Kill the player
    if Config.Overdose.killPlayer then
        SetEntityHealth(ped, 0)
    end

    -- Restore screen if faded
    if Config.Overdose.fadeScreen then
        Wait(2000)
        DoScreenFadeIn(1000)
    end
end

-- ==============================================================================
-- TRIGGER OVERDOSE
-- ==============================================================================
-- Called when toxicity reaches the overdose threshold.
-- Routes to external event or built-in effects based on config.
-- ==============================================================================
local function TriggerOverdose()
    if isOverdosing then return end
    isOverdosing = true

    DebugPrint('OVERDOSE TRIGGERED! Toxicity: ' .. toxicity)

    if Config.External.useExternalEffects then
        -- Defer to external script
        TriggerEvent(Config.External.overdoseEvent)
        DebugPrint('Fired external event: ' .. Config.External.overdoseEvent)
    else
        -- Run built-in effects
        RunOverdoseEffects()
    end

    -- Reset toxicity after overdose
    toxicity = 0
    isOverdosing = false

    DebugPrint('Toxicity reset after overdose.')
end

-- ==============================================================================
-- ADD DRUG USE (CORE FUNCTION)
-- ==============================================================================
-- Call this function to add toxicity from a drug use.
-- Accepts ANY drug name — uses config value or falls back to default.
-- ==============================================================================
function AddDrugUse(drugType)
    if not drugType or type(drugType) ~= 'string' then
        DebugPrint('AddDrugUse called with invalid drugType.')
        return
    end

    local value = GetDrugValue(drugType)
    toxicity = toxicity + value

    DebugPrint('Drug used: ' .. drugType .. ' | Value: ' .. value .. ' | Total toxicity: ' .. toxicity)

    -- Check overdose threshold
    if toxicity >= Config.Thresholds.overdose then
        TriggerOverdose()
    end
end

-- ==============================================================================
-- EVENT: Add Drug Use (for external scripts)
-- ==============================================================================
-- Other scripts can trigger this event to add drug toxicity:
--   TriggerEvent('DjonStNix-Overdose:addDrugUse', 'cocaine')
-- ==============================================================================
RegisterNetEvent('DjonStNix-Overdose:addDrugUse', function(drugType)
    AddDrugUse(drugType)
end)

-- ==============================================================================
-- AUTO-HOOK: QBCore Item Use
-- ==============================================================================
-- Listens for the QBCore item use event. When a player uses an item that is
-- recognized as a drug (configured or detected), toxicity is added automatically.
-- This means other scripts do NOT need to manually call AddDrugUse.
-- ==============================================================================
RegisterNetEvent('QBCore:Client:OnUseItem', function(itemData)
    if not itemData or not itemData.name then return end

    local itemName = string.lower(itemData.name)
    if IsDrug(itemName) then
        DebugPrint('Auto-hook triggered for item: ' .. itemName)
        AddDrugUse(itemName)
    end
end)

-- ==============================================================================
-- AUTO-HOOK: ox_inventory Item Use
-- ==============================================================================
-- Listens for ox_inventory's item use event.
-- When a used item is recognized as a drug, toxicity is added automatically.
-- ==============================================================================
RegisterNetEvent('ox_inventory:usedItem', function(itemName, slotId, metadata)
    if not itemName then return end

    local lowerName = string.lower(itemName)
    if IsDrug(lowerName) then
        DebugPrint('ox_inventory auto-hook triggered for item: ' .. lowerName)
        AddDrugUse(lowerName)
    end
end)

-- ==============================================================================
-- EXPORT: AddDrugUse (for external scripts)
-- ==============================================================================
-- Other scripts can also use the export:
--   exports['DjonStNix-Overdose']:AddDrugUse('cocaine')
-- ==============================================================================
exports('AddDrugUse', AddDrugUse)

-- ==============================================================================
-- EXPORT: GetToxicity (read current toxicity level)
-- ==============================================================================
-- Other scripts can read the current toxicity:
--   local tox = exports['DjonStNix-Overdose']:GetToxicity()
-- ==============================================================================
exports('GetToxicity', function()
    return toxicity
end)

-- ==============================================================================
-- EXPORT: ResetToxicity (force reset)
-- ==============================================================================
-- Other scripts can force-reset toxicity:
--   exports['DjonStNix-Overdose']:ResetToxicity()
-- ==============================================================================
exports('ResetToxicity', function()
    toxicity = 0
    DebugPrint('Toxicity manually reset.')
end)

-- ==============================================================================
-- EXPORT: IsDrug (check if item is recognized as a drug)
-- ==============================================================================
-- Other scripts can check if an item is a recognized drug:
--   local isDrug = exports['DjonStNix-Overdose']:IsDrug('weed_joint')
-- ==============================================================================
exports('IsDrug', function(itemName)
    return IsDrug(itemName)
end)

-- ==============================================================================
-- DECAY THREAD
-- ==============================================================================
-- Single lightweight thread that decays toxicity over time.
-- Only active when decay is enabled. Uses Config.Decay.interval as wait.
-- No frame-rate tied loops.
-- ==============================================================================
CreateThread(function()
    if not Config.Decay.enabled then
        DebugPrint('Decay system disabled.')
        return
    end

    DebugPrint('Decay thread started. Interval: ' .. Config.Decay.interval .. 'ms | Amount: ' .. Config.Decay.amount)

    while true do
        Wait(Config.Decay.interval)

        if toxicity > 0 then
            toxicity = math.max(0, toxicity - Config.Decay.amount)
            DebugPrint('Toxicity decayed. Current: ' .. toxicity)
        end
    end
end)

-- ==============================================================================
-- INITIALIZATION
-- ==============================================================================
-- Run local QBCore scan + request server-detected drugs on player load.
-- ==============================================================================
CreateThread(function()
    -- Wait for QBCore to be fully loaded
    Wait(1000)

    -- Local client-side scan of QBCore.Shared.Items
    ScanQBCoreItemsLocal()

    -- Request server-detected drugs (includes ox_inventory results)
    TriggerServerEvent('DjonStNix-Overdose:requestDetectedDrugs')

    DebugPrint('DjonStNix-Overdose client initialized.')
end)
