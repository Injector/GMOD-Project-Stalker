
CreateConVar("sv_stalker_pda_mode", "0", {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "If set to 1, the PDA can be opened only if you picked it up (player:GetNWBool('m_bHasPDA') == true)")

CreateClientConVar("cl_stalker_pda_keycode", "", true, true, "Key button to open the PDA, leave empty for default button - M")

local dir = "pj/stalker/"

if SERVER then
	AddCSLuaFile(dir.."cl_stalker_pda.lua")
	AddCSLuaFile(dir.."cl_stalker_pda_config.lua")
	AddCSLuaFile(dir.."cl_stalker_pda_localization.lua")
	AddCSLuaFile(dir.."cl_stalker_pda_net.lua")
	--AddCSLuaFile(dir.."cl_stalker_pda_res.lua")
	
	include(dir.."sv_stalker_pda.lua")
	include(dir.."sv_stalker_pda_net.lua")
	--include(dir.."sv_stalker_pda_map_data_load.lua")
else
	include(dir.."cl_stalker_pda.lua")
	include(dir.."cl_stalker_pda_config.lua")
	include(dir.."cl_stalker_pda_localization.lua")
	include(dir.."cl_stalker_pda_net.lua")
	--include(dir.."cl_stalker_pda_res.lua")
end