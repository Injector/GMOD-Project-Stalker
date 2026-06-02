
CStalkerCore = {}
CStalkerMapData = CStalkerMapData or {}

CStalkerCore.CachedMaterials = {}

local dir = "pj/stalker/"

if SERVER then
	AddCSLuaFile(dir.."cl_stalker_res.lua")
	
	AddCSLuaFile(dir.."sh_stalker_config.lua")
	
	include(dir.."sv_stalker_player.lua")
	include(dir.."sv_stalker_config.lua")
	include(dir.."sh_stalker_config.lua")
	include(dir.."sv_stalker_gen_name.lua")
else
	include(dir.."cl_stalker_res.lua")
	include(dir.."sh_stalker_config.lua")
end

function CStalkerCore:ShowPlayerInMinimap(otherPlayer, me)
	
	if (me) then
		if (me:Team() != otherPlayer:Team()) then return false end
	end
	
	if (otherPlayer:GetMoveType() == 8 && !otherPlayer:InVehicle()) then return false end
	
	if (otherPlayer:GetNoDraw()) then return false end
	
	if (otherPlayer:GetColor().a == 0) then return false end
	
	return otherPlayer:Alive() && otherPlayer:GetNWBool("DrawOnMM", true)
end

function CStalkerCore:ShowNPCInMinimap(ent)
	return ent:GetNWBool("DrawOnMM", false)
end

function CStalkerCore:GetMaterial(path)
	for _, v in pairs(CStalkerCore.CachedMaterials) do
		if (v != nil && v.path == path) then
			-- Someone deleted our cached material, wtf?
			if (v.material == nil) then
				v.material = Material(path)
				return v.material
			end
			return v.material
		end
	end
	
	-- Material is not cached
	local hMat = Material(path)
	table.insert(CStalkerCore.CachedMaterials, { path = path, material = hMat })
	
	return hMat
end

function CStalkerCore:GetRank(rankPoints)
	
	local iRank = 1
	
	-- Скипаем первый ранг, так как у него 0
	for i = 2, #CStalkerConfig.RanksProgress do
		if (rankPoints >= CStalkerConfig.RanksProgress[i]) then iRank = i end
	end
	
	return iRank
end

function CStalkerCore:GetReputation(rankPoints)
	
	local iRank = 4
	
	for i = 1, #CStalkerConfig.ReputationsProgress do
		if (CStalkerConfig.ReputationsProgress[i].minimum <= rankPoints && rankPoints > CStalkerConfig.ReputationsProgress[i].maximum) then
			iRank = i
		end
	end
	
	return iRank
end

local function GetRandomPosInSphere(center, radius)
	local randVec = Vector(math.random(-1.0, 1.0), math.random(-1.0, 1.0), 0)
	return center + (randVec * (math.random() * radius))
end

local function SpawnEnt(pos, class, ammoAmount, isWeapon)
	if (!class) then return end
	if (class == "") then return end
	
	pos = GetRandomPosInSphere(pos, 48)
	
	local hEnt = ents.Create(class)
	if (IsValid(hEnt)) then
		--print("Spawned")
		hEnt:SetPos(pos)
		if (hEnt.Primary && hEnt.Primary.DefaultClip) then
			hEnt.Primary.DefaultClip = 0
			hEnt.Primary.ClipSize = 0
			hEnt:SetClip1(0)
		end
		hEnt:Spawn()
		if (hEnt.SetClip1) then
		hEnt:SetClip1(0)
		hEnt:SetClip2(0)
		end
		
		if (ammoAmount) then
			hEnt.iAmmo = ammoAmount
			timer.Simple(0.1, function()
				if (IsValid(hEnt)) then
					hEnt.iAmmo = ammoAmount
				end
			end)
		end
		
		
		if (isWeapon) then
			local hEntWpn = ents.Create("stalker_weapon_drop")
			hEntWpn:SetPos(pos)
			hEntWpn:SetModel(hEnt:GetModel())
			hEntWpn:PhysicsInit(SOLID_VPHYSICS)
			hEntWpn:Spawn()
			hEntWpn.m_szWeaponClassName = class
			hEnt:Remove()
		end
		
	end
	--iAmmo
end

function CStalkerCore:SpawnDropItems(pos, community, weapon, ammoType, weaponClassDrop)
	-- CStalkerConfigServer.Drop = 
	-- {
		-- { item = "ammo_pistol", chance = 100, minimum = 15, maximum = 32 },
		-- { item = "ammo_smg", chance = 100, minimum = 15, maximum = 32 },
		-- { item = "ammo_ar2", chance = 100, minimum = 15, maximum = 32 },
		-- { item = "ammo_buckshot", chance = 100, minimum = 7, maximum = 15 },
		
		-- --{ item = "item_", chance = 40, minimum = 1, maximum = 2 },
		-- { item = "item_medkit", chance = 20, minimum = 1, maximum = 1, dont_spawn = { "military", "science" } },
		-- { item = "item_medkit_military", chance = 0, minimum 1 = maximum 1, spawn_override = { { community = "military", chance = 20 }, { community = "duty", chance = 20 }, } },
		-- { item = "item_medkit_science", chance = 5, minimum = 1, maximum = 1, spawn_override = { { community = "duty", chance = 20 }, { community = "science", chance = 20 }, } },

		-- { item = "food_bread", chance = 20, dont_spawn = { "killer", "zombied", "science" } },
		-- { item = "food_kolbasa", chance = 20, dont_spawn = { "military", "killer", "zombied", "science" } },
		-- { item = "food_konserva", chance = 10, dont_spawn = { "zombied", "science" }, spawn_override = { { community = "military", chance = 30 } } },
		
		-- --{ item = "artefact", chance = 1, dont_spawn = { "military", "zombied", "monolith" } },
	-- }
	
	--print("Begin!", pos, community, weapons, ammoType)
	
	pos = pos + Vector(0, 0, 5)
	
	local tbl = {}
	
	for _, v in ipairs(CStalkerConfigServer.Drop) do
		if (string.find(v.item, "item_") || string.find(v.item, "food_")) then
			table.insert(tbl, v)
			--print("Added", v.item)
		end
		
		if (string.find(v.item, "ammo_")) then
			if (v.item == "ammo_" .. ammoType) then
				table.insert(tbl, v)
				--print("Added ammo", v.item)
			end
		end
	end
	
	for _, v in ipairs(tbl) do
		local bDontSpawn = false
		local iChance = v.chance
		
		if (v.dont_spawn) then
			for _, c in ipairs(v.dont_spawn) do
				if (community == c) then
					bDontSpawn = true
				end
			end
		end
		
		if (bDontSpawn) then continue end
		
		if (v.spawn_override) then
			for _, c in ipairs(v.spawn_override) do
				if (community == c.community) then
					iChance = c.chance
				end
			end
		end
		
		if (math.random(1, 100) <= iChance) then
			--print("We can spawn", v.item)
			if (v.minimum && v.maximum) then
				local iAmount = math.random(v.minimum, v.maximum)
				--print("Spawn ammo amount", iAmount)
				-- for i = 1, iAmount do
					-- SpawnEnt(pos, 
				-- end
				SpawnEnt(pos, v.class, iAmount)
			else
				--print("Just spawn item")
				SpawnEnt(pos, v.class)
			end
		end
	end
	
	if (weaponClassDrop && weaponClassDrop != "") then
		SpawnEnt(pos, weaponClassDrop, nil, true)
	end
end

-- Синхронизация данных о мини-карте, потом может перемещу в другой файл

if SERVER then
	util.AddNetworkString("CStalkerCore::SyncMap")
	
	local mapDataLoaded = false

	local function LoadMapData()
		if mapDataLoaded then return end
		mapDataLoaded = true
		local mapName = game.GetMap()
		local data = file.Read("overviews/" .. mapName .. ".txt", "DATA")
		
		if not data then
			print("[Project: Stalker] No mini-map data " .. mapName .. ".txt found in garrysmod/data/overviews")
		else
			--print("SV Found data!")
		end
		
		if not data then return end
		
		for k, v in string.gmatch(data, "([^%\n]+)=([^%\n]+)") do
			--print("SV key " .. k .. " value " .. v)
			if (k == "pos_x") then
				CStalkerMapData.pos_x = tonumber(v)
			elseif (k == "pos_y") then
				CStalkerMapData.pos_y = tonumber(v)
			elseif (k == "scale") then
				CStalkerMapData.scale = tonumber(v)
			end
		end
	end

	hook.Add( "InitPostEntity", "StalkerCore_Map_InitPostEntity", function()
		LoadMapData()
	end )

	hook.Add("PlayerSpawn", "StalkerCore_Map_PlayerSpawn", function(ply)
		
		if (CStalkerMapData && CStalkerMapData.pos_x && CStalkerMapData.pos_y && CStalkerMapData.scale) then
			net.Start("CStalkerCore::SyncMap")
				net.WriteInt(CStalkerMapData.pos_x, 16)
				net.WriteInt(CStalkerMapData.pos_y, 16)
				net.WriteFloat(CStalkerMapData.scale)
			net.Send(ply)
		end
	end)
else
	net.Receive("CStalkerCore::SyncMap", function(len, ply)
		CStalkerMapData.pos_x = net.ReadInt(16)
		CStalkerMapData.pos_y = net.ReadInt(16)
		CStalkerMapData.scale = net.ReadFloat()
	end)
end