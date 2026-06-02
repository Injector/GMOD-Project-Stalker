-- ============================================================
-- STALKER MINIMAP — мини-карта в левом верхнем углу
-- ============================================================

local MM = {}
MM.Size     = 200       -- размер квадрата мини-карты в пикселях
MM.Scale    = 0.1         -- пикселей на 1 хаммер-юнит (больше = крупнее)
MM.NpcRange = 2500      -- радиус обнаружения НПС (hammer units)
MM.X        = 10        -- позиция на экране
MM.Y        = 10
-- Сдвиг оси overview; вместе с yaw даёт «вперёд = вверх» на радаре
MM.OverviewYawOffset = 90

MM.PreviousOnline = 0

-- Цвета точек
local C_PLAYER  	= Color(255, 255, 255, 255)   -- белая точка - игрок
local C_NPC_NEU 	= Color(255, 200, 0,   255)   -- желтая - нейтрал
local C_NPC_ENE 	= Color(255, 50,  50,  255)   -- красная - враг
local C_NPC_FRN 	= Color(0,  255,   0,  255)   -- зеленая - друг
local C_NPC_DEAD 	= Color(144, 144, 144, 255)	  -- серая - труп, сделано для энтити-рюкзаков, которые дропают нпс после смерти
local C_BORDER  	= Color(80,  80,  80,  255)
local C_BG      	= Color(0,   0,   0,   180)
local C_COMPASS 	= Color(200, 180, 50,  255)

local CD_HT = 1
local CD_LI = 3
local CD_NU = 4

surface.CreateFont("MM_Compass", {font="Trebuchet MS", size=14, weight=700})
surface.CreateFont("MM_Dist",    {font="Trebuchet MS", size=12, weight=400})
surface.CreateFont("MM_Ammo",    {font="Trebuchet MS", size=22, weight=700})

-- ---- Загрузка overview ----
local mapMat      = nil
local mapData     = {}
local mapLoaded   = false

-- Сталкеры-враги
-- Значение: { entity = Entity(), time = 0 }
local m_tblEnemyStalkers = {}

-- TODO: Заменить + на bit.bor(flag, flag, ...)? Есть ли вообще разница?
local function IsAbleToSee(ply, ent)
	local traceFilter = { ply }
	
	local tr = util.TraceLine({ start = ply:EyePos(), endpos = ent:WorldSpaceCenter(), filter = traceFilter, mask = MASK_SOLID + CONTENTS_HITBOX })
	
	-- Увидели центр тела цели
	if (tr.Entity == ent) then
		return true
	end
	
	return false
end

-- Нам незачем каждый раз проводить математические формулы, делаем это один раз
local localPlayerFOV = 0
local localPlayerCosHalfFOV = 0

-- Сколько секунд красная точка должна быть жирной?
local LargeEnemyDotDuration = 2.0
-- Через сколько секунд красная точка пропадет с мини-карты?
local EnemyDotDissaper = 5.0

local function PointWithinViewAngle(srcPos, targetPos, lookDir, cosHalfFOV)
	local delta = targetPos - srcPos
	local cosDiff = lookDir:Dot(delta)
	
	if (cosDiff < 0.0) then return false end
	
	local leng = delta:LengthSqr()
	
	return cosDiff * cosDiff > leng * cosHalfFOV * cosHalfFOV
end

local function IsEntInFOV(ply, ent)
	-- Нам незачем каждый раз проводить математические формулы, делаем это один раз
	if (localPlayerFOV != ply:GetFOV()) then
		localPlayerFOV = ply:GetFOV()
		localPlayerCosHalfFOV = math.cos(0.5 * localPlayerFOV * math.pi / 180)
	end
	
	return PointWithinViewAngle(ply:EyePos(), ent:WorldSpaceCenter(), ply:GetAimVector(), localPlayerCosHalfFOV)
end

local function GetEnemy(ent)
	for _, v in ipairs(m_tblEnemyStalkers) do
		if (IsValid(v.entity) && v.entity:EntIndex() == ent:EntIndex()) then return v end
	end
	
	return nil
end

local function AddEnemy(ent)
	local bFound = false
	
	for _, v in ipairs(m_tblEnemyStalkers) do
		if (IsValid(v.entity) && v.entity:EntIndex() == ent:EntIndex()) then
			-- Чтобы огромная точка не появлялась каждый раз
			v.time = CurTime() + EnemyDotDissaper
			bFound = true
			break
		end
	end
	
	if (bFound) then return end
	
	table.insert(m_tblEnemyStalkers, { entity = ent, time = CurTime() + EnemyDotDissaper, time2 = CurTime() })
end

local function ClearEnemies()
	for k, v in ipairs(m_tblEnemyStalkers) do
		if (CurTime() > v.time || !IsValid(v.entity)) then
			table.remove(m_tblEnemyStalkers, k) 
		end
	end
end

-- local mapData =
-- {
	-- pos_x = -6066,
	-- pos_y = 7415,
	-- scale = 12.00,
	
	-- -- pos_x = -13182,
	-- -- pos_y = 15155,
	-- -- scale = 30.0,
-- }
--mapDataLoaded = true

--TODO: Почистить
local function LoadMap()
    if mapLoaded then return end
    mapLoaded = true
    local name = game.GetMap()
    -- Текстура
    local m = Material("overviews/" .. name .. ".png")
    if not m:IsError() then mapMat = m end
    -- Данные
    local txt = file.Read("overviews/" .. name .. ".txt", "GAME")
    if not txt then return end
    for k, v in string.gmatch(txt, '"([^"]+)"%s+"([^"]+)"') do
        mapData[k] = tonumber(v) or v
    end
end

local function GetOverviewData()
    if CStalkerMapData and CStalkerMapData.pos_x then
        return CStalkerMapData
    end
    return mapData
end

local function WorldToUV(wx, wy)
    local data = GetOverviewData()
    if not data.pos_x then return 0.5, 0.5 end
    local scale = data.scale or 1
    local u = (wx - (data.pos_x or 0)) / scale / 1024
    local v = (wy - (data.pos_y or 0)) / scale / 1024 * -1.0
    return u, v
end

local function GetOverviewTexPx()
    local data = GetOverviewData()
    return (data.scale or 1) * 1024 * MM.Scale
end

local function GetMapDrawYaw(eyeYaw)
    return MM.OverviewYawOffset - eyeYaw
end

-- Точки: UV→texPx→Rotate — тот же угол, что у Matrix overview
local function WorldPosToMinimapScreen(wx, wy, plyWx, plyWy, cx, cy, texPx, drawYaw)
    local pu, pv = WorldToUV(plyWx, plyWy)
    local u, v = WorldToUV(wx, wy)
    local offset = Vector((u - pu) * texPx, (v - pv) * texPx, 0)
    offset:Rotate(Angle(0, drawYaw, 0))
    return cx + offset.x, cy - offset.y
end

local function EntityToMinimapScreen(ep, wpos, cx, cy, texPx, drawYaw)
    return WorldPosToMinimapScreen(ep.x, ep.y, wpos.x, wpos.y, cx, cy, texPx, drawYaw)
end

-- ---- Компас ----
local COMPASS_DIRS = {
    {ang=0,   label="С"},
    {ang=45,  label="СВ"},
    {ang=90,  label="В"},
    {ang=135, label="ЮВ"},
    {ang=180, label="Ю"},
    {ang=225, label="ЮЗ"},
    {ang=270, label="З"},
    {ang=315, label="СЗ"},
}

local function GetCompassLabel(yaw)
    -- yaw: 0=север (в GMod Y- = север зависит от карты, используем условно)
    local norm = (yaw % 360 + 360) % 360
    local best, bestD = "С", 999
    for _, d in ipairs(COMPASS_DIRS) do
        local diff = math.abs(((norm - d.ang + 180) % 360) - 180)
        if diff < bestD then bestD = diff; best = d.label end
    end
    return best
end

-- ---- Основной хук ----
hook.Add("HUDPaint", "StalkerMinimap_Draw", function()
    LoadMap()

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local sw, sh = ScrW(), ScrH()
    local cx = MM.X + MM.Size / 2   -- центр мини-карты на экране
    local cy = MM.Y + MM.Size / 2

    local wpos = ply:GetPos()
    local eyeYaw = ply:EyeAngles().y
    local drawYaw = GetMapDrawYaw(eyeYaw)
    local texPx = GetOverviewTexPx()

    -- === Фон + обрезка ===
    draw.RoundedBox(0, MM.X, MM.Y, MM.Size, MM.Size, C_BG)

    -- Overview: поворот по взгляду; точки считаются тем же drawYaw
    if mapMat then
        local pu, pv = WorldToUV(wpos.x, wpos.y)

        render.SetScissorRect(MM.X, MM.Y, MM.X+MM.Size, MM.Y+MM.Size, true)
        surface.SetDrawColor(255,255,255,200)
        surface.SetMaterial(mapMat)

        local m = Matrix()
        m:Translate(Vector(cx, cy, 0))
        m:Rotate(Angle(0, drawYaw, 0))
        m:Translate(Vector(-pu * texPx, -pv * texPx, 0))
        cam.PushModelMatrix(m)
        surface.DrawTexturedRect(0, 0, texPx, texPx)
        cam.PopModelMatrix()

        render.SetScissorRect(0,0,0,0,false)
    else
        -- Заглушка: сетка с тем же поворотом, что и карта
        render.SetScissorRect(MM.X, MM.Y, MM.X+MM.Size, MM.Y+MM.Size, true)
        surface.SetDrawColor(30, 45, 30, 255)
        surface.DrawRect(MM.X, MM.Y, MM.Size, MM.Size)

        local gridSize = 40
        local gridSpan = math.ceil(MM.Size / gridSize) + 2
        local mGrid = Matrix()
        mGrid:Translate(Vector(cx, cy, 0))
        mGrid:Rotate(Angle(0, drawYaw, 0))
        cam.PushModelMatrix(mGrid)
        surface.SetDrawColor(45, 65, 45, 255)
        for i = -gridSpan, gridSpan do
            local o = i * gridSize
            surface.DrawLine(-MM.Size, o, MM.Size, o)
            surface.DrawLine(o, -MM.Size, o, MM.Size)
        end
        cam.PopModelMatrix()
        render.SetScissorRect(0,0,0,0,false)
    end

	local flDistSqr = MM.NpcRange * MM.NpcRange
	local szClass = ""
	local iOnlineCount = 0
    -- === Точки НПС, игроков и маркеров ===
    render.SetScissorRect(MM.X+3, MM.Y+3, MM.X+MM.Size-3, MM.Y+MM.Size-3, true)
	
	-- Хоть у игроков индекс энтити от 1 до maxplayers, все равно думаю стоит сделать это отдельно, например, чтобы маркеры отображались поверх игроков
	for _, otherPly in player.Iterator() do
		if (!IsValid(otherPly)) then continue end
		if (otherPly:EntIndex() == LocalPlayer():EntIndex()) then continue end
		local ep = otherPly:GetPos()
		if (wpos:DistToSqr(ep) > flDistSqr) then continue end
		
		local bShouldDraw = CStalkerCore:ShowPlayerInMinimap(otherPly, LocalPlayer())
		
		if (!bShouldDraw) then continue end
		
        local sx, sy = EntityToMinimapScreen(ep, wpos, cx, cy, texPx, drawYaw)

		-- НПС или игрок
		local dotC = C_NPC_NEU

		--surface.SetDrawColor(dotC)
		--surface.DrawRect(sx-3, sy-3, 6, 6)
		draw.RoundedBox(99, sx-3, sy-3, 6, 6, dotC)
		
		iOnlineCount = iOnlineCount + 1
	end
	
	-- TODO: Нужно переделать, из-за этого код обрабатывается 10 ms, но на игру не влияет
	-- Можно заменить на ents.FindInSphere
	for _, ent in ents.Iterator() do
		if (!IsValid(ent)) then continue end
		local ep = ent:GetPos()
		if (wpos:DistToSqr(ep) > flDistSqr) then continue end
		
		szClass = ent:GetClass()
		local bShouldDraw = false
		local bShouldDisplay = false
		local iType = 0
		local bIsEnemy = false
		
		if (ent:IsNPC() || ent:IsNextBot()) then
			bShouldDisplay = CStalkerCore:ShowNPCInMinimap(ent)
			if (bShouldDisplay) then
				iType = 1
				iOnlineCount = iOnlineCount + 1
			end
		
		elseif (string.find(szClass, "pda_mark_")) then
			bShouldDraw = true
			iType = 2
			
			if (ent.GetShowEveryone != nill && !ent:GetShowEveryone()) then
				bShouldDraw = false
			end
		elseif ((ent:GetClass() == "pjblue_item_drop" || ent:GetClass() == "stalker_drop") && ent.m_bShowOnMM) then
			bShouldDraw = true
			
			iType = 1
		end
		
		if (ent.m_iAttitude != nil) then
			bIsEnemy = ent.m_iAttitude == CD_HT
		else
			bIsEnemy = ent:GetNWInt("Attitude", 0) == CD_HT
		end
		
		--print("minimap", bIsEnemy)
		
		local enemy = GetEnemy(ent)
		
		if (bIsEnemy && bShouldDisplay) then
			-- Отображаем на мини-карте только если мы прям четко их видим
			if (IsEntInFOV(LocalPlayer(), ent) && IsAbleToSee(LocalPlayer(), ent)) then
				AddEnemy(ent)
			end
			
			if (enemy != nil) then
				if (CurTime() < enemy.time) then
					bShouldDraw = true
				end
			end
		elseif (!bIsEnemy && bShouldDisplay) then
			bShouldDraw = true
		end
		
		if (!bShouldDraw) then continue end
		
        local sx, sy = EntityToMinimapScreen(ep, wpos, cx, cy, texPx, drawYaw)

        -- Цвет точки
		
		-- НПС или игрок
		if (iType == 1) then
			local dotC = C_NPC_NEU
			
			if (ent:IsPlayer() || ent:IsNextBot() || ent:IsNPC()) then
				if (ent.m_iAttitude != nil) then
					if (ent.m_iAttitude == CD_HT) then
						dotC = C_NPC_ENE
						bIsEnemy = true
					elseif (ent.m_iAttitude == CD_FR || ent.m_iAttitude == CD_NU) then
						dotC = C_NPC_NEU
					elseif (ent.m_iAttitude == CD_LI) then
						dotC = C_NPC_FRN
					end
				else
					local iAttitude = ent:GetNWInt("Attitude", 0)
					if (iAttitude == CD_HT) then
						dotC = C_NPC_ENE
						bIsEnemy = true
					elseif (iAttitude == CD_LI) then
						dotC = C_NPC_FRN
					end
				end
			else
				dotC = C_NPC_DEAD
			end

			--surface.SetDrawColor(dotC)
			--surface.DrawRect(sx-3, sy-3, 6, 6)
			
			local boxSize = 6
			if (enemy != nil) then
				if (CurTime() < enemy.time2 + LargeEnemyDotDuration) then
					boxSize = 10
				end
			end
			
			draw.RoundedBox(99, sx-3, sy-3, boxSize, boxSize, dotC)
		-- Особый маркер (тайник, лагерь и тд)
		elseif (iType == 2) then
			local hMat = nil
			local iMarkW = 14
			local iMarkH = 14
			
			if (ent:GetClass() == "pda_mark_common") then
				local iIconMarkType = ent:GetMarkType()
				
				if (iIconMarkType == 6) then
					iMarkW = 22
					iMarkH = 22
				elseif (iIconMarkType == 7) then
					iMarkW = 18
					iMarkH = 18
				end
				
				hMat = CStalkerCore:GetMarkerMaterial(ent:GetMarkType())
			end
			
			if (hMat) then
				surface.SetDrawColor(255, 255, 255, 230)
				surface.SetMaterial(hMat)
				surface.DrawTexturedRect(sx-3, sy-3, iMarkW, iMarkH)
			end
		end
	end
    render.SetScissorRect(0,0,0,0,false)

    -- === Игрок — в центре; стрелка вверх (карта уже повёрнута, вперёд = вверх) ===
    surface.SetDrawColor(C_PLAYER)
    local arrowLen = 9
    surface.DrawLine(cx, cy, cx, cy - arrowLen)

    -- Белый кружок игрока
    draw.RoundedBox(99, cx-4, cy-4, 8, 8, C_PLAYER)

    -- === Рамка ===
    surface.SetDrawColor(C_BORDER)
    surface.DrawOutlinedRect(MM.X, MM.Y, MM.Size, MM.Size, 2)

    -- === Дистанция до цели ===
    local nearDist = nil
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:IsNPC() then
            local d = wpos:Distance(ent:GetPos())
            if not nearDist or d < nearDist then nearDist = d end
        end
    end
    if nearDist then
        local distM  = nearDist / 52.49   -- хаммер в метры
        local distStr = string.format("%.1f m", distM)

        surface.SetDrawColor(20, 20, 20, 200)
        surface.DrawRect(MM.X, MM.Y - 20, MM.Size, 20)
        draw.SimpleText(distStr, "MM_Dist",
            MM.X + MM.Size/2, MM.Y - 10,
            Color(255,255,255,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- === Компас — под мини-картой ===
    local compY   = MM.Y + MM.Size + -32 --4
    local compSize = 28

    -- Фон компаса
    draw.RoundedBox(4, MM.X + MM.Size / 1.1 - compSize/2, compY, compSize, compSize, Color(20,20,20,200))
    surface.SetDrawColor(C_BORDER)
    surface.DrawOutlinedRect(MM.X + MM.Size/1.1 - compSize/2, compY, compSize, compSize, 1)

    -- Стрелка компаса
    --local compCX = MM.X + MM.Size/2
	local compCX = MM.X + MM.Size/ 1.1
    local compCY = compY + compSize/2
    local northRad = math.rad(-eyeYaw - 90)
    -- Красная половина (север)
    surface.SetDrawColor(220, 50, 50, 255)
    surface.DrawLine(compCX, compCY,
        compCX + math.cos(northRad)*10,
        compCY + math.sin(northRad)*10)
    -- Белая половина (юг)
    surface.SetDrawColor(50, 50, 200, 255)
    surface.DrawLine(compCX, compCY,
        compCX - math.cos(northRad)*10,
        compCY - math.sin(northRad)*10)

    -- Буква направления над компасом
    draw.SimpleText(GetCompassLabel(eyeYaw), "MM_Compass",
        compCX, compY - 14,
        C_COMPASS, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

	if (MM.PreviousOnline != iOnlineCount) then
		local bMinus = MM.PreviousOnline > iOnlineCount
		MM.PreviousOnline = iOnlineCount
		local iRnd = math.random(1, 2)
		if (!bMinus) then
			if (iRnd == 1) then
				surface.PlaySound("pj/stalker/contact_1.mp3")
			else
				surface.PlaySound("pj/stalker/contact_8.mp3")
			end
		end
	end
	
    -- === Считает колво НПС или игроков в радиусе ===
    local ammoY = compY + compSize + 4
    --draw.RoundedBox(3, MM.X + MM.Size/2 - 18, ammoY, 36, 28, Color(20,20,20,200))
	draw.RoundedBox(3, MM.X + MM.Size/1.2 - 3, ammoY, 36, 28, Color(20,20,20,200))
    draw.SimpleText(iOnlineCount, "MM_Ammo",
        MM.X + MM.Size/1.1, ammoY+14,
        Color(255,220,50,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

hook.Add("Think", "StalkerMinimap_Think", function()
	ClearEnemies()
end)