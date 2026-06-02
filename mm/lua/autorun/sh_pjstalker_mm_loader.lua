
local dir = "pj/stalker/"

CreateClientConVar("cl_stalker_minimap_enable", "1", true, true, "Draw minimap")
CreateClientConVar("cl_stalker_minimap_draw", "1", true, true, "Draw minimap, same as cl_stalker_minimap_enable, but does not save. This convar can be used by the server to determine when minimap should be hidden")

CreateConVar("sv_stalker_minimap_npc_attitude", "1", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "If set to 1, the server will send the clients npc's attitude to client")
CreateConVar("sv_stalker_minimap_with_pda", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "If set to 1, the minimap will be shown only when you have the PDA (player:GetNWBool('m_bHasPDA') == true)")

if SERVER then
	util.AddNetworkString("CStalkerMM::GetNPC")
	
	hook.Add("OnEntityCreated", "StalkerMM_NPC_OnEntityCreated", function(ent)
		
		if (!GetConVar("sv_stalker_minimap_npc_attitude") || GetConVar("sv_stalker_minimap_npc_attitude"):GetInt() != 1) then return end
		
		--Если мы отправим сразу же после спауна нпс, то в net.Receive("CStalkerMM::GetNPC") энтити будет не валидно
		
		-- Не работает на выделенных серверах, убрано в пользу ручного способа навешивания отношения и показа на мини-карте
		-- Как это делать, смотрите на вики
		-- timer.Simple(0.5, function()
			-- if (IsValid(ent) && (ent:IsNPC() || ent:IsNextBot())) then
				-- for _, v in ipairs(player.GetAll()) do
					
					-- local iAttitude = nil
					
					-- if (ent:IsNPC()) then
						-- iAttitude = ent:Disposition(v)
					-- elseif (ent:IsNextBot()) then
						-- if (ent.GetRelationship != nil) then
							-- iAttitude = ent:GetRelationship(v)
						-- end
					-- end
					
					-- if (iAttitude != nil) then
						-- net.Start("CStalkerMM::GetNPC")
							-- net.WriteEntity(ent)
							-- net.WriteUInt(iAttitude, 3)
							-- --net.WriteString(ent.m_szIcon or "pda/profiles/chr/stalker_bandit_3.png")
							-- --net.WriteString(ent.m_szName or "Кляйнер")
						-- net.Send(v)
					-- end
					
					-- --ent:SetNWString("StalkerName", "Тестовый")
					-- --ent:SetNWString("StalkerIcon", "pda/profiles/chr/stalker_bandit_8.png")
				-- end
			-- end
		-- end)
	end)
else
	net.Receive("CStalkerMM::GetNPC", function(len, ply)
		
		local hEntity = net.ReadEntity()
		local iAttitude = net.ReadUInt(3)
		local szIcon = net.ReadString()
		local szName = net.ReadString()
		
		--Энтити может быть за пределами PVS и оно будет nil
		if (IsValid(hEntity)) then
			hEntity.m_iAttitude = iAttitude
			
			-- if (szIcon && szIcon != "") then
				-- hEntity.m_szIcon = szIcon
			-- end
			
			-- if (szName && szName != "") then
				-- hEntity.m_szName = szName
			-- end
		end
	end)
end

if SERVER then
	AddCSLuaFile(dir.."cl_stalker_minimap.lua")
else
	include(dir.."cl_stalker_minimap.lua")
end