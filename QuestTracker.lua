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

local function isDarkmoonFaireActive()
    local today = C_DateAndTime.GetCurrentCalendarTime()
    local numEvents = C_Calendar.GetNumDayEvents(0, today.monthDay)
    for i = 1, numEvents do
        local event = C_Calendar.GetDayEvent(0, today.monthDay, i)
        if event and event.title == "Darkmoon Faire" and event.sequenceType == "ONGOING" then
            return true
        end
    end
    return false
end

local quests = {
    {id=32604, name="Beasts of Fable Book I", showProgress=true},
    {id=32868, name="Beasts of Fable Book II", showProgress=true},
    {id=32869, name="Beasts of Fable Book III", showProgress=true},
    {id=32440, name="Whispering Pandaren Spirit - Jade Forest"},
    {id=32441, name="Thundering Pandaren Spirit - Eternal Blossoms"},
    {id=32434, name="Burning Pandaren Spirit - Townlong Steppes"},
    {id=32439, name="Flowing Pandaren Spirit - Dread Wastes"},
    {id=31958, name="Aki - Eternal Blossoms"},
    {id=31956, name="Yon - Kun-Lai Summit"},
    {id=31955, name="Farmer Nishi - The Four Winds"},
    {id=31954, name="Moruk - Krasarang Wilds"},
    {id=31957, name="Shu - Dread Wastes"},
    {id=31953, name="Hyuna - Jade Forest"},
    {id=31991, name="Zusshi - Townlong Steppes"},
    {id=31909, name="Trixxy - Everlook"},
    {id=31926, name="Antari - Shadowmoon Valley"},
    {id=31971, name="Obalis - Uldum"},
    {id=31935, name="Major Payne - Icecrown"},
    {id=31916, name="Lydia Accoste - Karazhan"},
    {id=32863, name="What we've been Training for"},
    {id=32175, name="Jeremy - Darkmoon Faire", dmfOnly=true},
}

local optionalQuests = {
    {id=31693, name="Julia Stevens - Elwynn Forest"},
    {id=31972, name="Brok - Mount Hyjal"},
    {id=31780, name="Old MacDonald - Westfall"},
    {id=31932, name="Nearly Headless Jacob - Crystalsong Forest"},
    {id=31923, name="Ras'an - Zangarmarsh"},
    {id=31862, name="Zonya the Sadist - Stonetalon Mountains"},
    {id=31924, name="Narrok - Nagrand"},
    {id=31934, name="Gutretch - Zul'Drak"},
    {id=31872, name="Merda Stronghoof - Desolace"},
    {id=31818, name="Zunta - Durotar"},
    {id=31922, name="Nicki Tinytech - Hellfire Peninsula"},
    {id=31931, name="Beegle Blastfuse - Howling Fjord"},
    {id=31819, name="Dagra the Fierce - Northern Barrens"},
    {id=31973, name="Bordin Steadyfist - Deepholm"},
    {id=31781, name="Lindsay - Redridge Mountains"},
    {id=31933, name="Okrut Dragonwaste - Dragonblight"},
    {id=31925, name="Morulu the Elder - Shattrath City"},
    {id=31851, name="Bill Buckler - Cape of Stranglethorn"},
    {id=31905, name="Grazzle the Great - Dustwallow Marsh"},
    {id=31910, name="David Kosse - The Hinterlands"},
    {id=31907, name="Zoltan - Felwood"},
    {id=31871, name="Traitor Gluk - Feralas"},
    {id=31908, name="Elena Flutterfly - Moonglade"},
    {id=31914, name="Durin Darkhammer - Burning Steppes"},
    {id=31850, name="Eric Davidson - Burning Steppes"},
    {id=31904, name="Cassandra Kaboom - Northern Stranglethorn"},
    {id=31852, name="Steven Lisbane - Deadwind Pass"},
    {id=31906, name="Kela Grimtotem - Thousand Needles"},
    {id=31912, name="Kortas Darkhammer - Searing Gorge"},
    {id=31854, name="Analynn - Ashenvale"},
    {id=31911, name="Deiza Plaguehorn - Eastern Plaguelands"},
    {id=31913, name="Everessa - Swamp of Sorrows"},
    {id=31974, name="Goz Banefury - Twilight Highlands"},
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
        local cb = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 0, -y)
        cb.Text:SetText(q.name)
        cb:SetChecked(isQuestEnabled(q.id))
        cb:SetScript("OnClick", function(self)
            setQuestEnabled(q.id, self:GetChecked())
        end)
        y = y + 24
    end

    -- Optional quests label
    local optLabel = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    optLabel:SetPoint("TOPLEFT", 0, -y - 8)
    optLabel:SetText("Optional Dailies (No Sack of Pet Supplies)")
    y = y + 28

    -- Optional quest checkboxes
    for i, q in ipairs(optionalQuests) do
        local cb = CreateFrame("CheckButton", nil, content, "ChatConfigCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", 0, -y)
        cb.Text:SetText(q.name)
        cb:SetChecked(isQuestEnabled(q.id))
        cb:SetScript("OnClick", function(self)
            setQuestEnabled(q.id, self:GetChecked())
        end)
        y = y + 24
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

-- Update updateQuestText to include optionalQuests
local function updateQuestText()
    local dmfActive = isDarkmoonFaireActive()
    local lines = {}

    for _, q in ipairs(quests) do
        if isQuestEnabled(q.id) then
            if not q.dmfOnly or dmfActive then
                if not C_QuestLog.IsQuestFlaggedCompleted(q.id) then
                    local displayName = q.name
                    if q.showProgress then
                        displayName = displayName .. getQuestProgressString(q.id)
                    end
                    table.insert(lines, displayName)
                end
            end
        end
    end
    for _, q in ipairs(optionalQuests) do
        if isQuestEnabled(q.id) then
            if not C_QuestLog.IsQuestFlaggedCompleted(q.id) then
                table.insert(lines, q.name)
            end
        end
    end

    if #lines == 0 then
        frame:Hide()
        return
    end

    -- Find the widest line
    local maxWidth = 0
    for _, line in ipairs(lines) do
        text:SetText(line)
        local w = text:GetStringWidth()
        if w > maxWidth then
            maxWidth = w
        end
    end

    -- Restore full text and set final size
    text:SetText(table.concat(lines, "\n"))
    text:SetWidth(maxWidth)
    local height = text:GetStringHeight()
    frame:SetSize(maxWidth + PADDING * 2, height + PADDING * 2)
    frame:Show()
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

    -- For all other events, request an update
    requestUpdate()
end)