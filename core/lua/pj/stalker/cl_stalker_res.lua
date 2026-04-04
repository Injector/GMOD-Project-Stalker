
CStalkerCore.Resources = {}

CStalkerCore.Resources.Markers = {}
CStalkerCore.Resources.Markers.m_hMatLager = Material("pda/markers/lager.png")
CStalkerCore.Resources.Markers.m_hMatLagerMutant = Material("pda/markers/lager_mutant.png")
CStalkerCore.Resources.Markers.m_hMatItem = Material("pda/markers/item.png")
CStalkerCore.Resources.Markers.m_hMatKill = Material("pda/markers/kill.png")
CStalkerCore.Resources.Markers.m_hMatArea = Material("pda/markers/area.png")
CStalkerCore.Resources.Markers.m_hMatStash = Material("pda/markers/stash.png")
CStalkerCore.Resources.Markers.m_hMatQuest = Material("pda/markers/mark.png")

CStalkerCore.Resources.TaskIcons = {}
CStalkerCore.Resources.TaskIcons.m_hMatArtefact = Material("pda/task_icons/artefact.png")
CStalkerCore.Resources.TaskIcons.m_hMatDefendLager = Material("pda/task_icons/defend_lager.png")
CStalkerCore.Resources.TaskIcons.m_hMatEliminateLager = Material("pda/task_icons/eliminate_lager.png")
CStalkerCore.Resources.TaskIcons.m_hMatItem = Material("pda/task_icons/find_item.png")
CStalkerCore.Resources.TaskIcons.m_hMatKill = Material("pda/task_icons/kill.png")
CStalkerCore.Resources.TaskIcons.m_hMatMutant = Material("pda/task_icons/mutant.png")
CStalkerCore.Resources.TaskIcons.m_hMatStash = Material("pda/task_icons/stash.png")
CStalkerCore.Resources.TaskIcons.m_hMatMoney = Material("pda/task_icons/money.png")
CStalkerCore.Resources.TaskIcons.m_hMatCompas = Material("pda/task_icons/compas.png")
CStalkerCore.Resources.TaskIcons.m_hMatStalker = Material("pda/task_icons/stalker.png")

function CStalkerCore:GetMarkerMaterial(iconMarkType)

	local mat = nil
	
	if (iconMarkType == 1) then
		mat = CStalkerCore.Resources.Markers.m_hMatStash
	elseif (iconMarkType == 2) then
		mat = CStalkerCore.Resources.Markers.m_hMatLager
	elseif (iconMarkType == 3) then
		mat = CStalkerCore.Resources.Markers.m_hMatLagerMutant
	elseif (iconMarkType == 4) then
		mat = CStalkerCore.Resources.Markers.m_hMatItem
	elseif (iconMarkType == 5) then
		mat = CStalkerCore.Resources.Markers.m_hMatKill
	elseif (iconMarkType == 6) then
		mat = CStalkerCore.Resources.Markers.m_hMatArea
	elseif (iconMarkType == 7) then
		mat = CStalkerCore.Resources.Markers.m_hMatQuest
	end
	
	return mat
end