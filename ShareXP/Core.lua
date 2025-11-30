local f = CreateFrame("frame", "ShareXPFrame", UIParent)

f.messages = {}
f.channel = "ShareXP"
f.debug = true

local numBars = 0
local barSize = 16
local barWidth = 200
local delay = 5

ShareXPDB = {
	["p"] = "RIGHT",
	["x"] = 0,
	["y"] = 0,
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

local function GetPrefix(msg)
        local index = string.find(msg, ":")

        if index and index > 1 then
                return gsub(msg, 1, index - 1)
        else
                return nil
        end
end

local function QueueAddOnMessage(msg)
        if UnitLevel("player") < 15 then return end
	if UnitLevel("player") == MAX_LEVEL and GetPrefix(msg) == "XP" then return end

        for i, existingMsg in ipairs(f.messages) do
                if existingMsg == msg then return end
                if GetPrefix(existingMsg) == GetPrefix(msg) and GetPrefix(existingMsg) ~= nil then
			table.remove(f.messages, i)
                end
        end

        table.insert(f.messages, msg)
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
		_G["ShareXPBar"..index.."Percent"]:SetText(("%s%% [%s]"):format(percent, lvl))	

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

local function ShareXP(lvl)
	if lvl ~= nil then
		QueueAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), lvl))
	else
		QueueAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), UnitLevel("player")))
	end
end

local function Disable()
	LeaveChannelByName(f.channel)

	for i=1,numBars,1 do
		_G["ShareXPBar"..i]:Hide()
	end

	ShareXPFrame:Hide()
end

local function Enable()
	JoinChannelByName(f.channel)

	for i=1,NUM_CHAT_WINDOWS,1 do
		RemoveChatWindowChannel(i, f.channel)
	end

	QueueAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), UnitLevel("player")))
	QueueAddOnMessage("REFRESH")

	PruneTable()

	ShareXP_Refresh()

	ShareXPFrame:Show()
end

local function AddUnit(name, class, curXP, maxXP, lvl)
	local index = false
	local percent = ("%.0f"):format((curXP / maxXP)*100)

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

local function SendAddOnMessage()
	if GetChannelName(f.channel) > 0 then
		SendChatMessage(f.messages[1], "CHANNEL", nil, GetChannelName(f.channel))
	end
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

		--if UnitLevel("player") < MAX_LEVEL then
			QueueAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), UnitLevel("player")))
		--end

		self:SetPoint(ShareXPDB.p, UIParent, ShareXPDB.p, ShareXPDB.x, ShareXPDB.y)
	elseif ( event == "PLAYER_ENTERING_WORLD" ) then
		if GetNumGroupMembers() == 0 then
			Disable()
		else
			Enable()
		end
	elseif ( event == "PLAYER_LEVEL_UP" ) then
		local lvl = ...
		--if lvl < MAX_LEVEL then
			QueueAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), lvl))
		--end
	elseif ( event == "PLAYER_XP_UPDATE" ) then
		--if UnitLevel("player") < MAX_LEVEL then
			QueueAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), UnitLevel("player")))
		--end
	elseif ( event == "CHAT_MSG_CHANNEL" ) then
		local msg, name, _, _, _, _, _, _, chan = ...		

		if name == UnitName("player") and chan == self.channel then
			print(msg, name, chan)
			for k, v in ipairs(self.messages) do
				print(k, v)
			end
		end

		if name == UnitName("player") and chan == self.channel then
			for k, v in ipairs(self.messages) do
				if v == msg then
					print("[SHAREXP]: message sent successfully ["..k.."] ("..msg..")")
					table.remove(f.messages, k)
				end
			end
		end

		if ( chan == self.channel and IsInParty(name) ) then
			local type, args = string.split(":", msg, 2)

			if ( type == "XP" ) then
				local unitName, class, curXP, maxXP, lvl = string.split(":", args, 5)
				
				AddUnit(unitName, class, curXP, maxXP, lvl)
			elseif ( type == "VERSION" ) then
				local maj, min, rev = string.split(".", args)

				if ( maj >= ShareXP_VERSION.maj and min >= ShareXP_VERSION.min and rev > ShareXP_VERSION.rev ) then
					print(("ShareXP: newer version available. Yours: %d.%d.%d New: %d.%d.%d (https://www.trap-nine.com/)"):format(ShareXP_VERSION.maj, ShareXP_VERSION.min, ShareXP_VERSION.rev, maj, min, rev))
				end
			elseif ( type == "REFRESH" ) then
				if name ~= UnitName("player") then
					--if UnitLevel("player") < MAX_LEVEL then
						QueueAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), UnitLevel("player")))
					--end
				end
			end
		end
	elseif ( event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" ) then
		if GetNumGroupMembers() > 0 then
			Disable()
		elseif GetNumGroupMembers() > 0 then
			Enable()
		end

		ShareXP_Refresh()
		if UnitLevel("player") < MAX_LEVEL then
			QueueAddOnMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), UnitClass("player"), UnitXP("player"), UnitXPMax("player"), UnitLevel("player")))
		end

		PruneTable()

		if ( GetNumGroupMembers() == 0 ) then
			ShareXPFrame:Hide()
		else
			ShareXPFrame:Show()
		end
	end

	if event:gsub(1, 9) == "CHAT_MSG_" then
		local _, name = ...

		if name == UnitName("player") then
			f.lastMessageTime = GetTime()
		end
	end
end

f:RegisterEvent("CHAT_MSG_GUILD")
f:RegisterEvent("CHAT_MSG_PARTY")
f:RegisterEvent("CHAT_MSG_PARTY_LEADER")
f:RegisterEvent("CHAT_MSG_RAID")
f:RegisterEvent("CHAT_MSG_RAID_LEADER")
f:RegisterEvent("CHAT_MSG_GUILD_OFFICER")
f:RegisterEvent("CHAT_MSG_YELL")
f:RegisterEvent("CHAT_MSG_SAY")
f:RegisterEvent("CHAT_MSG_CHANNEL")
f:RegisterEvent("CHAT_MSG_WHISPER_INFORM")
f:RegisterEvent("VARIABLES_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_XP_UPDATE")
f:RegisterEvent("PLAYER_LEVEL_UP")
f:RegisterEvent("RAID_ROSTER_UPDATE")
f:RegisterEvent("PARTY_MEMBERS_CHANGED")

local function OnUpdate(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        --self.timer2 = (self.timer2 or 0) + elapsed
        self.lastMessageTime = self.lastMessageTime or GetTime()

        if self.timer > 0.2 then
                --if GetTime() - self.lastMessageTime > MESSAGE_DELAY and (self.counter or 0) < 3 then
                if GetTime() - self.lastMessageTime > delay then
                        if #(self.messages) > 0 then
                                SendAddOnMessage()
                        end
                end

                self.timer = 0
        end

        --[[
        if self.timer2 >= MESSAGE_DELAY then
                if (self.counter or 0) > 0 then
                        self.counter = self.counter - 1
                end

                self.timer2 = 0
        end
        ]]
end

f:SetScript("OnEvent", OnEvent)
f:SetScript("OnUpdate", OnUpdate)

local function SlashCmd(...)
	local cmd, params = string.split(" ", string.lower(...), 2)

	if cmd == "off" then
		f.debug = true
                print("[SHAREXP]: debug off")
	elseif cmd == "on" then
		f.debug = false
                print("[SHAREXP]: debug on")
	elseif cmd == "remove" then
		table.remove(f.messages, 1)
		for k,v in ipairs(f.messages) do
			print(k, v)
		end	
	elseif cmd == "print" then
		for k,v in ipairs(f.messages) do
			print(k, v)
		end
	elseif cmd == "reset" then
		ShareXPDB.data = {}
		ShareXP_Refresh()
	end
end

SLASH_ShareXP1 = "/sxp"
SLASH_ShareXP2 = "/sharexp"
SlashCmdList["ShareXP"] = SlashCmd
