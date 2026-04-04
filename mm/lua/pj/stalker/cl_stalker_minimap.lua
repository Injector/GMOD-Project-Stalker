-- ============================================================
-- STALKER MINIMAP — мини-карта в левом верхнем углу
-- ============================================================

local MM = {}
MM.Size     = 200       -- размер квадрата мини-карты в пикселях
MM.Scale    = 0.1         -- пикселей на 1 хаммер-юнит (больше = крупнее)
MM.NpcRange = 1200      -- радиус обнаружения НПС (hammer units)
MM.X        = 10        -- позиция на экране
MM.Y        = 10

MM.PreviousOnline = 0

-- Цвета точек
local C_PLAYER  = Color(255, 255, 255, 255)   -- белая точка - игрок
local C_NPC_NEU = Color(255, 200, 0,   255)   -- желтая - нейтрал
local C_NPC_ENE = Color(255, 50,  50,  255)   -- красная - враг
local C_NPC_FRN = Color(0,  255,   0,  255)   -- зеленая - друг
local C_BORDER  = Color(80,  80,  80,  255)
local C_BG      = Color(0,   0,   0,   180)
local C_COMPASS = Color(200, 180, 50,  255)

surface.CreateFont("MM_Compass", {font="Trebuchet MS", size=14, weight=700})
surface.CreateFont("MM_Dist",    {font="Trebuchet MS", size=12, weight=400})
surface.CreateFont("MM_Ammo",    {font="Trebuchet MS", size=22, weight=700})

-- ---- Загрузка overview ----
local mapMat      = nil
local mapData     = {}
local mapLoaded   = false

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

local function WorldToUV(wx, wy)
    if not CStalkerMapData.pos_x then return 0.5, 0.5 end
    local scale = CStalkerMapData.scale or 1
    local u = (wx - (CStalkerMapData.pos_x or 0)) / scale / 1024
    local v = (wy - (CStalkerMapData.pos_y or 0)) / scale / 1024 * -1.0
    return u, v
end

-- Перевести смещение в мировых единицах в пиксели на мини-карте
local function DeltaToPixel(dx, dy)
    return dx * MM.Scale, dy * MM.Scale
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
    local yaw  = ply:EyeAngles().y

    -- === Фон + обрезка ===
    -- Рисуем тёмный фон
    draw.RoundedBox(0, MM.X, MM.Y, MM.Size, MM.Size, C_BG)

    -- Рисуем overview текстуру со смещением под игрока
    if mapMat then
        -- UV центра (позиция игрока на текстуре)
        local pu, pv = WorldToUV(wpos.x, wpos.y)

        -- Размер текстуры в пикселях на мини-карте при данном масштабе:
        -- overview покрывает scale*1024 хаммер-единиц
        -- при MM.Scale пикс/юнит это scale*1024*MM.Scale пикселей
        local texPx = (CStalkerMapData.scale or 1) * 1024 * MM.Scale

        -- Смещение: центр текстуры = позиция игрока
        local tx = cx - pu * texPx
        local ty = cy - pv * texPx

        -- Scissor чтобы не вылезало за пределы
        render.SetScissorRect(MM.X, MM.Y, MM.X+MM.Size, MM.Y+MM.Size, true)
        surface.SetDrawColor(255,255,255,200)
        surface.SetMaterial(mapMat)
        surface.DrawTexturedRect(tx, ty, texPx, texPx)
        render.SetScissorRect(0,0,0,0,false)
    else
        -- Заглушка: двигающаяся сетка
        render.SetScissorRect(MM.X, MM.Y, MM.X+MM.Size, MM.Y+MM.Size, true)
        local gridSize = 40
        local offX = (wpos.x * MM.Scale) % gridSize
        local offY = (wpos.y * MM.Scale) % gridSize
        surface.SetDrawColor(30, 45, 30, 255)
        surface.DrawRect(MM.X, MM.Y, MM.Size, MM.Size)
        surface.SetDrawColor(45, 65, 45, 255)
        for gx = MM.X - offX, MM.X + MM.Size, gridSize do
            surface.DrawLine(gx, MM.Y, gx, MM.Y + MM.Size)
        end
        for gy = MM.Y - offY, MM.Y + MM.Size, gridSize do
            surface.DrawLine(MM.X, gy, MM.X + MM.Size, gy)
        end
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
		
		local dx = ep.x - wpos.x
		local dy = ep.y - wpos.y
		
		local rad = 0
        local px  = dx * math.cos(rad) - dy * math.sin(rad)
        local py  = dx * math.sin(rad) + dy * math.cos(rad)

        local sx  = cx + px * MM.Scale
        local sy  = cy - py * MM.Scale   -- Y инвертирован

		-- НПС или игрок
		local dotC = C_NPC_NEU

		--surface.SetDrawColor(dotC)
		--surface.DrawRect(sx-3, sy-3, 6, 6)
		draw.RoundedBox(99, sx-3, sy-3, 6, 6, dotC)
		
		iOnlineCount = iOnlineCount + 1
	end
	
	for _, ent in ents.Iterator() do
		if (!IsValid(ent)) then continue end
		local ep = ent:GetPos()
		if (wpos:DistToSqr(ep) > flDistSqr) then continue end
		
		szClass = ent:GetClass()
		local bShouldDraw = false
		local iType = 0
		
		if (string.find(szClass, "npc_")) then
			bShouldDraw = true
			iType = 1
			iOnlineCount = iOnlineCount + 1
		elseif (string.find(szClass, "pda_mark_")) then
			bShouldDraw = true
			iType = 2
		end
		
		if (!bShouldDraw) then continue end
		
		-- Смещение от игрока в мировых ед.
        local dx = ep.x - wpos.x
        local dy = ep.y - wpos.y

		-- FIXME: Не работает так, как нужно
        -- Повернуть в экранное пространство (yaw игрока, чтобы карта была ориентирована по движению)
        --local rad = math.rad(-yaw)
		local rad = 0
        local px  = dx * math.cos(rad) - dy * math.sin(rad)
        local py  = dx * math.sin(rad) + dy * math.cos(rad)

        local sx  = cx + px * MM.Scale
        local sy  = cy - py * MM.Scale   -- Y инвертирован

        -- Цвет точки
		-- TODO: Disposition доступен только на стороне сервера, можно давать знак игроку об отношениях с помощью net
        --local rel = ent:Disposition(ply)
        --local dotC = (rel == D_LI or rel == D_FR) and C_NPC_NEU or C_NPC_ENE
		
		-- НПС или игрок
		if (iType == 1) then
			local dotC = C_NPC_NEU
			
			if (ent.m_iAttitude != nil) then
				if (ent.m_iAttitude == D_HT) then
					dotC = C_NPC_ENE
				elseif (ent.m_iAttitude == D_FR || ent.m_iAttitude == D_NU) then
					dotC = C_NPC_NEU
				elseif (ent.m_iAttitude == D_LI) then
					dotC = C_NPC_FRN
				end
			end

			--surface.SetDrawColor(dotC)
			--surface.DrawRect(sx-3, sy-3, 6, 6)
			draw.RoundedBox(99, sx-3, sy-3, 6, 6, dotC)
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

    -- === Игрок — белая точка в центре + стрелка направления ===
    -- Стрелка (маленький треугольник вверх = вперёд)
    surface.SetDrawColor(C_PLAYER)
    local arrowLen = 9
    local arrowRad = math.rad(-yaw - 0) -- поворачиваем стрелку по yaw
    -- Упрощённо: просто линия вперёд + боковые
    local ax = cx + math.cos(arrowRad) * arrowLen
    local ay = cy + math.sin(arrowRad) * arrowLen
    surface.DrawLine(cx, cy, ax, ay)

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
    local northRad = math.rad(-yaw - 90)   -- север
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
    draw.SimpleText(GetCompassLabel(yaw), "MM_Compass",
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