local ShareXPCore = ShareXPCore
if not ShareXPCore then return end

ShareXPDB = {
	["p"] = "TOPLEFT",
	["x"] = 200,
	["y"] = 200,
	["lock"] = false
}

ShareXP = {
	rowWidth = 180,
	rowHeight = 22,
	barHeight = 10,
	rowGap = 3,
	iconSize = 22,
	fontSize = 8,
	rows = {},
	classIconCoords = {
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
	},
	events = {
		"VARIABLES_LOADED"
	},
	Init = function(self)
		if self.initialized then return end
		self.initialized = true

		self.maxLevel = self:GetMaxLevel()

		self.frame = CreateFrame("Frame", nil, UIParent)
		self.frame:SetClampedToScreen(true)
		self.frame:SetMovable(true)
		self.frame:EnableMouse(true)
		self.frame:SetSize(self.rowWidth, self.barHeight)

		local title = self:CreateFont(self.frame, 8)
		title:SetPoint("LEFT", self.frame, "LEFT", 2, 0)
		title:SetJustifyH("LEFT")
		title:SetText("ShareXP")

		self.frame:SetScript("OnMouseDown", function(self, button)
			self:StartMoving()
		end)

		self.frame:SetScript("OnMouseUp", function(self, button)
			ShareXPDB.p, _, _, ShareXPDB.x, ShareXPDB.y = self:GetPoint()

			self:StopMovingOrSizing()
		end)

		for _, event in ipairs(self.events) do
			self.frame:RegisterEvent(event)
		end

		self.frame:SetScript("OnEvent", function(_, event, ...)
			if self[event] then
				self[event](...)
			end
		end)

		self.frame:SetBackdrop( { bgFile = "Interface\\TargetingFrame\\UI-StatusBar", edgeFile = nil, tile = false, tileSize = self.frame:GetWidth(), edgeSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0 } } )
		self.frame:SetBackdropColor(0.8, 0, 1, 1)

		ShareXPCore:RegisterCallback(function(data)
			ShareXP:RefreshList()
		end)

		self.frame:HookScript("OnShow", function(self)
			self:RefreshList()
		end)
	end,
	CreateFont = function(self, parent, size)
		local font = parent:CreateFontString(nil, "OVERLAY")
		font:SetFont("Interface\\AddOns\\ShareXP\\Audiowide-Regular.ttf", size or 10, "OUTLINE")
		return font
	end,
	GetMaxLevel = function(self)
		local expansion = GetAccountExpansionLevel()
		local maxLevel = 0

		if expansion == 0 then
			maxLevel = 60
		elseif expansion == 1 then
			maxLevel = 70
		elseif expansion == 2 then
			maxLevel = 80
		elseif expansion == 3 then
			maxLevel = 85
		elseif expansion == 4 then
			maxLevel = 90
		elseif expansion == 5 then
			maxLevel = 100
		elseif expansion == 6 then
			maxLevel = 110
		elseif expansion == 7 then
			maxLevel = 120
		elseif expansion == 8 then
			maxLevel = 60
		end

		return maxLevel
	end,
	UnitIndex = function(self, name)
		for k,v in pairs(ShareXPCore.data) do
			if v["name"] == name then
				return k
			end
		end

		return false
	end,
	CreateRow = function(self, index)
		local row = CreateFrame("Frame", nil, self.frame)
		row:SetHeight(self.rowHeight)

		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(self.iconSize, self.iconSize)
		row.icon:SetPoint("LEFT", row, "LEFT", 2, 0)
		row.icon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")

		row.bar = CreateFrame("StatusBar", nil, row)
		row.bar:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 4, 0)
		row.bar:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -1)
		row.bar:SetHeight(self.barHeight)
		row.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		row.bar:SetMinMaxValues(0, 1)
		row.bar:SetValue(0)

		row.bar2 = CreateFrame("StatusBar", nil, row)
		row.bar2:SetPoint("TOPLEFT", row.bar, "BOTTOMLEFT", 0, -1)
		row.bar2:SetPoint("TOPRIGHT", row.bar, "BOTTOMRIGHT", 0, -1)
		row.bar2:SetHeight(self.barHeight)
		row.bar2:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
		row.bar2:SetMinMaxValues(0, 1)
		row.bar2:SetValue(0)

		row.nameText = self:CreateFont(row.bar, self.fontSize)
		row.nameText:SetPoint("LEFT", row.bar, "LEFT", 5, 0)
		row.nameText:SetJustifyH("LEFT")
		row.nameText:SetWordWrap(false)

		row.valueText = self:CreateFont(row.bar, self.fontSize)
		row.valueText:SetPoint("RIGHT", row.bar, "RIGHT", -4, 0)
		row.valueText:SetJustifyH("RIGHT")

		row.valueText2 = self:CreateFont(row.bar2, self.fontSize)
		row.valueText2:SetPoint("RIGHT", row.bar2, "RIGHT", -4, 0)
		row.valueText2:SetJustifyH("RIGHT")

		row.valueText3 = self:CreateFont(row.bar2, self.fontSize)
		row.valueText3:SetPoint("LEFT", row.bar2, "LEFT", 5, 0)
		row.valueText3:SetJustifyH("LEFT")
		row.valueText3:SetWordWrap(false)

		row:Hide()
		self.rows[index] = row

		return row
	end,
	EnsureRow = function(self, index)
		if not self.rows[index] then
			return self:CreateRow(index)
		end

		return self.rows[index]
	end,
	RefreshList = function(self)
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
			local offsetY = -(((index-1) * (self.rowHeight + self.rowGap)) + self.rowGap)
			row:SetPoint("TOPLEFT", self.frame, "BOTTOMLEFT", 0, offsetY)
			row:SetPoint("TOPRIGHT", self.frame, "BOTTOMRIGHT", 0, offsetY)

			local coords = self.classIconCoords[string.upper(unit.class or "")]

			if coords then
				row.icon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
			else
				row.icon:SetTexCoord(0, 1, 0, 1)
			end

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

				row.bar2:SetStatusBarColor(paragonColor.r or 0.5, paragonColor.g or 0.5, paragonColor.b or 0.5, 1)
				row.bar2:SetValue(pxpPercent)
				row.bar2:Show()
				row.bar:SetHeight(self.rowHeight-9)
			else
				row.bar:SetHeight(self.rowHeight-2)
				row.bar2:Hide()
			end

			row.nameText:SetText(unit.name)
			row.nameText:SetWidth(math.max(35, row.bar:GetWidth() - 90))
			if level == self.maxLevel then
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

		--local rowsHeight = #ShareXPCore.data > 0 and (#ShareXPCore.data * self.rowHeight + (#ShareXPCore.data - 1) * self.rowGap) or 0
		--local totalHeight = 27 + rowsHeight + 4

		--self.frame:SetHeight(math.max(1, totalHeight))

		--self.content:SetHeight(math.max(1, totalHeight))
	end,
	VARIABLES_LOADED = function(self)
		local frame = self and self.frame or self
		if not frame then frame = ShareXP.frame end

		if ShareXPDB.lock == true then
			frame:EnableMouse(false)
			frame:SetMovable(false)
		else
			frame:EnableMouse(true)
			frame:SetMovable(true)
		end

		frame:SetPoint(ShareXPDB.p, UIParent, ShareXPDB.p, ShareXPDB.x, ShareXPDB.y)
	end
}

ShareXP:Init()
