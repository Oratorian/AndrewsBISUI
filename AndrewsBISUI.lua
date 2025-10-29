-- AndrewsBISUI - Best-in-Slot Gear Tool
local addonName, addon = ...

-- Initialize addon namespace
AndrewsBISUI = AndrewsBISUI or {}
local ABIS = AndrewsBISUI

-- Default settings (will be overridden by SavedVariables)
ABIS.Defaults = {
    minimapButton = {
        hide = false,
        position = 180,  -- degrees around minimap
    },
    uiScale = 1.0,  -- UI scale for character panel (0.5 to 1.5)
}

-- Stored BiS data sets (empty - will be populated from SavedVariables or user imports)
-- NOTE: BISData is now stored per-character in AndrewsBISUICharDB
ABIS.BISData = {}

ABIS.CurrentBISSet = nil
ABIS.CurrentCharacter = nil  -- Stores current character name for display

-- Create UI Frame for manual item ID import
function ABIS:CreateImportFrame()
    if self.importFrame then
        self.importFrame:SetFrameLevel(self.importFrame:GetFrameLevel() + 10)
        self.importFrame:Show()
        self.importFrame:Raise()  -- Bring to front
        return
    end

    local frame = CreateFrame("Frame", "AndrewsBISImportFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(500, 300)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")  -- Highest level
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.title:SetPoint("TOP", 0, -5)
    frame.title:SetText("Andrews BiS Importer")

    -- Manual Import Mode
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", 0, -40)
    instructions:SetText("Get your BiS item IDs from our scraper:")
    instructions:SetTextColor(1, 1, 1)

    -- Open Scraper Button with modern styling
    local openScraperBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    openScraperBtn:SetSize(250, 35)
    openScraperBtn:SetPoint("TOP", 0, -80)
    openScraperBtn:SetText("Click here to open BiS Scraper")
    openScraperBtn:SetNormalFontObject("GameFontNormal")
    openScraperBtn:SetHighlightFontObject("GameFontHighlight")

    -- Modern button backdrop
    openScraperBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    openScraperBtn:SetBackdropColor(0.15, 0.15, 0.17, 1)
    openScraperBtn:SetBackdropBorderColor(0.6, 0.6, 0.65, 1)

    -- Add hover glow effect
    openScraperBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    local highlight = openScraperBtn:GetHighlightTexture()
    highlight:SetBlendMode("ADD")

    openScraperBtn:SetScript("OnClick", function()
        ABIS:ShowAPIURLBox()
    end)

    local scraperHelp = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scraperHelp:SetPoint("TOP", openScraperBtn, "BOTTOM", 0, -10)
    scraperHelp:SetText("This will show you the API URL to open in your browser")
    scraperHelp:SetTextColor(0.7, 0.7, 0.7)

    -- Manual Import Instructions
    local manualText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    manualText:SetPoint("TOP", 0, -140)
    manualText:SetText("After scraping, paste the import string below:")
    manualText:SetTextColor(1, 1, 0.5)

    -- Multi-line ScrollFrame for import string with modern styling
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate, BackdropTemplate")
    scrollFrame:SetPoint("TOP", 0, -165)
    scrollFrame:SetSize(450, 80)

    -- Modern backdrop for scroll area
    scrollFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    scrollFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    scrollFrame:SetBackdropBorderColor(0.5, 0.5, 0.55, 1)

    -- EditBox inside ScrollFrame
    local itemIDBox = CreateFrame("EditBox", nil, scrollFrame)
    itemIDBox:SetMultiLine(true)
    itemIDBox:SetSize(420, 200)
    itemIDBox:SetPoint("TOPLEFT", 8, -8)
    itemIDBox:SetFontObject("ChatFontNormal")
    itemIDBox:SetAutoFocus(false)
    itemIDBox:SetMaxLetters(0)  -- No limit
    itemIDBox:SetTextInsets(10, 10, 10, 10)  -- Add padding inside EditBox for text
    itemIDBox:SetText("Click here to paste your import string...")
    itemIDBox:SetTextColor(0.5, 0.5, 0.5)  -- Gray placeholder text

    -- Clear placeholder text when clicked
    itemIDBox:SetScript("OnEditFocusGained", function(editBox)
        if editBox:GetText() == "Click here to paste your import string..." then
            editBox:SetText("")
            editBox:SetTextColor(1, 1, 1)  -- White text for actual content
        end
    end)

    -- Restore placeholder if empty when focus is lost
    itemIDBox:SetScript("OnEditFocusLost", function(editBox)
        if editBox:GetText() == "" then
            editBox:SetText("Click here to paste your import string...")
            editBox:SetTextColor(0.5, 0.5, 0.5)  -- Gray placeholder text
        end
    end)

    itemIDBox:SetScript("OnEscapePressed", function(editBox)
        editBox:ClearFocus()
    end)

    scrollFrame:SetScrollChild(itemIDBox)

    -- Import Button with modern styling
    local importBtn = CreateFrame("Button", nil, frame, "BackdropTemplate")
    importBtn:SetSize(150, 30)
    importBtn:SetPoint("TOP", 0, -260)
    importBtn:SetText("Import Items")
    importBtn:SetNormalFontObject("GameFontNormal")
    importBtn:SetHighlightFontObject("GameFontHighlight")

    -- Modern button backdrop (green accent for import action)
    importBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    importBtn:SetBackdropColor(0.1, 0.15, 0.1, 1)
    importBtn:SetBackdropBorderColor(0.5, 0.7, 0.5, 1)

    -- Add hover glow effect
    importBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    local highlight = importBtn:GetHighlightTexture()
    highlight:SetBlendMode("ADD")

    importBtn:SetScript("OnClick", function()
        local importString = itemIDBox:GetText()
        -- Check if user has entered something (not empty and not the placeholder)
        if importString and importString ~= "" and importString ~= "Click here to paste your import string..." then
            ABIS:ImportItemIDs(importString)
            frame:Hide()
        else
            print("|cFFFF0000Please paste the import string first!|r")
        end
    end)

    self.importFrame = frame

    -- Ensure it's on top
    frame:SetFrameLevel(1000)
    frame:Raise()
end

-- Show API URL copy box
function ABIS:ShowAPIURLBox()
    if self.apiURLBox then
        self.apiURLBox:SetFrameLevel(2000)
        self.apiURLBox:Show()
        self.apiURLBox:Raise()
        return
    end

    local frame = CreateFrame("Frame", "AndrewsBISAPIURLBox", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(550, 580)
    frame:SetPoint("CENTER")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetFrameLevel(2000)  -- Higher than import frame (1000)

    frame.TitleText:SetText("BiS Scraper API URL")

    -- Instructions
    local instructions = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    instructions:SetPoint("TOP", 0, -35)
    instructions:SetText("Copy this URL and open it in your web browser:")
    instructions:SetTextColor(1, 1, 1)

    -- API URL Box
    local urlBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    urlBox:SetSize(500, 30)
    urlBox:SetPoint("TOP", 0, -65)
    urlBox:SetAutoFocus(true)
    urlBox:SetText("https://andrewsbisui.middleton.one/")
    urlBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    urlBox:HighlightText()

    -- Help text
    local helpText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    helpText:SetPoint("TOP", 0, -105)
    helpText:SetWidth(500)
    helpText:SetJustifyH("CENTER")
    helpText:SetText("Paste your Wowhead BiS guide URL in the browser,\nthen copy the item IDs back into the addon.")
    helpText:SetTextColor(0.7, 0.7, 0.7)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
    closeBtn:SetSize(100, 30)
    closeBtn:SetPoint("BOTTOM", 0, 15)
    closeBtn:SetText("Close")
    closeBtn:SetNormalFontObject("GameFontNormal")
    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    self.apiURLBox = frame
end

-- Create Character Panel GUI
function ABIS:CreateCharacterPanel()
    if self.characterPanel then
        self.characterPanel:Show()
        self:RefreshCharacterPanel()  -- Auto-refresh when opening
        return
    end

    local frame = CreateFrame("Frame", "AndrewsBISCharacterPanel", UIParent, "BasicFrameTemplateWithInset")

    -- Restore saved size and position, or use defaults
    local savedWidth = AndrewsBISUIDB.settings.windowWidth or 700
    local savedHeight = AndrewsBISUIDB.settings.windowHeight or 350
    frame:SetSize(savedWidth, savedHeight)

    if AndrewsBISUIDB.settings.windowPos then
        local pos = AndrewsBISUIDB.settings.windowPos
        frame:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        frame:SetPoint("CENTER")
    end

    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, xOfs, yOfs = f:GetPoint()
        AndrewsBISUIDB.settings.windowPos = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end)
    frame:SetFrameStrata("DIALOG")

    -- Set size constraints (minWidth, minHeight, maxWidth, maxHeight)
    frame:SetResizeBounds(500, 580, 900, 900)

    -- Create resize button in bottom-right corner
    local resizeButton = CreateFrame("Button", nil, frame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT", -5, 5)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeButton:SetScript("OnMouseDown", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)

    resizeButton:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        ABIS:UpdateButtonLayout()

        -- Save window size
        AndrewsBISUIDB.settings.windowWidth = frame:GetWidth()
        AndrewsBISUIDB.settings.windowHeight = frame:GetHeight()
    end)

    frame.resizeButton = resizeButton

    -- Shift key handler to show all enchant tooltips
    frame:SetScript("OnUpdate", function(f)
        local isShiftDown = IsShiftKeyDown()

        -- Toggle tooltip visibility based on shift key
        if isShiftDown and not f.shiftWasDown then
            -- Shift just pressed - show all enchant tooltips
            ABIS:ShowAllEnchantTooltips()
            f.shiftWasDown = true
        elseif not isShiftDown and f.shiftWasDown then
            -- Shift just released - hide all enchant tooltips
            ABIS:HideAllEnchantTooltips()
            f.shiftWasDown = false
        end
    end)

    -- Title uses the default TitleText from template
    frame.TitleText:SetText("Discipline Priest Season 3")

    -- Character name display
    frame.characterName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.characterName:SetPoint("TOP", frame.TitleText, "BOTTOM", 0, -15)
    frame.characterName:SetTextColor(0.7, 0.7, 0.7)
    frame.characterName:SetText("")

    -- UI Scale slider (outside frame, on the right side)
    local scaleSlider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", frame, "TOPRIGHT", 10, -50)
    scaleSlider:SetWidth(20)
    scaleSlider:SetHeight(300)
    scaleSlider:SetOrientation("VERTICAL")
    scaleSlider:SetMinMaxValues(0.5, 1.5)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)
    scaleSlider:SetValue(AndrewsBISUIDB.settings.uiScale or 1.0)

    -- Hide default slider text elements
    scaleSlider.Low:SetText("")
    scaleSlider.High:SetText("")
    scaleSlider.Text:SetText("")

    -- Scale percentage label (above slider)
    frame.scaleLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.scaleLabel:SetPoint("BOTTOM", scaleSlider, "TOP", 0, 5)
    frame.scaleLabel:SetText(string.format("%.0f%%", (AndrewsBISUIDB.settings.uiScale or 1.0) * 100))
    frame.scaleLabel:SetTextColor(1, 0.82, 0)

    -- Scale text label
    local scaleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleText:SetPoint("BOTTOM", frame.scaleLabel, "TOP", 0, 2)
    scaleText:SetText("Scale:")

    -- Track if we're currently dragging to prevent feedback loop
    local isDragging = false

    scaleSlider:SetScript("OnMouseDown", function()
        isDragging = true
    end)

    scaleSlider:SetScript("OnMouseUp", function()
        isDragging = false
    end)

    scaleSlider:SetScript("OnValueChanged", function(_, value)
        AndrewsBISUIDB.settings.uiScale = value
        frame.scaleLabel:SetText(string.format("%.0f%%", value * 100))

        -- Only apply scale when not actively dragging to prevent cursor offset issues
        if not isDragging then
            frame:SetScale(value)
        end
    end)

    -- Apply final scale when mouse is released
    scaleSlider:SetScript("OnMouseUp", function(slider)
        isDragging = false
        frame:SetScale(slider:GetValue())
    end)

    -- Slot layout - positioned relative to frame top, accounting for title
    local slotLayout = {
        -- Left column
        {slot = "Head", column = "left", row = 0},
        {slot = "Neck", column = "left", row = 1},
        {slot = "Shoulders", column = "left", row = 2},
        {slot = "Cloak", column = "left", row = 3},
        {slot = "Chest", column = "left", row = 4},
        {slot = "Wrists", column = "left", row = 5},
        {slot = "Gloves", column = "left", row = 6},
        {slot = "Belt", column = "left", row = 7},

        -- Right column
        {slot = "Legs", column = "right", row = 0},
        {slot = "Boots", column = "right", row = 1},
        {slot = "Ring1", column = "right", row = 2},
        {slot = "Ring2", column = "right", row = 3},
        {slot = "Trinket1", column = "right", row = 4},
        {slot = "Trinket2", column = "right", row = 5},
        {slot = "MainHand", column = "right", row = 6},
        {slot = "OffHand", column = "right", row = 7},
    }

    frame.slotButtons = {}
    frame.slotLayout = slotLayout

    for _, slotInfo in ipairs(slotLayout) do
        local slotFrame = self:CreateItemSlotButton(frame, slotInfo.slot)
        -- Initial positioning (will be updated by UpdateButtonLayout)
        local xPos = slotInfo.column == "left" and 15 or 305
        local yPos = -50 - (slotInfo.row * 40)
        slotFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", xPos, yPos)
        slotFrame.layoutInfo = slotInfo
        frame.slotButtons[slotInfo.slot] = slotFrame
    end

    -- Button container at bottom
    local buttonContainer = CreateFrame("Frame", nil, frame)
    buttonContainer:SetSize(300, 30)
    buttonContainer:SetPoint("BOTTOM", 0, 8)

    -- Progress text above buttons
    frame.progressText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.progressText:SetPoint("BOTTOM", buttonContainer, "TOP", 0, 5)
    frame.progressText:SetTextColor(0.7, 0.7, 0.7)
    frame.progressText:SetText("")

    -- Alternative items container (between progress and hint text)
    local altItemsContainer = CreateFrame("Frame", nil, frame)
    altItemsContainer:SetSize(660, 40)
    altItemsContainer:SetPoint("BOTTOM", frame.progressText, "TOP", 0, 5)
    frame.altItemsContainer = altItemsContainer
    frame.altItemsButtons = {}  -- Store alternative item buttons

    -- Alternative items label
    altItemsContainer.label = altItemsContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    altItemsContainer.label:SetPoint("TOPLEFT", 0, 0)
    altItemsContainer.label:SetTextColor(0.8, 0.6, 1.0)  -- Purple color for alternatives
    altItemsContainer.label:SetText("")
    altItemsContainer:Hide()  -- Hidden by default, shown when alternatives exist

    -- Hint text above alternative items
    frame.hintText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.hintText:SetPoint("BOTTOM", altItemsContainer, "TOP", 0, 3)
    frame.hintText:SetTextColor(0.5, 0.7, 1.0)  -- Light blue color
    frame.hintText:SetText("Hold Shift to view all enchant tooltips")

    -- Import button with modern styling (blue accent)
    local importBtn = CreateFrame("Button", nil, buttonContainer, "BackdropTemplate")
    importBtn:SetSize(90, 25)
    importBtn:SetPoint("LEFT", 0, 0)
    importBtn:SetText("Import")
    importBtn:SetNormalFontObject("GameFontNormalSmall")
    importBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    importBtn:SetBackdropColor(0.1, 0.12, 0.2, 1)
    importBtn:SetBackdropBorderColor(0.4, 0.5, 0.8, 1)

    -- Add hover glow effect
    local importHighlight = importBtn:GetHighlightTexture() or importBtn:CreateTexture(nil, "HIGHLIGHT")
    importHighlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    importHighlight:SetBlendMode("ADD")
    importHighlight:SetAllPoints(importBtn)
    importBtn:SetHighlightTexture(importHighlight)

    importBtn:SetScript("OnClick", function()
        ABIS:CreateImportFrame()
    end)

    -- Clear button with modern styling (orange/warning accent)
    local clearBtn = CreateFrame("Button", nil, buttonContainer, "BackdropTemplate")
    clearBtn:SetSize(90, 25)
    clearBtn:SetPoint("CENTER", 0, 0)
    clearBtn:SetText("Clear")
    clearBtn:SetNormalFontObject("GameFontNormalSmall")
    clearBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    clearBtn:SetBackdropColor(0.2, 0.12, 0.05, 1)
    clearBtn:SetBackdropBorderColor(0.8, 0.5, 0.2, 1)

    -- Add hover glow effect
    local clearHighlight = clearBtn:GetHighlightTexture() or clearBtn:CreateTexture(nil, "HIGHLIGHT")
    clearHighlight:SetTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    clearHighlight:SetBlendMode("ADD")
    clearHighlight:SetAllPoints(clearBtn)
    clearBtn:SetHighlightTexture(clearHighlight)

    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("ABIS_CONFIRM_CLEAR")
    end)

    -- Close button with modern styling (red accent)
    local closeBtn = CreateFrame("Button", nil, buttonContainer, "BackdropTemplate")
    closeBtn:SetSize(90, 25)
    closeBtn:SetPoint("RIGHT", 0, 0)
    closeBtn:SetText("Close")
    closeBtn:SetNormalFontObject("GameFontNormalSmall")
    closeBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    closeBtn:SetBackdropColor(0.18, 0.1, 0.1, 1)
    closeBtn:SetBackdropBorderColor(0.7, 0.4, 0.4, 1)

    -- Add hover glow effect
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")
    local closeHighlight = closeBtn:GetHighlightTexture()
    closeHighlight:SetBlendMode("ADD")

    closeBtn:SetScript("OnClick", function()
        frame:Hide()
    end)

    self.characterPanel = frame

    -- Register events for automatic refresh when window is open
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:RegisterEvent("BAG_UPDATE_DELAYED")
    frame:SetScript("OnEvent", function(f)
        if f:IsShown() then
            -- Auto-refresh when equipment changes or bags update
            ABIS:RefreshCharacterPanel()
        end
    end)

    -- Unregister events when window is hidden to save performance
    frame:SetScript("OnHide", function(f)
        f:UnregisterEvent("PLAYER_EQUIPMENT_CHANGED")
        f:UnregisterEvent("BAG_UPDATE_DELAYED")
    end)

    -- Re-register events when window is shown
    frame:SetScript("OnShow", function(f)
        f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        f:RegisterEvent("BAG_UPDATE_DELAYED")
        ABIS:RefreshCharacterPanel()  -- Refresh when opening
    end)

    -- Apply saved UI scale
    if AndrewsBISUIDB and AndrewsBISUIDB.settings then
        frame:SetScale(AndrewsBISUIDB.settings.uiScale or 1.0)
    end

    self:UpdateButtonLayout()  -- Initial layout
    self:RefreshCharacterPanel()
end

-- Update button layout when window is resized
function ABIS:UpdateButtonLayout()
    if not self.characterPanel then
        return
    end

    local frame = self.characterPanel
    local frameWidth = frame:GetWidth()

    -- Calculate button width based on frame width
    -- Leave space for margins and divide by 2 for two columns
    local leftMargin = 15
    local columnSpacing = 10
    local buttonWidth = (frameWidth - (leftMargin * 2) - columnSpacing) / 2

    -- Calculate cumulative heights for each column
    local leftColumnY = {}
    local rightColumnY = {}

    -- Build arrays sorted by row
    for slotName, button in pairs(frame.slotButtons) do
        if button.layoutInfo then
            if button.layoutInfo.column == "left" then
                leftColumnY[button.layoutInfo.row] = button
            else
                rightColumnY[button.layoutInfo.row] = button
            end
        end
    end

    -- Update all slot buttons with cumulative positioning
    local startY = -50
    local rowSpacing = 2  -- Reduced from 4 to 2 for taller buttons

    -- Left column
    local currentY = startY
    for row = 0, 7 do
        local button = leftColumnY[row]
        if button then
            button:SetWidth(buttonWidth)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", leftMargin, currentY)
            currentY = currentY - button:GetHeight() - rowSpacing
        end
    end

    -- Right column
    local rightCurrentY = startY
    for row = 0, 7 do
        local button = rightColumnY[row]
        if button then
            button:SetWidth(buttonWidth)
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", frame, "TOPLEFT", leftMargin + buttonWidth + columnSpacing, rightCurrentY)
            rightCurrentY = rightCurrentY - button:GetHeight() - rowSpacing
        end
    end

    -- Note: Frame height is now manually controlled by user resizing
    -- No automatic height adjustment
end

-- Create an item slot button with tooltip and click handling
function ABIS:CreateItemSlotButton(parent, slotName)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(270, 50)
    -- Height will be increased dynamically if enchants exist

    -- Modern clean backdrop with sleek borders (thicker edge)
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = false,
        tileSize = 16,
        edgeSize = 29,  -- Increased from 24 to 29 (5 pixels wider)
        insets = { left = 10, right = 10, top = 10, bottom = 10 }  -- Adjusted insets for thicker border
    })
    button:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
    button:SetBackdropBorderColor(0.6, 0.6, 0.65, 1)

    -- Slot name
    button.slotName = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    button.slotName:SetPoint("LEFT", 18, 0)  -- Increased from 8 to 18 for more padding
    button.slotName:SetText(slotName)
    button.slotName:SetTextColor(1, 0.82, 0)
    button.slotName:SetWidth(75)
    button.slotName:SetJustifyH("LEFT")

    -- Item icon
    button.itemIcon = button:CreateTexture(nil, "ARTWORK")
    button.itemIcon:SetSize(24, 24)
    button.itemIcon:SetPoint("LEFT", button.slotName, "RIGHT", 5, 0)
    button.itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") -- Default
    button.itemIcon:Hide() -- Hidden until we have an item

    -- Item text (clickable, supports item links)
    button.itemText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    button.itemText:SetPoint("LEFT", button.itemIcon, "RIGHT", 5, 0)
    button.itemText:SetPoint("RIGHT", -8, 0)
    button.itemText:SetText("Empty")
    button.itemText:SetTextColor(0.5, 0.5, 0.5)
    button.itemText:SetJustifyH("LEFT")
    button.itemText:SetWordWrap(false)
    button.itemText:SetMaxLines(1)

    -- Enchant buttons container (will be populated later)
    button.enchantButtons = {}

    -- Store slot name
    button.slot = slotName

    -- Highlight on hover
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

    -- Tooltip
    button:SetScript("OnEnter", function(btn)
        if btn.itemID then
            GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(btn.itemID)
            GameTooltip:Show()

            -- Compare with equipped item
            local slotID = ABIS:GetSlotID(btn.slot)
            if slotID then
                GameTooltip_ShowCompareItem()
            end
        end
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click handlers: Shift+Click to link in chat, Ctrl+Click to open Encounter Journal
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", function(btn)
        if btn.itemID then
            if IsControlKeyDown() then
                -- Ctrl+Click: Open Encounter Journal to show where item drops
                -- Use the built-in item link click behavior which opens the journal
                if btn.itemLink then
                    -- Load EJ addon if needed
                    if not C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
                        C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
                    end

                    -- Open EJ if not open
                    if not EncounterJournal or not EncounterJournal:IsShown() then
                        ToggleEncounterJournal()
                    end

                    -- Search for the item in the Encounter Journal
                    C_Timer.After(0.3, function()
                        if not EncounterJournal then
                            print("|cFFFF0000Encounter Journal not loaded|r")
                            return
                        end

                        -- Get item name from link
                        local itemName = btn.itemLink:match("%[(.+)%]")
                        if not itemName then
                            print("|cFFFF0000Could not extract item name|r")
                            return
                        end

                        print("|cFF00FF00Searching for: " .. itemName .. "|r")

                        -- Switch to the Dungeon/Raid tab (not Traveler's Log)
                        ---@diagnostic disable-next-line: undefined-global
                        if EncounterJournalInstanceSelectDungeonTab then
                            ---@diagnostic disable-next-line: undefined-global
                            EncounterJournalInstanceSelectDungeonTab:Click()
                            print("|cFF00FF00Switched to Dungeon tab|r")
                        end

                        -- Wait a moment for tab switch, then search
                        C_Timer.After(0.2, function()
                            -- Try to access the search box
                            ---@diagnostic disable-next-line: undefined-global
                            local searchBox = EncounterJournalSearchBox
                            if searchBox then
                                -- Set the text
                                searchBox:SetText(itemName)
                                searchBox:SetFocus()

                                -- Simulate pressing Enter to execute the search
                                ---@diagnostic disable-next-line: undefined-global
                                if EncounterJournal_ExecuteSearch then
                                    ---@diagnostic disable-next-line: undefined-global
                                    EncounterJournal_ExecuteSearch()
                                    print("|cFF00FF00Search executed|r")
                                elseif searchBox:GetScript("OnEnterPressed") then
                                    searchBox:GetScript("OnEnterPressed")(searchBox)
                                    print("|cFF00FF00Search executed via Enter|r")
                                end
                            else
                                print("|cFFFF0000Search box not found|r")
                            end
                        end)
                    end)
                end
            elseif btn.itemLink and IsShiftKeyDown() then
                -- Shift+Click: Link in chat
                local chatFrame = ChatEdit_GetActiveWindow()
                if chatFrame then
                    chatFrame:Insert(btn.itemLink)
                end
            end
        end
    end)

    return button
end

--- Create an alternative item button (simpler than main slot buttons)
function ABIS:CreateAlternativeItemButton(parent, altItem)
    -- Container frame to hold both button and label
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(60, 55)  -- Wider to accommodate label below button

    local button = CreateFrame("Button", nil, container, "BackdropTemplate")
    button:SetSize(40, 40)
    button:SetPoint("TOP", 0, 0)
    button.slot = altItem.slot
    button.itemID = altItem.itemID
    button.isAlternative = true

    -- Backdrop with purple tint for alternatives
    button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 12,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    button:SetBackdropColor(0.15, 0.1, 0.2, 1)  -- Dark purple background
    button:SetBackdropBorderColor(0.6, 0.4, 0.8, 1)  -- Purple border

    -- Item icon
    button.itemIcon = button:CreateTexture(nil, "ARTWORK")
    button.itemIcon:SetAllPoints()
    button.itemIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Try to load item info
    local itemTexture = C_Item.GetItemIconByID(altItem.itemID)
    if itemTexture then
        button.itemIcon:SetTexture(itemTexture)
    else
        button.itemIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    end

    -- Extract slot type from slot name (e.g., "Trinket" from "Trinket (Alternative)")
    local slotType = string.match(altItem.slot, "^(%w+)") or altItem.slot

    -- Create label below button
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalTiny")
    label:SetPoint("TOP", button, "BOTTOM", 0, -2)
    label:SetTextColor(0.8, 0.6, 1.0)  -- Purple color
    label:SetText(slotType)
    label:SetWordWrap(false)

    container.button = button
    container.label = label

    -- Tooltip on hover
    button:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")
        GameTooltip:SetItemByID(btn.itemID)

        -- Add alternative item info
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("|cFFB088FF" .. altItem.slot .. "|r", 1, 1, 1)
        GameTooltip:AddLine("|cFF888888Can replace any item in this category|r", 0.8, 0.8, 0.8, true)

        -- Check if equipped in any relevant slot
        local isEquipped = self:CheckAlternativeItemEquipped(altItem)
        if isEquipped then
            GameTooltip:AddLine("|cFF00FF00[Equipped]|r", 1, 1, 1)
        end

        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click handling (same as regular buttons)
    button:SetScript("OnClick", function(btn)
        if btn.itemID then
            if IsControlKeyDown() then
                -- Ctrl+Click: Open Encounter Journal (same as regular items)
                if not C_AddOns.IsAddOnLoaded("Blizzard_EncounterJournal") then
                    C_AddOns.LoadAddOn("Blizzard_EncounterJournal")
                end
                if not EncounterJournal or not EncounterJournal:IsShown() then
                    ToggleEncounterJournal()
                end
                C_Timer.After(0.3, function()
                    local itemName = C_Item.GetItemInfo(btn.itemID)
                    if itemName and EncounterJournal then
                        EncounterJournal_SelectSearch(2)  -- 2 = Loot
                        if EncounterJournalSearchBox then
                            EncounterJournalSearchBox:SetText(itemName)
                            EncounterJournal_OnSearchTextChanged(EncounterJournalSearchBox)
                        end
                    end
                end)
            elseif btn.itemLink and IsShiftKeyDown() then
                -- Shift+Click: Link in chat
                local editBox = ChatEdit_GetActiveWindow()
                if editBox then
                    ChatEdit_InsertLink(btn.itemLink)
                end
            end
        end
    end)

    return container
end

--- Check if an alternative item is equipped in any relevant slot
function ABIS:CheckAlternativeItemEquipped(altItem)
    local itemID = altItem.itemID
    local slotName = altItem.slot

    -- Check which slots to scan based on alternative type
    local slotsToCheck = {}

    if string.match(slotName, "Trinket") then
        table.insert(slotsToCheck, 13)  -- Trinket1
        table.insert(slotsToCheck, 14)  -- Trinket2
    elseif string.match(slotName, "Finger") or string.match(slotName, "Ring") then
        table.insert(slotsToCheck, 11)  -- Ring1
        table.insert(slotsToCheck, 12)  -- Ring2
    elseif string.match(slotName, "Main Hand") then
        table.insert(slotsToCheck, 16)  -- MainHand
        table.insert(slotsToCheck, 17)  -- OffHand (for DW classes)
    end

    -- Check if item is equipped in any of the relevant slots
    for _, slotID in ipairs(slotsToCheck) do
        local equippedItemID = GetInventoryItemID("player", slotID)
        if equippedItemID == itemID then
            return true
        end
    end

    return false
end

-- Get player's Hero Talent spec name
function ABIS:GetHeroTalentSpec()
    -- Hero talent signature spells for Death Knight
    -- Each hero talent has a unique spell that identifies it
    local heroTalentSpells = {
        -- Death Knight Unholy
        [439843] = "Deathbringer",  -- Hero's Mark
        [433901] = "San'layn",       -- San'layn first talent (corrected)
        [439844] = "Rider of the Apocalypse",  -- Rider signature

        -- Add more hero talents for other classes here as needed
        -- Priest, Warrior, etc.
    }

    -- Check which hero talent spell the player has
    for spellID, heroName in pairs(heroTalentSpells) do
        if C_SpellBook.IsSpellInSpellBook(spellID) then
            return heroName
        end
    end

    return nil
end

-- Update enchant display for a slot button
function ABIS:UpdateSlotEnchants(button, enchantsData)
    -- Clear existing enchant buttons
    for _, enchantBtn in ipairs(button.enchantButtons) do
        enchantBtn:Hide()
    end

    if not enchantsData then
        button:SetHeight(50)
        return
    end

    -- Map slot names for enchants (Wowhead uses different names)
    local slotNameMap = {
        ["MainHand"] = "Weapon",
        ["Wrists"] = "Bracers",
        ["Gloves"] = "Hands",
        ["Belt"] = "Waist",
        ["Boots"] = "Boots",
        ["Legs"] = "Legs",
        ["Chest"] = "Chest",
        ["Cloak"] = "Cloak",
        ["Ring1"] = "Ring",
        ["Ring2"] = "Ring"
    }

    local enchantSlotName = slotNameMap[button.slot] or button.slot
    local slotEnchants = enchantsData[enchantSlotName]

    -- Special handling for Frost DK weapon enchants (dynamic based on talents and weapon type)
    -- This overrides whatever was scraped from Wowhead (which has build-based recommendations)
    if (button.slot == "MainHand" or button.slot == "OffHand") then
        local mhEnchant, ohEnchant = self:GetFrostDKWeaponEnchants()
        if mhEnchant and ohEnchant then
            -- Override enchants with the correct ones based on current talents/weapon type
            if button.slot == "MainHand" then
                slotEnchants = {{id = mhEnchant, context = ""}}
            elseif button.slot == "OffHand" then
                slotEnchants = {{id = ohEnchant, context = ""}}
            end
        end
    end

    -- Fallback for DK-specific ring names (Ring - Regular, Ring - Cursed)
    if not slotEnchants and (button.slot == "Ring1" or button.slot == "Ring2") then
        -- Try DK-specific ring names
        if button.slot == "Ring1" then
            slotEnchants = enchantsData["Ring - Regular"]
        elseif button.slot == "Ring2" then
            slotEnchants = enchantsData["Ring - Cursed"]
        end

        -- If still not found, try the opposite (both rings can use either enchant)
        if not slotEnchants then
            slotEnchants = enchantsData["Ring - Regular"] or enchantsData["Ring - Cursed"]
        end
    end

    if not slotEnchants or #slotEnchants == 0 then
        button:SetHeight(50)
        return
    end

    -- Get player's hero talent spec
    local playerSpec = self:GetHeroTalentSpec()

    -- Filter enchants based on hero talent
    local visibleEnchants = {}
    for _, enchant in ipairs(slotEnchants) do
        local originalContext = enchant.context or ""

        -- Keep original context for filtering
        local filterContext = originalContext
        filterContext = string.gsub(filterContext, "^%s+", "")  -- Trim leading whitespace
        filterContext = string.gsub(filterContext, "%s+$", "")  -- Trim trailing whitespace

        -- Create display context (only show descriptors like "ST", remove hero talent names)
        local displayContext = ""

        -- Check if context contains "ST" (Single Target)
        if string.find(originalContext, "ST") then
            displayContext = "ST"
        end

        -- Check for other descriptors (AoE, etc.) - can add more here
        if string.find(originalContext, "AoE") then
            displayContext = displayContext ~= "" and displayContext .. " / AoE" or "AoE"
        end

        -- If player has a hero talent, only show matching enchants
        if playerSpec then
            -- Match if context is empty (universal enchant) or contains the hero talent name
            -- Use case-insensitive matching
            local contextLower = string.lower(filterContext)
            local specLower = string.lower(playerSpec)

            if filterContext == "" or string.find(contextLower, specLower, 1, true) then
                table.insert(visibleEnchants, {id = enchant.id, context = displayContext})
            end
        else
            -- Show all enchants if no spec detected (for testing/no hero talents chosen)
            table.insert(visibleEnchants, {id = enchant.id, context = displayContext})
        end
    end

    if #visibleEnchants == 0 then
        button:SetHeight(50)
        return
    end

    -- Create/update enchant icon buttons (smaller size, vertically stacked)
    local enchantBtnSize = 24
    local enchantBtnSpacing = 2
    local enchantLeftPadding = 10  -- Padding from left edge

    for i, enchant in ipairs(visibleEnchants) do
        if not button.enchantButtons[i] then
            -- Create enchant button with BackdropTemplate
            local enchantBtn = CreateFrame("Button", nil, button, "BackdropTemplate")
            enchantBtn:SetSize(enchantBtnSize, enchantBtnSize)
            enchantBtn:RegisterForClicks("LeftButtonUp")

            -- Modern sleek backdrop for enchant button
            enchantBtn:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = false,
                edgeSize = 16,
                insets = { left = 4, right = 4, top = 4, bottom = 4 }
            })
            enchantBtn:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
            enchantBtn:SetBackdropBorderColor(0.7, 0.5, 0.9, 1)  -- Purple accent border

            -- Icon
            local icon = enchantBtn:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", 2, -2)
            icon:SetPoint("BOTTOMRIGHT", -2, 2)
            icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            enchantBtn.icon = icon

            -- ST Badge overlay (top-right corner)
            local stBadge = enchantBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            stBadge:SetPoint("TOPRIGHT", enchantBtn, "TOPRIGHT", -2, -4)
            stBadge:SetFont("Fonts\\FRIZQT__.TTF", 8, "OUTLINE")
            stBadge:SetTextColor(1, 0.3, 0.3, 1)  -- Red color for ST
            stBadge:SetShadowColor(0, 0, 0, 1)
            stBadge:SetShadowOffset(1, -1)
            stBadge:Hide()  -- Hidden by default
            enchantBtn.stBadge = stBadge

            -- Highlight
            enchantBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

            button.enchantButtons[i] = enchantBtn
        end

        local enchantBtn = button.enchantButtons[i]
        enchantBtn:ClearAllPoints()

        -- Position enchants: MainHand gets horizontal layout, others get vertical
        if button.slot == "MainHand" then
            -- Horizontal layout for weapon enchants
            local xOffset = -10 + ((i - 3) * (enchantBtnSize + enchantBtnSpacing))
            enchantBtn:SetPoint("LEFT", button, "RIGHT", xOffset, 0)
        else
            -- Vertical layout for other slots
            local yOffset = ((i - 1) * (enchantBtnSize + enchantBtnSpacing))
            enchantBtn:SetPoint("LEFT", button, "RIGHT", -40, -yOffset)
        end

        -- Store enchant data
        enchantBtn.enchantID = enchant.id
        enchantBtn.context = enchant.context

        -- Get spell/item icon
        local iconTexture
        local enchantName
        local enchantLink

        -- DK weapon enchants are spells (Rune of Fallen Crusader, etc.)
        -- All other enchants are items in TWW
        local _, playerClass = UnitClass("player")
        local isDKWeaponEnchant = (playerClass == "DEATHKNIGHT" and (button.slot == "MainHand" or button.slot == "OffHand"))

        if isDKWeaponEnchant then
            -- Try spell first for DK weapon runes
            local spellInfo = C_Spell.GetSpellInfo(enchant.id)
            if spellInfo then
                iconTexture = C_Spell.GetSpellTexture(enchant.id)
                enchantName = spellInfo.name
                enchantLink = C_Spell.GetSpellLink(enchant.id)
            end

            -- If not a spell, try item (fallback)
            if not iconTexture then
                iconTexture = C_Item.GetItemIconByID(enchant.id)
                local itemInfo = C_Item.GetItemInfo(enchant.id)
                if itemInfo then
                    enchantName = itemInfo
                    enchantLink = select(2, C_Item.GetItemInfo(enchant.id))
                end
            end
        else
            -- Try item first (enchants are items in TWW)
            iconTexture = C_Item.GetItemIconByID(enchant.id)
            local itemInfo = C_Item.GetItemInfo(enchant.id)
            if itemInfo then
                enchantName = itemInfo
                enchantLink = select(2, C_Item.GetItemInfo(enchant.id))
            end

            -- If not an item, try spell (fallback)
            if not iconTexture then
                local spellInfo = C_Spell.GetSpellInfo(enchant.id)
                if spellInfo then
                    iconTexture = C_Spell.GetSpellTexture(enchant.id)
                    enchantName = spellInfo.name
                    enchantLink = C_Spell.GetSpellLink(enchant.id)
                end
            end
        end

        if iconTexture then
            enchantBtn.icon:SetTexture(iconTexture)
        else
            enchantBtn.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            -- Request data
            C_Spell.RequestLoadSpellData(enchant.id)
            C_Item.RequestLoadItemDataByID(enchant.id)
        end

        -- Store link
        enchantBtn.enchantLink = enchantLink

        -- Show ST badge if context contains "ST"
        if enchant.context and string.find(enchant.context, "ST") then
            enchantBtn.stBadge:SetText("ST")
            enchantBtn.stBadge:Show()
        else
            enchantBtn.stBadge:Hide()
        end

        -- Click handler
        enchantBtn:SetScript("OnClick", function(btn)
            if btn.enchantLink and IsShiftKeyDown() then
                local focusedFrame = GetCurrentKeyBoardFocus()

                -- Check if focused frame is a chat EditBox
                local isChatFrame = false
                if focusedFrame then
                    local chatFrame = ChatEdit_GetActiveWindow()
                    isChatFrame = (focusedFrame == chatFrame)
                end

                if focusedFrame and focusedFrame:IsObjectType("EditBox") and focusedFrame:IsVisible() then
                    if isChatFrame then
                        -- Insert full link for chat frames
                        focusedFrame:Insert(btn.enchantLink)
                    else
                        -- Extract item name for non-chat EditBoxes (like AH search)
                        local itemName = btn.enchantLink:match("%[(.+)%]")
                        if itemName then
                            focusedFrame:Insert(itemName)
                        else
                            focusedFrame:Insert(btn.enchantLink)
                        end
                    end
                else
                    -- No EditBox focused - try to insert into chat
                    local chatFrame = ChatEdit_GetActiveWindow()
                    if chatFrame then
                        chatFrame:Insert(btn.enchantLink)
                    end
                end
            end
        end)

        -- Tooltip
        enchantBtn:SetScript("OnEnter", function(btn)
            if btn.enchantID then
                GameTooltip:SetOwner(btn, "ANCHOR_RIGHT")

                -- DK weapon enchants are spells, everything else is items
                local _, playerClass = UnitClass("player")
                local isDKWeaponEnchant = (playerClass == "DEATHKNIGHT" and button.slot == "MainHand")

                if isDKWeaponEnchant then
                    -- Try spell first for DK weapon runes
                    local spellInfo = C_Spell.GetSpellInfo(btn.enchantID)
                    if spellInfo then
                        GameTooltip:SetSpellByID(btn.enchantID)
                    else
                        GameTooltip:SetItemByID(btn.enchantID)
                    end
                else
                    -- Try item first (TWW enchants are items), then spell
                    local itemInfo = C_Item.GetItemInfo(btn.enchantID)
                    if itemInfo then
                        GameTooltip:SetItemByID(btn.enchantID)
                    else
                        GameTooltip:SetSpellByID(btn.enchantID)
                    end
                end

                GameTooltip:Show()
            end
        end)

        enchantBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        enchantBtn:Show()
    end

    -- Calculate new height: either base height OR tall enough for stacked enchants (whichever is larger)
    -- MainHand enchants are horizontal so don't increase height
    if button.slot == "MainHand" then
        button:SetHeight(50)
    else
        -- Vertical layout: each enchant takes enchantBtnSize + enchantBtnSpacing (except last one)
        local enchantTotalHeight = (#visibleEnchants * enchantBtnSize) + ((#visibleEnchants - 1) * enchantBtnSpacing)
        local newHeight = math.max(50, enchantTotalHeight)
        button:SetHeight(newHeight)
    end
end

-- Map slot names to WoW slot IDs
function ABIS:GetSlotID(slotName)
    local slotMap = {
        Head = 1,
        Neck = 2,
        Shoulders = 3,
        Chest = 5,
        Belt = 6,
        Legs = 7,
        Boots = 8,
        Wrists = 9,
        Gloves = 10,
        Ring1 = 11,
        Ring2 = 12,
        Trinket1 = 13,
        Trinket2 = 14,
        Cloak = 15,
        MainHand = 16,
        OffHand = 17,
    }
    return slotMap[slotName]
end

-- Refresh the character panel with current BiS data
function ABIS:RefreshCharacterPanel()
    if not self.characterPanel then
        return
    end

    local setName = self.CurrentBISSet or "DisciplinePriest_S3"
    local bisSet = self.BISData[setName]

    if not bisSet then
        return
    end

    -- Update title
    self.characterPanel.TitleText:SetText(bisSet.title or "BiS Gear")

    -- Update character name display
    if self.CurrentCharacter then
        self.characterPanel.characterName:SetText("Character: " .. self.CurrentCharacter)
    end

    -- Separate regular items and alternative items
    local itemLookup = {}
    local alternativeItems = {}
    for _, item in ipairs(bisSet.items) do
        if item.isAlternative then
            table.insert(alternativeItems, item)
        else
            itemLookup[item.slot] = item
        end
    end

    -- Update each slot button and track progress (only regular items)
    local totalItems = 0
    local equippedItems = 0

    for slotName, button in pairs(self.characterPanel.slotButtons) do
        local item = itemLookup[slotName]

        if item and item.itemID then
            totalItems = totalItems + 1
            button.itemID = item.itemID

            -- Try to get item info with link
            local itemName, itemLink, itemQuality = C_Item.GetItemInfo(item.itemID)

            if itemName and itemLink then
                -- Store item link for shift+click
                button.itemLink = itemLink

                -- Get item icon texture
                local itemTexture = C_Item.GetItemIconByID(item.itemID)
                if itemTexture then
                    button.itemIcon:SetTexture(itemTexture)
                    button.itemIcon:Show()
                end

                -- Check if player has this item equipped
                local slotID = self:GetSlotID(slotName)
                local isEquipped = false
                if slotID then
                    local equippedItemID = GetInventoryItemID("player", slotID)
                    if equippedItemID == item.itemID then
                        isEquipped = true
                        equippedItems = equippedItems + 1
                    end

                    -- For rings and trinkets, also check the other slot (since they can be in either)
                    if not isEquipped and (slotName == "Ring1" or slotName == "Ring2" or slotName == "Trinket1" or slotName == "Trinket2") then
                        local otherSlotID = nil
                        if slotName == "Ring1" then
                            otherSlotID = 12  -- Ring2
                        elseif slotName == "Ring2" then
                            otherSlotID = 11  -- Ring1
                        elseif slotName == "Trinket1" then
                            otherSlotID = 14  -- Trinket2
                        elseif slotName == "Trinket2" then
                            otherSlotID = 13  -- Trinket1
                        end

                        if otherSlotID then
                            local otherEquippedItemID = GetInventoryItemID("player", otherSlotID)
                            if otherEquippedItemID == item.itemID then
                                isEquipped = true
                                equippedItems = equippedItems + 1
                            end
                        end
                    end
                end

                -- Check if item is in bags (only if not equipped)
                local isInBags = false
                if not isEquipped then
                    isInBags = C_Item.GetItemCount(item.itemID, false, false, false) > 0
                end

                -- Set quality color
                local r, g, b = C_Item.GetItemQualityColor(itemQuality or 1)
                button.itemText:SetTextColor(r, g, b)
                -- Display status: Equipped > In Inventory > Item name only
                if isEquipped then
                    button.itemText:SetText(itemName .. " |cFF00FF00[Equipped]|r")
                elseif isInBags then
                    button.itemText:SetText(itemName .. " |cFFFFD700[In Inventory]|r")
                else
                    button.itemText:SetText(itemName)
                end
            else
                -- Item not cached yet
                button.itemText:SetTextColor(0.8, 0.8, 0.8)
                button.itemText:SetText("Loading...")

                -- Request item data
                C_Item.RequestLoadItemDataByID(item.itemID)
            end
        else
            button.itemID = nil
            button.itemText:SetText("Empty")
            button.itemText:SetTextColor(0.5, 0.5, 0.5)
        end

        -- Update enchants for this slot
        self:UpdateSlotEnchants(button, bisSet.enchants)
    end

    -- Update button layout to account for dynamic heights from enchants
    self:UpdateButtonLayout()

    -- Handle alternative items display
    if #alternativeItems > 0 then
        local altContainer = self.characterPanel.altItemsContainer
        altContainer.label:SetText("|cFFB088FFAlternative Items:|r")

        -- Clean up old alternative item buttons
        for _, btn in ipairs(self.characterPanel.altItemsButtons) do
            btn:Hide()
        end
        self.characterPanel.altItemsButtons = {}

        -- Create/update alternative item buttons
        local xOffset = 120  -- Start after label
        for _, altItem in ipairs(alternativeItems) do
            local itemContainer = self:CreateAlternativeItemButton(altContainer, altItem)
            itemContainer:SetPoint("TOPLEFT", xOffset, -5)
            table.insert(self.characterPanel.altItemsButtons, itemContainer)
            xOffset = xOffset + 65  -- Space between containers (60px wide + 5px gap)
        end

        altContainer:Show()
    else
        self.characterPanel.altItemsContainer:Hide()
    end

    -- Update progress text
    if totalItems > 0 then
        local percentage = math.floor((equippedItems / totalItems) * 100)
        local color = equippedItems == totalItems and "|cFF00FF00" or "|cFFFFD700"
        self.characterPanel.progressText:SetText(
            string.format("%sProgress: %d/%d items (%d%%)|r", color, equippedItems, totalItems, percentage)
        )
    else
        self.characterPanel.progressText:SetText("No BiS items loaded")
    end
end

-- Show all enchant tooltips when shift is held
function ABIS:ShowAllEnchantTooltips()
    if not self.characterPanel or not self.characterPanel.slotButtons then
        return
    end

    local tooltipOffset = 0  -- Track vertical offset to stack tooltips
    local columnOffset = 0   -- Track horizontal offset for columns
    local maxColumnHeight = GetScreenHeight() * 0.8  -- Use 80% of screen height per column

    -- Iterate through all slot buttons and show enchant tooltips
    for slotName, button in pairs(self.characterPanel.slotButtons) do
        if button.enchantButtons then
            for i, enchantBtn in ipairs(button.enchantButtons) do
                if enchantBtn:IsShown() and enchantBtn.enchantID and enchantBtn.enchantLink then
                    -- Create a unique tooltip frame for this enchant button
                    if not enchantBtn.shiftTooltip then
                        local tooltipName = "ABIS_Tooltip_" .. slotName .. "_" .. i
                        enchantBtn.shiftTooltip = CreateFrame("GameTooltip", tooltipName, UIParent, "GameTooltipTemplate")
                    end

                    local tooltip = enchantBtn.shiftTooltip
                    tooltip:SetOwner(UIParent, "ANCHOR_NONE")
                    tooltip:ClearAllPoints()

                    -- Position tooltip to the right of the BiS UI window, stacked vertically
                    tooltip:SetPoint("TOPLEFT", self.characterPanel, "TOPRIGHT", 10 + columnOffset, -20 - tooltipOffset)

                    -- Use hyperlink for instant display (no loading delay)
                    tooltip:SetHyperlink(enchantBtn.enchantLink)
                    tooltip:Show()

                    -- Increase offset for next tooltip (use tooltip height + spacing)
                    local tooltipHeight = tooltip:GetHeight()
                    tooltipOffset = tooltipOffset + tooltipHeight + 5

                    -- Start a new column if we exceed max height
                    if tooltipOffset > maxColumnHeight then
                        tooltipOffset = 0
                        columnOffset = columnOffset + 350  -- Width of one tooltip + spacing
                    end
                end
            end
        end
    end
end

-- Hide all enchant tooltips when shift is released
function ABIS:HideAllEnchantTooltips()
    if not self.characterPanel or not self.characterPanel.slotButtons then
        return
    end

    -- Iterate through all slot buttons and hide enchant tooltips
    for _, button in pairs(self.characterPanel.slotButtons) do
        if button.enchantButtons then
            for _, enchantBtn in ipairs(button.enchantButtons) do
                if enchantBtn.shiftTooltip then
                    enchantBtn.shiftTooltip:Hide()
                end
            end
        end
    end
end

-- Function to clear all BiS data for current character+spec
function ABIS:ClearBISData()
    -- Clear in-memory data
    self.BISData = {}
    self.CurrentBISSet = nil

    -- Clear saved variables for this character's current spec
    local specName = self.CurrentSpec or "NoSpec"
    if AndrewsBISUICharDB.specs and AndrewsBISUICharDB.specs[specName] then
        AndrewsBISUICharDB.specs[specName].savedSets = {}
        AndrewsBISUICharDB.specs[specName].currentSet = nil
    end

    -- Force clear all cached item info
    if self.characterPanel and self.characterPanel.slotButtons then
        for _, button in pairs(self.characterPanel.slotButtons) do
            button.itemID = nil
            button.itemLink = nil
            button.itemText:SetText("Empty")
            button.itemText:SetTextColor(0.5, 0.5, 0.5)
            button.itemIcon:Hide()

            -- Hide all enchant buttons
            if button.enchantButtons then
                for _, enchantBtn in ipairs(button.enchantButtons) do
                    enchantBtn:Hide()
                end
            end
        end
    end

    -- Refresh the panel to show empty state
    if self.characterPanel and self.characterPanel:IsShown() then
        self:RefreshCharacterPanel()
    end

    print("|cFFFF8800All BiS items and enchants have been cleared for " .. (specName or "current spec") .. ".|r")

    -- Show success message in UI if panel is open
    if self.characterPanel and self.characterPanel:IsShown() and self.characterPanel.progressText then
        self.characterPanel.progressText:SetText("|cFFFF8800No BiS items loaded|r")
    end
end

-- Function to display BiS items in chat frame (legacy)
function ABIS:ShowBISItems()
    -- Show the character panel instead
    self:CreateCharacterPanel()
end

-- Function to import item IDs manually
function ABIS:ImportItemIDs(importString)
    local items = {}
    local enchants = {}

    -- Check if this is the new format: BIS##...;;ENCHANT##...
    if string.find(importString, "BIS##") or string.find(importString, "ENCHANT##") then
        -- Split by ;; to separate BIS and ENCHANT sections
        local bisSection, enchantSection = string.match(importString, "(.-);;(.*)")

        -- If no ;; found, check which section we have
        if not bisSection then
            if string.find(importString, "^BIS##") then
                bisSection = importString
            elseif string.find(importString, "^ENCHANT##") then
                enchantSection = importString
            end
        end

        -- Parse BIS section
        if bisSection and string.find(bisSection, "^BIS##") then
            -- Parse BIS gear: BIS##'slot':id;'slot':id
            local bisContent = string.match(bisSection, "^BIS##(.+)$")
            if bisContent then
                for slotPair in string.gmatch(bisContent, "[^;]+") do
                    local slot, itemID = string.match(slotPair, "'([^']+)':(%d+)")
                    if slot and itemID then
                        -- Map Wowhead slot names to addon slot names
                        local slotMap = {
                            ["Head"] = "Head",
                            ["Neck"] = "Neck",
                            ["Shoulders"] = "Shoulders",
                            ["Cloak"] = "Cloak",
                            ["Chest"] = "Chest",
                            ["Wrists"] = "Wrists",
                            ["Hands"] = "Gloves",
                            ["Waist"] = "Belt",
                            ["Legs"] = "Legs",
                            ["Feet"] = "Boots",
                            ["Finger 1"] = "Ring1",
                            ["Finger 2"] = "Ring2",
                            ["Trinket 1"] = "Trinket1",
                            ["Trinket 2"] = "Trinket2",
                            ["Main Hand"] = "MainHand",
                            ["Off Hand"] = "OffHand",
                            -- Alternative items - keep original slot name with (Alternative) marker
                            ["Trinket (Alternative)"] = "Trinket (Alternative)",
                            ["Finger (Alternative)"] = "Finger (Alternative)",
                            ["Main Hand (Alternative)"] = "Main Hand (Alternative)",
                        }

                        local addonSlot = slotMap[slot] or slot
                        local isAlternative = string.match(slot, "%(Alternative%)") ~= nil
                        table.insert(items, {slot = addonSlot, itemID = tonumber(itemID), isAlternative = isAlternative})
                    end
                end
            end
        end

        -- Parse ENCHANT section
        if enchantSection and string.find(enchantSection, "^ENCHANT##") then
            -- Parse enchants: ENCHANT##'slot':id~context|id~context;'slot':id
            local enchantContent = string.match(enchantSection, "^ENCHANT##(.+)$")
            if enchantContent then
                for slotPair in string.gmatch(enchantContent, "[^;]+") do
                    local slot, enchantData = string.match(slotPair, "'([^']+)':(.+)")
                    if slot and enchantData then
                        -- Parse multiple enchant options separated by |
                        local enchantOptions = {}
                        for option in string.gmatch(enchantData, "[^|]+") do
                            local enchantID, context = string.match(option, "(%d+)~(.+)")
                            if enchantID and context then
                                table.insert(enchantOptions, {id = tonumber(enchantID), context = context})
                            else
                                -- No context, just ID
                                enchantID = string.match(option, "^(%d+)$")
                                if enchantID then
                                    table.insert(enchantOptions, {id = tonumber(enchantID), context = ""})
                                end
                            end
                        end

                        if #enchantOptions > 0 then
                            enchants[slot] = enchantOptions
                        end
                    end
                end
            end
        end
    else
        -- Legacy format: just comma/space separated item IDs
        for itemID in string.gmatch(importString, "%d+") do
            table.insert(items, {itemID = tonumber(itemID)})
        end

        -- Auto-assign slots for legacy format
        local slotNames = {"Head", "Neck", "Shoulders", "Cloak", "Chest",
                           "Wrists", "Gloves", "Belt", "Legs", "Boots",
                           "Ring1", "Ring2", "Trinket1", "Trinket2", "MainHand", "OffHand"}

        for i, item in ipairs(items) do
            item.slot = slotNames[i] or ("Item" .. i)
        end
    end

    if #items == 0 then
        print("|cFFFF0000No valid item IDs found|r")
        return
    end

    -- Store the data
    local setName = "Manual_" .. date("%Y%m%d_%H%M%S")
    local bisData = {
        title = "Andrews BiS & Enchantment UI",
        url = "",
        items = items,
        enchants = enchants  -- Store enchants data
    }

    -- Store in memory
    self.BISData[setName] = bisData
    self.CurrentBISSet = setName

    -- IMPORTANT: Save to per-character per-spec SavedVariables so it persists across reloads
    local specName = self.CurrentSpec or "Spec1"

    AndrewsBISUICharDB.specs = AndrewsBISUICharDB.specs or {}
    AndrewsBISUICharDB.specs[specName] = AndrewsBISUICharDB.specs[specName] or {}
    AndrewsBISUICharDB.specs[specName].savedSets = AndrewsBISUICharDB.specs[specName].savedSets or {}
    AndrewsBISUICharDB.specs[specName].savedSets[setName] = bisData
    AndrewsBISUICharDB.specs[specName].currentSet = setName

    local enchantCount = 0
    for _ in pairs(enchants) do enchantCount = enchantCount + 1 end

    print("|cFF00FF00Successfully imported " .. #items .. " items and " .. enchantCount .. " enchant slots!|r")
    self:ShowBISItems()

    -- Automatically refresh the panel after import
    if self.characterPanel then
        self:RefreshCharacterPanel()
    end
end

-- Get correct weapon enchants for Frost Death Knight based on talents and weapon type
function ABIS:GetFrostDKWeaponEnchants()
    local _, playerClass = UnitClass("player")
    if playerClass ~= "DEATHKNIGHT" then
        return nil, nil
    end

    local specIndex = C_SpecializationInfo.GetSpecialization()
    if not specIndex then
        return nil, nil
    end

    local _, specName = C_SpecializationInfo.GetSpecializationInfo(specIndex)
    if specName ~= "Frost" then
        return nil, nil
    end

    -- Check if player has Shattering Blade talent (spell ID 207057)
    local hasShatteringBlade = C_SpellBook.IsSpellInSpellBook(207057)

    -- Check if main hand weapon is two-handed
    local mainHandLink = GetInventoryItemLink("player", INVSLOT_MAINHAND)
    local isTwoHander = false
    if mainHandLink then
        local itemID = C_Item.GetItemInfoInstant(mainHandLink)
        if itemID then
            -- C_Item.GetItemInfo returns: itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc
            local _, _, _, _, _, _, _, _, itemEquipLoc = C_Item.GetItemInfo(itemID)
            if itemEquipLoc then
                isTwoHander = (itemEquipLoc == "INVTYPE_2HWEAPON")
            end
        end
    end

    -- Determine enchants based on logic:
    -- - Shattering Blade: Razorice (53343) MH + Fallen Crusader (53344) OH
    -- - Two-Handed: Fallen Crusader (53344) on both
    -- - All other builds: Stoneskin Gargoyle (62158) MH + Fallen Crusader (53344) OH

    local mainHandEnchant, offHandEnchant

    if isTwoHander then
        -- Two-handed weapon: Fallen Crusader on both slots
        mainHandEnchant = 53344  -- Fallen Crusader
        offHandEnchant = 53344   -- Fallen Crusader
    elseif hasShatteringBlade then
        -- Shattering Blade talent: Razorice MH + Fallen Crusader OH
        mainHandEnchant = 53343  -- Razorice
        offHandEnchant = 53344   -- Fallen Crusader
    else
        -- Default dual-wield: Stoneskin Gargoyle MH + Fallen Crusader OH
        mainHandEnchant = 62158  -- Stoneskin Gargoyle
        offHandEnchant = 53344   -- Fallen Crusader
    end

    return mainHandEnchant, offHandEnchant
end


-- Create Minimap Button
function ABIS:CreateMinimapButton()
    local button = CreateFrame("Button", "AndrewsBISMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Icon
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")  -- Book icon, change as needed
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)  -- Crop edges to fit circular frame

    -- Border
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    -- Tooltip
    button:SetScript("OnEnter", function(btn)
        GameTooltip:SetOwner(btn, "ANCHOR_LEFT")
        GameTooltip:SetText("Andrews BiS UI", 1, 1, 1)
        GameTooltip:AddLine("Click: Show BiS Panel", 0, 1, 0)
        GameTooltip:AddLine("Drag: Move button", 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Click handlers
    button:RegisterForClicks("LeftButtonUp")
    button:SetScript("OnClick", function()
        ABIS:CreateCharacterPanel()
    end)

    -- Dragging
    button:RegisterForDrag("LeftButton")
    button:SetScript("OnDragStart", function(btn)
        btn:LockHighlight()
        btn.isDragging = true
    end)

    button:SetScript("OnDragStop", function(btn)
        btn:UnlockHighlight()
        btn.isDragging = false
    end)

    button:SetScript("OnUpdate", function(btn)
        if btn.isDragging then
            local mx, my = Minimap:GetCenter()
            local px, py = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            px, py = px / scale, py / scale

            local angle = math.deg(math.atan2(py - my, px - mx))
            AndrewsBISUIDB.settings.minimapButton.position = angle
            ABIS:UpdateMinimapButtonPosition()
        end
    end)

    self.minimapButton = button
    self:UpdateMinimapButtonPosition()

    if AndrewsBISUIDB.settings.minimapButton.hide then
        button:Hide()
    end
end

function ABIS:UpdateMinimapButtonPosition()
    if not self.minimapButton then return end

    local angle = math.rad(AndrewsBISUIDB.settings.minimapButton.position or 180)
    local radius = 105  -- Reduced radius to keep button within minimap circle
    local x = math.cos(angle) * radius
    local y = math.sin(angle) * radius

    self.minimapButton:ClearAllPoints()
    self.minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function ABIS:ShowMinimapButton()
    if self.minimapButton then
        self.minimapButton:Show()
    end
end

function ABIS:HideMinimapButton()
    if self.minimapButton then
        self.minimapButton:Hide()
    end
end

-- Register slash commands
SLASH_ANDREWSBIS1 = "/bis"
SLASH_ANDREWSBIS2 = "/abis"
SlashCmdList["ANDREWSBIS"] = function(msg)
    msg = string.lower(msg or "")

    if msg == "import" or msg == "add" then
        ABIS:CreateImportFrame()
    elseif msg == "show" or msg == "" then
        ABIS:CreateCharacterPanel()
    elseif msg == "refresh" or msg == "reload" then
        ABIS:RefreshCharacterPanel()
        print("|cFF00FF00BiS panel refreshed!|r")
    elseif msg == "hide" or msg == "close" then
        if ABIS.characterPanel then
            ABIS.characterPanel:Hide()
        end
    elseif msg == "debug" then
        print("|cFF00FF00=== Debug Info ===|r")
        print("Current BiS Set: " .. (ABIS.CurrentBISSet or "None"))

        if AndrewsBISUIDB and AndrewsBISUIDB.importedItems then
            print("|cFF00FF00SavedVariables has importedItems:|r")
            local count = 0
            for slot, data in pairs(AndrewsBISUIDB.importedItems) do
                count = count + 1
                print(string.format("  %s: %d", slot, data.itemID or 0))
            end
            print(string.format("Total in SavedVars: %d items", count))
        else
            print("|cFFFF0000No importedItems in SavedVariables|r")
        end

        if ABIS.CurrentBISSet and ABIS.BISData[ABIS.CurrentBISSet] then
            print(string.format("|cFF00FF00Loaded BiS Set has %d items|r",
                #ABIS.BISData[ABIS.CurrentBISSet].items))
        end
    elseif msg == "chars" or msg == "characters" then
        print("|cFF00FF00=== Characters with BiS Data ===|r")
        local charData = ABIS:GetAllCharactersWithData()
        local hasChars = false

        for charName, data in pairs(charData) do
            hasChars = true
            local isCurrent = (charName == ABIS.CurrentCharacter) and " |cFF00FF00(Current)|r" or ""
            print(string.format("|cFFFFD700%s|r%s - %d BiS set(s)", charName, isCurrent, data.setCount or 0))
        end

        if not hasChars then
            print("|cFF888888No characters with BiS data yet|r")
        end
    elseif msg == "help" then
        print("|cFF00FF00=== Andrews BiS UI Commands ===|r")
        print("|cFFFFD700/bis|r or |cFFFFD700/bis show|r - Show BiS gear panel")
        print("|cFFFFD700/bis import|r - Import BiS items")
        print("|cFFFFD700/bis refresh|r - Refresh the gear panel")
        print("|cFFFFD700/bis hide|r - Hide the gear panel")
        print("|cFFFFD700/bis chars|r - List all characters with BiS data")
        print("|cFFFFD700/bis debug|r - Show debug info")
        print("|cFFFFD700/bis help|r - Show this help")
        print(" ")
        print("|cFF888888Tip: Hover over items for tooltips|r")
        print("|cFF888888Tip: Shift+Click items to link in chat|r")
        print("|cFF888888Tip: Ctrl+Click items to open Encounter Journal|r")
        print("|cFF888888Tip: Use the scale slider in the BiS panel to resize|r")
        print("|cFF888888Note: BiS data is now stored per-character!|r")
    else
        ABIS:CreateCharacterPanel()
    end
end

-- Get all characters with BiS data (from global cross-character tracking)
function ABIS:GetAllCharactersWithData()
    -- Initialize cross-character tracking in global DB
    AndrewsBISUIDB.characterData = AndrewsBISUIDB.characterData or {}

    -- Update current character's info
    if AndrewsBISUICharDB.savedSets and next(AndrewsBISUICharDB.savedSets) then
        AndrewsBISUIDB.characterData[ABIS.CurrentCharacter] = {
            lastUpdated = time(),
            setCount = 0
        }

        -- Count sets
        for _ in pairs(AndrewsBISUICharDB.savedSets) do
            AndrewsBISUIDB.characterData[ABIS.CurrentCharacter].setCount =
                AndrewsBISUIDB.characterData[ABIS.CurrentCharacter].setCount + 1
        end
    end

    return AndrewsBISUIDB.characterData
end

-- Migrate old global saved sets to per-character storage
function ABIS:MigrateOldData()
    -- Check if there are old saved sets in the global DB
    if AndrewsBISUIDB.savedSets and next(AndrewsBISUIDB.savedSets) then
        print("|cFFFFAA00Migrating BiS sets to per-character storage...|r")

        -- Copy sets to character DB
        AndrewsBISUICharDB.savedSets = AndrewsBISUICharDB.savedSets or {}
        for setName, bisData in pairs(AndrewsBISUIDB.savedSets) do
            if not AndrewsBISUICharDB.savedSets[setName] then
                AndrewsBISUICharDB.savedSets[setName] = bisData
                print("|cFF00FF00Migrated set: " .. setName .. "|r")
            end
        end

        -- Migrate current set
        if AndrewsBISUIDB.currentSet then
            AndrewsBISUICharDB.currentSet = AndrewsBISUIDB.currentSet
        end

        -- Clear old data from global DB
        AndrewsBISUIDB.savedSets = nil
        AndrewsBISUIDB.currentSet = nil

        print("|cFF00FF00Migration complete!|r")
    end
end

-- Initialization
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "ADDON_LOADED" then
        if loadedAddon == addonName then
            -- Initialize Global SavedVariables (for settings and cross-character data)
            AndrewsBISUIDB = AndrewsBISUIDB or {}
            AndrewsBISUIDB.settings = AndrewsBISUIDB.settings or {}

            -- Initialize Per-Character SavedVariables (for BiS sets)
            AndrewsBISUICharDB = AndrewsBISUICharDB or {}

            -- Store current character name and spec
            ABIS.CurrentCharacter = UnitName("player") .. "-" .. GetRealmName()

            -- Get current spec index (1, 2, 3, or 4)
            local specIndex = C_SpecializationInfo.GetSpecialization()
            local specName = "Spec1"  -- Default fallback
            if specIndex then
                local _, name = C_SpecializationInfo.GetSpecializationInfo(specIndex)
                if name then
                    specName = name
                else
                    specName = "Spec" .. specIndex  -- Use index number if name not available yet
                end
            end
            ABIS.CurrentSpec = specName
            ABIS.CurrentCharacterSpec = ABIS.CurrentCharacter .. "_" .. specName

            -- Merge defaults with saved settings
            if AndrewsBISUIDB.settings.minimapButton == nil then
                AndrewsBISUIDB.settings.minimapButton = CopyTable(ABIS.Defaults.minimapButton)
            end
            if AndrewsBISUIDB.settings.uiScale == nil then
                AndrewsBISUIDB.settings.uiScale = ABIS.Defaults.uiScale
            end

            -- Migrate old data if it exists
            ABIS:MigrateOldData()

            -- Create minimap button
            ABIS:CreateMinimapButton()

            -- Define StaticPopup dialogs
            StaticPopupDialogs["ABIS_CONFIRM_CLEAR"] = {
                text = "Are you sure you want to clear all BiS items and enchants for this spec?",
                button1 = "Yes",
                button2 = "No",
                OnAccept = function()
                    ABIS:ClearBISData()
                end,
                timeout = 0,
                whileDead = true,
                hideOnEscape = true,
                preferredIndex = 3,
            }

            -- Initialize spec-based storage structure
            AndrewsBISUICharDB.specs = AndrewsBISUICharDB.specs or {}
            AndrewsBISUICharDB.specs[specName] = AndrewsBISUICharDB.specs[specName] or {}

            -- Load saved BiS sets for current spec
            if AndrewsBISUICharDB.specs[specName].savedSets then
                for setName, bisData in pairs(AndrewsBISUICharDB.specs[specName].savedSets) do
                    ABIS.BISData[setName] = bisData
                end
            end

            -- Restore the current set for this spec
            if AndrewsBISUICharDB.specs[specName].currentSet and ABIS.BISData[AndrewsBISUICharDB.specs[specName].currentSet] then
                ABIS.CurrentBISSet = AndrewsBISUICharDB.specs[specName].currentSet
            end

            -- Update cross-character tracking
            ABIS:GetAllCharactersWithData()

            print("|cFF00FF00AndrewsBISUI loaded!|r")
            print("|cFF888888Character: " .. ABIS.CurrentCharacter .. " (" .. specName .. ")|r")

            -- Check if we have saved sets
            if ABIS.CurrentBISSet then
                local itemCount = #ABIS.BISData[ABIS.CurrentBISSet].items
                print(string.format("|cFF00FF00Loaded saved BiS set with %d items|r", itemCount))
            else
                print("Type |cFFFFD700/bis import|r to import BiS gear")
            end

            print("Type |cFFFFD700/bis help|r for commands")
        end
    elseif event == "GET_ITEM_INFO_RECEIVED" then
        -- Refresh panel when item info is cached
        if ABIS.characterPanel and ABIS.characterPanel:IsShown() then
            ABIS:RefreshCharacterPanel()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Update spec info when entering world (in case it wasn't available at ADDON_LOADED)
        local specIndex = C_SpecializationInfo.GetSpecialization()
        if specIndex then
            local _, specName = C_SpecializationInfo.GetSpecializationInfo(specIndex)
            if specName and specName ~= ABIS.CurrentSpec then
                -- Update current spec
                ABIS.CurrentSpec = specName

                -- Clear in-memory data
                ABIS.BISData = {}
                ABIS.CurrentBISSet = nil

                -- Load BiS data for the correct spec
                AndrewsBISUICharDB.specs = AndrewsBISUICharDB.specs or {}
                AndrewsBISUICharDB.specs[specName] = AndrewsBISUICharDB.specs[specName] or {}

                if AndrewsBISUICharDB.specs[specName].savedSets then
                    for setName, bisData in pairs(AndrewsBISUICharDB.specs[specName].savedSets) do
                        ABIS.BISData[setName] = bisData
                    end
                end

                if AndrewsBISUICharDB.specs[specName].currentSet and ABIS.BISData[AndrewsBISUICharDB.specs[specName].currentSet] then
                    ABIS.CurrentBISSet = AndrewsBISUICharDB.specs[specName].currentSet
                end

                print("|cFF888888Current spec: " .. specName .. "|r")

                -- Refresh panel if open
                if ABIS.characterPanel and ABIS.characterPanel:IsShown() then
                    ABIS:RefreshCharacterPanel()
                end
            end
        end
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        -- Reload BiS data when spec changes
        local specIndex = C_SpecializationInfo.GetSpecialization()
        if specIndex then
            local _, specName = C_SpecializationInfo.GetSpecializationInfo(specIndex)
            if specName and specName ~= ABIS.CurrentSpec then
                print("|cFF00FF00Spec changed to " .. specName .. ", reloading BiS data...|r")

                -- Update current spec
                ABIS.CurrentSpec = specName

                -- Clear in-memory data
                ABIS.BISData = {}
                ABIS.CurrentBISSet = nil

                -- Load BiS data for new spec
                AndrewsBISUICharDB.specs = AndrewsBISUICharDB.specs or {}
                AndrewsBISUICharDB.specs[specName] = AndrewsBISUICharDB.specs[specName] or {}

                if AndrewsBISUICharDB.specs[specName].savedSets then
                    for setName, bisData in pairs(AndrewsBISUICharDB.specs[specName].savedSets) do
                        ABIS.BISData[setName] = bisData
                    end
                end

                if AndrewsBISUICharDB.specs[specName].currentSet and ABIS.BISData[AndrewsBISUICharDB.specs[specName].currentSet] then
                    ABIS.CurrentBISSet = AndrewsBISUICharDB.specs[specName].currentSet
                end

                -- Refresh panel if open
                if ABIS.characterPanel and ABIS.characterPanel:IsShown() then
                    ABIS:RefreshCharacterPanel()
                end
            end
        end
    end
end)
