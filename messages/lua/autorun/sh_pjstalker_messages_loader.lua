
local dir = "pj/stalker/"

if SERVER then
	util.AddNetworkString("CStalkerMsg::AddMsg")
	
	CStalkerMessages = {}

	function CStalkerMessages:AddMessage(ply, msgType, text, imagePath)
		net.Start("CStalkerMsg::AddMsg")
			net.WriteString(msgType)
			net.WriteString(text)
			net.WriteString(imagePath)
		net.Send(ply)
	end

	function CStalkerMessages:AddMessageAll(msgType, text, imagePath)
		for i, v in ipairs(player.GetAll()) do
			if (IsValid(v)) then
				CStalkerMessages:AddMessage(v, msgType, text, imagePath)
			end
		end
	end
else
	net.Receive("CStalkerMsg::AddMsg", function(len, ply)
		
		local szMsgType = net.ReadString()
		local szMsgText = net.ReadString()
		local szImage = net.ReadString()
		
		STALKER_AddMessage(szMsgType, szMsgText, szImage)
	end)
end

if SERVER then
	AddCSLuaFile(dir.."cl_stalker_messages.lua")
else
	include(dir.."cl_stalker_messages.lua")
end