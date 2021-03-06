
local checkParam = mingeban.utils.checkParam
local accessorFunc = mingeban.utils.accessorFunc
local validSteamID = mingeban.utils.validSteamID

mingeban.ranks = mingeban.ranks or {}
mingeban.users = mingeban.users or {}

local Rank = {}
Rank.__index = Rank
if SERVER then
	function Rank:SetLevel(level)
		checkParam(level, "number", 1, "SetLevel")
		assert(not istable(mingeban.ranks[level]), "rank with level " .. tostring(level) .. " already exists!")

		mingeban.ranks[self.level] = nil
		self.level = level
		mingeban.ranks[level] = self

		mingeban.SaveRanks()
		return self
	end
	function Rank:SetName(name)
		checkParam(name, "string", 1, "SetName")
		assert(not istable(mingeban.GetRank(name)), "rank with name " .. name .. " already exists!")

		self.name = name

		mingeban.SaveRanks()
		return self
	end
	function Rank:SetRoot(root)
		checkParam(root, "boolean", 1, "SetRoot")

		self.root = root

		mingeban.SaveRanks()
		return self
	end

	function Rank:AddUser(sid)
		if type(sid) == "Player" then
			assert(not sid:IsBot(), "bad argument #1 to 'AddUser' (Player expected, got BOT)")
			sid:SetNWString("UserGroup", self.name)
			sid = sid:SteamID()
		end
		checkParam(sid, "string", 1, "AddUser")
		assert(sid:match("STEAM_0:%d:%d+"), "bad argument #1 to 'AddUser' (SteamID32 expected, got something else)")

		for group, plys in next, mingeban.users do
			if plys[sid] then
				plys[sid] = nil
			end
		end
		if not mingeban.users[self.name] then
			mingeban.users[self.name] = {}
		end
		mingeban.users[self.name][sid] = true

		mingeban.SaveUsers()
		return self
	end
	function Rank:RemoveUser(sid)
		if type(sid) == "Player" and not sid:IsBot() then
			sid:SetNWString("UserGroup", "user")
			sid = sid:SteamID()
		end
		checkParam(sid, "string", 1, "RemoveUser")
		assert(sid:match("STEAM_0:%d:%d+"), "bad argument #1 to 'RemoveUser' (steamid expected, got something else)")

		if not mingeban.users[self.name] then
			return false
		end
		mingeban.users[self.name][sid] = nil

		mingeban.SaveUsers()
		return self
	end

	function Rank:AddPermission(perm)
		checkParam(perm, "string", 1, "AddPermission")

		self.permissions[perm] = true

		mingeban.SaveRanks()
		return self
	end
	function Rank:RemovePermission(perm)
		checkParam(perm, "string", 1, "RemovePermission")

		self.permissions[perm] = nil

		mingeban.SaveRanks()
		return self
	end
end

function Rank:GetPermission(perm)
	checkParam(perm, "string", 1, "GetPermission")

	return self.permissions[perm]
end
function Rank:HasPermission(perm)
	checkParam(perm, "string", 1, "HasPermission")

	if self.root then return true end
	return self:GetPermission(perm)
end
function Rank:GetPermissions()
	return self.permissions
end

function Rank:GetUser(sid)
	if type(sid) == "Player" and not sid:IsBot() then
		return mingeban.users[self.name][sid:SteamID()] and sid or false
	else
		checkParam(sid, "string", 1, "GetUser")
		assert(validSteamID(sid), "bad argument #1 to 'GetUser' (invalid SteamID)")

		local ply = player.GetBySteamID(sid)
		if not IsValid(ply) then
			ply = true
		end
		return mingeban.users[self.name][sid] and ply or nil
	end
end
function Rank:GetUsers()
	return mingeban.users[self.name]
end

accessorFunc(Rank, "Name", "name", CLIENT)
accessorFunc(Rank, "Level", "level", CLIENT)
accessorFunc(Rank, "Root", "root", CLIENT)

mingeban.objects.Rank = Rank

-- Rank object defined.

function mingeban.GetRank(name)
	checkParam(name, "string", 1, "GetRank")

	for level, rank in next, mingeban.ranks do
		if rank.name:lower() == name:lower() then
			return mingeban.ranks[level]
		end
	end
end
function mingeban.GetRanks()
	return mingeban.ranks
end
function mingeban.GetUsers()
	return mingeban.users
end

-- PLAYER META

local PLAYER = FindMetaTable("Player")

function PLAYER:CheckUserGroupLevel(name)
	checkParam(name, "string", 1, "CheckUserGroupLevel")

	local plyRank = mingeban.GetRank(self:GetUserGroup())
	if plyRank.root then return true end

	local rank = mingeban.GetRank(name)
	if not rank then return true end

	if plyRank.level < rank.level then
		return false
	else
		return true
	end
end
function PLAYER:GetRank()
	return mingeban.GetRank(self:GetUserGroup())
end
function PLAYER:IsUserGroup(name)
	checkParam(name, "string", 1, "IsUserGroup")

	return self:GetUserGroup() == name:lower()
end
function PLAYER:HasPermission(name)
	return self:GetRank():HasPermission(name)
end

--[[ useless, this is default
add IsAdmin and IsSuperAdmin override later

function PLAYER:GetUserGroup()
	return self:GetNWString("UserGroup", "user")
end

]]

