local addonName, addonTable = ...
local frame = CreateFrame("Frame", "PetDailyTrackerFrame", UIParent, "BackdropTemplate")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)

local db
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint()
    if db and relativeTo and relativeTo.GetName then
        db.position = {
            point = point,
            relativeTo = relativeTo:GetName(),
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs,
        }
    end
end)

-- Styling
frame:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
frame:SetBackdropColor(0, 0, 0, 0.8)
frame:SetBackdropBorderColor(0.8, 0.8, 0.8)

local content = CreateFrame("Frame", nil, frame)
content:SetPoint("TOPLEFT", 10, -10)
content:SetPoint("BOTTOMRIGHT", -10, 10)

local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
text:SetJustifyH("LEFT")
text:SetJustifyV("TOP")
text:SetPoint("TOPLEFT")
text:SetWidth(260)

-- Constants
local SAFARI_HAT_ID = 92738
local PADDING = 10
local DEBOUNCE_TIME = 0.3
local DEFAULT_TEXT_WIDTH = 260

text:SetWidth(DEFAULT_TEXT_WIDTH)

local function getQuestProgressString(questID)
    local objectives = C_QuestLog.GetQuestObjectives(questID)
    if not objectives then return "" end

    local completed = 0
    for i = 1, #objectives do
        local obj = objectives[i]
        if obj.finished then
            completed = completed + 1
        end
    end
    return string.format(" (%d/%d)", completed, #objectives)
end

local dmfActive = false
-- local function updateDmfStatus()
--     local wasActive = dmfActive
--     local today = C_DateAndTime.GetCurrentCalendarTime()
--     local numEvents = C_Calendar.GetNumDayEvents(0, today.monthDay)
--     for i = 1, numEvents do
--         local event = C_Calendar.GetDayEvent(0, today.monthDay, i)
--         print(event.title)
--         if event and event.title == "Darkmoon Faire" and event.sequenceType == "ONGOING" then
--             dmfActive = true
--             if not wasActive then requestUpdate() end -- Update if status changed to active
--             return
--         end
--     end
--     dmfActive = false
--     if wasActive then requestUpdate() end -- Update if status changed to inactive
-- end
local function updateDmfStatus()
    local wasActive = dmfActive
    local currentDate = C_DateAndTime.GetCurrentCalendarTime()

    -- Calculate the first day of the current week (Sunday)
    local currentWeekday = currentDate.weekday  -- 1 = Sunday, 2 = Monday, etc.
    local firstDayOfWeek = currentDate.monthDay - (currentWeekday - 1)

    -- Month offset: 0 = current month, -1 = previous month (if firstDayOfWeek < 1)
    local monthOffset = 0
    if firstDayOfWeek < 1 then
        monthOffset = -1
        local prevMonthInfo = C_Calendar.GetMonthInfo(monthOffset)
        firstDayOfWeek = prevMonthInfo.numDays + firstDayOfWeek
    end

    -- Default to inactive
    dmfActive = false

    -- Check all events on that Sunday for Darkmoon Faire with eventType == 4
    local numEvents = C_Calendar.GetNumDayEvents(monthOffset, firstDayOfWeek)
    for i = 1, numEvents do
        local event = C_Calendar.GetDayEvent(monthOffset, firstDayOfWeek, i)
        if event and event.title == "Darkmoon Faire" and event.eventType == 4 then
            dmfActive = true
            break
        end
    end

    -- Fire update if the active state changed
    if dmfActive ~= wasActive then
        requestUpdate()
    end
end




local quests = {
    {
        id=32604, name="Beasts of Fable Book I", category="Pandaria", showProgress=true,
        objectives={
            {name="Ka'wi the Gorger", npc=68555, waypoint={map=371, x=48.4, y=71.0, title="Ka'wi the Gorger"}},
            {name="Kafi", npc=68563, waypoint={map=379, x=35.2, y=56.0, title="Kafi"}},
            {name="Dos-Ryga", npc=68564, waypoint={map=379, x=67.8, y=84.4, title="Dos-Ryga"}},
            {name="Nitun", npc=68565, waypoint={map=371, x=57.0, y=29.2, title="Nitun"}},
        }
    },
    {
        id=32868, name="Beasts of Fable Book II", category="Pandaria", showProgress=true,
        objectives={
            {name="Greyhoof", npc=68560, waypoint={map=376, x=25.2, y=78.6, title="Greyhoof"}},
            {name="Lucky Yi", npc=68561, waypoint={map=376, x=40.6, y=43.8, title="Lucky Yi"}},
            {name="Skitterer Xi'a", npc=68566, waypoint={map=418, x=36.2, y=37.6, title="Skitterer Xi'a"}},
        }
    },
    {
        id=32869, name="Beasts of Fable Book III", category="Pandaria", showProgress=true,
        objectives={
            {name="Gorespine", npc=68558, waypoint={map=422, x=26.2, y=50.2, title="Gorespine"}},
            {name="No-No", npc=68559, waypoint={map=390, x=11.0, y=71.0, title="No-No"}},
            {name="Ti'un the Wanderer", npc=68562, waypoint={map=388, x=72.2, y=79.8, title="Ti'un the Wanderer"}},
        }
    },
    {id=32440, name="Whispering Pandaren Spirit", category="Pandaria", waypoint={map=371, x=28.8, y=36.0, title="Whispering Pandaren Spirit"}},
    {id=32441, name="Thundering Pandaren Spirit - Eternal Blossoms", category="Pandaria", waypoint={map=379, x=64.8, y=93.6, title="Thundering Pandaren Spirit"}},
    {id=32434, name="Burning Pandaren Spirit - Townlong Steppes", category="Pandaria", waypoint={map=388, x=57.0, y=42.2, title="Burning Pandaren Spirit"}},
    {id=32439, name="Flowing Pandaren Spirit - Dread Wastes", category="Pandaria", waypoint={map=422, x=61.2, y=87.6, title="Flowing Pandaren Spirit"}},
    {id=31958, name="Aki the Chosen - Eternal Blossoms", category="Pandaria", waypoint={map=390, x=67.32, y=40.49, title="Aki the Chosen"}},
    {id=31956, name="Courageous Yon - Kun-Lai Summit", category="Pandaria", waypoint={map=379, x=35.8, y=73.6, title="Courageous Yon"}},
    {id=31955, name="Farmer Nishi - The Four Winds", category="Pandaria", waypoint={map=376, x=46.0, y=43.6, title="Farmer Nishi"}},
    {id=31954, name="Mo'ruk - Krasarang Wilds", category="Pandaria", waypoint={map=418, x=62.2, y=45.8, title="Mo'ruk"}},
    {id=31957, name="Wastewalker Shu - Dread Wastes", category="Pandaria", waypoint={map=422, x=55.0, y=37.4, title="Wastewalker Shu"}},
    {id=31953, name="Hyuna of the Shrines - Jade Forest", category="Pandaria", waypoint={map=371, x=48.0, y=54.0, title="Hyuna of the Shrines"}},
    {id=31991, name="Seeker Zusshi - Townlong Steppes", category="Pandaria", waypoint={map=388, x=36.2, y=52.2, title="Seeker Zusshi"}},
    {id=31909, name="Trixxy - Everlook", category="Kalimdor", waypoint={map=83, x=65.6, y=64.6, title="Stone Cold Trixxy"}},
    {id=31926, name="Antari - Shadowmoon Valley", category="Outland", waypoint={map=104, x=30.4, y=41.8, title="Bloodknight Antari"}},
    {id=31971, name="Obalis - Uldum", category="Kalimdor", waypoint={map=249, x=56.4, y=41.8, title="Obalis"}},
    {id=31935, name="Major Payne - Icecrown", category="Northrend", waypoint={map=118, x=77.4, y=19.6, title="Major Payne"}},
    {id=31916, name="Lydia Accoste - Karazhan", category="Eastern Kingdoms", waypoint={map=42, x=40.2, y=76.4, title="Lydia Accoste"}},
    {id=32863, name="What we've been Training for", category="PvP"},
    {id=32175, name="Jeremy Feasel - Darkmoon Faire", category="Darkmoon Island", dmfOnly=true},
}

local optionalQuests = {
    {id=31693, name="Julia Stevens - Elwynn Forest", category="Eastern Kingdoms", waypoint={map=37, x=41.6, y=83.6, title="Julia Stevens"}},
    {id=31972, name="Brok - Mount Hyjal", category="Kalimdor", waypoint={map=198, x=61.4, y=32.8, title="Brok"}},
    {id=31780, name="Old MacDonald - Westfall", category="Eastern Kingdoms", waypoint={map=52, x=60.8, y=18.4, title="Old MacDonald"}},
    {id=31932, name="Nearly Headless Jacob - Crystalsong Forest", category="Northrend", waypoint={map=127, x=50.2, y=59.0, title="Nearly Headless Jacob"}},
    {id=31923, name="Ras'an - Zangarmarsh", category="Outland", waypoint={map=102, x=17.2, y=50.4, title="Ras'an"}},
    {id=31862, name="Zonya the Sadist - Stonetalon Mountains", category="Kalimdor", faction="Horde",waypoint={map=65, x=59.6, y=71.4, title="Zonya the Sadist"}},
    {id=31924, name="Narrok - Nagrand", category="Outland", waypoint={map=107, x=61.0, y=49.4, title="Narrok"}},
    {id=31934, name="Gutretch - Zul'Drak", category="Northrend", waypoint={map=121, x=13.2, y=66.8, title="Gutretch"}},
    {id=31872, name="Merda Stronghoof - Desolace", category="Kalimdor", faction="Horde",waypoint={map=66, x=57.2, y=45.8, title="Merda Stronghoof"}},
    {id=31818, name="Zunta - Durotar", category="Kalimdor", faction="Horde",waypoint={map=1, x=43.8, y=28.8, title="Zunta"}},
    {id=31922, name="Nicki Tinytech - Hellfire Peninsula", category="Outland", waypoint={map=100, x=64.4, y=49.2, title="Nicki Tinytech"}},
    {id=31931, name="Beegle Blastfuse - Howling Fjord", category="Northrend", waypoint={map=117, x=28.6, y=33.8, title="Beegle Blastfuse"}},
    {id=31819, name="Dagra the Fierce - Northern Barrens", category="Kalimdor", faction="Horde",waypoint={map=10, x=58.6, y=53.0, title="Dagra the Fierce"}},
    {id=31973, name="Bordin Steadyfist - Deepholm", category="Elemental Plane", waypoint={map=207, x=49.8, y=57.0, title="Bordin Steadyfist"}},
    {id=31781, name="Lindsay - Redridge Mountains", category="Eastern Kingdoms", waypoint={map=49, x=33.2, y=52.4, title="Lindsay"}},
    {id=31933, name="Okrut Dragonwaste - Dragonblight", category="Northrend", waypoint={map=115, x=59.0, y=77.0, title="Okrut Dragonwaste"}},
    {id=31925, name="Morulu the Elder - Shattrath City", category="Outland", waypoint={map=111, x=58.6, y=69.2, title="Morulu the Elder"}},
    {id=31851, name="Bill Buckler - Cape of Stranglethorn", category="Eastern Kingdoms", waypoint={map=210, x=51.4, y=73.2, title="Bill Buckler"}},
    {id=31905, name="Grazzle the Great - Dustwallow Marsh", category="Kalimdor", faction="Horde",waypoint={map=70, x=53.8, y=74.8, title="Grazzle the Great"}},
    {id=31910, name="David Kosse - The Hinterlands", category="Eastern Kingdoms", waypoint={map=26, x=62.8, y=54.4, title="David Kosse"}},
    {id=31907, name="Zoltan - Felwood", category="Kalimdor", faction="Horde",waypoint={map=77, x=40.0, y=56.4, title="Zoltan"}},
    {id=31871, name="Traitor Gluk - Feralas", category="Kalimdor", faction="Horde",waypoint={map=69, x=59.6, y=49.6, title="Traitor Gluk"}},
    {id=31908, name="Elena Flutterfly - Moonglade", category="Kalimdor", faction="Horde",waypoint={map=80, x=46.0, y=60.4, title="Elena Flutterfly"}},
    {id=31914, name="Durin Darkhammer - Burning Steppes", category="Eastern Kingdoms", waypoint={map=36, x=25.4, y=47.4, title="Durin Darkhammer"}},
    {id=31850, name="Eric Davidson - Duskwood", category="Eastern Kingdoms", waypoint={map=47, x=19.8, y=44.8, title="Eric Davidson"}},
    {id=31904, name="Cassandra Kaboom - Southern Barrens", category="Kalimdor", faction="Horde",waypoint={map=199, x=39.6, y=79.2, title="Cassandra Kaboom"}},
    {id=31852, name="Steven Lisbane - Northern Stranglethorn", category="Eastern Kingdoms", waypoint={map=50, x=46.0, y=40.4, title="Steven Lisbane"}},
    {id=31906, name="Kela Grimtotem - Thousand Needles", category="Kalimdor", faction="Horde",waypoint={map=64, x=31.8, y=32.8 , title="Kela Grimtotem"}},
    {id=31912, name="Kortas Darkhammer - Searing Gorge", category="Eastern Kingdoms", waypoint={map=32, x=35.6, y=27.8, title="Kortas Darkhammer"}},
    {id=31854, name="Analynn - Ashenvale", category="Kalimdor", faction="Horde",waypoint={map=63, x=20.0, y=29.4, title="Analynn"}},
    {id=31911, name="Deiza Plaguehorn - Eastern Plaguelands", category="Eastern Kingdoms", waypoint={map=23, x=67.0, y=52.4, title="Deiza Plaguehorn"}},
    {id=31913, name="Everessa - Swamp of Sorrows", category="Eastern Kingdoms", waypoint={map=51, x=76.6, y=41.6, title="Everessa"}},
    {id=31974, name="Goz Banefury", category="Eastern Kingdoms", waypoint={map=241, x=56.4, y=56.8, title="Goz Banefury"}},
}



table.sort(quests, function(a, b) return a.name < b.name end)
table.sort(optionalQuests, function(a, b) return a.name < b.name end)

-- Per-quest enable/disable logic
local function isQuestEnabled(questID)
    db.enabledQuests = db.enabledQuests or {}
    -- Optional quests: default to disabled
    for _, q in ipairs(optionalQuests) do
        if q.id == questID then
            if db.enabledQuests[questID] == nil then
                return false
            end
        end
    end
    -- Main quests: default to enabled
    if db.enabledQuests[questID] == nil then
        return true
    end
    return db.enabledQuests[questID]
end

local function setQuestEnabled(questID, enabled)
    db.enabledQuests = db.enabledQuests or {}
    db.enabledQuests[questID] = enabled
    requestUpdate()
end

-- Config frame
local configFrame
local function createConfigFrame()
    if configFrame then
        configFrame:Show()
        return
    end

    configFrame = CreateFrame("Frame", "QuestTrackerConfigFrame", UIParent, "BackdropTemplate")
    configFrame:SetSize(350, 400)
    configFrame:SetPoint("CENTER")
    configFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    configFrame:SetBackdropColor(0, 0, 0, 0.9)
    configFrame:SetBackdropBorderColor(0.8, 0.8, 0.8)
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)

    local playerFaction = UnitFactionGroup("player")

    local title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("Quest Tracker Configuration")

    local close = CreateFrame("Button", nil, configFrame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -4, -4)

    -- ScrollFrame for quest list
    local scrollFrame = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 12, -40)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 12)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(1, 1)
    scrollFrame:SetScrollChild(content)

    local y = 0

    -- Main dailies label
    local mainLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainLabel:SetPoint("TOPLEFT", 0, -y)
    mainLabel:SetText("Main Dailies (Reward a Sack of Pet Supplies)")
    y = y + 20

    -- Main quest checkboxes
    for i, q in ipairs(quests) do
        if not q.faction or q.faction == playerFaction then
            local cb = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 0, -y)
            cb.Text:SetText(q.name)
            cb:SetChecked(isQuestEnabled(q.id))
            cb:SetScript("OnClick", function(self)
                setQuestEnabled(q.id, self:GetChecked())
            end)
            y = y + 24
        end
    end

    -- Optional quests label
    local optLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optLabel:SetPoint("TOPLEFT", 0, -y - 8)
    optLabel:SetText("Optional Dailies (No Sack of Pet Supplies)")
    y = y + 32

    -- Optional quest checkboxes
    for i, q in ipairs(optionalQuests) do
        if not q.faction or q.faction == playerFaction then
            local cb = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
            cb:SetPoint("TOPLEFT", 0, -y)
            cb.Text:SetText(q.name)
            cb:SetChecked(isQuestEnabled(q.id))
            cb:SetScript("OnClick", function(self)
                setQuestEnabled(q.id, self:GetChecked())
            end)
            y = y + 24
        end
    end

    content:SetHeight(y)
end

-- Slash command
SLASH_QUESTTRACKER1 = "/qt"
SlashCmdList["QUESTTRACKER"] = function(msg)
    msg = msg:lower():gsub("^%s+", "")
    if msg == "config" then
        createConfigFrame()
    else
        print("|cffffd200QuestTracker:|r Type /qt config to open configuration.")
    end
end

-- Table to hold clickable line buttons
local questLineButtons = {}
local beastObjectiveButtons = {}

local collapsedQuests = {}

local function groupQuestsByCategory(questList)
    local categories = {}
    for _, q in ipairs(questList) do
        local cat = q.category or "Other"
        if not categories[cat] then categories[cat] = {} end
        table.insert(categories[cat], q)
    end
    return categories
end

-- local function updateQuestText()
--     local playerFaction = UnitFactionGroup("player")
--     local questEntries = {}
--     for _, q in ipairs(quests) do
--         if isQuestEnabled(q.id) and (not q.dmfOnly or dmfActive) and not C_QuestLog.IsQuestFlaggedCompleted(q.id) and (not q.faction or q.faction == playerFaction) then
--             table.insert(questEntries, q)
--         end
--     end
--     for _, q in ipairs(optionalQuests) do
--         if isQuestEnabled(q.id) and not C_QuestLog.IsQuestFlaggedCompleted(q.id) and (not q.faction or q.faction == playerFaction) then
--             table.insert(questEntries, q)
--         end
--     end

--     local categories = groupQuestsByCategory(questEntries)
--     local orderedCategories = {
--         "Kalimdor", "Eastern Kingdoms", "Outland", "Northrend", "Elemental Plane",
--         "Darkmoon Island", "Pandaria", "PvP", "Other"
--     }

--     -- Find the last category that will actually be displayed
--     local lastVisibleCategory
--     for i = #orderedCategories, 1, -1 do
--         local catName = orderedCategories[i]
--         if categories[catName] and #categories[catName] > 0 then
--             lastVisibleCategory = catName
--             break
--         end
--     end

--     -- Find the widest line for sizing
--     local maxWidth = 0
--     local tempFont = text

--     -- Check category header widths (they use a different, larger font)
--     tempFont:SetFontObject(GameFontNormal)
--     for catName, _ in pairs(categories) do
--         tempFont:SetText(catName)
--         local w = tempFont:GetStringWidth()
--         if w > maxWidth then maxWidth = w end
--     end
--     tempFont:SetFontObject(GameFontHighlightSmall) -- Set it back for quests

--     for _, q in ipairs(questEntries) do
--         local isComplete = IsQuestComplete(q.id)
--         local isTurnedIn = C_QuestLog.IsQuestFlaggedCompleted(q.id)
--         local displayName = q.name
--         if q.showProgress then
--             displayName = displayName .. getQuestProgressString(q.id)
--         end
--         -- Add the "!" icon at the end if completed-but-not-turned-in
--         if not q.objectives and isComplete and not isTurnedIn then
--             displayName = "|cffffff00" .. displayName .. "|r  |TInterface\\GossipFrame\\AvailableQuestIcon:16:16:0:0|t"
--         end
--         tempFont:SetText(displayName)
--         local w = tempFont:GetStringWidth()
--         if w > maxWidth then maxWidth = w end

--         -- Check for objectives
--         if q.objectives then
--             for _, obj in ipairs(q.objectives) do
--                 tempFont:SetText("    " .. obj.name)
--                 local w2 = tempFont:GetStringWidth()
--                 if w2 > maxWidth then maxWidth = w2 end
--             end
--         end
--     end

--     text:SetText("")
--     text:SetWidth(maxWidth)
--     local lineHeight = text:GetLineHeight()
--     local totalLines = 0

--     -- Draw quest lines and objectives
--     local btnIdx, objBtnIdx = 1, 1
--     for _, cat in ipairs(orderedCategories) do
--         local catQuests = categories[cat]
--         if catQuests and #catQuests > 0 then
--             -- Draw category header
--             local catBtn = questLineButtons[btnIdx] or CreateFrame("Button", nil, content)
--             if not questLineButtons[btnIdx] then
--                 catBtn.text = catBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
--                 catBtn.text:SetJustifyH("LEFT")
--                 catBtn.text:SetJustifyV("TOP")
--                 catBtn.text:SetPoint("LEFT")
--                 catBtn.text:SetPoint("RIGHT")
--                 questLineButtons[btnIdx] = catBtn
--             end
--             catBtn:Show()
--             catBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((totalLines) * lineHeight))
--             catBtn:SetSize(maxWidth, lineHeight)
--             catBtn:SetHighlightTexture("")
--             catBtn.text:SetFontObject(GameFontNormal)
--             catBtn.text:SetText(cat)
--             catBtn:SetScript("OnClick", nil)
--             catBtn:SetScript("OnEnter", nil)
--             catBtn:SetScript("OnLeave", nil)
--             btnIdx = btnIdx + 1
--             totalLines = totalLines + 1

--             -- Draw quests in this category
--             for _, q in ipairs(catQuests) do
--                 -- Main quest line
--                 local btn = questLineButtons[btnIdx] or CreateFrame("Button", nil, content)
--                 if not questLineButtons[btnIdx] then
--                     btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
--                     btn.text:SetJustifyH("LEFT")
--                     btn.text:SetJustifyV("TOP")
--                     btn.text:SetPoint("LEFT")
--                     btn.text:SetPoint("RIGHT")
--                     questLineButtons[btnIdx] = btn
--                 end
--                 btn:Show()
--                 btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((totalLines) * lineHeight))
--                 btn:SetSize(maxWidth, lineHeight)
--                 btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
--                 local isComplete = IsQuestComplete(q.id)
--                 local isTurnedIn = C_QuestLog.IsQuestFlaggedCompleted(q.id)
--                 local displayName = q.name
--                 if q.showProgress then
--                     displayName = displayName .. getQuestProgressString(q.id)
--                 end

--                 -- Visual feedback for completed-but-not-turned-in quests (not Beasts of Fable)
--                 if not q.objectives and isComplete and not isTurnedIn then
--                     displayName = "|TInterface\\GossipFrame\\AvailableQuestIcon:16:16:0:0|t |cffffff00" .. displayName .. "|r"
--                 end

--                 btn.text:SetFontObject(GameFontHighlightSmall)
--                 btn.text:SetText(displayName)
--                 btn:SetScript("OnClick", nil)
--                 btn:SetScript("OnEnter", nil)
--                 btn:SetScript("OnLeave", nil)

--                 if q.objectives then
--                     -- Collapse/expand for Beasts of Fable
--                     btn:SetScript("OnClick", function()
--                         collapsedQuests[q.id] = not collapsedQuests[q.id]
--                         updateQuestText()
--                     end)
--                     btn:SetScript("OnEnter", function(self)
--                         GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
--                         GameTooltip:SetText(collapsedQuests[q.id] and "Expand" or "Collapse", 1, 1, 1)
--                         GameTooltip:Show()
--                     end)
--                     btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
--                 elseif q.waypoint and TomTom then
--                     btn:SetScript("OnClick", function()
--                         if TomTom.RemoveAllWaypoints then
--                             TomTom:RemoveAllWaypoints()
--                         end
--                         TomTom:AddWaypoint(q.waypoint.map, q.waypoint.x/100, q.waypoint.y/100, {title=q.waypoint.title or q.name})
--                     end)
--                     btn:SetScript("OnEnter", function(self)
--                         GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
--                         if isComplete and not isTurnedIn then
--                             GameTooltip:SetText("Quest complete!\n|cffffcc00Don't forget to turn in for rewards!|r", 1, 1, 1)
--                         else
--                             GameTooltip:SetText("Set TomTom waypoint for " .. (q.waypoint.title or q.name), 1, 1, 1)
--                         end
--                         GameTooltip:Show()
--                     end)
--                     btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
--                 end

--                 btnIdx = btnIdx + 1
--                 totalLines = totalLines + 1

--                 -- Objectives (for Beasts of Fable)
--                 if q.objectives and not collapsedQuests[q.id] then
--                     local objectives = C_QuestLog.GetQuestObjectives(q.id)
--                     for objIdx, beast in ipairs(q.objectives) do
--                         local beastBtn = beastObjectiveButtons[objBtnIdx] or CreateFrame("Button", nil, content)
--                         if not beastObjectiveButtons[objBtnIdx] then
--                             beastBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
--                             beastBtn.text = beastBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
--                             beastBtn.text:SetJustifyH("LEFT")
--                             beastBtn.text:SetJustifyV("TOP")
--                             beastBtn.text:SetPoint("LEFT")
--                             beastBtn.text:SetPoint("RIGHT")
--                             beastObjectiveButtons[objBtnIdx] = beastBtn
--                         end
--                         beastBtn:Show()
--                         beastBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -((totalLines) * lineHeight))
--                         beastBtn:SetSize(maxWidth, lineHeight)

--                         -- Determine completion
--                         local completed = false
--                         if objectives and objectives[objIdx] and objectives[objIdx].finished then
--                             completed = true
--                         end

--                         -- Visual feedback: strikethrough if completed, checkbox otherwise
--                         local beastText = "    "
--                         if completed then
--                             beastText = beastText .. "|cFF888888|TInterface\\Buttons\\UI-CheckBox-Check:16:16:0:0|t|r " .. "|cFF888888" .. beast.name .. "|r"
--                         else
--                             beastText = beastText .. "|TInterface\\Buttons\\UI-CheckBox-Up:16:16:0:0|t " .. beast.name
--                         end
--                         beastBtn.text:SetText(beastText)

--                         -- TomTom waypoint on click
--                         beastBtn:SetScript("OnClick", nil)
--                         beastBtn:SetScript("OnEnter", nil)
--                         beastBtn:SetScript("OnLeave", nil)
--                         if beast.waypoint and TomTom then
--                             beastBtn:SetScript("OnClick", function()
--                                 if TomTom.RemoveWaypoints then
--                                     TomTom:RemoveWaypoints()
--                                 end
--                                 TomTom:AddWaypoint(beast.waypoint.map, beast.waypoint.x/100, beast.waypoint.y/100, {title=beast.waypoint.title or beast.name})
--                             end)
--                             beastBtn:SetScript("OnEnter", function(self)
--                                 GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
--                                 GameTooltip:SetText("Set TomTom waypoint for " .. (beast.waypoint.title or beast.name), 1, 1, 1)
--                                 GameTooltip:Show()
--                             end)
--                             beastBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
--                         end

--                         objBtnIdx = objBtnIdx + 1
--                         totalLines = totalLines + 1
--                     end
--                 end
--             end

--             -- Add 10px spacing after the category block, but not for the last one
--             if cat ~= lastVisibleCategory then
--                 totalLines = totalLines + (10 / lineHeight)
--             end
--         end
--     end

--     -- Hide unused buttons
--     for i = btnIdx, #questLineButtons do
--         questLineButtons[i]:Hide()
--     end
--     for i = objBtnIdx, #beastObjectiveButtons do
--         beastObjectiveButtons[i]:Hide()
--     end

--     if totalLines > 0 then
--         frame:SetSize(maxWidth + PADDING * 2, totalLines * lineHeight + PADDING * 2)
--         frame:Show()
--     else
--         frame:Hide()
--     end
-- end

local function updateQuestText()
    local playerFaction = UnitFactionGroup("player")
    local questEntries = {}
    for _, q in ipairs(quests) do
        if isQuestEnabled(q.id) and (not q.dmfOnly or dmfActive) and not C_QuestLog.IsQuestFlaggedCompleted(q.id) and (not q.faction or q.faction == playerFaction) then
            table.insert(questEntries, q)
        end
    end
    for _, q in ipairs(optionalQuests) do
        if isQuestEnabled(q.id) and not C_QuestLog.IsQuestFlaggedCompleted(q.id) and (not q.faction or q.faction == playerFaction) then
            table.insert(questEntries, q)
        end
    end

    local categories = groupQuestsByCategory(questEntries)
    local orderedCategories = {
        "Kalimdor", "Eastern Kingdoms", "Outland", "Northrend", "Elemental Plane",
        "Darkmoon Island", "Pandaria", "PvP", "Other"
    }

    -- Find last visible category
    local lastVisibleCategory
    for i = #orderedCategories, 1, -1 do
        local catName = orderedCategories[i]
        if categories[catName] and #categories[catName] > 0 then
            lastVisibleCategory = catName
            break
        end
    end

    -- Measure max width (include plus/minus icon in measurement)
    local maxWidth = 0
    local tempFont = text

    tempFont:SetFontObject(GameFontNormal)
    for catName, _ in pairs(categories) do
        tempFont:SetText(catName)
        local w = tempFont:GetStringWidth()
        if w > maxWidth then maxWidth = w end
    end
    tempFont:SetFontObject(GameFontHighlightSmall)

    for _, q in ipairs(questEntries) do
        local isComplete = IsQuestComplete(q.id)
        local isTurnedIn = C_QuestLog.IsQuestFlaggedCompleted(q.id)

        local displayName = q.name
        if q.showProgress then
            displayName = displayName .. getQuestProgressString(q.id)
        end

        if q.objectives then
            local isCollapsed = (collapsedQuests[q.id] == nil) and true or collapsedQuests[q.id]
            local icon = isCollapsed
                and "|TInterface\\Buttons\\UI-PlusButton-Up:14:14:0:0|t "
                or "|TInterface\\Buttons\\UI-MinusButton-Up:14:14:0:0|t "
            displayName = icon .. displayName
        elseif isComplete and not isTurnedIn then
            displayName = "|TInterface\\GossipFrame\\AvailableQuestIcon:16:16:0:0|t |cffffff00" .. displayName .. "|r"
        end

        tempFont:SetText(displayName)
        local w = tempFont:GetStringWidth()
        if w > maxWidth then maxWidth = w end

        if q.objectives then
            for _, obj in ipairs(q.objectives) do
                tempFont:SetText("    " .. obj.name)
                local w2 = tempFont:GetStringWidth()
                if w2 > maxWidth then maxWidth = w2 end
            end
        end
    end

    -- Draw
    text:SetText("")
    text:SetWidth(maxWidth)
    local lineHeight = text:GetLineHeight()
    local totalLines = 0
    local entrySpacing = 2 / lineHeight -- 2px in units of lineHeight
    local btnIdx, objBtnIdx = 1, 1

    for _, cat in ipairs(orderedCategories) do
        local catQuests = categories[cat]
        if catQuests and #catQuests > 0 then
            -- Category header
            local catBtn = questLineButtons[btnIdx] or CreateFrame("Button", nil, content)
            if not questLineButtons[btnIdx] then
                catBtn.text = catBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                catBtn.text:SetJustifyH("LEFT")
                catBtn.text:SetJustifyV("TOP")
                catBtn.text:SetPoint("LEFT")
                catBtn.text:SetPoint("RIGHT")
                questLineButtons[btnIdx] = catBtn
            end
            catBtn:Show()
            catBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(totalLines * lineHeight))
            catBtn:SetSize(maxWidth, lineHeight)
            catBtn.text:SetFontObject(GameFontNormal)
            catBtn.text:SetText(cat)
            btnIdx = btnIdx + 1
            totalLines = totalLines + 1 + entrySpacing

            -- Quests
            for _, q in ipairs(catQuests) do
                local btn = questLineButtons[btnIdx] or CreateFrame("Button", nil, content)
                if not questLineButtons[btnIdx] then
                    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                    btn.text:SetJustifyH("LEFT")
                    btn.text:SetJustifyV("TOP")
                    btn.text:SetPoint("LEFT")
                    btn.text:SetPoint("RIGHT")
                    questLineButtons[btnIdx] = btn
                end
                btn:Show()
                btn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(totalLines * lineHeight))
                btn:SetSize(maxWidth, lineHeight)
                btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

                local isComplete = IsQuestComplete(q.id)
                local isTurnedIn = C_QuestLog.IsQuestFlaggedCompleted(q.id)
                local displayName = q.name
                if q.showProgress then
                    displayName = displayName .. getQuestProgressString(q.id)
                end

                if q.objectives then
                    local isCollapsed = (collapsedQuests[q.id] == nil) and true or collapsedQuests[q.id]
                    local icon = isCollapsed
                        and "|TInterface\\Buttons\\UI-PlusButton-Up:14:14:0:0|t "
                        or "|TInterface\\Buttons\\UI-MinusButton-Up:14:14:0:0|t "
                    displayName = icon .. displayName

                    local qid = q.id
                    btn:SetScript("OnClick", function()
                        collapsedQuests[qid] = not ((collapsedQuests[qid] == nil) and true or collapsedQuests[qid])
                        updateQuestText()
                    end)
                    btn:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        local isCollapsed = (collapsedQuests[qid] == nil) and true or collapsedQuests[qid]
                        GameTooltip:SetText(isCollapsed and "Expand" or "Collapse", 1, 1, 1)
                        GameTooltip:Show()
                    end)
                    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

                elseif isComplete and not isTurnedIn then
                    displayName = "|TInterface\\GossipFrame\\AvailableQuestIcon:16:16:0:0|t |cffffff00" .. displayName .. "|r"
                    if q.waypoint and TomTom then
                        btn:SetScript("OnClick", function()
                            if TomTom.RemoveAllWaypoints then TomTom:RemoveAllWaypoints() end
                            TomTom:AddWaypoint(q.waypoint.map, q.waypoint.x/100, q.waypoint.y/100, {title=q.waypoint.title or q.name})
                        end)
                    end
                elseif q.waypoint and TomTom then
                    btn:SetScript("OnClick", function()
                        if TomTom.RemoveAllWaypoints then TomTom:RemoveAllWaypoints() end
                        TomTom:AddWaypoint(q.waypoint.map, q.waypoint.x/100, q.waypoint.y/100, {title=q.waypoint.title or q.name})
                    end)
                end

                btn.text:SetFontObject(GameFontHighlightSmall)
                btn.text:SetText(displayName)

                btnIdx = btnIdx + 1
                totalLines = totalLines + 1 + entrySpacing

                -- Objectives if expanded: use Texture icons instead of inline tag
                if q.objectives and not ((collapsedQuests[q.id] == nil) and true or collapsedQuests[q.id]) then
                    local objectives = C_QuestLog.GetQuestObjectives(q.id)
                    for objIdx, beast in ipairs(q.objectives) do
                        local beastBtn = beastObjectiveButtons[objBtnIdx] or CreateFrame("Button", nil, content)
                        if not beastObjectiveButtons[objBtnIdx] then
                            beastBtn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

                            -- icon texture (checkbox)
                            beastBtn.icon = beastBtn:CreateTexture(nil, "ARTWORK")
                            beastBtn.icon:SetSize(16, 16)
                            beastBtn.icon:SetPoint("LEFT", beastBtn, "LEFT", 4, 0)

                            -- text placed to the right of the icon
                            beastBtn.text = beastBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                            beastBtn.text:SetJustifyH("LEFT")
                            beastBtn.text:SetJustifyV("TOP")
                            beastBtn.text:SetPoint("LEFT", beastBtn.icon, "RIGHT", 6, 0)
                            beastBtn.text:SetPoint("RIGHT")

                            beastObjectiveButtons[objBtnIdx] = beastBtn
                        end

                        beastBtn:Show()
                        beastBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(totalLines * lineHeight))
                        beastBtn:SetSize(maxWidth, lineHeight)

                        -- Determine completion
                        local completed = objectives and objectives[objIdx] and objectives[objIdx].finished

                        -- Set icon texture and text color
                        if completed then
                            beastBtn.icon:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                            beastBtn.icon:SetVertexColor(0.53, 0.53, 0.53) -- grey
                            beastBtn.text:SetText("|cFF888888" .. beast.name .. "|r")
                        else
                            beastBtn.icon:SetTexture("Interface\\Buttons\\UI-CheckBox-Up")
                            beastBtn.icon:SetVertexColor(1, 1, 1)
                            beastBtn.text:SetText(beast.name)
                        end

                        -- TomTom waypoint on click (if exists)
                        beastBtn:SetScript("OnClick", nil)
                        beastBtn:SetScript("OnEnter", nil)
                        beastBtn:SetScript("OnLeave", nil)
                        if beast.waypoint and TomTom then
                            beastBtn:SetScript("OnClick", function()
                                if TomTom.RemoveWaypoints then TomTom:RemoveWaypoints() end
                                TomTom:AddWaypoint(beast.waypoint.map, beast.waypoint.x/100, beast.waypoint.y/100, {title=beast.waypoint.title or beast.name})
                            end)
                            beastBtn:SetScript("OnEnter", function(self)
                                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                                GameTooltip:SetText("Set TomTom waypoint for " .. (beast.waypoint.title or beast.name), 1, 1, 1)
                                GameTooltip:Show()
                            end)
                            beastBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)
                        end

                        objBtnIdx = objBtnIdx + 1
                        totalLines = totalLines + 1 + entrySpacing
                    end
                end
            end

            -- Remove the spacing from the last item before adding the category gap
            totalLines = totalLines - entrySpacing
            if cat ~= lastVisibleCategory then
                totalLines = totalLines + (10 / lineHeight)
            end
        end
    end

    -- Hide unused buttons
    for i = btnIdx, #questLineButtons do questLineButtons[i]:Hide() end
    for i = objBtnIdx, #beastObjectiveButtons do beastObjectiveButtons[i]:Hide() end

    if totalLines > 0 then
        -- Remove trailing space from the very last item for the final height calculation
        totalLines = totalLines - entrySpacing
        frame:SetSize(maxWidth + PADDING * 2, totalLines * lineHeight + PADDING * 2)
        frame:Show()
    else
        frame:Hide()
    end
end


local function updateTracker()
    -- Only show the frame if the Safari Hat is equipped
    if not IsEquippedItem(SAFARI_HAT_ID) then
        frame:Hide()
        return
    end

    -- If the hat is equipped, proceed with the normal update
    updateQuestText()
end

-- Debouncing logic to prevent multiple rapid updates
local updatePending = false
function requestUpdate()
    if updatePending then return end
    updatePending = true
    C_Timer.After(DEBOUNCE_TIME, function()
        updatePending = false
        updateTracker()
    end)
end

-- Events
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("QUEST_ACCEPTED")
frame:RegisterEvent("QUEST_TURNED_IN")
frame:RegisterEvent("QUEST_LOG_UPDATE")
frame:RegisterEvent("CALENDAR_UPDATE_EVENT_LIST")

frame:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == addonName then
        -- Initialize SavedVariables. This table will be saved account-wide.
        QuestTrackerDB = QuestTrackerDB or {}
        db = QuestTrackerDB

        -- Set default position if none exists
        if not db.position then
            db.position = {
                point = "TOPLEFT",
                relativeTo = "PlayerFrame",
                relativePoint = "BOTTOMLEFT",
                xOfs = 0,
                yOfs = -100,
            }
        end

        -- Load position from saved data
        frame:ClearAllPoints()
        local relativeFrame = _G[db.position.relativeTo] or UIParent
        frame:SetPoint(db.position.point, relativeFrame, db.position.relativePoint, db.position.xOfs, db.position.yOfs)
        return -- Don't update on load, wait for other events
    end

    if event == "PLAYER_ENTERING_WORLD" then
        updateDmfStatus()
    elseif event == "CALENDAR_UPDATE_EVENT_LIST" then
        updateDmfStatus()
    end

    -- For all other events, request an update
    requestUpdate()
end)