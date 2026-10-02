local f = CreateFrame("frame", "ShareXPFrame", UIParent)

local messages = {}
local channel = "ShareXP"

local numBars = 0
local barSize = 16
local barWidth = 200
local delay = 5

--GetAccountExpansionLevel() - Returns registered expansion. (0=WoW, 1=BC, 2=WotLK, 3=Cata, 4=Mists, 5=Warlords, 6=Legion, 7=BfA, 8=Shadowlands)

ShareXPDB = {
	["p"] = "TOPLEFT",
	["x"] = 200,
	["y"] = 200,
	["lock"] = false,
	["data"] = {},
}

local Settings = {
	["background"] = "Interface\\BUTTONS\\GRADBLUE",
	["border"] = "Interface\\Tooltips\\UI-Tooltip-Border",
	["refresh_rate"] = 2,
}

local MAX_LEVEL = 80

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

function ShareXPFrame:UI_ERROR_MESSAGE(event, name, ...)
        for k, v in ipairs(ErrorFilter) do
                if( string.find( string.lower(name), v ) ) then
                        return
                end
        end

        return origErrorOnEvent(self, event, name, ...)
end

local function ucfirst(str)
	return string.upper(string.sub(str, 1, 1))..string.lower(string.sub(str, 2))
end

local function ShortNumber(number)
	if number >= 1000000000 then
		return ("%.2fB"):format(number/1000000000)
	elseif number >= 1000000 then
		return ("%.2fM"):format(number/1000000)
	elseif number >= 1000 then
		return ("%.2fK"):format(number/1000)
	else
		return number
	end
end

local function DecimalToHexColor(r, g, b, a)
	return ("|c%02x%02x%02x%02x"):format(a*255, r*255, g*255, b*255)
end

local function TableSum(table)
	local retVal = 0

	for _, n in ipairs(table) do
		retVal = retVal + n
	end

	return retVal
end

local function unitIndex(name)
	for k,v in pairs(ShareXPDB.data) do
		if v["name"] == name then
			return k
		end
	end
	return false
end

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

local function IsInParty(name)
	if ( name == UnitName("player") ) then
		return true
	end

	local numMembers, groupType = GetNumGroupMembers()

	if numMembers > 0 then
		for i=1, numMembers, 1 do
			local unit = ("%s%d"):format(groupType, i)

			if UnitName(unit) == name then return true end
		end
	end

	return false
end

local function PruneTable()
	for k,v in ipairs(ShareXPDB.data) do
		if not IsInParty(v["name"]) and v["name"] ~= UnitName("player") then
			table.remove(ShareXPDB.data, k)
		end
	end
end

local function ShareXP_Refresh()
	local sortTbl = {}
	for k,v in ipairs(ShareXPDB.data) do table.insert(sortTbl, k) end
	table.sort(sortTbl, function(a,b) return ShareXPDB.data[a].percent > ShareXPDB.data[b].percent end)

	local index = 1
	for k,v in ipairs(sortTbl) do
		local bar = ShareXP_AddBar(index)
		local name = ShareXPDB.data[v].name
		local percent = ShareXPDB.data[v].percent
		local lvl = ShareXPDB.data[v].lvl
		local class = string.upper(ShareXPDB.data[v].class)

		_G["ShareXPBar"..index.."Name"]:SetText(name)
		_G["ShareXPBar"..index.."Percent"]:SetText(("%s%% [%s]"):format(percent or "?", lvl or "?"))

		if ( class ~= nil and RAID_CLASS_COLORS[class] ~= nil ) then
			_G[bar:GetName().."Status"]:SetStatusBarColor(RAID_CLASS_COLORS[class].r, RAID_CLASS_COLORS[class].g, RAID_CLASS_COLORS[class].b, 1)
		else
			_G[bar:GetName().."Status"]:SetStatusBarColor(0, 1, 0, 1)
		end
		_G[bar:GetName().."Status"]:SetValue(ShareXPDB.data[v].percent)

		if IsInParty(ShareXPDB.data[v].name) ~= false then
			bar:Show()
			index = index + 1
		end
	end

	if ( numBars > #(ShareXPDB.data) ) then
		for i=#(ShareXPDB.data)+1,numBars,1 do
			if _G["ShareXPFrameBar"..i] then _G["ShareXPFrameBar"..i]:Hide() end
		end
	end
end

local function AddUnit(name, class, curXP, maxXP, lvl)
	local index = false
	local percent = ("%.0f"):format((curXP / maxXP)*100)

	curXP = tonumber(curXP)
	maxXP = tonumber(maxXP)
	lvl = tonumber(lvl)

	for k,v in pairs(ShareXPDB.data) do
		if v.name == name then
			index = k
			break
		end
	end

	if index == false then
		table.insert(ShareXPDB.data, { ["name"] = name, ["class"] = class, ["curXP"] = curXP, ["maxXP"] = maxXP, ["lvl"] = lvl, ["percent"] = percent })
	else
		ShareXPDB.data[index].percent = percent
		ShareXPDB.data[index].curXP = curXP
		ShareXPDB.data[index].maxXP = maxXP
		ShareXPDB.data[index].lvl = lvl
	end

	ShareXP_Refresh()
end

local function SendXP(lvl)
	--SendAddonMessage("ShareXP", ("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player")), "GUILD")

	if ( GetNumRaidMembers() > 0 ) then
		SendAddonMessage("ShareXP", ("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player")), "RAID")
	elseif ( GetNumPartyMembers() > 0 ) then
		SendAddonMessage("ShareXP", ("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player")), "PARTY")
	end

	AddUnit(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player"))
end

f:SetSize(barWidth, barSize)

f:SetClampedToScreen(true)
f:SetMovable(true)
f:EnableMouse(true)

f:SetScript("OnMouseDown", function(self, button)
	self:StartMoving()
end)

f:SetScript("OnMouseUp", function(self, button)
	ShareXPDB.p, _, _, ShareXPDB.x, ShareXPDB.y = self:GetPoint()

	self:StopMovingOrSizing()
end)

f:SetBackdrop( { bgFile = "Interface\\TargetingFrame\\UI-StatusBar", edgeFile = nil, tile = false, tileSize = f:GetWidth(), edgeSize = 0, insets = { left = 0, right = 0, top = 0, bottom = 0 } } )
f:SetBackdropColor(0.8, 0, 1, 1)

local title = f:CreateFontString(f:GetName().."Text", "OVERLAY")
title:SetFont("Fonts\\ARIALN.ttf", 12, "OUTLINE")
title:SetAllPoints(f)
title:SetJustifyH("LEFT")
title:SetText("ShareXP")

function ShareXP_AddBar(i)
	local bar = _G["ShareXPBar"..i] or CreateFrame("Frame", "ShareXPBar"..i, f)

	bar:SetSize(barWidth, barSize)

	if i == 1 then
		bar:SetPoint("TOP", f, "BOTTOM", 0, -2)
	else
		bar:SetPoint("TOP", _G["ShareXPBar"..(i-1)], "BOTTOM", 0, -2)
	end

	bar.background = bar:CreateTexture(nil, "BACKGROUND")
	bar.background:SetTexture("Interface\\DialogFrame\\UI-DialogBox-BackGround-Dark")
	bar.background:SetVertexColor(0.5, 0.5, 0.5, 0.5)

	local sb = CreateFrame("StatusBar", bar:GetName().."Status", bar)
	sb:SetMinMaxValues(0, 100)
	sb:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
	sb:GetStatusBarTexture():SetHorizTile(false)
	sb:SetStatusBarColor(0, 1, 0)
	sb:SetValue(0)

	sb:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
	sb:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

	local t = sb:CreateFontString(bar:GetName().."Name", "OVERLAY", "NumberFont_Outline_Med")
	t:SetJustifyH("LEFT")
	t:SetPoint("LEFT", sb, "LEFT", 2, 0)

	local t = sb:CreateFontString(bar:GetName().."Percent", "OVERLAY", "NumberFont_Outline_Med")
	t:SetJustifyH("RIGHT")
	t:SetPoint("RIGHT", sb, "RIGHT", -2, 0)

	numBars = i

	return bar
end

local function OnEvent(self, event, ...)
	if ( event == "VARIABLES_LOADED" ) then
		if ShareXPDB.lock == true then
			self:EnableMouse(false)
			self:SetMovable(false)
		else
			self:EnableMouse(true)
			self:SetMovable(true)
		end

		self:SetPoint(ShareXPDB.p, UIParent, ShareXPDB.p, ShareXPDB.x, ShareXPDB.y)
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		SendXP()
	elseif ( event == "PLAYER_LEVEL_UP" ) then
		local lvl = ...

		SendXP(lvl)
	elseif ( event == "PLAYER_XP_UPDATE" ) then
		SendXP()
	elseif ( event == "CHAT_MSG_ADDON" ) then
		local prefix, msg, type, sender = ...

		if prefix == "ShareXP" then
			local cmd, args = string.split(":", msg, 2)

			if ( cmd == "XP" ) then
				local unitName, class, curXP, maxXP, lvl = string.split(":", args, 5)

				AddUnit(unitName, class, curXP, maxXP, lvl)
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
	elseif ( event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" ) then
		ShareXP_Refresh()
		SendXP(UnitLevel("player"))

		--PruneTable()

		--[[
		if ( GetNumGroupMembers() == 0 ) then
			ShareXPFrame:Hide()
		else
			ShareXPFrame:Show()
		end
		]]
	end
end

f:RegisterEvent("CHAT_MSG_ADDON")
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")

f:SetScript("OnEvent", OnEvent)
