local SteakMinimap = SteakMinimap
if not SteakMinimap or not SteakMinimap.RegisterInfoView then return end
local ShareXPCore = ShareXPCore
if not ShareXPCore then return end

local ROW_HEIGHT = 22
local BAR_HEIGHT = 10
local ROW_GAP = 3
local ICON_SIZE = 22
local FONT_SIZE = 8

local view = {
	name = "ShareXP",
	title = "ShareXP",
	rows = {}
}

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
	--row.bar:SetHeight(ROW_HEIGHT - 8)
	row.bar:SetHeight(BAR_HEIGHT)
	row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	row.bar:SetMinMaxValues(0, 1)
	row.bar:SetValue(0)

	row.bar2 = CreateFrame("StatusBar", nil, row)
	row.bar2:SetPoint("TOPLEFT", row.bar, "BOTTOMLEFT", 0, -1)
	row.bar2:SetPoint("TOPRIGHT", row.bar, "BOTTOMRIGHT", 0, -1)
	--row.bar2:SetHeight(6)
	row.bar2:SetHeight(BAR_HEIGHT)
	row.bar2:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	row.bar2:SetMinMaxValues(0, 1)
	row.bar2:SetValue(0)

	--[[
	row.background = row.bar:CreateTexture(nil, "BACKGROUND")
	row.background:SetAllPoints(row.bar)
	row.background:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
	row.background:SetVertexColor(0.04, 0.04, 0.04, 0.85)
	]]

	row.nameText = CreateFont(row.bar, FONT_SIZE)
	row.nameText:SetPoint("LEFT", row.bar, "LEFT", 5, 0)
	row.nameText:SetJustifyH("LEFT")
	row.nameText:SetWordWrap(false)

	row.valueText = CreateFont(row.bar, FONT_SIZE)
	row.valueText:SetPoint("RIGHT", row.bar, "RIGHT", -4, 0)
	row.valueText:SetJustifyH("RIGHT")

	row.valueText2 = CreateFont(row.bar2, FONT_SIZE)
	row.valueText2:SetPoint("RIGHT", row.bar2, "RIGHT", -4, 0)
	row.valueText2:SetJustifyH("RIGHT")

	row.valueText3 = CreateFont(row.bar2, FONT_SIZE)
	row.valueText3:SetPoint("LEFT", row.bar2, "LEFT", 5, 0)
	row.valueText3:SetJustifyH("LEFT")
	row.valueText3:SetWordWrap(false)

	row:Hide()
	self.rows[index] = row

	return row
end

local function unitIndex(name)
	for k,v in pairs(ShareXPCore.data) do
		if v["name"] == name then
			return k
		end
	end
	return false
end

function view:EnsureRow(index)
	if not self.rows[index] then
		return self:CreateRow(index)
	end

	return self.rows[index]
end

function view:Initialize(panel, content)
	self.panel = panel
	self.content = content

	self.frame = CreateFrame("Frame", nil, content)
	self.frame:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
	self.frame:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, 0)
	self.frame:SetHeight(1)
end

function view:RefreshList()
	if not self.frame then return end

	table.sort(ShareXPCore.data, function(a, b)
		local aXP = tonumber(a.curXP) or 0
		local aMax = tonumber(a.maxXP) or 0
		local bXP = tonumber(b.curXP) or 0
		local bMax = tonumber(b.maxXP) or 0

		local aPercent = aMax > 0 and aXP / aMax or 0
		local bPercent = bMax > 0 and bXP / bMax or 0

		return aPercent > bPercent
	end)

	for index, unit in ipairs(ShareXPCore.data) do
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

			--level = level..":"..hexColor..pLevel.."|r"

			row.bar2:SetValue(pxpPercent)
			row.bar2:Show()
			row.bar:SetHeight(ROW_HEIGHT-9)
		else
			row.bar:SetHeight(ROW_HEIGHT-2)
			row.bar2:Hide()
		end

		row.nameText:SetText(unit.name)
		row.nameText:SetWidth(math.max(35, row.bar:GetWidth() - 90))
		if level == MAX_LEVEL then
			row.valueText:SetText("[MAX]")
			row.bar:SetValue(1)
		else
			row.valueText:SetText(("%.0f%% [%s]"):format(xpPercent * 100, level))
		end
		row.valueText2:SetText(("%.0f%% [%s]"):format(pxpPercent * 100, pLevel))
		row.valueText3:SetText(("-%d"):format(pMaxXP - pCurXP))

		row:Show()
	end

	for index = #ShareXPCore.data + 1, #self.rows do
		self.rows[index]:Hide()
	end


	local rowsHeight = #ShareXPCore.data > 0 and (#ShareXPCore.data * ROW_HEIGHT + (#ShareXPCore.data - 1) * ROW_GAP) or 0

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

ShareXPCore:RegisterCallback(function(data)
	view:RefreshList()
end)
SteakMinimap:RegisterInfoView(view)
