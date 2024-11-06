-- WaypointAdder.lua

-- Import the waypoint data
local waypointData = WaypointData
local activeWaypoints = {}
local queuedZone = nil
local currentZone = nil
local currentProxy = nil

-- Function to check if a zone is already discovered
function IsZoneDiscovered(achievementID, pointName)
    local characterID = GetCharacterID()
    if xpModeData[characterID] then
        for key, zoneInfo in pairs(xpModeData[characterID]) do
            if zoneInfo.achievementID == achievementID then
                for _, waypoint in ipairs(zoneInfo.waypoints) do
                    if waypoint.name == pointName and waypoint.status ~= "undiscovered" then
                        return true
                    end
                end
                return false
            end
        end
    end
    return false
end

-- Function to add waypoints for a specific zone and return whether any were added
function AddWaypointsForZone(continentName, zoneName)
    -- Clear any existing waypoints to avoid duplicates
    RemoveAllWaypoints()

    local characterID = GetCharacterID()
    local key = continentName .. ":" .. zoneName
    local zoneData = xpModeData[characterID] and xpModeData[characterID][key]
    
    if not zoneData then
        print("|cFFFF0000No data found for " .. zoneName .. ".|r")
        return false
    end

    local m = C_Map.GetBestMapForUnit("player")
    if not m then
        print("|cFFFF0000Unable to get current map.|r")
        return false
    end

    local waypointsAdded = false

    -- Add waypoints for the selected zone
    for _, waypoint in ipairs(zoneData.waypoints) do
        local x, y, desc = waypoint.x, waypoint.y, waypoint.name
        x = tonumber(x) / 100
        y = tonumber(y) / 100

        if waypoint.status == "undiscovered" then
            local uid = TomTom:AddWaypoint(m, x, y, {
                title = desc,
                persistent = false,
                minimap = true,
                world = true
            })
            if uid then
                activeWaypoints[desc] = uid
                waypointsAdded = true
            else
            end
        end
    end

    if waypointsAdded then
        currentZone = zoneName
        print("|cFF00FF00Waypoints added for " .. zoneName .. ".|r")
        return true
    else
        print("|cFFFF0000No undiscovered waypoints found for " .. zoneName .. ".|r")
    end

    return false
end

-- Function to remove waypoints when leaving a zone
function RemoveAllWaypoints()
    for desc, uid in pairs(activeWaypoints) do
        TomTom:RemoveWaypoint(uid)
    end
    activeWaypoints = {}  -- Clear the active waypoints table
end

-- Function to add a proxy waypoint on the world map near the zone
function AddProxyWaypoint(continentName, zoneName)
    local continentInfo = waypointData[continentName]
    if not continentInfo then return end

    local zoneInfo = continentInfo[zoneName]
    if not zoneInfo then return end

    local proxyLocation = zoneInfo.proxyLocation
    local continentMapID = GetContinentMapID(continentName)

    -- Check if the waypoint already exists and remove it if necessary
    if currentProxy and activeWaypoints[zoneName] then
        TomTom:RemoveWaypoint(currentProxy)
        activeWaypoints[zoneName] = nil
        currentProxy = nil
    end

    if proxyLocation and continentMapID then
        local x, y, desc = unpack(proxyLocation)
        x = tonumber(x) / 100  -- Convert percentage to decimal
        y = tonumber(y) / 100  -- Convert percentage to decimal
        if x and y then
            local uid = TomTom:AddWaypoint(continentMapID, x, y, { title = "Head to " .. zoneName })
            activeWaypoints[zoneName] = uid  -- Store the UID so we know the waypoint was added
            currentProxy = uid  -- Ensure we're storing the correct UID, not a table
            return uid
        end
    end
end

function GetContinentMapID(continentName)
    local continentMapIDs = {
        ["Eastern Kingdoms"] = 13,
        ["Kalimdor"] = 12,
        ["Outland"] = 101,
        ["Northrend"] = 113,
        ["Pandaria"] = 424,
        ["Draenor"] = 572,
        ["Broken Isles"] = 619,
        ["Zandalar"] = 875,
        ["Kul Tiras"] = 876,
        ["Argus"] = 905,
        ["The Maelstrom"] = 948,
        ["Vashj'ir"] = 203,
        ["Dragon Isles"] = 1978,
        ["The Shadowlands"] = 1550,
    }

    local mapID = continentMapIDs[continentName]
    return mapID
    
end

function HandleZoneSelection(continentName, zoneName)
    -- Clear all waypoints, not just the active ones
    TomTom:ClearAllWaypoints()

    -- Clear any existing proxy waypoint
    if currentProxy then
        TomTom:RemoveWaypoint(currentProxy)
        currentProxy = nil
    end

    -- Get the current map ID and parent map ID
    local mapID = C_Map.GetBestMapForUnit("player")
    local mapInfo = C_Map.GetMapInfo(mapID)
    local parentMapInfo = mapInfo and C_Map.GetMapInfo(mapInfo.parentMapID)
    local currentContinent = parentMapInfo and parentMapInfo.name or "Unknown"

    -- Special handling for Dalaran
    if GetZoneText() == "Dalaran" and continentName == "Northrend" then
        currentContinent = "Northrend"
    end

    -- Special handling for Stormshield
    if GetZoneText() == "Stormshield" or continentName == "Ashran" then
        currentContinent = "Draenor"
    end

    -- Special handling for Deathknell in Tirisfal Glades
    if GetZoneText() == "Deathknell" then
        currentContinent = "Eastern Kingdoms"
        zoneName = "Tirisfal Glades"
    end

    -- Special handling for Sunstrider Isle
    if GetZoneText() == "Sunstrider Isle" then
        currentContinent = "Eastern Kingdoms"
        zoneName = "Eversong Woods"
    end

    -- Special handling for Coldridge Valley and New Tinkertown
    if GetZoneText() == "Coldridge Valley" or GetZoneText() == "New Tinkertown" then
        currentContinent = "Eastern Kingdoms"
        zoneName = "Dun Morogh"  -- Set the zoneName to Dun Morogh
    end
    
    -- Special handling for Vashj'ir and its subzones
    if continentName == "Eastern Kingdoms" and (zoneName == "Vashj'ir" or zoneName == "Abyssal Depths" or zoneName == "Shimmering Expanse" or zoneName == "Kelp'thar Forest") then
        if GetZoneText() == "Vashj'ir" or GetZoneText() == "Abyssal Depths" or GetZoneText() == "Shimmering Expanse" or GetZoneText() == "Kelp'thar Forest" then
            currentContinent = "Eastern Kingdoms"
        else
            print("|cFF00FF00You are currently on " .. GetZoneText() .. ". Please go to Vashj'ir and try again.|r")
            return
        end
    elseif currentContinent ~= continentName then
        -- Special handling for Kul Tiras and its zones
        if continentName == "Kul Tiras" and (zoneName == "Tiragarde Sound" or zoneName == "Drustvar" or zoneName == "Stormsong Valley") then
            currentContinent = "Kul Tiras"
        -- Special handling for Stranglethorn Vale and its subzones
        elseif continentName == "Eastern Kingdoms" and (zoneName == "Northern Stranglethorn" or zoneName == "The Cape of Stranglethorn") then
            if GetZoneText() == "Northern Stranglethorn" or GetZoneText() == "The Cape of Stranglethorn" then
                currentContinent = "Eastern Kingdoms"
            else
                print("|cFF00FF00You are currently on " .. GetZoneText() .. ". Please go to Stranglethorn Vale and try again.|r")
                return
            end
        else
            print("|cFF00FF00You are currently on " .. currentContinent .. ". Please go to " .. continentName .. " and try again.|r")
            return
        end
    end

    -- Existing logic to handle zone selection
    local newZone = GetZoneText()
    if newZone == zoneName then
        AddWaypointsForZone(continentName, zoneName)
    else
        -- Add a proxy waypoint
        local proxyUid = AddProxyWaypoint(continentName, zoneName)
        queuedZone = zoneName  -- Queue the zone for later
        selectedContinent = continentName
        currentProxy = proxyUid
    end
end

local removeWaypointsTimer = nil

-- Modify OnZoneChange to only trigger on zone changes, ignoring subzone changes
function OnZoneChange(event)
    local newZone = GetZoneText()

    -- Clear the existing timer if a new zone change occurs
    if removeWaypointsTimer then
        removeWaypointsTimer:Cancel()
        removeWaypointsTimer = nil
    end

    -- If we've entered the queued zone, add waypoints
    if queuedZone and queuedZone == newZone then
        print("|cFF00FF00Zone reached: " .. newZone .. ". Setting waypoints.|r")
        local waypointsAdded = AddWaypointsForZone(selectedContinent, newZone)
        queuedZone = nil

        -- Remove the proxy waypoint if it exists
        if currentProxy then
            TomTom:RemoveWaypoint(currentProxy)
            currentProxy = nil
        end

        -- Force update the closest waypoint only if waypoints were added
        if waypointsAdded then
            TomTom:SetClosestWaypoint(true)
        end
    elseif currentZone and currentZone ~= newZone then
        -- Start a 15-second timer to remove the zone waypoints only if they exist
        if next(activeWaypoints) ~= nil then
            removeWaypointsTimer = C_Timer.NewTimer(15, function()
                print("|cFF00FF00Zone change detected after 15 seconds. Clearing zone waypoints.|r")
                RemoveZoneWaypoints()
            end)
        end
    end

    -- Update current zone
    currentZone = newZone
end

-- Function to remove only zone waypoints
function RemoveZoneWaypoints()
    for desc, uid in pairs(activeWaypoints) do
        if desc ~= "proxy" then  -- Keep the proxy waypoint
            TomTom:RemoveWaypoint(uid)
            activeWaypoints[desc] = nil
        end
    end
end

-- Event Registration for Login Delay
local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:SetScript("OnEvent", function(self, event)
    C_Timer.After(2, function()
        local frame = CreateFrame("Frame")
        frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        frame:RegisterEvent("ZONE_CHANGED")
        frame:RegisterEvent("ZONE_CHANGED_INDOORS")
        frame:RegisterEvent("CRITERIA_UPDATE")
        frame:SetScript("OnEvent", OnZoneChange)

        -- Set initial current zone
        currentZone = GetZoneText()
        currentSubZone = GetSubZoneText()
    end)
end)

-- Function to get the current character's unique identifier
function GetCharacterID()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

function UpdateWaypointStatus(waypointName)
    local characterID = GetCharacterID()
    if xpModeData[characterID] then
        for key, zoneInfo in pairs(xpModeData[characterID]) do
            for _, waypoint in ipairs(zoneInfo.waypoints) do
                if waypoint.name == waypointName then
                    waypoint.status = "discovered"
                    
                    -- Remove the waypoint from TomTom
                    if activeWaypoints[waypointName] then
                        TomTom:RemoveWaypoint(activeWaypoints[waypointName])
                        activeWaypoints[waypointName] = nil
                    end
                    
                    -- Check if all waypoints in the zone are discovered
                    local allDiscovered = true
                    for _, wp in ipairs(zoneInfo.waypoints) do
                        if wp.status == "undiscovered" then
                            allDiscovered = false
                            break
                        end
                    end
                    
                    if allDiscovered then
                        zoneInfo.completed = true
                        print("Zone completed: " .. zoneInfo.zone)
                    end
                    
                    -- Update the UI
                    if UpdateZoneStatusContainer then
                        UpdateZoneStatusContainer(zoneInfo.continent, zoneInfo.zone)
                    end
                    if UpdateContinentStatus then
                        UpdateContinentStatus()
                    end
                    
                    return true
                end
            end
        end
    end
    return false
end

local chatFrame = CreateFrame("Frame")
chatFrame:RegisterEvent("CHAT_MSG_SYSTEM")
chatFrame:SetScript("OnEvent", function(self, event, message)
    if event == "CHAT_MSG_SYSTEM" then
        local waypointName = message:match("Discovered (.+): %d+ experience gained")
        if waypointName then
            UpdateWaypointStatus(waypointName)
        end
    end
end)