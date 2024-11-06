function ShowXPModeFrame(exploreFrame)
    -- Create a new frame for XP Mode
    local XPModeFrame = CreateFrame("Frame", "XPModeFrame", UIParent, "ThinBorderTemplate")
    XPModeFrame:SetSize(800, 500)  -- Set size of the frame
    XPModeFrame:SetPoint("CENTER", UIParent, "CENTER")  -- Center the frame
    XPModeFrame:SetMovable(true)  -- Make the frame movable
    XPModeFrame:EnableMouse(true)
    XPModeFrame:RegisterForDrag("LeftButton")
    XPModeFrame:SetScript("OnDragStart", XPModeFrame.StartMoving)
    XPModeFrame:SetScript("OnDragStop", XPModeFrame.StopMovingOrSizing)
    XPModeFrame:Hide()  -- Start hidden

    -- Add black background
    local xpModeBackgroundTexture = XPModeFrame:CreateTexture(nil, "BACKGROUND")
    xpModeBackgroundTexture:SetAllPoints(XPModeFrame)
    xpModeBackgroundTexture:SetColorTexture(0, 0, 0, 0.8)

    -- Title text for the new frame
    XPModeFrame.title = XPModeFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
    XPModeFrame.title:SetPoint("TOP", XPModeFrame, "TOP", 0, -10)
    XPModeFrame.title:SetText("XP Mode")

    -- Close button for the new frame
    local xpModeCloseButton = CreateFrame("Button", nil, XPModeFrame, "UIPanelCloseButton")
    xpModeCloseButton:SetPoint("TOPRIGHT", XPModeFrame, "TOPRIGHT", -5, -5)
    xpModeCloseButton:SetScript("OnClick", function()
        XPModeFrame:Hide()
        if type(ReturnFromXPMode) == "function" then
            ReturnFromXPMode()
        else
            -- Fallback if ReturnFromXPMode is not available
            if exploreFrame then
                exploreFrame:Show()
            end
        end
    end)

    -- Save Data Button
    local saveDataButton = CreateFrame("Button", nil, XPModeFrame, "UIPanelButtonTemplate")
    saveDataButton:SetPoint("TOPLEFT", XPModeFrame, "TOPLEFT", 50, -20)
    saveDataButton:SetSize(120, 20)
    saveDataButton:SetText("Add Character")
    saveDataButton:SetScript("OnClick", function()
        CheckUniversalAchievement()
        UpdateLeftFrame()  -- Refresh the left frame
        if selectedCharacter then
            UpdateRightFrame(selectedCharacter)  -- Refresh the right frame for the selected character
        end
    end)

    -- Left Frame for character names
    local leftFrame = CreateFrame("Frame", nil, XPModeFrame, "ThinBorderTemplate")
    leftFrame:ClearAllPoints()
    leftFrame:SetPoint("TOPLEFT", XPModeFrame, "TOPLEFT", 0, -60)
    leftFrame:SetSize(220, 350)

    -- Right Frame for achievement details
    local rightFrame = CreateFrame("Frame", nil, XPModeFrame, "ThinBorderTemplate")
    rightFrame:SetPoint("TOPRIGHT", XPModeFrame, "TOPRIGHT", -30, -60)
    rightFrame:SetSize(550, 430)  -- Set a fixed size for the right frame

    -- Scroll Frame for right frame content
    local scrollFrame = CreateFrame("ScrollFrame", nil, rightFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)  -- Will be dynamically resized
    scrollFrame:SetScrollChild(content)

    -- Function to clear children of a frame
    local function ClearFrameChildren(frame)
        local children = { frame:GetChildren() }
        for _, child in ipairs(children) do
            child:Hide()
            child:SetParent(nil)
        end
    end

    -- Define UpdateLeftFrame as a global function
    UpdateLeftFrame = function()
        ClearFrameChildren(leftFrame)  -- Clear previous content

        local yOffset = -10
        for character, _ in pairs(xpModeData) do
            local characterButton = CreateFrame("Button", nil, leftFrame)
            characterButton:SetSize(220, 30)
            characterButton:SetPoint("TOPLEFT", 0, yOffset)

            -- Create bookmark texture
            local bookmarkTexture = characterButton:CreateTexture(nil, "BACKGROUND")
            bookmarkTexture:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
            bookmarkTexture:SetBlendMode("ADD")
            bookmarkTexture:SetAllPoints(characterButton)
            bookmarkTexture:SetVertexColor(0.5, 0.5, 0.5, 0.5)

            -- Create character text
            local characterText = characterButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            characterText:SetPoint("LEFT", 10, 0)
            characterText:SetText(character)

            -- Create delete button
            local deleteButton = CreateFrame("Button", nil, characterButton, "UIPanelCloseButton")
            deleteButton:SetSize(14, 14)
            deleteButton:SetPoint("RIGHT", -10, 0)
            deleteButton:SetScript("OnClick", function()
                xpModeData[character] = nil
                UpdateLeftFrame()
                if selectedCharacter == character then
                    selectedCharacter = nil
                    UpdateRightFrame("")
                end
            end)

            characterButton:SetScript("OnClick", function()
                if selectedCharacter then
                    _G[selectedCharacter .. "Bookmark"]:SetVertexColor(0.5, 0.5, 0.5, 0.5)
                end
                selectedCharacter = character
                bookmarkTexture:SetVertexColor(1, 0.8, 0, 1)
                UpdateRightFrame(character)
            end)

            characterButton:SetScript("OnEnter", function()
                if character ~= selectedCharacter then
                    bookmarkTexture:SetVertexColor(0, 0.5, 0.5, 0.5)
                end
            end)

            characterButton:SetScript("OnLeave", function()
                if character ~= selectedCharacter then
                    bookmarkTexture:SetVertexColor(0.5, 0.5, 0.5, 0.5)
                end
            end)
            
            _G[character .. "Bookmark"] = bookmarkTexture
            yOffset = yOffset - 35
        end

        leftFrame:SetHeight(-yOffset + 10)
    end

    -- Define UpdateRightFrame as a global function
    UpdateRightFrame = function(character)
        if not character or character == "" then
            return
        end

        -- Clear previous content
        content:SetSize(1, 1)  -- Reset content size
        for _, child in pairs({content:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end

        -- Create a sorted list of continents and their zones
        local sortedContinents = {}
        for continent, zones in pairs(WaypointData) do
            table.insert(sortedContinents, {continent = continent, zones = zones})
        end
        table.sort(sortedContinents, function(a, b) return a.continent < b.continent end)

        local yOffset = 0
        for _, continentData in ipairs(sortedContinents) do
            local continent = continentData.continent
            local zones = continentData.zones

            -- Create a container for the continent and its zones
            local continentContainer = CreateFrame("Frame", nil, content)
            continentContainer:SetSize(rightFrame:GetWidth() - 60, 30)
            continentContainer:SetPoint("TOPLEFT", 0, yOffset)

            -- Create continent header
            local continentHeader = continentContainer:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
            continentHeader:SetPoint("TOPLEFT", 0, 0)
            continentHeader:SetText(continent)

            -- Create "Mark Continent" button
            local markContinentButton = CreateFrame("Button", nil, continentContainer, "UIPanelButtonTemplate")
            markContinentButton:SetSize(50, 20)
            markContinentButton:SetText("Mark")
            markContinentButton:SetPoint("LEFT", continentHeader, "RIGHT", 10, 0)  -- Position to the right of the header with 10px padding
            markContinentButton:SetScript("OnClick", function()
                for zone, info in pairs(zones) do
                    local key = continent .. ":" .. zone
                    if xpModeData[character][key] then
                        xpModeData[character][key].completed = true
                        for _, waypoint in ipairs(xpModeData[character][key].waypoints) do
                            waypoint.status = "discovered"
                        end
                    end
                end
                UpdateRightFrame(character)
            end)

            local zoneYOffset = -30

            -- Create a sorted list of zones within the continent
            local sortedZones = {}
            for zone, info in pairs(zones) do
                local key = continent .. ":" .. zone
                if xpModeData[character][key] then
                    table.insert(sortedZones, {zone = zone, info = xpModeData[character][key]})
                end
            end
            table.sort(sortedZones, function(a, b) return a.zone < b.zone end)

            for _, data in ipairs(sortedZones) do
                local zone = data.zone
                local info = data.info

                local zoneContainer = CreateFrame("Frame", nil, continentContainer)
                zoneContainer:SetSize(rightFrame:GetWidth() - 60, 30)
                zoneContainer:SetPoint("TOPLEFT", 0, zoneYOffset)

                local icon = zoneContainer:CreateTexture(nil, "ARTWORK")
                icon:SetSize(20, 20)
                icon:SetPoint("LEFT", 10, 0)
                icon:SetTexture(select(10, GetAchievementInfo(info.achievementID)))

                local zoneText = zoneContainer:CreateFontString(nil, "ARTWORK", "GameFontNormal")
                zoneText:SetPoint("LEFT", icon, "RIGHT", 10, 0)
                if info.completed then
                    zoneText:SetText(zone .. ": |cff00ff00Completed|r") -- Green for completed
                else
                    zoneText:SetText(zone .. ": |cffff0000Not Completed|r") -- Red for not completed
                end
                

                local toggleButton = CreateFrame("Button", nil, zoneContainer, "UIPanelButtonTemplate")
                toggleButton:SetPoint("RIGHT", -60, 0)
                toggleButton:SetSize(80, 20)
                toggleButton:SetText("Waypoints")

                local removeButton = CreateFrame("Button", nil, zoneContainer, "UIPanelButtonTemplate")
                removeButton:SetPoint("RIGHT", 20, 0)
                removeButton:SetSize(80, 20)
                removeButton:SetText(info.completed and "Unmark" or "Mark")
                removeButton:SetScript("OnClick", function()
                    info.completed = not info.completed
                    for _, waypoint in ipairs(info.waypoints) do
                        waypoint.status = info.completed and "discovered" or "undiscovered"
                    end
                    -- Check if all waypoints are discovered immediately
                    local allDiscovered = true
                    for _, waypoint in ipairs(info.waypoints) do
                        if waypoint.status ~= "discovered" then
                            allDiscovered = false
                            break
                        end
                    end
                    info.completed = allDiscovered  -- Update completion status
                    UpdateRightFrame(character)  -- Update the frame immediately
                end)

                zoneYOffset = zoneYOffset - 35

                -- Create a separate container for waypoints
                local waypointsContainer = CreateFrame("Frame", nil, zoneContainer)
                waypointsContainer:SetSize(rightFrame:GetWidth() - 80, 25 * #info.waypoints)
                waypointsContainer:SetPoint("TOP", zoneContainer, "BOTTOM", 0, 0)
                waypointsContainer:Hide() -- Initially hidden

                -- Add waypoints to the waypoints container
                local waypointYOffset = 0
                for _, waypoint in ipairs(info.waypoints) do
                    local waypointFrame = CreateFrame("Frame", nil, waypointsContainer)
                    waypointFrame:SetSize(rightFrame:GetWidth() - 80, 25)
                    waypointFrame:SetPoint("TOPLEFT", 20, waypointYOffset)

                    local waypointText = waypointFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
                    waypointText:SetPoint("LEFT", 0, 0)
                    -- Add status color based on waypoint status
                    local waypointStatusColor = waypoint.status == "discovered" and "|cff00ff00" or "|cffff0000"
                    waypointText:SetText(waypoint.name .. " (" .. waypoint.x .. ", " .. waypoint.y .. ") - " .. waypointStatusColor .. (waypoint.status == "discovered" and "Discovered" or "Not Discovered") .. "|r")

                    local waypointButton = CreateFrame("Button", nil, waypointFrame, "UIPanelButtonTemplate")
                    waypointButton:SetPoint("RIGHT", 0, 0)
                    waypointButton:SetSize(60, 20)
                    waypointButton:SetText(waypoint.status == "discovered" and "Unmark" or "Mark")
                    waypointButton:SetScript("OnClick", function()
                        waypoint.status = waypoint.status == "discovered" and "undiscovered" or "discovered"
                        -- Check if all waypoints are discovered immediately
                        local allDiscovered = true
                        for _, wp in ipairs(info.waypoints) do
                            if wp.status ~= "discovered" then
                                allDiscovered = false
                                break
                            end
                        end
                        info.completed = allDiscovered  -- Update completion status
                        UpdateRightFrame(character)  -- Update the frame immediately
                    end)

                    waypointYOffset = waypointYOffset - 25
                end

                -- Modify the toggle button to show/hide waypoints
                toggleButton:SetScript("OnClick", function()
                    info.showWaypoints = not info.showWaypoints
                    if info.showWaypoints then
                        waypointsContainer:Show()
                        zoneYOffset = zoneYOffset - waypointsContainer:GetHeight()
                    else
                        waypointsContainer:Hide()
                        zoneYOffset = zoneYOffset + waypointsContainer:GetHeight()
                    end
                    UpdateRightFrame(character)
                end)

                if info.showWaypoints then
                    waypointsContainer:Show()
                    zoneYOffset = zoneYOffset - waypointsContainer:GetHeight()
                end
            end

            continentContainer:SetHeight(-zoneYOffset)
            yOffset = yOffset - continentContainer:GetHeight() - 10
        end

        content:SetHeight(-yOffset)
        content:SetWidth(rightFrame:GetWidth() - 60)  -- Set content width to match containers
    end

    -- Initial update of the left frame
    UpdateLeftFrame()

    XPModeFrame:Show()

    -- Mark All Button
    local markAllButton = CreateFrame("Button", nil, XPModeFrame, "UIPanelButtonTemplate")
    markAllButton:SetPoint("TOPRIGHT", rightFrame, "TOPRIGHT", -120, 30)
    markAllButton:SetSize(70, 20)
    markAllButton:SetText("Mark All")
    markAllButton:SetScript("OnClick", function()
        if selectedCharacter then
            for key, zoneInfo in pairs(xpModeData[selectedCharacter]) do
                zoneInfo.completed = true
                -- Update all waypoints in the zone
                for _, waypoint in ipairs(zoneInfo.waypoints) do
                    waypoint.status = "discovered"
                end
            end
            UpdateRightFrame(selectedCharacter)
        end
    end)

    -- Unmark All Button
    local unmarkAllButton = CreateFrame("Button", nil, XPModeFrame, "UIPanelButtonTemplate")
    unmarkAllButton:SetPoint("TOPRIGHT", rightFrame, "TOPRIGHT", -20, 30)
    unmarkAllButton:SetSize(80, 20)
    unmarkAllButton:SetText("Unmark All")
    unmarkAllButton:SetScript("OnClick", function()
        if selectedCharacter then
            for key, zoneInfo in pairs(xpModeData[selectedCharacter]) do
                zoneInfo.completed = false
                -- Update all waypoints in the zone
                for _, waypoint in ipairs(zoneInfo.waypoints) do
                    waypoint.status = "undiscovered"
                end
            end
            UpdateRightFrame(selectedCharacter)
        end
    end)
end

-- Ensure xpModeData is initialized
if not xpModeData then
    xpModeData = {}
end

-- Function to get the current character's unique identifier
local function GetCharacterID()
    local name = UnitName("player")
    local realm = GetRealmName()
    return name .. "-" .. realm
end

-- Function to check for Universal Explorer achievement
function CheckUniversalAchievement()
    local characterID = GetCharacterID()
    xpModeData[characterID] = xpModeData[characterID] or {}

    print("XP Mode enabled for " .. characterID .. ".")
    
    -- Save data for all zones and achievements
    for continent, zones in pairs(WaypointData) do
        for zone, info in pairs(zones) do
            local key = continent .. ":" .. zone
            xpModeData[characterID][key] = {
                zone = zone,
                continent = continent,
                achievementID = info.achievementID,
                completed = false,
                showWaypoints = false,
                waypoints = {}
            }
            -- Add waypoints with undiscovered status
            for _, waypoint in ipairs(info.waypoints) do
                table.insert(xpModeData[characterID][key].waypoints, {
                    name = waypoint[3],
                    x = waypoint[1],
                    y = waypoint[2],
                    status = "undiscovered"
                })
            end
            -- Sort waypoints alphabetically by name
            table.sort(xpModeData[characterID][key].waypoints, function(a, b)
                return a.name < b.name
            end)
        end
    end
    print("Zone data saved for " .. characterID)
    
    -- Update the frame immediately
    if XPModeFrame and XPModeFrame:IsShown() then
        if UpdateLeftFrame then
            UpdateLeftFrame()
        end
        if selectedCharacter == characterID and UpdateRightFrame then
            UpdateRightFrame(characterID)
        end
    end
    
    return true  -- Always return true to enable XP Mode
end