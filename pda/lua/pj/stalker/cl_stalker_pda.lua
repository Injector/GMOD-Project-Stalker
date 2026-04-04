-- Stalker PDA Interface for Garry's Mod
-- Opens/Closes with F4

-- ============================================================
-- CONFIGURATION
-- ============================================================
PDA = {}
PDA.Open = false
PDA.CurrentTab = 1
PDA.Tabs = {"Задачи", "План", "Журнал", "Контакты", "Ранги", "Данные"}

PDA.Markers = {}

-- Colors
local COLOR_BG        = Color(15, 15, 15, 245)
local COLOR_FRAME     = Color(60, 60, 60, 255)
local COLOR_PANEL     = Color(25, 25, 25, 255)
local COLOR_HEADER    = Color(35, 35, 35, 255)
local COLOR_TAB_ACT   = Color(180, 140, 30, 255)
local COLOR_TAB_INACT = Color(100, 100, 100, 255)
local COLOR_TEXT      = Color(200, 200, 200, 255)
local COLOR_TEXT_DIM  = Color(120, 120, 120, 255)
local COLOR_GREEN     = Color(80, 200, 80, 255)
local COLOR_RED       = Color(200, 60, 60, 255)
local COLOR_YELLOW    = Color(200, 180, 50, 255)
local COLOR_BORDER    = Color(80, 80, 80, 255)
local COLOR_SCROLLBAR = Color(60, 60, 60, 255)
local COLOR_ITEM_HOV  = Color(40, 40, 40, 255)
local COLOR_ITEM_SEL  = Color(50, 45, 15, 255)

local COLOR_MARKER_STASH = Color(154, 140, 204, 255) --Color(140, 121, 206, 255)
local COLOR_MARKER_QUEST = Color(110, 204, 110, 255) --Color(0, 206, 0, 255)

-- ============================================================
-- PDA DIMENSIONS — размеры пда
-- ============================================================
local PW, PH = 1100, 680
local PX, PY  -- вычисляются каждый кадр
local BORDER   = 20
local TAB_H    = 32
local SCROLL_W = 12

-- ============================================================
-- CLICK SYSTEM — система лкм через Think, чтобы исправить проблему GUIMousePressed (иногда клик может не срабатывать)
-- clickQueue очищаются в HUDPaint
-- ============================================================
local clickQueue     = {}
local prevMouseDown  = false

hook.Add("Think", "StalkerPDA_ClickDetect", function()
    if not PDA.Open then
        prevMouseDown = false
        return
    end
    local down = input.IsMouseDown(MOUSE_LEFT)
    if down and not prevMouseDown then
        -- Мышь только что нажата
        local mx, my = gui.MousePos()
        table.insert(clickQueue, {x = mx, y = my})
    end
    prevMouseDown = down
end)

-- ============================================================
-- TASKS DATA
-- ============================================================
--Ниже оставлено как пример заполнения квестов
-- PDA.Tasks = {
    -- {
		-- id = 1,
        -- title = "Отключить пси-излучение",
        -- date  = "03/05/2012 22:54",
        -- desc  = "Сахаров: «Молодец, Меченый, ты таки добрался до лаборатории. Для нас крайне важно изучить установку, которая там находится. Попробуй её отключить, чтобы мы смогли её исследовать. Послушай, Меченый, прототип не сможет долго защищать от сильного излучения. Я предусмотрел такой случай, поэтому, когда ты попадёшь под сильное воздействие, включится таймер. Когда время истечёт, прототип перестанет тебя защищать. Будь осторожней, и не забывай про таймер.»",
        -- steps = {
            -- {done=true,  text="Отключить 1-ый блок управления"},
            -- {done=true,  text="Отключить 2-ой блок управления"},
            -- {done=false, text="Отключить 3-ий блок управления"},
            -- {done=false, text="Отключить питание установки"},
        -- },
		-- icon = CStalkerCore.Resources.TaskIcons.m_hMatCompas
    -- },
    -- {
		-- id = 2,
        -- title = "Найти документы в лаборатории X16",
        -- date  = "03/05/2012 07:25",
        -- desc  = "Найдите документы в лаборатории X-16 и принесите их бармену.",
        -- steps = {
            -- {done=true,  text="Найти документы X-16"},
            -- {done=false, text="Принести документы бармену"},
        -- },
		-- icon = CStalkerCore.Resources.TaskIcons.m_hMatCompas
    -- },
    -- {
		-- id = 3,
        -- title = "Найти тайник группировки Стрелка",
        -- date  = "02/05/2012 07:48",
        -- desc  = "Найдите тайник группировки Стрелка и изучите информацию о нём.",
        -- steps = {
            -- {done=true,  text="Найти тайник"},
            -- {done=false, text="Найти в тайнике информацию о Стрелке"},
        -- },
		-- icon = CStalkerCore.Resources.TaskIcons.m_hMatStalker
    -- },
	-- {
		-- id = 4,
        -- title = "Добыть часть тела монстра",
        -- date  = "03/05/2012 09:28",
        -- desc  = "Просто найти часть тела монстра, че бубнить?",
        -- steps = {
            -- {done=true,  text="Притащить хвост псевдособаки"},
            -- {done=false, text="Принести заказчику обещанное."},
        -- },
		-- icon = CStalkerCore.Resources.TaskIcons.m_hMatMutant
    -- },
	-- {
		-- id = 5,
        -- title = "Убить сталкера",
        -- date  = "02/05/2012 04:20",
        -- desc  = "Просто убить сталкера, че бубнить?",
        -- steps = {
            -- {done=false,  text="Убить \"торгового представителя\""},
            -- {done=false, text="Вернуться за наградой"},
        -- },
		-- icon = CStalkerCore.Resources.TaskIcons.m_hMatKill
    -- },
	-- {
		-- id = 6,
        -- title = "Уничтожение лагеря",
        -- date  = "02/05/2012 04:20",
        -- desc  = "Просто уничтожить лагерь, че бубнить?",
        -- steps = {
            -- {done=false,  text="Зачистить местность от мутантов"},
            -- {done=false, text="Вернуться за наградой"},
        -- },
		-- icon = CStalkerCore.Resources.TaskIcons.m_hMatEliminateLager
    -- },
	-- {
		-- id = 7,
        -- title = "Добыть артефакт",
        -- date  = "02/05/2012 04:20",
        -- desc  = "Просто найти артефакт, че бубнить?",
        -- steps = {
            -- {done=true,  text="Найти артефакт \"Медуза\""},
            -- {done=false, text="Принести заказчику обещанное"},
        -- },
		-- icon = CStalkerCore.Resources.TaskIcons.m_hMatArtefact
    -- },
-- }
PDA.Tasks = {}
PDA.SelectedTask     = nil
PDA.ShowTaskDesc     = false
PDA.TaskScrollOffset = 0

-- ============================================================
-- JOURNAL DATA
-- ============================================================
--Оставлено как пример, а так же для дебага
-- PDA.Journal = {
    -- {
		-- id = 1,
        -- group = "Личные заметки", open = true,
        -- notes = {
            -- {id = 1, title="Кто я?",                   text="Чёрт, смутно помню какую-то машину… долго везли и болело всё тело, потом темнота, а что до этого? А вот что было, до этого ума не приложу… бред какой-то… Теперь этот толстый мужик, называет меня Меченым, видимо из за странной татуировки на руке, плюс это непонятное и единственное задание убить некоего Стрелка, на моём КПК… ещё вопрос моё ли это КПК? Фото Стрелка — как не напрягаю мозги не могу вспомнить, знаю я его или нет… Чёрт! Всё это напоминает дурной сон. Вот только проснуться не получается. Что делать? Куда идти? Хуже того — кто я? Так, успокоиться, держать себя в руках! Первое — видимо пока придётся-таки побегать кабанчиком по заданиям этого Сидоровича, всё-таки говорит жизнь спас… да и может всё не так плохо, прогуляюсь, приду в себя — глядишь мозги и прояснятся."},
            -- {id = 2, title="Первые впечатления",        text="Нормальное такое место."},
            -- {id = 3, title="Первая дальняя вылазка",    text="Наконец-то выбрался дальше периметра..."},
            -- {id = 4, title="Полезная информация",        text="Стрелок был в центре зоны, крутяк."},
            -- {id = 5, title="Встреча с Лисом",            text="Сомнительный тип, но вроде нормальный мужик. Правда Сидорович меня немного обманул, Лис ничего не знает про стрелка, только очень мелкий опыт знакомства."},
            -- {id = 6, title="Встреча с Серым",            text="Благодаря Серому я узнал о Кроте, который знает про тайник Стрелка, сколько мне еще так бегать?"},
            -- {id = 7, title="Встреча с Кротом",           text="Крот рассказал что они тут искали тайник Стрелка, что-ж, посмотрим что я найду."},
            -- {id = 8, title="Военные документы",          text="Секретные материалы военных, связанные с лабораторией х-18, пора двигать к бармену!"},
            -- {id = 9, title="Бармен",                     text="Бармен - ключевая фигура в Баре, он рассказал про лабораторию в Темной Долине, для открытия нужно два электронных ключа, один есть, второй заберу у Борова."},
            -- {id = 10, title="Странный сон",               text="Какой-то странный сон..."},
            -- {id = 11, title="Лаборатория X18",            text="Жуткое место."},
            -- {id = 12, title="'Выжигатель' рукотворен?",   text="Похоже, пси-установка создана людьми, в частности неким доктором Каймановым, но по крайней мере ее можно отключить, надо наведаться к ученым на Янтаре."},
            -- {id = 13, title="В шаге от Призрака",         text="Призрак работал с учеными? Но у меня дурное предчуствие, если Васильев сбежал и погиб, то Призрак может и не жилец..."},
        -- }
    -- },
    -- {id = 2, group="Найденные КПК",      open=false, notes={{id = 1, title="КПК сталкера #1",     text="Похоже, бандит хотел отыскать своего братка на элеваторе."}}},
    -- {id = 3, group="Операция «Агропром»", open=false, notes={{id = 1, title="Сведения об Агропроме",text="Абракадабра, типа шифр"}}},
    -- {id = 4, group="Информация из X-18", open=false, notes={{id = 1, title="Документы X-18",       text="Тут написано что-то на умном, мне не понять."}}},
-- }
PDA.Journal = {}
PDA.SelectedNote     = nil
PDA.JournalScrollOff = 0

-- ============================================================
-- STATS DATA
-- ============================================================
-- Оставлено как пример
-- PDA.Stats = {
    -- npc_kills    = 16590,
    -- mutant_kills = 1188,
    -- quests_done  = 169,
    -- kill_list = {
        -- {id = 1, name="военный, рядовой",       mult=33,  total=33},
        -- {id = 2, name="военный, лейтенант",     mult=17,  total=51},
        -- {id = 3, name="военный, сержант",       mult=13,  total=26},
        -- {id = 4, name="военный, капитан",       mult=1,   total=4},
        -- {id = 5, name="бандит, новичок",        mult=58,  total=58},
        -- {id = 6, name="сталкер, новичок",       mult=2,   total=2},
        -- {id = 7, name="бандит, опытный",        mult=65,  total=130},
        -- {id = 8, name="бандит, ветеран",        mult=3,   total=9},
        -- {id = 9, name="наёмник, ветеран",       mult=6,   total=18},
        -- {id = 10, name="наёмник, опытный",       mult=22,  total=44},
        -- {id = 11, name="зомбированный, новичок", mult=37,  total=37},
        -- {id = 12, name="зомбированный, опытный", mult=1,   total=2},
    -- }
-- }
PDA.Stats = {
	npc_kills    = 0,
    mutant_kills = 0,
    quests_done  = 0,
    kill_list = {}
}
PDA.StatsKillScroll    = 0

PDA.SelectedRankPlayer = nil
PDA.RankScroll         = 0
PDA.ContactScroll      = 0
PDA.SelectedContact    = nil

-- ============================================================
-- FONTS
-- ============================================================
surface.CreateFont("PDA_Title",  {font="Trebuchet MS", size=24, weight=700})
surface.CreateFont("PDA_Tab",    {font="Trebuchet MS", size=16, weight=600})
surface.CreateFont("PDA_Body",   {font="Trebuchet MS", size=15, weight=400})
surface.CreateFont("PDA_Small",  {font="Trebuchet MS", size=13, weight=400})
surface.CreateFont("PDA_Header", {font="Trebuchet MS", size=17, weight=700})
surface.CreateFont("PDA_Huge",   {font="Trebuchet MS", size=26, weight=700})

-- ============================================================
-- HELPERS
-- ============================================================
local function IsHovered(x, y, w, h)
    local mx, my = gui.MousePos()
    return mx >= x and mx <= x+w and my >= y and my <= y+h
end

local function Scissor(x, y, w, h, fn)
    render.SetScissorRect(x, y, x+w, y+h, true)
    fn()
    render.SetScissorRect(0, 0, 0, 0, false)
end

local function WrapText(text, font, maxW)
    surface.SetFont(font)
    local lines = {}
    local words = string.Explode(" ", text)
    local line  = ""
    for _, word in ipairs(words) do
        local test = line == "" and word or (line .. " " .. word)
        local w    = surface.GetTextSize(test)
        if w > maxW and line ~= "" then
            table.insert(lines, line)
            line = word
        else
            line = test
        end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

-- ============================================================
-- SCROLLBAR DRAG SYSTEM
-- ============================================================
local SB = {}
SB.Active    = false   -- идёт ли перетаскивание
SB.Target    = nil     -- ключ: "tasks"|"journal"|"contacts"|"ranks"|"stats"
SB.StartY    = 0       -- Y мыши в момент начала drag
SB.StartOff  = 0       -- значение offset в момент начала drag
SB.MaxOff    = 0       -- максимальный offset для данного скроллбара
SB.BarY      = 0       -- Y верхней границы ползунка (для hit-test)
SB.BarH      = 0       -- высота ползунка
SB.TrackY    = 0       -- Y верхней границы трека
SB.TrackH    = 0       -- высота трека

-- Вызывается из Think — обновляет offset во время drag
hook.Add("Think", "StalkerPDA_ScrollDrag", function()
    if not PDA.Open then SB.Active = false; return end

    local down = input.IsMouseDown(MOUSE_LEFT)

    if SB.Active then
        if not down then
            -- Отпустили кнопку — конец drag
            SB.Active = false
            return
        end
        -- Двигаем offset пропорционально смещению мыши
        local _, my = gui.MousePos()
        local delta = my - SB.StartY
        -- Сколько пикселей трека соответствует всему диапазону offset
        local trackUsable = SB.TrackH - SB.BarH
        if trackUsable > 0 then
            local newOff = SB.StartOff + delta * (SB.MaxOff / trackUsable)
            newOff = math.Clamp(newOff, 0, SB.MaxOff)

            if     SB.Target == "tasks"    then PDA.TaskScrollOffset  = newOff
            elseif SB.Target == "journal"  then PDA.JournalScrollOff  = newOff
            elseif SB.Target == "contacts" then PDA.ContactScroll     = newOff
            elseif SB.Target == "ranks"    then PDA.RankScroll        = newOff
            elseif SB.Target == "stats"    then PDA.StatsKillScroll   = newOff
            end
        end
    end
end)

-- Проверяет, нажал ли игрок на ползунок скроллбара
-- Вызывается из DrawScrollbar при обработке кликов
local function TryStartScrollDrag(target, clicks, trackX, trackY, trackW, trackH, barY, barH, maxOff, currentOff)
    for _, cl in ipairs(clicks) do
        if cl.x >= trackX and cl.x <= trackX + trackW and
           cl.y >= trackY and cl.y <= trackY + trackH then

            if cl.y >= barY and cl.y <= barY + barH then
                -- Клик попал на ползунок — начать drag
                SB.Active   = true
                SB.Target   = target
                SB.StartY   = cl.y
                SB.StartOff = currentOff
                SB.MaxOff   = maxOff
                SB.TrackY   = trackY
                SB.TrackH   = trackH
                SB.BarY     = barY
                SB.BarH     = barH
            else
                -- Клик по треку вне ползунка — прыжок к позиции
                local trackUsable = trackH - barH
                if trackUsable > 0 then
                    local rel = (cl.y - trackY - barH/2) / trackUsable
                    local newOff = math.Clamp(rel * maxOff, 0, maxOff)
                    if     target == "tasks"    then PDA.TaskScrollOffset  = newOff
                    elseif target == "journal"  then PDA.JournalScrollOff  = newOff
                    elseif target == "contacts" then PDA.ContactScroll     = newOff
                    elseif target == "ranks"    then PDA.RankScroll        = newOff
                    elseif target == "stats"    then PDA.StatsKillScroll   = newOff
                    end
                end
            end
        end
    end
end


-- local function DrawScrollbar(x, y, w, h, offset, maxOff)
    -- draw.RoundedBox(2, x, y, w, h, COLOR_SCROLLBAR)
    -- if maxOff <= 0 then return end
    -- local ratio = h / (h + maxOff)
    -- local barH  = math.max(24, h * ratio)
    -- local barY  = y + (offset / maxOff) * (h - barH)
    -- draw.RoundedBox(2, x+1, barY, w-2, barH, COLOR_TAB_ACT)
-- end

function DrawScrollbar(x, y, w, h, offset, maxOff, target, clicks)
    -- Фон трека
    draw.RoundedBox(2, x, y, w, h, COLOR_SCROLLBAR)
    if maxOff <= 0 then return end

    -- Вычисляем размер и позицию ползунка
    local ratio = h / (h + maxOff)
    local barH  = math.max(24, h * ratio)
    local barY  = y + (offset / maxOff) * (h - barH)
	-- Подсветка ползунка если drag активен на этом таргете
    local barColor = (SB.Active and SB.Target == target)
        and Color(220, 170, 50, 255)   -- ярче при drag
        or  COLOR_TAB_ACT

    draw.RoundedBox(2, x+1, barY, w-2, barH, barColor)

    -- Hover подсветка
    local mx, my = gui.MousePos()
    if mx >= x and mx <= x+w and my >= barY and my <= barY+barH then
        draw.RoundedBox(2, x+1, barY, w-2, barH, Color(220, 170, 50, 255))
    end

    -- Обработка кликов
    if clicks and target then
        TryStartScrollDrag(target, clicks, x, y, w, h, barY, barH, maxOff, offset)
    end
end

-- Проверяет, попал ли клик в зону
local function ClickIn(cl, x, y, w, h)
    return cl.x >= x and cl.x <= x+w and cl.y >= y and cl.y <= y+h
end

-- ============================================================
-- MAP — overview-текстура карты
-- ============================================================
local mapMaterial = nil
local mapData     = {}
local mapDataLoaded = false

--PDA.MapData = PDA.MapData or {}

-- local mapData =
-- {
	-- -- pos_x = -6066,
	-- -- pos_y = 7415,
	-- -- scale = 12.00,
	
	-- pos_x = -13182,
	-- pos_y = 15155,
	-- scale = 30.0,
-- }
-- mapDataLoaded = false

--TODO: Почистить от говна
local function LoadMapData()
    if mapDataLoaded then return end
    mapDataLoaded = true
    local mapName = game.GetMap()
    local data = file.Read("overviews/" .. mapName .. ".txt", "DATA")
	
	if not data then
		--print("No data ")
	else
		--print("Found data!")
	end
	
    if not data then return end
	
	for k, v in string.gmatch(data, "([^%\n]+)=([^%\n]+)") do
		--print("key " .. k .. " value " .. v)
		if (k == "pos_x") then
			mapData.pos_x = tonumber(v)
		elseif (k == "pos_y") then
			mapData.pos_y = tonumber(v)
		elseif (k == "scale") then
			mapData.scale = tonumber(v)
		end
	end
end

local function GetMapMaterial()
    if mapMaterial then return mapMaterial end
    local mat = Material("overviews/" .. game.GetMap() .. ".png")
    if not mat:IsError() then mapMaterial = mat end
    return mapMaterial
end

local function WorldToMap(wx, wy, mx, my, mw, mh)
    if not CStalkerMapData.pos_x then return mx + mw/2, my + mh/2 end
    local scale = CStalkerMapData.scale or 1
    local px = (wx - (CStalkerMapData.pos_x or 0)) / scale
    local py = (wy - (CStalkerMapData.pos_y or 0)) / scale
    return mx + (px / 1024) * mw,
           my + (py / 1024) * mh * -1
end

local function DrawMiniMap(mx, my, mw, mh)
    LoadMapData()
    -- Фон карты
    draw.RoundedBox(0, mx, my, mw, mh, Color(18, 22, 18, 255))

    local mat = GetMapMaterial()
    if mat then
        -- Рисуем текстуру обзора карты
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(mx, my, mw, mh)

        -- Позиция и направление игрока
        local ply = LocalPlayer()
        if IsValid(ply) then
            local wpos    = ply:GetPos()
            local px, py2 = WorldToMap(wpos.x, wpos.y, mx, my, mw, mh)

            -- Синий квадрат — игрок
            surface.SetDrawColor(0, 200, 255, 230)
            surface.DrawRect(px-6, py2-6, 12, 12)

            -- Стрелка направления
			local eyeAngles = ply:EyeAngles()
			eyeAngles:RotateAroundAxis(eyeAngles:Up(), 90)
			
            --local yaw = ply:EyeAngles().y
			local yaw = eyeAngles.y
			
            local rad = math.rad(yaw)
            local ax  = px + math.sin(rad) * 18
            local ay2 = py2 + math.cos(rad) * 18
            surface.SetDrawColor(0, 255, 100, 255)
            surface.DrawLine(px, py2, ax, ay2)
			
			--draw.SimpleText(ply:Nick(), "PDA_Small", px, py2+6, color_white, TEXT_ALIGN_CENTER)

            -- Координаты
            draw.SimpleText(
                string.format("X:%.0f Y:%.0f", wpos.x, wpos.y),
                "PDA_Small", mx+6, my+mh-20, COLOR_GREEN)
        end
		
		for i, v in ipairs(player.GetAll()) do
			
			-- Для отображения других игроков, должны выполнены ВСЕ условия:
			-- Игрок должен быть жив, находится в одной команде (вроде как профессии в даркрп работают именно так)
			-- Игрок должен не быть в ноуклипе, и быть видимым другими
			-- По желанию, игроку можно прописать m_bDontTrackMePDA = true чтобы не отображать (например, админам в нонрп режиме)
			if (ply:EntIndex() != v:EntIndex() && CStalkerCore:ShowPlayerInMinimap(v, ply)) then
				local wpos    = v:GetPos()
				local px, py2 = WorldToMap(wpos.x, wpos.y, mx, my, mw, mh)

				-- Зеленый квадрат
				surface.SetDrawColor(0, 255, 0, 230)
				surface.DrawRect(px-6, py2-6, 12, 12)

				-- Стрелка направления
				local eyeAngles = v:EyeAngles()
				eyeAngles:RotateAroundAxis(eyeAngles:Up(), 90)
				
				--local yaw = ply:EyeAngles().y
				local yaw = eyeAngles.y
				
				local rad = math.rad(yaw)
				local ax  = px + math.sin(rad) * 18
				local ay2 = py2 + math.cos(rad) * 18
				surface.SetDrawColor(0, 255, 100, 255)
				surface.DrawLine(px, py2, ax, ay2)
				
				draw.SimpleText(v:Nick(), "PDA_Small", px, py2+6, color_white, TEXT_ALIGN_CENTER)
			end
		end
		
		-- Ищем энтити с классом pda_mark_, так как у них флаг TRANSMIT_ALWAYS, 
		-- Это означает, что они всегда будут на карте, даже если игрок не видит вживую данные энтити (за пределы PVS и тд)
		for _, ent in ents.Iterator() do
			if (string.find(ent:GetClass(), "pda_mark_common")) then
				local hMat = nil
				local iMarkH = 14
				local iMarkW = 14
				local iMarkType = 0
				
				local iIconMarkType = ent:GetMarkType()
				
				if (iIconMarkType == 6) then
					iMarkW = 22
					iMarkH = 22
				elseif (iIconMarkType == 7) then
					iMarkW = 18
					iMarkH = 18
					--Квестовая иконка
					iMarkType = 2
				end
				
				hMat = CStalkerCore:GetMarkerMaterial(ent:GetMarkType())
				
				local wpos    = ent:GetPos()
				local px, py2 = WorldToMap(wpos.x, wpos.y, mx, my, mw, mh)
				
				local bShouldDraw = true

				if (ent.GetShowEveryone != nill && !ent:GetShowEveryone()) then
					bShouldDraw = false
				end
				
				if (bShouldDraw && hMat) then
					surface.SetDrawColor(255, 255, 255, 230)
					--if (hMat) then
						surface.SetMaterial(hMat)
					--end
					surface.DrawTexturedRect(px-6, py2-6, iMarkW, iMarkH)
				
				
					if (IsHovered(px-6, py2-6, iMarkW + 4, iMarkH + 4)) then
						if (iMarkType == 0) then
							
							if (bShouldDraw && ent.GetStashName != nil && ent.GetStashDesc != nil) then
								draw.SimpleText(ent:GetStashName(), "PDA_Small", px, py2+6, COLOR_MARKER_STASH, TEXT_ALIGN_CENTER)
								draw.SimpleText(ent:GetStashDesc(), "PDA_Small", px, py2+14, COLOR_MARKER_STASH, TEXT_ALIGN_CENTER)
							end
							
							--draw.SimpleText("Рюкзак Дохляка", "PDA_Small", px, py2+6, color_white, TEXT_ALIGN_CENTER)
							--draw.SimpleText("Говорят, Дохляк на Свалке скопытился, надо наведаться, хабар глянуть. А то желающих много набежит.", "PDA_Small", px, py2+14, color_white, TEXT_ALIGN_CENTER)
						elseif (iMarkType == 2) then
							--draw.SimpleText("Отключить 1-ый блок управления", "PDA_Small", px, py2+6, color_white, TEXT_ALIGN_CENTER)
							
							if (bShouldDraw && ent.GetQuestName != nil && ent.GetQuestDesc != nil) then
								if (ent:GetQuestName() != "" || ent:GetQuestDesc() != "") then
									draw.SimpleText(ent:GetQuestName(), "PDA_Small", px, py2+6, COLOR_MARKER_QUEST, TEXT_ALIGN_CENTER)
									draw.SimpleText(ent:GetQuestDesc(), "PDA_Small", px, py2+14, COLOR_MARKER_QUEST, TEXT_ALIGN_CENTER)
								end
							end
							
							for i = 1, #PDA.Tasks do
								if (!PDA.Tasks[i].steps) then continue end
								
								for k = 1, #PDA.Tasks[i].steps do
									if (!PDA.Tasks[i].steps[k].done && PDA.Tasks[i].steps[k].ent_marker && PDA.Tasks[i].steps[k].ent_marker:EntIndex() == ent:EntIndex()) then
										draw.SimpleText(PDA.Tasks[i].steps[k].text, "PDA_Small", px, py2+6, color_white, TEXT_ALIGN_CENTER)
									end
								end
							end
						end
					end
				end
			end
		end
    else
        -- Нет overview текстуры/данных — показываем заглушку с сеткой
        surface.SetDrawColor(30, 40, 30, 255)
        surface.DrawRect(mx, my, mw, mh)

        -- Сетка
        surface.SetDrawColor(40, 55, 40, 255)
        for gx = mx, mx+mw, 40 do
            surface.DrawLine(gx, my, gx, my+mh)
        end
        for gy = my, my+mh, 40 do
            surface.DrawLine(mx, gy, mx+mw, gy)
        end

        draw.SimpleText("Карта недоступна", "PDA_Body",
            mx + mw/2, my + mh/2, COLOR_TEXT_DIM,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        -- Всё равно рисуем позицию игрока
        local ply = LocalPlayer()
        if IsValid(ply) then
            local wpos = ply:GetPos()
            draw.SimpleText(
                string.format("X:%.0f Y:%.0f Z:%.0f", wpos.x, wpos.y, wpos.z),
                "PDA_Small", mx+6, my+mh-20, COLOR_GREEN)
        end
    end

    -- Название карты
    draw.SimpleText(game.GetMap(), "PDA_Small",
        mx+mw-6, my+mh-20, COLOR_TEXT_DIM, TEXT_ALIGN_RIGHT)
end

local m_hAvatars = {}
local m_hMyLocalAvatar = nil

local function HasAvatar(index)
	for i = 1, #m_hAvatars do
		if (m_hAvatars[i].id == index) then return true end
	end
	
	return false
end

-- ============================================================
-- MAIN HUD HOOK
-- ============================================================
hook.Add("HUDPaint", "StalkerPDA_HUD", function()
	
	if (!PDA.Open) then
		if (PDA.CurrentTab == 5) then
			for i = 1, #m_hAvatars do
				if (m_hAvatars[i] != nil && m_hAvatars[i].avatar != nil) then
					m_hAvatars[i].avatar:Remove()
				end
			end
			m_hAvatars = {}
		end
		
		if (PDA.CurrentTab == 6) then
			if (m_hMyLocalAvatar != nil) then
				m_hMyLocalAvatar:Remove()
				m_hMyLocalAvatar = nil
			end
		end
	end
	
    if (!PDA.Open) then return end

    local sw, sh = ScrW(), ScrH()
    PX = math.floor((sw - PW) / 2)
    PY = math.floor((sh - PH) / 2)

    -- Внешняя рамка КПК
    draw.RoundedBox(10, PX-BORDER,      PY-BORDER-36, PW+BORDER*2, PH+BORDER*2+36+TAB_H, COLOR_FRAME)
    draw.RoundedBox(8,  PX-BORDER+4,    PY-BORDER-32, PW+BORDER*2-8, PH+BORDER*2+28+TAB_H, COLOR_BG)

    -- Заголовок
    draw.RoundedBox(4, PX, PY-32, PW, 30, COLOR_HEADER)
    draw.SimpleText("КПК / ЛИЧНЫЙ ПОМОЩНИК", "PDA_Header",
        PX + PW/2, PY-17, COLOR_TAB_ACT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(os.date("%H:%M  %d/%m/%Y"), "PDA_Small",
        PX+PW-6, PY-17, COLOR_TEXT_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    -- Вкладки (снизу)
    local tabW = PW / #PDA.Tabs
    for i, name in ipairs(PDA.Tabs) do
        local tx  = PX + (i-1)*tabW
        local ty  = PY + PH
        local act = (PDA.CurrentTab == i)
        local col = act and COLOR_TAB_ACT or COLOR_TAB_INACT
        draw.RoundedBox(3, tx+1, ty+1, tabW-2, TAB_H-2, COLOR_HEADER)
        if act then
            -- подсветка активной вкладки сверху
            surface.SetDrawColor(COLOR_TAB_ACT)
            surface.DrawRect(tx+1, ty+1, tabW-2, 3)
        end
        draw.SimpleText(name, "PDA_Tab",
            tx + tabW/2, ty + TAB_H/2, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    -- Контентная область
    draw.RoundedBox(4, PX, PY, PW, PH, COLOR_PANEL)

    -- Забираем накопленные клики
    local clicks = clickQueue
    clickQueue   = {}

    -- Клики по вкладкам
    for _, cl in ipairs(clicks) do
        local ty = PY + PH
        for i = 1, #PDA.Tabs do
            local tx = PX + (i-1)*tabW
            if ClickIn(cl, tx, ty, tabW, TAB_H) then
                PDA.CurrentTab = i
            end
        end
    end

    -- Рисуем нужную вкладку
    local t = PDA.CurrentTab
    if     t == 1 then DrawTabTasks(clicks)
    elseif t == 2 then DrawTabPlan()
    elseif t == 3 then DrawTabJournal(clicks)
    elseif t == 4 then DrawTabContacts(clicks)
    elseif t == 5 then DrawTabRanks(clicks)
    elseif t == 6 then DrawTabData(clicks)
    end
	
	if (PDA.CurrentTab != 5) then
		for i = 1, #m_hAvatars do
			if (m_hAvatars[i] != nil && m_hAvatars[i].avatar != nil) then
				m_hAvatars[i].avatar:Remove()
			end
		end
		m_hAvatars = {}
	end
	
	if (PDA.CurrentTab != 6) then
		if (m_hMyLocalAvatar != nil) then
			m_hMyLocalAvatar:Remove()
			m_hMyLocalAvatar = nil
		end
	end
end)

-- ============================================================
-- TAB 1 — ЗАДАЧИ
-- ============================================================
function DrawTabTasks(clicks)
    local leftW = 380
    local cx, cy = PX, PY

    -- Разделитель
    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(cx+leftW, cy, 1, PH)

    -- Список задач
    local itemH  = 140
    local listH  = PH
    local maxOff = math.max(0, #PDA.Tasks * itemH - listH)
    PDA.TaskScrollOffset = math.Clamp(PDA.TaskScrollOffset, 0, maxOff)

    Scissor(cx, cy, leftW - SCROLL_W, listH, function()
        for i, task in ipairs(PDA.Tasks) do
			
            local iy  = cy + (i-1)*itemH - PDA.TaskScrollOffset
            if iy+itemH < cy or iy > cy+listH then continue end

            local sel    = (PDA.SelectedTask == i)
            local hov    = IsHovered(cx, iy, leftW-SCROLL_W, itemH)
            local bgCol  = sel and COLOR_ITEM_SEL or (hov and COLOR_ITEM_HOV or COLOR_PANEL)
            draw.RoundedBox(0, cx, iy, leftW-SCROLL_W, itemH, bgCol)

            -- Иконка задачи
			if (task.icon != nil && !task.icon:IsError()) then
				surface.SetDrawColor(color_white)
				surface.SetMaterial(task.icon)
				surface.DrawTexturedRect(cx+8, iy+8, 70, 58)
			else
            draw.RoundedBox(3, cx+8, iy+8, 70, 58, COLOR_HEADER)
            draw.SimpleText("?", "PDA_Huge", cx+43, iy+37,
                COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

            -- Заголовок и дата
            draw.SimpleText(task.title, "PDA_Body",
                cx+86, iy+8, sel and COLOR_TAB_ACT or COLOR_TEXT,
                TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
            draw.SimpleText(task.date, "PDA_Small",
                cx+86, iy+26, COLOR_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

            -- Этапы выполнения
            local sy = iy + 44
            for _, step in ipairs(task.steps) do
                if sy > iy+itemH-4 then break end
                local dot = step.done and "●" or "○"
                local sc  = step.done and COLOR_GREEN or COLOR_TEXT_DIM
                draw.SimpleText(dot.." "..step.text, "PDA_Small",
                    cx+86, sy, sc, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                sy = sy + 15
            end

            -- Кнопка «i»
            local btnX = cx+leftW-SCROLL_W-26
            local btnY = iy+6
            draw.RoundedBox(4, btnX, btnY, 20, 20, COLOR_HEADER)
            draw.SimpleText("i", "PDA_Body",
                btnX+10, btnY+10, COLOR_TAB_ACT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            -- Разделитель
            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawRect(cx, iy+itemH-1, leftW-SCROLL_W, 1)

            -- Обработка кликов
            for _, cl in ipairs(clicks) do
                if ClickIn(cl, cx, iy, leftW-SCROLL_W, itemH) then
                    PDA.SelectedTask = i
                    if ClickIn(cl, btnX, btnY, 20, 20) then
                        PDA.ShowTaskDesc = not PDA.ShowTaskDesc
                    else
                        PDA.ShowTaskDesc = false
                    end
                end
            end
        end
    end)

    DrawScrollbar(cx+leftW-SCROLL_W, cy, SCROLL_W, listH,
              PDA.TaskScrollOffset, maxOff, "tasks", clicks)

    -- Правая панель
    local rx = cx+leftW+1
    local rw = PW-leftW-1

	-- Если нажали на кнопку i возле задания, отображаем подробную инфу о задании. По умолчанию отображаем карту
    if PDA.ShowTaskDesc and PDA.SelectedTask then
        local task = PDA.Tasks[PDA.SelectedTask]
        draw.RoundedBox(0, rx, cy, rw, PH, COLOR_HEADER)
        draw.SimpleText("Детальная информация о задании", "PDA_Small",
            rx+8, cy+8, COLOR_TEXT_DIM)

        local wrapped = WrapText(task.desc, "PDA_Body", rw-20)
        local ty = cy + 28
        for _, line in ipairs(wrapped) do
            draw.SimpleText(line, "PDA_Body", rx+10, ty, COLOR_TEXT)
            ty = ty + 18
        end
    else
        DrawMiniMap(rx, cy, rw, PH)
    end
end

-- ============================================================
-- TAB 2 — ПЛАН
-- ============================================================
function DrawTabPlan()
    DrawMiniMap(PX, PY, PW, PH)
end

-- ============================================================
-- TAB 3 — ЖУРНАЛ
-- ============================================================
function DrawTabJournal(clicks)
    local leftW = 280

    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(PX+leftW, PY, 1, PH)

    -- Плоский список групп и заметок
    local items = {}
    for gi, group in ipairs(PDA.Journal) do
        table.insert(items, {type="group", group=group, gi=gi})
        if group.open then
            for ni, note in ipairs(group.notes) do
                table.insert(items, {type="note", note=note, gi=gi, ni=ni})
            end
        end
    end

    local itemH  = 24
    local listH  = PH
    local maxOff = math.max(0, #items * itemH - listH + 10)
    PDA.JournalScrollOff = math.Clamp(PDA.JournalScrollOff, 0, maxOff)

    Scissor(PX, PY, leftW-SCROLL_W, listH, function()
        for idx, item in ipairs(items) do
            local iy = PY + (idx-1)*itemH - PDA.JournalScrollOff
            if iy+itemH < PY or iy > PY+listH then continue end

            if item.type == "group" then
                local arrow = item.group.open and "▾ " or "▸ "
                draw.SimpleText(arrow..item.group.group, "PDA_Body",
                    PX+8, iy+4, COLOR_TAB_ACT)

                for _, cl in ipairs(clicks) do
                    -- Клик по строке группы
                    if ClickIn(cl, PX, iy, leftW-SCROLL_W, itemH) then
                        item.group.open = not item.group.open
                        PDA.SelectedNote = nil
                    end
                end
            else
                local sel = PDA.SelectedNote and
                            PDA.SelectedNote.gi == item.gi and
                            PDA.SelectedNote.ni == item.ni
                local hov = IsHovered(PX, iy, leftW-SCROLL_W, itemH)
                if sel then draw.RoundedBox(0, PX, iy, leftW-SCROLL_W, itemH, COLOR_ITEM_SEL) end
                if hov and not sel then draw.RoundedBox(0, PX, iy, leftW-SCROLL_W, itemH, COLOR_ITEM_HOV) end

                draw.SimpleText("   "..item.note.title, "PDA_Small",
                    PX+20, iy+5, COLOR_GREEN)

                for _, cl in ipairs(clicks) do
                    if ClickIn(cl, PX, iy, leftW-SCROLL_W, itemH) then
                        PDA.SelectedNote = item
                    end
                end
            end
        end
    end)

    DrawScrollbar(PX+leftW-SCROLL_W, PY, SCROLL_W, listH,
              PDA.JournalScrollOff, maxOff, "journal", clicks)

    -- Правая панель: текст заметки
    local rx = PX+leftW+1
    local rw = PW-leftW-1
    if PDA.SelectedNote then
        local note    = PDA.SelectedNote.note
        local wrapped = WrapText(note.text, "PDA_Body", rw-20)
        local ty = PY+12
        draw.SimpleText(note.title, "PDA_Header", rx+10, ty, COLOR_TAB_ACT)
        ty = ty + 24
        for _, line in ipairs(wrapped) do
            draw.SimpleText(line, "PDA_Body", rx+10, ty, COLOR_TEXT)
            ty = ty + 18
        end
    else
        draw.SimpleText("Выберите заметку", "PDA_Body",
            rx+rw/2, PY+PH/2, COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- ============================================================
-- TAB 4 — КОНТАКТЫ
-- ============================================================
function DrawTabContacts(clicks)
    local npcs = {}
    local ply  = LocalPlayer()
    local pos  = ply:GetPos()
	
	--TODO: Заменить на MM.NpcRange
	local flDistSqr = 1200 * 1200
	
	for _, ent in ents.Iterator() do
		if (IsValid(ent) && (ent:IsNPC() || ent:IsPlayer())) then
			if (ent:GetPos():DistToSqr(pos) > flDistSqr) then continue end
			--Если не появляются на мини-карте, значит в контактах не нужно оторбражать, логично?
			if (ent:IsPlayer() && !CStalkerCore:ShowPlayerInMinimap(ent, LocalPlayer())) then continue end
			
			table.insert(npcs, ent)
		end
	end

    local leftW = 360
    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(PX+leftW, PY, 1, PH)

    local itemH  = 76
    local listH  = PH
    local maxOff = math.max(0, #npcs*itemH - listH)
    PDA.ContactScroll = math.Clamp(PDA.ContactScroll, 0, maxOff)

    Scissor(PX, PY, leftW-SCROLL_W, listH, function()
        if #npcs == 0 then
            draw.SimpleText("Контакты не обнаружены", "PDA_Body",
                PX+leftW/2, PY+PH/2, COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            return
        end
        for i, npc in ipairs(npcs) do
            local iy  = PY + (i-1)*itemH - PDA.ContactScroll
            if iy+itemH < PY or iy > PY+listH then continue end

            local sel   = (PDA.SelectedContact == i)
            local hov   = IsHovered(PX, iy, leftW-SCROLL_W, itemH)
            draw.RoundedBox(0, PX, iy, leftW-SCROLL_W, itemH,
                sel and COLOR_ITEM_SEL or (hov and COLOR_ITEM_HOV or COLOR_PANEL))

            -- Аватар NPC
			-- TODO: Прикрутить систему аватаров игроков и нпс
			-- Если какой нибудь нпс исчезнет из поле зрения, то все собьется, аватары будут отображаться на прежних позициях из-за особенностей vgui
			-- Поэтому нам нужно ввести учет как с MM.OnlineContacts или типа того, если количество изменилось, удаляем ВСЕ аватарки и заново создаем
			-- Удалять все аватарки и создаать с нуля, конечно, такая себе идея. Но мне в падлу делать более умную систему
			if (npc.m_iCustomAvatar) then
				--Индекс вместо хранения материала чтобы избежать утечек памяти кастомных иконок которых нет в ресурсах, и тд и тп
				--С помощь индекса мы проходимся по всем иконкам в классе-ресурсе
			else
				draw.RoundedBox(3, PX+8, iy+8, 54, 44, COLOR_HEADER)
				draw.SimpleText("NPC", "PDA_Small", PX+35, iy+30,
					COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end

            -- Статус-точка
			-- TODO: Придумать фичу с этим
            surface.SetDrawColor(COLOR_GREEN)
            surface.DrawRect(PX+68, iy+10, 9, 9)

            -- Имя
			if (npc:IsPlayer()) then
				draw.SimpleText(npc:Nick(), "PDA_Body", PX+82, iy+8, COLOR_TEXT)
			else
				draw.SimpleText(npc:GetClass(), "PDA_Body", PX+82, iy+8, COLOR_TEXT)
			end

            -- Инфо
            local ry = iy+26
            for _, row in ipairs({{"группа","неизвестна"},{"отношение","нейтрал"},{"ранг","новичок"}}) do
                draw.SimpleText(row[1], "PDA_Small", PX+82, ry, COLOR_TEXT_DIM)
                draw.SimpleText(row[2], "PDA_Small", PX+160, ry, COLOR_TEXT)
                ry = ry + 14
            end

            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawRect(PX, iy+itemH-1, leftW-SCROLL_W, 1)

            for _, cl in ipairs(clicks) do
                if ClickIn(cl, PX, iy, leftW-SCROLL_W, itemH) then
                    PDA.SelectedContact = i
                end
            end
        end
    end)

    DrawScrollbar(PX+leftW-SCROLL_W, PY, SCROLL_W, listH,
              PDA.ContactScroll, maxOff, "contacts", clicks)

    -- Правая панель
    local rx = PX+leftW+1
    local rw = PW-leftW-1
    if PDA.SelectedContact and npcs[PDA.SelectedContact] then
        local npc = npcs[PDA.SelectedContact]
        draw.RoundedBox(3, rx+12, PY+12, 110, 90, COLOR_HEADER)
        draw.SimpleText("NPC", "PDA_Body", rx+67, PY+57,
            COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(npc:GetClass(), "PDA_Header", rx+132, PY+22, COLOR_TEXT)
    else
        draw.SimpleText("Выберите контакт", "PDA_Body",
            rx+rw/2, PY+PH/2, COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- ============================================================
-- TAB 5 — РАНГИ
-- ============================================================
function DrawTabRanks(clicks)
    local players = player.GetAll()
    local leftW   = 320

    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(PX+leftW, PY, 1, PH)

    local itemH  = 42
    local listH  = PH
    local maxOff = math.max(0, #players*itemH - listH)
    PDA.RankScroll = math.Clamp(PDA.RankScroll, 0, maxOff)

    Scissor(PX, PY, leftW-SCROLL_W, listH, function()
        for i, p in ipairs(players) do
            local iy  = PY + (i-1)*itemH - PDA.RankScroll
            if iy+itemH < PY or iy > PY+listH then continue end

            local sel = (PDA.SelectedRankPlayer == i)
            local hov = IsHovered(PX, iy, leftW-SCROLL_W, itemH)
            draw.RoundedBox(0, PX, iy, leftW-SCROLL_W, itemH,
                sel and COLOR_ITEM_SEL or (hov and COLOR_ITEM_HOV or COLOR_PANEL))

            -- Аватар
			-- FIXME: Реализация такое себе, нужно удалять вручную, может есть вариант получше?
			if (!HasAvatar(p:EntIndex())) then
				local Avatar = vgui.Create("AvatarImage")
				Avatar:SetSize(32, 32)
				Avatar:SetPos(PX+6, iy+5)
				Avatar:SetPlayer(p, 32)
				table.insert(m_hAvatars, { id = p:EntIndex(), avatar = Avatar, userid = p:UserID() })
			end
			
			-- Аватар (первая буква ника)
            --draw.RoundedBox(3, PX+6, iy+5, 32, 32, COLOR_HEADER)
            --draw.SimpleText(string.sub(p:Nick(),1,1), "PDA_Body",
            --    PX+22, iy+21, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

            draw.SimpleText(p:Nick(),     "PDA_Body",  PX+44, iy+6,  COLOR_TEXT)
            draw.SimpleText("ранг: новичок","PDA_Small",PX+44, iy+22, COLOR_TEXT_DIM)

            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawRect(PX, iy+itemH-1, leftW-SCROLL_W, 1)

            for _, cl in ipairs(clicks) do
                if ClickIn(cl, PX, iy, leftW-SCROLL_W, itemH) then
                    PDA.SelectedRankPlayer = i
                end
            end
        end
    end)

    DrawScrollbar(PX+leftW-SCROLL_W, PY, SCROLL_W, listH,
              PDA.RankScroll, maxOff, "ranks", clicks)

    -- Правая панель
    local rx = PX+leftW+1
    local rw = PW-leftW-1
    if PDA.SelectedRankPlayer and players[PDA.SelectedRankPlayer] then
        local p  = players[PDA.SelectedRankPlayer]
        local ay = PY+24
        draw.RoundedBox(3, rx+12, ay, 100, 100, COLOR_HEADER)
        draw.SimpleText(string.sub(p:Nick(),1,2), "PDA_Huge",
            rx+62, ay+50, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

        local infoX = rx+122
        local ry    = ay+10
        for _, row in ipairs({
            {"Игрок",     p:Nick()},
            {"Ранг",      "новичок"},
            {"Группа",    "Одиночка"},
            {"Репутация", "нейтрал"},
            {"Отношение", "нейтрал"},
        }) do
            draw.SimpleText(row[1], "PDA_Small", infoX,    ry, COLOR_TEXT_DIM)
            draw.SimpleText(row[2], "PDA_Body",  infoX+100, ry, COLOR_TEXT)
            ry = ry + 22
        end
    else
        draw.SimpleText("Выберите игрока", "PDA_Body",
            rx+rw/2, PY+PH/2, COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

-- ============================================================
-- TAB 6 — ДАННЫЕ
-- ============================================================
function DrawTabData(clicks)
    local leftW = 340

    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(PX+leftW, PY, 1, PH)

    -- Левая панель: карточка игрока
	
	-- Аватар
    local ply = LocalPlayer()
	
	if (m_hMyLocalAvatar == nil) then
		local Avatar = vgui.Create("AvatarImage")
		Avatar:SetSize(90, 90)
		Avatar:SetPos(PX+12, PY+12)
		Avatar:SetPlayer(ply, 64)
		m_hMyLocalAvatar = Avatar
	end
    -- draw.RoundedBox(3, PX+12, PY+12, 90, 90, COLOR_HEADER)
    -- draw.SimpleText(string.sub(ply:Nick(),1,2), "PDA_Huge",
        -- PX+57, PY+57, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    draw.SimpleText(ply:Nick(), "PDA_Header", PX+112, PY+16, COLOR_TEXT)

    local ry = PY+40
    for _, row in ipairs({{"Ранг","ветеран"},{"Группа","Одиночка"},{"Репутация","отлично"}}) do
        draw.SimpleText(row[1], "PDA_Small", PX+112, ry, COLOR_TEXT_DIM)
        draw.SimpleText(row[2], "PDA_Small", PX+210, ry, COLOR_TEXT)
        ry = ry + 18
    end

    -- Статистика
    draw.SimpleText("Статистика", "PDA_Header", PX+12, PY+114, COLOR_TAB_ACT)
    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(PX+12, PY+132, leftW-24, 1)

    local sy = PY+140
    for _, row in ipairs({
        {"Убийство сталкеров", PDA.Stats.npc_kills},
        {"Убийство мутантов",  PDA.Stats.mutant_kills},
        {"Выполненные квесты", PDA.Stats.quests_done},
        {"Всего",              PDA.Stats.npc_kills + PDA.Stats.mutant_kills},
    }) do
        draw.SimpleText(row[1], "PDA_Body", PX+12, sy, COLOR_TEXT)
        draw.SimpleText(tostring(row[2]), "PDA_Body",
            PX+leftW-14, sy, COLOR_YELLOW, TEXT_ALIGN_RIGHT)
        sy = sy + 24
    end

    -- Правая панель: список убийств
    local rx     = PX+leftW+1
    local rw     = PW-leftW-1
    local itemH  = 22
    local listH  = PH-34
    local maxOff = math.max(0, #PDA.Stats.kill_list*itemH - listH)
    PDA.StatsKillScroll = math.Clamp(PDA.StatsKillScroll, 0, maxOff)

    draw.SimpleText("Убийство сталкеров", "PDA_Header",
        rx+rw/2, PY+10, COLOR_TAB_ACT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(rx, PY+30, rw, 1)

    Scissor(rx, PY+32, rw-SCROLL_W, listH, function()
        for i, row in ipairs(PDA.Stats.kill_list) do
            local iy  = PY+32 + (i-1)*itemH - PDA.StatsKillScroll
            local hov = IsHovered(rx, iy, rw-SCROLL_W, itemH)
            if hov then draw.RoundedBox(0, rx, iy, rw-SCROLL_W, itemH, COLOR_ITEM_HOV) end

            draw.SimpleText(tostring(i-1)..".", "PDA_Small",
                rx+8, iy+4, COLOR_TEXT_DIM)
            draw.SimpleText(row.name, "PDA_Small",
                rx+32, iy+4, COLOR_TEXT)
            draw.SimpleText("x"..row.mult, "PDA_Small",
                rx+rw-SCROLL_W-68, iy+4, COLOR_TEXT_DIM, TEXT_ALIGN_RIGHT)
            draw.SimpleText(tostring(row.total), "PDA_Small",
                rx+rw-SCROLL_W-8, iy+4, COLOR_YELLOW, TEXT_ALIGN_RIGHT)
        end
    end)

    DrawScrollbar(rx+rw-SCROLL_W, PY+32, SCROLL_W, listH,
              PDA.StatsKillScroll, maxOff, "stats", clicks)
end

-- ============================================================
-- КОЛЕСО МЫШИ
-- ============================================================
hook.Add("VGUIMouseWheeled", "StalkerPDA_Scroll", function(delta)
    if not PDA.Open then return end
    local speed = 36
    local t     = PDA.CurrentTab
    if     t == 1 then PDA.TaskScrollOffset  = PDA.TaskScrollOffset  - delta*speed
    elseif t == 3 then PDA.JournalScrollOff  = PDA.JournalScrollOff  - delta*speed
    elseif t == 4 then PDA.ContactScroll     = PDA.ContactScroll     - delta*speed
    elseif t == 5 then PDA.RankScroll        = PDA.RankScroll        - delta*speed
    elseif t == 6 then PDA.StatsKillScroll   = PDA.StatsKillScroll   - delta*speed
    end
end)

-- ============================================================
-- ОТКРЫТИЕ / ЗАКРЫТИЕ КПК
-- ============================================================
hook.Add("PlayerButtonDown", "StalkerPDA_Toggle", function(ply, btn)
    if ply ~= LocalPlayer() then return end
	
	local iKey = KEY_M --KEY_F4
	
	if (GetConVar("cl_stalker_pda_keycode") && GetConVar("cl_stalker_pda_keycode"):GetString() != "") then
		local iKey2 = input.GetKeyCode(GetConVar("cl_stalker_pda_keycode"):GetString())
		if (iKey2 != 0) then
			iKey = iKey2
		end
	end
	
	if (GetConVar("sv_stalker_pda_mode") && GetConVar("sv_stalker_pda_mode"):GetInt() == 1) then
		if (!LocalPlayer():GetNWBool("m_bHasPDA")) then
			PDA.Open = false
			gui.EnableScreenClicker(false)
			return
		end
	end
	
    if btn == iKey then
        PDA.Open = not PDA.Open
        gui.EnableScreenClicker(PDA.Open)
        if PDA.Open then PDA.CurrentTab = 1 end
    end
end)

gameevent.Listen( "player_disconnect" )
hook.Add("player_disconnect", "Stalker_PDA_PlayerDisconnect", function( data )
	local name = data.name			// Same as Player:Nick()
	local steamid = data.networkid	// Same as Player:SteamID()
	local id = data.userid			// Same as Player:UserID()
	local bot = data.bot			// Same as Player:IsBot(), returns a integer 0 for players, 1 for bot
	local reason = data.reason		// Text reason for disconnected such as "Kicked by console!", "Timed out!", etc...
	
	--Если какой нибудь игрок отключился во время просмотра рангов, мы пересоздаем все аватары
	for i = 1, #m_hAvatars do
		if (m_hAvatars[i] != nil && m_hAvatars[i].avatar != nil) then
			m_hAvatars[i].avatar:Remove()
		end
	end
	m_hAvatars = {}
end )