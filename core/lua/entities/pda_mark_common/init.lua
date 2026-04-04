AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetSolid(SOLID_BBOX)

	self:SetModel("models/hunter/blocks/cube025x025x025.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:KeyValue(key, value)
	if (key == "m_name") then
		self:SetStashName(value)
	elseif (key == "m_desc") then
		self:SetStashDesc(value)
	elseif (key == "m_type") then
		self:SetMarkType(value)
	elseif (key == "show_everyone") then
		self:SetShowEveryone(value)
	elseif (key == "m_size") then
		self:SetMarkSize(value)
	end
end