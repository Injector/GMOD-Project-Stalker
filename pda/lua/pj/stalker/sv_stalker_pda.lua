CStalkerPDA = {}

function CStalkerPDA:SendTask(ply, id, title, date, desc, steps, icon)
	
	local szSteps = ""
	local iStepsEnts = 0
	local iSendEnts = {}
	
	if (steps) then
		for k, v in pairs(steps) do
			szSteps = szSteps .. "|" .. v.text .. "|"
			table.insert(iSendEnts, v.ent_marker)
		end
	end

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
end

function CStalkerPDA:UpdateTaskStep(ply, id, stepIndex, done)
	net.Start("CStalkerPDA::UpdateTask")
		net.WriteUInt(id, 16)
		net.WriteUInt(stepIndex, 6)
		net.WriteBool(done)
	net.Send(ply)
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