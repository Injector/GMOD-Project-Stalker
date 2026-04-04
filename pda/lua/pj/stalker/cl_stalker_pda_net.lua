net.Receive("CStalkerPDA::GetTask", function(len, ply)

	local iID = net.ReadUInt(16)
	local szTitle = net.ReadString()
	local szDate = net.ReadString()
	local szDesc = net.ReadString()
	local szSteps = net.ReadString()
	local szIconPath = net.ReadString()
	local iStepsForEnts = net.ReadUInt(16)
	local hReceivedEntitiesForSteps = {}
	
	for i = 1, iStepsForEnts do
		local ent = net.ReadEntity()
		--Шаг 1 может содержать пустой энтити, но шаг 2 уже может содержать, так что будем использовать pairs
		table.insert(hReceivedEntitiesForSteps, ent)
	end
	
	local stepsFinal = {}
	
	local szStepsArray = string.Split(szSteps, "|")
	
	for i = 1, #szStepsArray do
		table.insert(stepsFinal, { done = false, text = szSteps[i], ent_marker = hReceivedEntitiesForSteps[i] })
	end
	
	local hMat = nil

	local iIconType = tonumber(szIconPath)
	
	if (iIconType != nil) then
		if (iIconType == 0) then
			hMat = PDA.Resources.TaskIcons.m_hMatArtefact
		elseif (iIconType == 1) then
			hMat = PDA.Resources.TaskIcons.m_hMatDefendLager
		elseif (iIconType == 2) then
			hMat = PDA.Resources.TaskIcons.m_hMatEliminateLager
		elseif (iIconType == 3) then
			hMat = PDA.Resources.TaskIcons.m_hMatItem
		elseif (iIconType == 4) then
			hMat = PDA.Resources.TaskIcons.m_hMatKill
		end
	else
		hMat = Material(szIconPath)
	end
	
	--TODO: Очищать кастомные созданные материалы при выполнении задания. Чтобы не захламлять память
	-- Нужно учитывать перед удалением, если это иконка PDA.Resources.TaskIcons. то ничего не делать
	-- Если нет, то удалять
	local task = 
	{
		id = iID,
		title = szTitle,
		date = szDate,
		desc = szDesc,
		steps = stepsFinal,
		icon = hMat
	}
	
	table.insert(PDA.Tasks, task)
end)

net.Receive("CStalkerPDA::UpdateTask", function(len, ply)
	local iID = net.ReadUInt(16)
	local iStepIndex = net.ReadUInt(6)
	local bDone = net.ReadBool()
	
	for i = 1, #PDA.Tasks do
		if (PDA.Tasks[i].id == iID) then
			if (#PDA.Tasks[i].steps <= iStepIndex) then
				PDA.Tasks[i].steps[iStepIndex].done = bDone
			end
		end
	end
end)

net.Receive("CStalkerPDA::AddNote", function(len, ply)

	local iGroupID = net.ReadUInt(16)
	local iID = net.ReadUInt(16)
	local szTitle = net.ReadString()
	local szText = net.ReadString()
	
	for i = 1, #PDA.Journal do
		
		if (PDA.Journal[i].id == iGroupID) then
			
			table.insert(PDA.Journal[i].notes, { id = iID, title = szTitle, text = szText })
		end
	end
end)

net.Receive("CStalkerPDA::KnownMarker", function(len, ply)
	
	local hEnt = net.ReadEntity()
	local iMarkType = net.ReadUInt(6)
	
	if (iMarkType == 1) then
		table.insert(PDA.Markers.Stashes, hEnt)
	elseif (iMarkType == 2) then
		table.insert(PDA.Markers.Quests, hEnt)
	elseif (iMarkType == 3) then
		table.insert(PDA.Markers.Commons, hEnt)
	elseif (iMarkType == 4) then
		table.insert(PDA.Markers.Areas, hEnt)
	end
	
end)

net.Receive("CStalkerPDA::UpdatePlayerStats", function(len, ply)
	
	local iNPCKills = net.ReadUInt(20)
	local iMutantKills = net.ReadUInt(20)
	local iQuestsDone = net.ReadUInt(20)
	
	PDA.Stats.npc_kills = iNPCKills
	PDA.Stats.mutant_kills = iMutantKills
	PDA.Stats.quests_done = iQuestsDone
	
end)

net.Receive("CStalkerPDA::UpdateKilledStats", function(len, ply)
	
	local iID = net.ReadUInt(16)
	local szName = net.ReadString()
	local iMult = net.ReadUInt(16)
	local iTotal = net.ReadUInt(16)
	
	local bFound = false
	
	for i = 1, #PDA.Stats.kill_list do
		
		if (PDA.Stats.kill_list[i].id == iID) then
			
			PDA.Stats.kill_list[i].mult = iMult
			PDA.Stats.kill_list[i].total = iTotal
			
			bFound = true
		end
	end
	
	if (!bFound) then
		table.insert(PDA.Stats.kill_list[i], { id = iID, name = szName, mult = iMult, total = iTotal })
	end
	
end)

net.Receive("CStalkerPDA::UpdatePlayerStat", function(len, ply)
	
end)

net.Receive("CStalkerPDA::SyncMap", function(len, ply)
	PDA.MapData.pos_x = net.ReadInt(16)
	PDA.MapData.pos_y = net.ReadInt(16)
	PDA.MapData.scale = net.ReadFloat()
end)