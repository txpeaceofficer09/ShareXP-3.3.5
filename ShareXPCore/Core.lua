ShareXPCore = {
	data = {},
	callbacks = {},
	events = {
		"PLAYER_ENTERING_WORLD",
		"PLAYER_LEVEL_UP",
		"PLAYER_XP_UPDATE",
		"PARAGON_STATE_UPDATED",
		"PARAGON_XP_UPDATED",
		"PARAGON_LEVEL_UP",
		"CHAT_MSG_ADDON",
		"RAID_ROSTER_UPDATE",
		"PARTY_MEMBERS_CHANGED"
	},
	frame = CreateFrame("Frame", nil, UIParent),
	prefix = "ShareXP",
	Init = function(self)
		if self.initialized then return end
		self.initialized = true

		if RegisterAddonMessagePrefix then
			RegisterAddonMessagePrefix("ShareXP")
		end

		for _, event in ipairs(self.events) do
			self.frame:RegisterEvent(event)
		end

		self.frame:SetScript("OnEvent", function(_, event, ...)
			if self[event] then
				self[event](self, ...)
			end
		end)
	end,
	GetData = function(self)
		return self.data
	end,
	GetPlayerData = function(self, name)
		for k,v in pairs(self.data) do
			if v.name == name then
				return v
			end
		end
		return nil
	end,
	GetGroupData = function(self)
		local table = {}

		for k,v in pairs(self.data) do
			if not self:IsGuildMember(v.name) then
				table.insert(table, v)
			end
		end

		return table
	end,
	NotifyCallbacks = function(self)
		for _, callback in pairs(self.callbacks) do
			callback(self.data)
		end
	end,
	SendAddonMessage = function(self, message)
		SendAddonMessage(self.prefix, message, "GUILD")

		if GetNumRaidMembers() > 0 then
			SendAddonMessage(self.prefix, message, "RAID")
		elseif GetNumPartyMembers() > 0 then
			SendAddonMessage(self.prefix, message, "PARTY")
		end
	end,
	RequestRefresh = function(self)
		self:SendAddonMessage("REFRESH")
		--[[
		SendAddonMessage("ShareXP", "REFRESH", "GUILD")
		if GetNumRaidMembers() > 0 then
			SendAddonMessage("ShareXP", "REFRESH", "RAID")
		elseif GetNumPartyMembers() > 0 then
			SendAddonMessage("ShareXP", "REFRESH", "PARTY")
		end
		]]
	end,
	PruneTable = function(self)
		local changed = false

		for i = #self.data, 1, -1 do
			if not self:IsInGroup(self.data[i].name) and not self:IsGuildMember(self.data[i].name) then
				table.remove(self.data, i)
				changed = true
			end
		end

		if changed then self:NotifyCallbacks() end
	end,
	RegisterCallback = function(self, callback)
		if type(callback) ~= "function" then return end

		for _, registered in ipairs(self.callbacks) do
			if registered == callback then
				return
			end
		end

		table.insert(self.callbacks, callback)
	end,
	UnregisterCallback = function(self, callback)
		for k,v in pairs(self.callbacks) do
			if v == callback then
				table.remove(self.callbacks, k)
				break
			end
		end
	end,
	GetNumGroupMembers = function(self)
		local party, raid = GetNumPartyMembers(), GetNumRaidMembers()

		if raid > 0 then
			return raid, "raid"
		elseif party > 0 then
			return party, "party"
		else
			return 0, nil
		end
	end,
	IsInGroup = function(self, name)
		if ( name == UnitName("player") ) then return true end

		local numMembers, groupType = self:GetNumGroupMembers()

		if numMembers > 0 then
			for i=1, numMembers, 1 do
				local unit = ("%s%d"):format(groupType, i)

				if UnitName(unit) == name then return true end
			end
		end

		return false
	end,
	IsGuildMember = function(self, playerName)
		local i = 1

		while GetGuildRosterInfo(i) ~= nil do
			local name, rank, rankIndex, level, class, zone, note, officerNote, online, _, classFileName = GetGuildRosterInfo(i)

			if playerName == name then return true, online end

			i = i + 1
		end

		return false, false
	end,
	GetUnitXP = function(self, name)
		for _, unit in ipairs(self.data) do
			if unit.name == name then
				return unit.name, unit.curXP, unit.maxXP, unit.lvl
			end
		end

		return nil
	end,
	GetUnitPXP = function(self, name)
		for _, unit in ipairs(self.data) do
			return name, pCurXP, pMaxXP, pLvl, pUnlocked, pQuality
		end

		return nil
	end,
	AddUnitXP = function(self, name, class, curXP, maxXP, lvl)
		local index = false

		curXP = tonumber(curXP)
		maxXP = tonumber(maxXP)
		lvl = tonumber(lvl)

		for k,v in pairs(self.data) do
			if v.name == name then
				index = k
				break
			end
		end

		if index == false then
			table.insert(self.data, {
				name = name,
				class = class,
				curXP = curXP,
				maxXP = maxXP,
				lvl = lvl
			})
		else
			--if self.data[index].maxXP == maxXP and self.data[index].lvl == lvl and self.data[index].curXP < curXP then
				self.data[index].curXP = curXP
				self.data[index].maxXP = maxXP
				self.data[index].lvl = lvl
				self.data[index].class = class
			--elseif self.data[index].maxXP < maxXP or self.data[index].lvl < lvl then
			--	self.data[index].curXP = curXP
			--	self.data[index].maxXP = maxXP
			--	self.data[index].lvl = lvl
			--	self.data[index].class = class
			--end
		end

		self:NotifyCallbacks()
	end,
	AddUnitPXP = function(self, name, class, unlocked, curXP, maxXP, lvl, quality)
		local index = false

		curXP = tonumber(curXP)
		maxXP = tonumber(maxXP)
		lvl = tonumber(lvl)

		for k,v in pairs(self.data) do
			if v.name == name then
				index = k
				break
			end
		end

		if index == false then
			table.insert(self.data, {
				name = name,
				class = class,
				pUnlocked = unlocked,
				pLvl = lvl,
				pCurXP = curXP,
				pMaxXP = maxXP,
				pQuality = quality
			})
		else
			--if self.data[index].pMaxXP == maxXP and self.data[index].pLvl == lvl and self.data[index].pCurXP < curXP then
				self.data[index].class = class
				self.data[index].pUnlocked = unlocked
				self.data[index].pLvl = lvl
				self.data[index].pCurXP = curXP
				self.data[index].pMaxXP = maxXP
				self.data[index].pQuality = quality
			--elseif self.data[index].pMaxXP < maxXP or self.data[index].pLvl < lvl then
			--	self.data[index].class = class
			--	self.data[index].pUnlocked = unlocked
			--	self.data[index].pLvl = lvl
			--	self.data[index].pCurXP = curXP
			--	self.data[index].pMaxXP = maxXP
			--	self.data[index].pQuality = quality
			--end
		end

		self:NotifyCallbacks()
	end,
	SendXP = function(self, lvl)
		--[[
		if ( GetNumRaidMembers() > 0 ) then
			SendAddonMessage("ShareXP", ("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player")), "RAID")
		elseif ( GetNumPartyMembers() > 0 ) then
			SendAddonMessage("ShareXP", ("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player")), "PARTY")
		end
		]]
		self:SendAddonMessage(("XP:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player")))

		self:AddUnitXP(UnitName("player"), select(2, UnitClass("player")), UnitXP("player"), UnitXPMax("player"), lvl or UnitLevel("player"))
	end,
	SendPXP = function(self, lvl)
		if not C_Paragon or not C_Paragon.GetAccountInfo then return end

		local Unlocked, Lvl, CurXP, MaxXP, Quality = C_Paragon.GetAccountInfo()

		--[[
		if ( GetNumRaidMembers() > 0 ) then
			SendAddonMessage("ShareXP", ("PXP:%s:%s:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), Unlocked and 1 or 0, CurXP, MaxXP, Lvl, Quality), "RAID")
		elseif ( GetNumPartyMembers() > 0 ) then
			SendAddonMessage("ShareXP", ("PXP:%s:%s:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), Unlocked and 1 or 0, CurXP, MaxXP, Lvl, Quality), "PARTY")
		end
		]]
		self:SendAddonMessage(("PXP:%s:%s:%s:%s:%s:%s:%s"):format(UnitName("player"), select(2, UnitClass("player")), Unlocked and 1 or 0, CurXP, MaxXP, Lvl, Quality))

		self:AddUnitPXP(UnitName("player"), select(2, UnitClass("player")), Unlocked, CurXP, MaxXP, Lvl, Quality)
	end,
	PLAYER_ENTERING_WORLD = function(self)
		self:SendXP()
		self:SendPXP()
		self:RequestRefresh()
	end,
	PLAYER_LEVEL_UP = function(self, lvl)
		self:SendXP(lvl)
	end,
	PLAYER_XP_UPDATE = function(self)
		self:SendXP()
	end,
	PARAGON_STATE_UPDATED = function(self)
		self:SendPXP()
	end,
	PARAGON_XP_UPDATED = function(self)
		self:SendPXP()
	end,
	PARAGON_LEVEL_UP = function(self)
		self:SendPXP()
	end,
	CHAT_MSG_ADDON = function(self, prefix, msg, type, sender)
		if prefix ~= "ShareXP" then return end

		local cmd, args = string.split(":", msg, 2)

		if cmd == "XP" then
			local unitName, class, curXP, maxXP, lvl = string.split(":", args, 5)

			self:AddUnitXP(unitName, class, curXP, maxXP, lvl)
		elseif cmd == "PXP" then
			local unitName, class, unlocked, curXP, maxXP, lvl, quality = string.split(":", args, 7)

			self:AddUnitPXP(unitName, class, unlocked == "1", curXP, maxXP, lvl, quality)
		elseif cmd == "VERSION" then
			local maj, min, rev = string.split(".", args)

			maj = tonumber(maj) or 0
			min = tonumber(min) or 0
			rev = tonumber(rev) or 0

			local current = ShareXP_VERSION
			local newer = maj > current.maj or (maj == current.maj and min > current.min) or (maj == current.maj and min == current.min and rev > current.rev)

			if newer then
				print(("ShareXPCore: newer version available. Yours: %d.%d.%d New: %d.%d.%d (https://www.trap-nine.com/)"):format(current.maj, current.min, current.rev, maj, min, rev))
			end
		elseif cmd == "REFRESH" then
			if sender ~= UnitName("player") then
				self:SendXP(UnitLevel("player"))
				self:SendPXP()
			end
		end
	end,
	RAID_ROSTER_UPDATE = function(self)
		self:SendXP(UnitLevel("player"))
		self:SendPXP()

		self:PruneTable()
	end,
	PARTY_MEMBERS_CHANGED = function(self)
		self:SendXP(UnitLevel("player"))
		self:SendPXP()

		self:PruneTable()
	end
}

ShareXPCore:Init()
