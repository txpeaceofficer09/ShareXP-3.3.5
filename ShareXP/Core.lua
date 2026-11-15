local SteakMinimap = SteakMinimap
--if not SteakMinimap or not SteakMinimap.RegisterInfoView then return end
local INFO_PANEL_AVAILABLE = SteakMinimap and type(SteakMinimap.RegisterInfoView) == "function"

local ROW_HEIGHT = 22
local ROW_GAP = 3
local ICON_SIZE = 18

local view = {
	name = "ShareXP",
	title = "ShareXP",
	rows = {}
}

local data = {}

local CLASS_ICON_TCOORDS = {
	DEATHKNIGHT = { 3/8, 4/8, 0, 1/4 },
	DRUID = { 5/8, 6/8, 0, 1/4 },
	HUNTER = { 1/8, 2/8, 1/4, 2/4 },
	MAGE = { 2/8, 3/8, 1/4, 2/4 },
	PALADIN = { 5/8, 6/8, 1/4, 2/4 },
	PRIEST = { 6/8, 7/8, 1/4, 2/4 },
	ROGUE = { 3/8, 4/8, 2/8, 3/8 },
	SHAMAN = { 4/8, 5/8, 2/4, 3/4 },
	WARLOCK = { 3/8, 4/8, 3/4, 1 },
	WARRIOR = { 4/8, 5/8, 3/4, 1 }
}

local expansion = GetAccountExpansionLevel()
local MAX_LEVEL = 0

if expansion == 0 then
	MAX_LEVEL = 60
elseif expansion == 1 then
	MAX_LEVEL = 70
elseif expansion == 2 then
	MAX_LEVEL = 80
elseif expansion == 3 then
	MAX_LEVEL = 85
elseif expansion == 4 then
	MAX_LEVEL = 90
elseif expansion == 5 then
	MAX_LEVEL = 100
elseif expansion == 6 then
	MAX_LEVEL = 110
elseif expansion == 7 then
	MAX_LEVEL = 120
elseif expansion == 8 then
	MAX_LEVEL = 60
end

--[[
local ErrorFilter = {
		"send message of this type until you reach level",
		"your target is dead",
		"there is nothing to attack",
		"not enough rage",
		"not enough energy",
		"that ability requires combo points",
		"not enough runic power",
		"not enough runes",
		"invalid target",
		"you have no target",
		"you cannot attack that target",
		"spell is not ready yet",
		"ability is not ready yet",
		"you can't do that yet",
		"you are too far away",
		"out of range",
		"another action is in progress",
		"not enough mana",
		"not enough focus"
}

local origErrorOnEvent = UIErrorsFrame:GetScript("OnEvent")
UIErrorsFrame:SetScript("OnEvent", function(self, event, ...)
		if ShareXPFrame[event] then
				return ShareXPFrame[event](self, event, ...)
		else
				return origErrorOnEvent(self, event, ...)
		end
end)
]]

local function GetNumGroupMembers()
		local party, raid = GetNumPartyMembers(), GetNumRaidMembers()

		if raid > 0 then
				return raid, "raid"
		elseif party > 0 then
				return party, "party"
		else
				return 0, nil
		end
end

local function IsInGroup(name)
	if ( name == UnitName("player") ) then return true end

	local numMembers, groupType = GetNumGroupMembers()

	if numMembers > 0 then
		for i=1, numMembers, 1 do
			local unit = ("%s%d"):format(groupType, i)

			if UnitName(unit) == name then return true end
		end
	end

	return false
end

local function IsGuildMember(playerName)
	local i = 1

	while GetGuildRosterInfo(i) ~= nil do
		local name, rank, rankIndex, level, class, zone, note, officerNote, online, _, classFileName = GetGuildRosterInfo(i)

		if playerName == name then return true, online end

		i = i + 1
	end

	return false, false
end

local function FormatNumber(value)
	value = tonumber(value) or 0

	if value >= 1000000 then
		return string.format("%.1fm", value / 1000000)
	elseif value >= 10000 then
		return string.format("%.1fk", value / 1000)
	end

	return tostring(math.floor(value))
end

local function CreateFont(parent, size)
	if SteakMinimap.CreateFont then
		return SteakMinimap:CreateFont(parent, size)
	end

	local font = parent:CreateFontString(nil, "OVERLAY")
	font:SetFont("Fonts\\FRIZQT__.TTF", size or 10, "OUTLINE")
	return font
end

function view:CreateRow(index)
	local row = CreateFrame("Frame", nil, self.frame)
	row:SetHeight(ROW_HEIGHT)

	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ICON_SIZE, ICON_SIZE)
	row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
	row.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")

	row.bar = CreateFrame("StatusBar", nil, row)
	row.bar:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 4, 0)
	row.bar:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -1)
	row.bar:SetHeight(ROW_HEIGHT - 8)
	row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	row.bar:SetMinMaxValues(0, 1)
	row.bar:SetValue(0)

	row.bar2 = CreateFrame("StatusBar", nil, row)
	row.bar2:SetPoint("TOPLEFT", row.bar, "BOTTOMLEFT", 0, -1)
	row.bar2:SetPoint("TOPRIGHT", row.bar, "BOTTOMRIGHT", 0, -1)
	row.bar2:SetHeight(6)
	row.bar2:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	row.bar2:SetMinMaxValues(0, 1)
	row.bar2:SetValue(0)

	row.background = row.bar:CreateTexture(nil, "BACKGROUND")
	row.background:SetAllPoints(row.bar)
	row.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	row.background:SetVertexColor(0.04, 0.04, 0.04, 0.85)

	row.nameText = CreateFont(row.bar, 9)
	row.nameText:SetPoint("LEFT", row.bar, "LEFT", 5, 0)
	row.nameText:SetJustifyH("LEFT")
	row.nameText:SetWordWrap(false)

	row.valueText = CreateFont(row.bar, 9)
	row.valueText:SetPoint("RIGHT", row.bar, "RIGHT", -4, 0)
	row.valueText:SetJustifyH("RIGHT")

	row:Hide()
	self.rows[index] = row

	return row
end

local function unitIndex(name)
	for k,v in pairs(data) do
		if v["name"] == name then
			return k
		end
	end
	return false
end

local function PruneTable()
	for k,v in ipairs(data) do
		--if not IsInGroup(v.name) and v.name ~= UnitName("player") and not IsGuildMember(v.name) then
		if not IsInGroup(v.name) and v.name ~= UnitName("player") then
			table.remove(data, k)
		end
	end
end

local function AddUnitXP(name, class, curXP, maxXP, lvl)
	local index = false

	curXP = tonumber(curXP)
	maxXP = tonumber(maxXP)
	lvl = tonumber(lvl)

	for k,v in pairs(data) do
		if v.name == name then
			index = k
			break
		end
	end

	if index == false then
		table.insert(data, {
			name = name,
			class = class,
			curXP = curXP,
			maxXP = maxXP,
			lvl = lvl
		})
	else
		data[index].curXP = curXP
		data[index].maxXP = maxXP
		data[index].lvl = lvl
		data[index].class = class
	end

	if view.frame then
		view:RefreshList()
	end
end

local function AddUnitPXP(name, class, unlocked, curXP, maxXP, lvl, quality)
	local index = false

	curXP = tonumber(curXP)
	maxXP = tonumber(maxXP)
	lvl = tonumber(lvl)

	for k,v in pairs(data) do
		if v.name == name then
			index = k
			break
		end
	end

	if index == false then
		table.insert(data, {
			name = name,
			class = class,
			pUnlocked = unlocked,
			pLvl = lvl,
			pCurXP = curXP,
			pMaxXP = maxXP,
			pQuality = quality
		})
	else
		data[index].class = class
		data[index].pUnlocked = unlocked
		data[index].pLvl = lvl
		data[index].pCurXP = curXP
		data[index].pMaxXP = maxXP
		data[index].pQuality = quality
	end

	if view.frame then
		view:RefreshList()
	end
end

local function SendXP(lvl)
	--SendAddonMessage("ShareXP", ("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player")), "GUILD")
	if ( GetNumRaidMembers() > 0 ) then
		SendAddonMessage("ShareXP", ("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player")), "RAID")
	elseif ( GetNumPartyMembers() > 0 ) then
		SendAddonMessage("ShareXP", ("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player")), "PARTY")
	end

	AddUnitXP(UnitName("player"), select(2, UnitClass("player")), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player"))
end

local function SendPXP(lvl)
	if not C_Paragon or not C_Paragon.GetAccountInfo then return end

	local Unlocked, Lvl, CurXP, MaxXP, Quality = C_Paragon.GetAccountInfo()

	if ( GetNumRaidMembers() > 0 ) then
		SendAddonMessage("ShareXP", ("PXP:%s:%s:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), Unlocked and 1 or 0, CurXP, MaxXP, Lvl, Quality), "RAID")
	elseif ( GetNumPartyMembers() > 0 ) then
		SendAddonMessage("ShareXP", ("PXP:%s:%s:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), Unlocked and 1 or 0, CurXP, MaxXP, Lvl, Quality), "PARTY")
	end

	AddUnitPXP(UnitName("player"), select(2, UnitClass("player")), Unlocked, CurXP, MaxXP, Lvl, Quality)
end

function view:EnsureRow(index)
	if not self.rows[index] then
		return self:CreateRow(index)
	end

	return self.rows[index]
end

function view:CreateStandaloneWindow()
	if self.window then return self.window end

	local window = CreateFrame("Frame", "ShareXPStandaloneFrame", UIParent)

	window:SetSize(280, 320)
	window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	window:SetFrameStrata("MEDIUM")
	window:SetMovable(true)
	window:EnableMouse(true)
	window:SetClampedToScreen(true)

	window:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })

	local titleBar = CreateFrame("Frame", nil, window)
	titleBar:SetPoint("TOPLEFT", window, "TOPLEFT", 12, -8)
	titleBar:SetPoint("TOPRIGHT", window, "TOPRIGHT", -12, -8)
	titleBar:SetHeight(24)
	titleBar:EnableMouse(true)

	titleBar:RegisterForDrag("LeftButton")
	titleBar:SetScript("OnDragStart", function() window:StartMoving() end)
	titleBar:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)

	local title = CreateFont(titleBar, 12)
	title:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
	title:SetText("ShareXP")

	local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -4, -4)
	close:SetScript("OnClick", function() window:Hide() end)

	local content = CreateFrame("Frame", nil, window)
	content:SetPoint("TOPLEFT", window, "TOPLEFT", 14, -38)
	content:SetPoint("TOPRIGHT", window, "TOPRIGHT", -14, -16)
	content:SetHeight(1)

	self.window = window
	self.standaloneContent = content

	return window
end

function view:Initialize(panel, content)
	if self.initialized then
		self.panel = panel or self.panel
		self.content = content or self.content
		self:RefreshList()
		return
	end

	self.panel = panel

	if not content then
		self:CreateStandaloneWindow()
		content = self.standaloneContent
	end

	self.content = content

	self.frame = CreateFrame("Frame", nil, content)
	self.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	self.frame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
	self.frame:SetHeight(1)

	self.eventHandler = CreateFrame("Frame")
	self.eventHandler:RegisterEvent("PLAYER_ENTERING_WORLD")
	self.eventHandler:RegisterEvent("CHAT_MSG_ADDON")
	self.eventHandler:RegisterEvent("VARIABLES_LOADED")
	self.eventHandler:RegisterEvent("PLAYER_XP_UPDATE")
	self.eventHandler:RegisterEvent("RAID_ROSTER_UPDATE")
	self.eventHandler:RegisterEvent("PARTY_MEMBERS_CHANGED")
	self.eventHandler:RegisterEvent("PLAYER_LEVEL_UP")
	self.eventHandler:RegisterEvent("PARAGON_STATE_UPDATED")
	self.eventHandler:RegisterEvent("PARAGON_XP_UPDATED")
	self.eventHandler:RegisterEvent("PARAGON_LEVEL_UP")

	if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix("ShareXP") end

	self.eventHandler:SetScript("OnEvent", function(self, event, ...)
		view:OnEvent(event, ...)
	end)

	self.initialized = true

	SendXP(UnitLevel("player"))
	SendPXP()
	self:RefreshList()
end

function view:RefreshList()
	if not self.frame then return end

	table.sort(data, function(a, b)
		local aXP = tonumber(a.curXP) or 0
		local aMax = tonumber(a.maxXP) or 0
		local bXP = tonumber(b.curXP) or 0
		local bMax = tonumber(b.maxXP) or 0

		local aPercent = aMax > 0 and aXP / aMax or 0
		local bPercent = bMax > 0 and bXP / bMax or 0

		return aPercent > bPercent
	end)

	for index, unit in ipairs(data) do
		local row = self:EnsureRow(index)

		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -((index - 1) * (ROW_HEIGHT + ROW_GAP)))
		row:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -((index - 1) * (ROW_HEIGHT + ROW_GAP)))

		local coords = CLASS_ICON_TCOORDS[string.upper(unit.class or "")]

		if coords then
			row.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
		else
			row.icon:SetTexCoord(0, 1, 0, 1)
		end

		--local r, g, b = unpack(RAID_CLASS_COLORS[unit.class])
		local color = RAID_CLASS_COLORS[unit.class]

		if color then
			row.bar:SetStatusBarColor(color.r, color.g, color.b, 1)
		else
			row.bar:SetStatusBarColor(0.5, 0.5, 0.5, 1)
		end

		local curXP = tonumber(unit.curXP) or 0
		local maxXP = tonumber(unit.maxXP) or 0
		local level = tonumber(unit.lvl) or 0

		local xpPercent = maxXP > 0 and curXP / maxXP or 0

		--row.bar:SetMinMaxValues(0, 100)
		row.bar:SetValue(xpPercent)

		local pCurXP = tonumber(unit.pCurXP) or 0
		local pMaxXP = tonumber(unit.pMaxXP) or 0
		local pLevel = tonumber(unit.pLvl) or 0
		local pUnlocked = unit.pUnlocked and true or false
		local pQuality = tonumber(unit.pQuality) or 1
		local pxpPercent = pMaxXP > 0 and pCurXP / pMaxXP or 0

		if pUnlocked and pMaxXP > 0 then
			local paragonColor = ITEM_QUALITY_COLORS[pQuality] or HIGHLIGHT_FONT_COLOR
			local hexColor = paragonColor.hex or "|cffffffff"

			--if paragonColor then
				row.bar2:SetStatusBarColor(paragonColor.r or 0.5, paragonColor.g or 0.5, paragonColor.b or 0.5, 1)
			--else
			--	row.bar2:SetStatusBarColor(0.5, 0.5, 0.5, 1)
			--end

			level = level..":"..hexColor..pLevel.."|r"

			row.bar2:SetValue(pxpPercent)
			row.bar2:Show()
			row.bar:SetHeight(ROW_HEIGHT-9)
		else
			row.bar:SetHeight(ROW_HEIGHT-2)
			row.bar2:Hide()
		end

		row.nameText:SetText(unit.name)
		row.nameText:SetWidth(math.max(35, row.bar:GetWidth() - 90))
		row.valueText:SetText(("%.0f%% [%s]"):format(xpPercent * 100, level))

		row:Show()
	end

	for index = #data + 1, #self.rows do
		self.rows[index]:Hide()
	end


	local rowsHeight = #data > 0 and (#data * ROW_HEIGHT + (#data - 1) * ROW_GAP) or 0

	local totalHeight = 27 + rowsHeight + 4

	self.frame:SetHeight(math.max(1, totalHeight))

	-- The InfoPanel scrolls this content frame, so keep its height in sync.
	self.content:SetHeight(math.max(1, totalHeight))
end

function view:Refresh(panel, content)
	self.panel = panel or self.panel
	self.content = content or self.content
	self:RefreshList()
end

function view:OnShow()
	self:RefreshList()
end

function view:OnHide()
	-- Keep the List event listener registered so the view
	-- has current data when selected again.
end

function view:OnEvent(event, ...)
	if ( event == "PLAYER_ENTERING_WORLD" ) then
		SendXP()
		SendPXP()
		return
	end

	if ( event == "PLAYER_LEVEL_UP" ) then
		local lvl = ...

		SendXP(lvl)
		return
	end

	if ( event == "PLAYER_XP_UPDATE" ) then
		SendXP()
		return
	end

	if ( event == "PARAGON_STATE_UPDATED" ) then
		SendPXP()
		return
	end

	if ( event == "PARAGON_XP_UPDATED" ) then
		SendPXP()
		return
	end

	if ( event == "PARAGON_LEVEL_UP" ) then
		SendPXP()
		return
	end

	if ( event == "CHAT_MSG_ADDON" ) then
		local prefix, msg, type, sender = ...

		if prefix == "ShareXP" then
			local cmd, args = string.split(":", msg, 2)

			if ( cmd == "XP" ) then
				local unitName, class, curXP, maxXP, lvl = string.split(":", args, 5)

				AddUnitXP(unitName, class, curXP, maxXP, lvl)
			elseif ( cmd == "PXP" ) then
				local unitName, class, unlocked, curXP, maxXP, lvl, quality = string.split(":", args, 7)

				AddUnitPXP(unitName, class, unlocked == "1", curXP, maxXP, lvl, quality)
			elseif ( cmd == "VERSION" ) then
				local maj, min, rev = string.split(".", args)

				if ( maj >= ShareXP_VERSION.maj and min >= ShareXP_VERSION.min and rev > ShareXP_VERSION.rev ) then
					print(("ShareXP: newer version available. Yours: %d.%d.%d New: %d.%d.%d (https://www.trap-nine.com/)"):format(ShareXP_VERSION.maj, ShareXP_VERSION.min, ShareXP_VERSION.rev, maj, min, rev))
				end
			elseif ( cmd == "REFRESH" ) then
				if name ~= UnitName("player") then
					SendXP(UnitLevel("player"))
				end
			end
		end
		return
	end

	if ( event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" ) then
		SendXP(UnitLevel("player"))
		self:RefreshList()

		PruneTable()

		--[[
		if ( GetNumGroupMembers() == 0 ) then
			ShareXPFrame:Hide()
		else
			ShareXPFrame:Show()
		end
		]]
		return
	end
end

--SteakMinimap:RegisterInfoView(view)

local registeredWithInfoPanel = false

if INFO_PANEL_AVAILABLE then
	local success, err = pcall(function()
		SteakMinimap:RegisterInfoView(view)
	end)

	if success then
		registeredWithInfoPanel = true
	else
		print("|cffff5555ShareXP:|r InfoPanel registration failed: " .. tostring(err))
	end
end

if not registeredWithInfoPanel then view:Initialize() end

SLASH_SHAREXP1 = "/sharexp"

SlashCmdList.SHAREXP = function()
	if not view.window then
		print("|cffff5555ShareXP:|r The standalone window is unavailable while integrated into SteakMinimap.")
		return
	end

	if view.window:IsShown() then
		view.window:Hide()
	else
		view.window:Show()
		view:RefreshList()
	end
end
