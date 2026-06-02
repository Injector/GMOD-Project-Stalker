CStalkerPDA = {}

function CStalkerPDA:SendTask(ply, id, title, date, desc, steps, icon)
	
	local szSteps = ""
	local iStepsEnts = 0
	local iSendEnts = {}
	
	local tblTexts = {}
	
	if (steps) then
		for k, v in pairs(steps) do
			table.insert(tblTexts, v.text)
			table.insert(iSendEnts, v.ent_marker)
		end
	end
	
	szSteps = table.concat(tblTexts, "|")
	
	-- print("Write ID", id)
	-- print("Write title", title)
	-- print("Write date", date)
	-- print("Write desc", desc)
	-- print("Write steps", szSteps)
	-- print("Write icon", icon)
	-- print("Write sendents", #iSendEnts)

	net.Start("CStalkerPDA::GetTask")
		net.WriteUInt(id, 16)
		net.WriteString(title)
		net.WriteString(date)
		net.WriteString(desc)
		net.WriteString(szSteps)
		net.WriteString(icon)
		net.WriteUInt(#iSendEnts, 16)
		
		for i = 1, #iSendEnts do
			net.WriteEntity(iSendEnts[i])
		end
    net.Send(ply)
	
	local hPly = CStalkerPlayer:GetPlayer(ply:EntIndex())
	
	if (hPly != nil) then
	
		local tblSteps = {}
		
		for i = 1, #steps do
			table.insert(tblSteps, { id = 1, done = false })
		end
		
		local tbl = { id = id, title = title, icon = icon, steps = tblSteps, origSteps = steps, date = date, desc = desc }
		
		table.insert(hPly.tasks, tbl)
	end
	
	if (CStalkerMessages) then
		CStalkerMessages:AddMessage(ply, "new_task", title, icon)
		
		-- done
	end
end

function CStalkerPDA:UpdateTaskStep(ply, id, stepIndex, done)
	net.Start("CStalkerPDA::UpdateTask")
		net.WriteUInt(id, 16)
		net.WriteUInt(stepIndex, 6)
		net.WriteBool(done)
	net.Send(ply)
	
	if (CStalkerMessages) then
		local stalkerPlayer = CStalkerPlayer:GetPlayer(ply:EntIndex())
		
		if (stalkerPlayer) then
			local task = nil
			
			for i = 1, #stalkerPlayer.tasks do
				if (stalkerPlayer.tasks[i].id == id) then
					task = stalkerPlayer.tasks[i]
				end
			end
			
			if (task) then
				task.steps[stepIndex].done = done
				
				CStalkerMessages:AddMessage(ply, "updated", task.title, task.icon)
			end
		end
		--CStalkerMessages:AddMessage(ply, "updated", title, icon)
	end
	
	local stalkerPlayer = CStalkerPlayer:GetPlayer(ply:EntIndex())
	if (stalkerPlayer) then
		local task = nil
		
		for i = 1, #stalkerPlayer.tasks do
			if (stalkerPlayer.tasks[i].id == id) then
				task = stalkerPlayer.tasks[i]
			end
		end
		
		if (task) then
			local iCount = 0
			
			for i = 1, #task.steps do
				if (task.steps[i].done) then
					iCount = iCount + 1
				end
			end
			
			if (iCount == #task.steps) then
				CStalkerMessages:AddMessage(ply, "done", task.title, task.icon)
				
				CStalkerPDA:RemoveTask(ply, id)
			end
		end
	end
end

function CStalkerPDA:RemoveTask(ply, id)
	net.Start("CStalkerPDA::RemoveTask")
		net.WriteUInt(id, 16)
    net.Send(ply)
	
	local stalkerPlayer = CStalkerPlayer:GetPlayer(ply:EntIndex())
	if (stalkerPlayer) then
		for i = 1, #stalkerPlayer.tasks do
			if (stalkerPlayer.tasks[i].id == id) then
				table.remove(stalkerPlayer.tasks, i)
			end
		end
	end
end

-- ============================================================
-- Добавляет заметку в ПДА во вкладку заметки
-- ============================================================
-- ply - игрок
-- groupId - игрок
-- id - игрок
-- title - игрок
-- text - игрок
function CStalkerPDA:AddNote(ply, groupId, id, title, text)
	net.Start("CStalkerPDA::AddNote")
		net.WriteUInt(groupId, 16)
		net.WriteUInt(id, 16)
		net.WriteString(title)
		net.WriteString(text)
	net.Send(ply)
end

function CStalkerPDA:UpdatePlayerStats(ply, npcKills, mutantKills, questsDone)
	net.Start("CStalkerPDA::UpdatePlayerStats")
		net.WriteUInt(npcKills, 20)
		net.WriteUInt(mutantKills, 20)
		net.WriteUInt(questsDone, 20)
	net.Send(ply)
end