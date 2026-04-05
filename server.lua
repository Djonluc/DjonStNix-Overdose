-- ==============================================================================
-- 👑 DJONSTNIX OVERDOSE SYSTEM — SERVER
-- ==============================================================================
-- Server-side detection for ox_inventory items.
-- Scans item registries once on startup and sends detected drugs to clients.
-- ==============================================================================

local QBCore = exports['qb-core']:GetCoreObject()

-- ==============================================================================
-- STATE
-- ==============================================================================
local detectedDrugs = {}    -- Table of detected drug item names

-- ==============================================================================
-- DEBUG HELPER
-- ==============================================================================
local function DebugPrint(...)
    if Config.Debug then
        print('[DjonStNix-Overdose][Server]', ...)
    end
end

-- ==============================================================================
-- KEYWORD MATCH CHECK
-- ==============================================================================
-- Returns true if itemName contains any of the configured keywords.
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
-- SCAN QBCORE SHARED ITEMS
-- ==============================================================================
local function ScanQBCoreItems()
    local items = QBCore.Shared.Items
    if not items then
        DebugPrint('QBCore.Shared.Items not available.')
        return
    end

    local count = 0
    for itemName, _ in pairs(items) do
        if MatchesKeyword(itemName) and not Config.DrugValues[itemName] then
            detectedDrugs[itemName] = true
            count = count + 1
            DebugPrint('QBCore detected drug: ' .. itemName)
        end
    end
    DebugPrint('QBCore scan complete. Found ' .. count .. ' drug(s).')
end

-- ==============================================================================
-- SCAN OX_INVENTORY ITEMS
-- ==============================================================================
-- Uses ox_inventory server export to pull all registered items.
-- Only runs if ox_inventory is started.
-- ==============================================================================
local function ScanOxInventoryItems()
    local oxResource = GetResourceState('ox_inventory')
    if oxResource ~= 'started' then
        DebugPrint('ox_inventory not running, skipping ox scan.')
        return
    end

    -- ox_inventory exposes Items as a shared export
    local success, items = pcall(function()
        return exports['ox_inventory']:Items()
    end)

    if not success or not items then
        DebugPrint('Could not fetch ox_inventory items.')
        return
    end

    local count = 0
    for itemName, _ in pairs(items) do
        if MatchesKeyword(itemName) and not Config.DrugValues[itemName] and not detectedDrugs[itemName] then
            detectedDrugs[itemName] = true
            count = count + 1
            DebugPrint('ox_inventory detected drug: ' .. itemName)
        end
    end
    DebugPrint('ox_inventory scan complete. Found ' .. count .. ' drug(s).')
end

-- ==============================================================================
-- RUN ALL SCANS
-- ==============================================================================
local function RunDetection()
    if not Config.Detection.enabled or not Config.Detection.autoRegister then
        DebugPrint('Auto-detection disabled.')
        return
    end

    ScanQBCoreItems()
    ScanOxInventoryItems()

    local total = 0
    for _ in pairs(detectedDrugs) do total = total + 1 end
    DebugPrint('Total auto-detected drugs: ' .. total)
end

-- ==============================================================================
-- SEND DETECTED DRUGS TO CLIENT
-- ==============================================================================
-- When a player loads in, send them the detected drug list so the client
-- knows which items are drugs (for auto-hook on item use).
-- ==============================================================================
RegisterNetEvent('DjonStNix-Overdose:requestDetectedDrugs', function()
    local src = source
    TriggerClientEvent('DjonStNix-Overdose:receiveDetectedDrugs', src, detectedDrugs)
end)

-- ==============================================================================
-- EXPORT: Get detected drugs (for other server scripts)
-- ==============================================================================
exports('GetDetectedDrugs', function()
    return detectedDrugs
end)

-- ==============================================================================
-- INITIALIZATION
-- ==============================================================================
CreateThread(function()
    -- Small delay to ensure all resources are loaded
    Wait(2000)
    RunDetection()
    DebugPrint('DjonStNix-Overdose server initialized.')
end)
