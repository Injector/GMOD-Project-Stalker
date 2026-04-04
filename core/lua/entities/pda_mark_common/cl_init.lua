include("shared.lua")

function ENT:Draw()
	if (IsValid(LocalPlayer()) && IsValid(LocalPlayer():GetActiveWeapon())) then
		local szClass = LocalPlayer():GetActiveWeapon():GetClass()
		if (szClass == "weapon_physgun" || szClass == "gmod_tool") then
			self:DrawModel()
		end
	end
end