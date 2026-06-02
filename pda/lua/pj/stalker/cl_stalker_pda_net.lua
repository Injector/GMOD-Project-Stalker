net.Receive("CStalkerPDA::GetTask", function(len, ply)

	local iID = net.ReadUInt(16)
	local szTitle = net.ReadString()
	local szDate = net.ReadString()
	local szDesc = net.ReadString()
	local szSteps = net.ReadString()
	local szIconPath = net.ReadString()
	local iStepsForEnts = net.ReadUInt(16)
	local hReceivedEntitiesForSteps = {}
	
	-- print("ID", iID)
	-- print("Title", szTitle)
	-- print("Date", szDate)
	-- print("Desc", szDesc)
	-- print("Steps", szSteps)
	-- print("Icon", szIconPath)
	-- print("StepsEnt", iStepsForEnts)
	
	for i = 1, iStepsForEnts do
		local ent = net.ReadEntity()
		--Шаг 1 может содержать пустой энтити, но шаг 2 уже может содержать, так что будем использовать pairs
		table.insert(hReceivedEntitiesForSteps, ent)
	end
	
	local stepsFinal = {}
	
	local szStepsArray = string.Split(szSteps, "|")
	
	for i = 1, #szStepsArray do
		table.insert(stepsFinal, { done = false, text = szStepsArray[i], ent_marker = hReceivedEntitiesForSteps[i] })
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
		--icon = hMat,
		iconPath = szIconPath
	}
	
	table.insert(PDA.Tasks, task)
end)

net.Receive("CStalkerPDA::UpdateTask", function(len, ply)
	local iID = net.ReadUInt(16)
	local iStepIndex = net.ReadUInt(6)
	local bDone = net.ReadBool()
	
	for i = 1, #PDA.Tasks do
		if (PDA.Tasks[i].id == iID) then
			--print("Found id "..tostring(#PDA.Tasks[i].steps).." "..tostring(iStepIndex))
			if (iStepIndex <= #PDA.Tasks[i].steps) then
				PDA.Tasks[i].steps[iStepIndex].done = bDone
			end
		end
	end
end)

net.Receive("CStalkerPDA::RemoveTask", function(len, ply)
	local iID = net.ReadUInt(16)
	
	--for i = 1, #PDA.Tasks do
	for i = #PDA.Tasks, 1, -1 do
		if (PDA.Tasks[i].id == iID) then
			table.remove(PDA.Tasks, i)
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
	
	local iID = net.ReadUInt(8)
	local iType = net.ReadUInt(4)
	local szMsg = net.ReadString()
	local hEnt = net.ReadEntity()
	
	if (IsValid(hEnt)) then
		
		local bFound = false
		
		for i = 1, #PDA.Markers.Stashes do
			if (PDA.Markers.Stashes[i].id != nil && PDA.Markers.Stashes[i].id == iID) then
				bFound = true
				break
			end
		end
		
		if (!bFound) then
			table.insert(PDA.Markers.Stashes, { id = iID, entity = hEnt})
			
			if (STALKER_AddMessage) then
				STALKER_AddMessage("new_stash", szMsg, "pda/task_icons/base/found_thing.png")
			end
		end
	end
end)

-- TODO: Заменить на UInt для оптимизации трафика
-- А для очистки до 0 использовать net.ReadBool(), если true то ставим 0
net.Receive("CStalkerPDA::UpdatePlayerStats", function(len, ply)
	
	local iNPCKills = net.ReadInt(18)
	local iMutantKills = net.ReadInt(18)
	local iQuestsDone = net.ReadInt(18)
	
	PDA.Stats.npc_kills = iNPCKills
	PDA.Stats.mutant_kills = iMutantKills
	PDA.Stats.quests_done = iQuestsDone
end)

net.Receive("CStalkerPDA::UpdateKillStats", function(len, ply)
	
	local iID = net.ReadUInt(16)
	local szName = net.ReadString()
	local iMult = net.ReadUInt(16)
	local iTotal = net.ReadUInt(16)
	local iListType = net.ReadUInt(5)
	
	local bFound = false
	
	local tbl = PDA.Stats.kill_list
	
	if (iListType == 2) then
		tbl = PDA.Stats.kill_mutant_list
	end
	
	for i = 1, #tbl do
		
		if (tbl[i].id == iID) then
			
			tbl[i].mult = iMult
			tbl[i].total = iTotal
			
			bFound = true
			break
		end
	end
	
	if (!bFound) then
		table.insert(tbl, { id = iID, name = szName, mult = iMult, total = iTotal })
	else
		-- table.sort(tbl, function(a, b)
			-- return a.name < b.name
		-- end)
	end
	
	table.sort(tbl, function(a, b)
		return a.name < b.name
	end)
end)