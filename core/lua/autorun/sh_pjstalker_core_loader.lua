
CStalkerCore = {}
CStalkerMapData = CStalkerMapData or {}

local dir = "pj/stalker/"

if SERVER then
	AddCSLuaFile(dir.."cl_stalker_res.lua")
else
	include(dir.."cl_stalker_res.lua")
end

function CStalkerCore:ShowPlayerInMinimap(otherPlayer, me)
	
	if (me) then
		if (me:Team() != otherPlayer:Team()) then return false end
	end
	
	if (otherPlayer:GetMoveType() == 8) then return false end
	
	if (otherPlayer:GetNoDraw()) then return false end
	
	if (otherPlayer:GetColor().a == 0) then return false end
	
	return otherPlayer:Alive() && !otherPlayer.m_bDontTrackMePDA
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