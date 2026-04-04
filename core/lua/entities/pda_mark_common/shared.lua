ENT.Base = "base_gmodentity"
ENT.Type = "anim"

ENT.PrintName = "Common marker" -- The name that will appear in the spawn menu.
ENT.Author = "Bloomstorm" -- The author's name for this Entity.
ENT.Category = "Stalker PDA Markers" -- The category for this Entity in the spawn menu.
ENT.Contact = "bloomstorm.su" -- The contact details for the author of this Entity.
ENT.Purpose = "Draw marker on the PDA map" -- The purpose of this Entity.
ENT.Spawnable = true
ENT.Editable = true

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "StashName", { KeyName = "StashName", Edit = { type = "String", order = 0, waitforenter = false } })
	self:NetworkVar("String", 1, "StashDesc", { KeyName = "StashDesc", Edit = { type = "String", order = 1, waitforenter = false } })
	self:NetworkVar("Int", 0, "MarkType", { KeyName = "MarkType", Edit = { type = "Int", order = 2, min = 0, max = 7 } })
	self:NetworkVar("Bool", 0, "ShowEveryone", { KeyName = "ShowEveryone", Edit = { type = "Bool", order = 3 } })
	self:NetworkVar("Int", 1, "MarkSize", { KeyName = "MarkSize", Edit = { type = "Int", order = 4, min = 0, max = 50 } })
end