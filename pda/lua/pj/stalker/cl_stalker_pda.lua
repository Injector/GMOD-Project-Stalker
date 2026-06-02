-- ============================================================
-- STALKER PDA
-- ============================================================

PDA = {}
PDA.Open        = false
PDA.CurrentTab  = 1
PDA.Tabs        = {"Задачи", "План", "Журнал", "Контакты", "Ранги", "Данные"}

PDA.Markers = {}
PDA.Markers.Stashes = {}

local COLOR_BG        = Color(15, 15, 15, 245)
local COLOR_FRAME     = Color(60, 60, 60, 255)
local COLOR_PANEL     = Color(25, 25, 25, 255)
local COLOR_HEADER    = Color(35, 35, 35, 255)
local COLOR_TAB_ACT   = Color(180, 140, 30, 255)
local COLOR_TAB_INACT = Color(100, 100, 100, 255)
local COLOR_TEXT      = Color(200, 200, 200, 255)
local COLOR_TEXT_DIM  = Color(120, 120, 120, 255)
local COLOR_GREEN     = Color(80, 200, 80, 255)
local COLOR_YELLOW    = Color(200, 180, 50, 255)
local COLOR_BORDER    = Color(80, 80, 80, 255)
local COLOR_SCROLLBAR = Color(60, 60, 60, 255)
local COLOR_ITEM_HOV  = Color(40, 40, 40, 255)
local COLOR_ITEM_SEL  = Color(50, 45, 15, 255)

local COLOR_ATTITUDE_GREEN = Color(0, 255, 0, 255)
local COLOR_ATTITUDE_RED = Color(255, 0, 0, 255)
local COLOR_ATTITUDE_NEUTRAL = Color(200, 200, 200, 255)

local PW, PH   = 1100, 680
local PX, PY   = 0, 0
local BORDER   = 20
local TAB_H    = 32
local SCROLL_W = 12

-- ============================================================
-- FONTS
-- ============================================================
surface.CreateFont("PDA_Title",  {font="Trebuchet MS", size=24, weight=700})
surface.CreateFont("PDA_Tab",    {font="Trebuchet MS", size=16, weight=600})
surface.CreateFont("PDA_Body",   {font="Trebuchet MS", size=15, weight=400})
surface.CreateFont("PDA_Small",  {font="Trebuchet MS", size=13, weight=400})
surface.CreateFont("PDA_Header", {font="Trebuchet MS", size=17, weight=700})
surface.CreateFont("PDA_Huge",   {font="Trebuchet MS", size=26, weight=700})
surface.CreateFont("MAP_Font_S", {font="Trebuchet MS", size=13, weight=400})
surface.CreateFont("MAP_Font_M", {font="Trebuchet MS", size=16, weight=400})
surface.CreateFont("MAP_Font_L", {font="Trebuchet MS", size=20, weight=400})

-- ============================================================
-- MAP ZOOM / PAN
-- ============================================================
local TEX_SIZE           = 1024
local MAP_ZOOM_MIN_TASKS = 680  / TEX_SIZE
local MAP_ZOOM_MIN_PLAN  = 1100 / TEX_SIZE
local MAP_ZOOM_MAX       = 5.0

PDA.MapZoomTasks = MAP_ZOOM_MIN_TASKS
PDA.MapZoomPlan  = MAP_ZOOM_MIN_PLAN
PDA.MapPanTasks  = {x=0, y=0}
PDA.MapPanPlan   = {x=0, y=0}
PDA.MapSyncTasks = false
PDA.MapSyncPlan  = false
PDA.MapFullTasks = false
PDA.MapFullPlan  = false

-- 

local CD_HT = 1
local CD_LI = 3

local function GetMapFont(zoom, zoomMin)
    local t = math.Clamp((zoom - zoomMin) / (MAP_ZOOM_MAX - zoomMin), 0, 1)
    if     t < 0.33 then return "MAP_Font_S"
    elseif t < 0.66 then return "MAP_Font_M"
    else                  return "MAP_Font_L" end
end

local function GetIconScaleAdd(zoom, zoomMin)
    local t = math.Clamp((zoom - zoomMin) / (MAP_ZOOM_MAX - zoomMin), 0, 1)
    if     t < 0.33 then return 0
    elseif t < 0.66 then return 4
    else                  return 10 end
end

-- ============================================================
-- MAP DRAG STATE
-- ============================================================
local MapDrag = {
    active=false, target="tasks",
    startMX=0, startMY=0,
    startPanX=0, startPanY=0
}

-- ============================================================
-- SCROLLBAR DRAG STATE
-- ============================================================
local SB = {
    active=false, target=nil,
    startY=0, startOff=0, maxOff=0,
    barY=0, barH=0, trackY=0, trackH=0
}

-- ============================================================
-- CLICK QUEUE
-- система лкм через Think, чтобы исправить проблему GUIMousePressed (иногда клик может не срабатывать)
-- clickQueue очищаются в HUDPaint
-- ============================================================
local clickQueue = {}
local prevDown   = false

hook.Add("Think", "StalkerPDA_InputThink", function()
    if not PDA.Open then
        prevDown       = false
        SB.active      = false
        MapDrag.active = false
        return
    end

    local down   = input.IsMouseDown(MOUSE_LEFT)
    local mx, my = gui.MousePos()

    if down and not prevDown then
        table.insert(clickQueue, {x=mx, y=my})
    end

    if not down then
        SB.active      = false
        MapDrag.active = false
    end

    -- Scrollbar drag
    if SB.active and down then
        local delta       = my - SB.startY
        local trackUsable = SB.trackH - SB.barH
        if trackUsable > 0 then
            local newOff = math.Clamp(SB.startOff + delta * (SB.maxOff / trackUsable), 0, SB.maxOff)
            if     SB.target == "tasks"    then PDA.TaskScrollOffset = newOff
            elseif SB.target == "journal"  then PDA.JournalScrollOff = newOff
            elseif SB.target == "contacts" then PDA.ContactScroll    = newOff
            elseif SB.target == "ranks"    then PDA.RankScroll       = newOff
            elseif SB.target == "stats"    then PDA.StatsKillScroll  = newOff
            end
        end
    end

    -- Map drag
    if MapDrag.active and down then
        local tgt  = MapDrag.target
        local zoom = (tgt == "tasks") and PDA.MapZoomTasks or PDA.MapZoomPlan
        local zmin = (tgt == "tasks") and MAP_ZOOM_MIN_TASKS or MAP_ZOOM_MIN_PLAN
        local pan  = (tgt == "tasks") and PDA.MapPanTasks or PDA.MapPanPlan
        local full = (tgt == "tasks") and PDA.MapFullTasks or PDA.MapFullPlan

        if full then return end

        local dX = mx - MapDrag.startMX
        local dY = my - MapDrag.startMY

        -- При минимальном зуме - только вертикаль
        if zoom <= zmin + 0.001 then dX = 0 end

        -- Сохраняем без ограничений - ограничения применяются при рендере
        pan.x = MapDrag.startPanX + dX
        pan.y = MapDrag.startPanY + dY
    end

    prevDown = down
end)

-- ============================================================
-- MOUSE WHEEL
-- ============================================================
local pendingWheel = 0

-- FIXME: Не работает когда активен vgui, что StartCommand что StartMove
-- hook.Add("StartCommand", "StalkerPDA_WheelCapture", function(ply, cmd)
    -- if not PDA.Open then return end
    -- local w = cmd:GetMouseWheel()
    -- if w ~= 0 then pendingWheel = w end
-- end)

hook.Add("Think", "StalkerPDA_WheelProcess", function()
    if not PDA.Open or pendingWheel == 0 then return end
    local delta = pendingWheel
    pendingWheel = 0

    local mx2, my2    = gui.MousePos()
    local t           = PDA.CurrentTab
    local leftW_tasks = 380
    local mapRX       = PX + leftW_tasks + 1
    local mapRW       = PW - leftW_tasks - 1

    local overTasks = t==1 and not PDA.ShowTaskDesc
        and mx2>=mapRX and mx2<=mapRX+mapRW
        and my2>=PY    and my2<=PY+PH

    local overPlan = t==2
        and mx2>=PX and mx2<=PX+PW
        and my2>=PY and my2<=PY+PH

    if overTasks and not PDA.MapFullTasks then
        PDA.MapZoomTasks = math.Clamp(
            PDA.MapZoomTasks + delta * PDA.MapZoomTasks * 0.12,
            MAP_ZOOM_MIN_TASKS, MAP_ZOOM_MAX)
        return
    end

    if overPlan and not PDA.MapFullPlan then
        PDA.MapZoomPlan = math.Clamp(
            PDA.MapZoomPlan + delta * PDA.MapZoomPlan * 0.12,
            MAP_ZOOM_MIN_PLAN, MAP_ZOOM_MAX)
        return
    end

    local speed = 36
    if     t==1 then PDA.TaskScrollOffset = PDA.TaskScrollOffset - delta*speed
    elseif t==3 then PDA.JournalScrollOff = PDA.JournalScrollOff - delta*speed
    elseif t==4 then PDA.ContactScroll    = PDA.ContactScroll    - delta*speed
    elseif t==5 then PDA.RankScroll       = PDA.RankScroll       - delta*speed
    elseif t==6 then PDA.StatsKillScroll  = PDA.StatsKillScroll  - delta*speed
    end
end)

PDA.SelectedKillList = 1

-- ============================================================
-- TASKS DATA
-- ============================================================
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
PDA.Journal = {
	{ id = 1, group = "Личные заметки", open = false, notes = {} },
	{ id = 2, group = "Найденные КПК", open = false, notes = {} },
	{ id = 3, group = "Операция Агропром", open = false, notes = {} },
	{ id = 4, group = "Информация из X-18", open = false, notes = {} },
}
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
    kill_list = {},
	kill_mutant_list = {},
	quests_done_list = {},
}
PDA.StatsKillScroll    = 0
PDA.SelectedRankPlayer = nil
PDA.RankScroll         = 0
PDA.ContactScroll      = 0
PDA.SelectedContact    = nil

PDA.ContactsOnline = 0

-- ============================================================
-- HELPERS
-- ============================================================
local function IsHovered(x, y, w, h)
    local mx, my = gui.MousePos()
    return mx>=x and mx<=x+w and my>=y and my<=y+h
end

local function Scissor(x, y, w, h, fn)
    render.SetScissorRect(x, y, x+w, y+h, true)
    fn()
    render.SetScissorRect(0, 0, 0, 0, false)
end

local function WrapText(text, font, maxW)
    surface.SetFont(font)
    local lines, line = {}, ""
    for _, word in ipairs(string.Explode(" ", text)) do
        local test = line=="" and word or (line.." "..word)
        if surface.GetTextSize(test) > maxW and line ~= "" then
            table.insert(lines, line); line = word
        else line = test end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

local function ClickIn(cl, x, y, w, h)
    return cl.x>=x and cl.x<=x+w and cl.y>=y and cl.y<=y+h
end

local m_hAvatars = {}
local m_hMyLocalAvatar = nil
local m_hAvatarsContacts = {}

local function HasAvatar(tbl, index)
	for i = 1, #tbl do
		if (tbl[i].id == index) then return true end
	end
	
	return false
end

-- ============================================================
-- SCROLLBAR
-- ============================================================
local function DrawScrollbar(x, y, w, h, offset, maxOff, target, clicks)
    draw.RoundedBox(2, x, y, w, h, COLOR_SCROLLBAR)
    if maxOff <= 0 then return end

    local ratio = h / (h + maxOff)
    local barH  = math.max(24, h * ratio)
    local barY  = y + (offset / maxOff) * (h - barH)

    local hov    = IsHovered(x, barY, w, barH)
    local drag   = SB.active and SB.target == target
    local barCol = (drag or hov) and Color(220,170,50,255) or COLOR_TAB_ACT
    draw.RoundedBox(2, x+1, barY, w-2, barH, barCol)

    if clicks and target then
        for _, cl in ipairs(clicks) do
            if ClickIn(cl, x, y, w, h) then
                if cl.y >= barY and cl.y <= barY+barH then
                    SB.active   = true
                    SB.target   = target
                    SB.startY   = cl.y
                    SB.startOff = offset
                    SB.maxOff   = maxOff
                    SB.trackY   = y
                    SB.trackH   = h
                    SB.barY     = barY
                    SB.barH     = barH
                else
                    local usable = h - barH
                    if usable > 0 then
                        local rel    = (cl.y - y - barH/2) / usable
                        local newOff = math.Clamp(rel * maxOff, 0, maxOff)
                        if     target=="tasks"    then PDA.TaskScrollOffset = newOff
                        elseif target=="journal"  then PDA.JournalScrollOff = newOff
                        elseif target=="contacts" then PDA.ContactScroll    = newOff
                        elseif target=="ranks"    then PDA.RankScroll       = newOff
                        elseif target=="stats"    then PDA.StatsKillScroll  = newOff
                        end
                    end
                end
            end
        end
    end
end

-- ============================================================
-- MAP DATA LOADING
-- ============================================================
local mapMaterial   = nil
local mapDataLoaded = false

local function LoadMapData()
    if mapDataLoaded then return end
    mapDataLoaded = true
    local name = game.GetMap()
    local mat  = Material("overviews/"..name..".png")
    if not mat:IsError() then mapMaterial = mat end
end

-- ============================================================
-- MAP TOGGLE BUTTONS
-- ============================================================
local function DrawMapToggleButton(x, y, r, active, activeCol, label, clicks)
    local col = active and activeCol or Color(50,50,50,200)
    draw.RoundedBox(99, x-r, y-r, r*2, r*2, col)
    surface.SetDrawColor(120,120,120,180)
    surface.DrawOutlinedRect(x-r, y-r, r*2, r*2, 1)
    draw.SimpleText(label, "MAP_Font_S", x, y,
        Color(255,255,255,220), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    for _, cl in ipairs(clicks) do
        if ClickIn(cl, x-r, y-r, r*2, r*2) then return true end
    end
    return false
end

local function WorldToMap(wx, wy, mx, my, mw, mh, tx, ty, texPx, syncMode, fullMode)

	local pu, pv = 0.5, 0.5
    if CStalkerMapData.pos_x then
        local sc = CStalkerMapData.scale or 1
        pu = (wx - CStalkerMapData.pos_x) / sc / TEX_SIZE
        pv = (wy - CStalkerMapData.pos_y) / sc / TEX_SIZE * -1
    end
	
	--local texPx = TEX_SIZE * zoom
	
	-- ---- Вычисляем позицию текстуры (tx, ty) ----
    -- local tx, ty

    -- if fullMode then
        -- -- Растянуть на всю панель — TexturedRect рисуем с mx,my,mw,mh
        -- tx = mx
        -- ty = my
    -- elseif syncMode then
        -- -- Следуем за игроком, игрок в центре
        -- tx = cx - pu * texPx
        -- ty = cy - pv * texPx
    -- else
        -- -- Свободный пан: базовая позиция как в sync + смещение pan
        -- tx = cx - pu * texPx + panX
        -- ty = cy - pv * texPx + panY

        -- -- При минимальном зуме — горизонтальный пан запрещён
        -- if zoom <= zoomMin + 0.001 then
            -- tx = cx - pu * texPx
        -- end

        -- -- Допустимый диапазон tx: [mx+mw-texPx , mx]
        -- --   левый край текстуры (tx) не правее левого края панели (mx)
        -- --   правый край текстуры (tx+texPx) не левее правого края панели (mx+mw)
        -- if texPx >= mw then
            -- tx = math.Clamp(tx, mx + mw - texPx, mx)
        -- else
            -- -- текстура уже панели — центрируем
            -- tx = mx + (mw - texPx) * 0.5
        -- end

        -- if texPx >= mh then
            -- ty = math.Clamp(ty, my + mh - texPx, my)
        -- else
            -- ty = my + (mh - texPx) * 0.5
        -- end
    -- end

    local markerX, markerY

	if fullMode then
		-- Панель полностью покрыта текстурой (растянутой).
		-- Позиция = UV * размер панели
		markerX = mx + pu * mw
		markerY = my + pv * mh
	elseif syncMode then
		-- Игрок всегда в центре
		markerX = tx + pu * texPx
		markerY = ty + pv * texPx
	else
		-- Позиция = начало текстуры + UV * размер текстуры
		markerX = tx + pu * texPx
		markerY = ty + pv * texPx
	end
	
	return markerX, markerY
end

-- ============================================================
-- MAP RENDERER
-- ============================================================
local function DrawMiniMap(mx, my, mw, mh, zoom, zoomMin, panX, panY, syncMode, fullMode, dragTarget, clicks)
    LoadMapData()

    local ply  = LocalPlayer()
    local wpos = IsValid(ply) and ply:GetPos() or Vector(0,0,0)
    local cx   = mx + mw/2
    local cy   = my + mh/2

    -- UV позиция игрока (0..1) на текстуре карты
    local pu, pv = 0.5, 0.5
    if CStalkerMapData.pos_x then
        local sc = CStalkerMapData.scale or 1
        pu = (wpos.x - CStalkerMapData.pos_x) / sc / TEX_SIZE
        pv = (wpos.y - CStalkerMapData.pos_y) / sc / TEX_SIZE * -1
    end

    -- Размер текстуры в экранных пикселях
    local texPx = TEX_SIZE * zoom

    -- ---- Вычисляем позицию текстуры (tx, ty) ----
    local tx, ty

    if fullMode then
        -- Растянуть на всю панель — TexturedRect рисуем с mx,my,mw,mh
        tx = mx
        ty = my
    elseif syncMode then
        -- Следуем за игроком, игрок в центре
        tx = cx - pu * texPx
        ty = cy - pv * texPx
    else
        -- Свободный пан: базовая позиция как в sync + смещение pan
        tx = cx - pu * texPx + panX
        ty = cy - pv * texPx + panY

        -- При минимальном зуме — горизонтальный пан запрещён
        if zoom <= zoomMin + 0.001 then
            tx = cx - pu * texPx
        end

        -- Допустимый диапазон tx: [mx+mw-texPx , mx]
        --   левый край текстуры (tx) не правее левого края панели (mx)
        --   правый край текстуры (tx+texPx) не левее правого края панели (mx+mw)
        if texPx >= mw then
            tx = math.Clamp(tx, mx + mw - texPx, mx)
        else
            -- текстура уже панели — центрируем
            tx = mx + (mw - texPx) * 0.5
        end

        if texPx >= mh then
            ty = math.Clamp(ty, my + mh - texPx, my)
        else
            ty = my + (mh - texPx) * 0.5
        end
    end

    -- Фон
    draw.RoundedBox(0, mx, my, mw, mh, Color(18,22,18,255))

    render.SetScissorRect(mx, my, mx+mw, my+mh, true)

    if mapMaterial then
        surface.SetDrawColor(255,255,255,255)
        surface.SetMaterial(mapMaterial)
        if fullMode then
            -- Растягиваем всю текстуру на всю панель
            surface.DrawTexturedRect(mx, my, mw, mh)
        else
            surface.DrawTexturedRect(tx, ty, texPx, texPx)
        end
		
		local font = GetMapFont(zoom, zoomMin)
		
		for i, v in ipairs(player.GetAll()) do
			
			-- Для отображения других игроков, должны выполнены ВСЕ условия:
			-- Игрок должен быть жив, находится в одной команде (вроде как профессии в даркрп работают именно так)
			-- Игрок должен не быть в ноуклипе, и быть видимым другими
			-- По желанию, игроку можно прописать m_bDontTrackMePDA = true чтобы не отображать (например, админов в нонрп режиме)
			if (ply:EntIndex() != v:EntIndex() && CStalkerCore:ShowPlayerInMinimap(v, ply)) then
				local wpos    = v:GetPos()
				local px, py2 = WorldToMap(wpos.x, wpos.y, mx, my, mw, mh, tx, ty, texPx, syncMode, fullMode)

				-- Зеленый квадрат
				surface.SetDrawColor(0, 255, 0, 230)
				surface.DrawRect(px-5, py2-5, 10, 10)

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
				
				draw.SimpleText(v:Nick(), font, px, py2+6, color_white, TEXT_ALIGN_CENTER)
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
				
				iMarkH = iMarkH + GetIconScaleAdd(zoom, zoomMin)
				iMarkW = iMarkW + GetIconScaleAdd(zoom, zoomMin)
				
				hMat = CStalkerCore:GetMarkerMaterial(ent:GetMarkType())
				
				local wpos    = ent:GetPos()
				local px, py2 = WorldToMap(wpos.x, wpos.y, mx, my, mw, mh, tx, ty, texPx, syncMode, fullMode)
				
				local bShouldDraw = true

				if (ent.GetShowEveryone != nill && !ent:GetShowEveryone()) then
					bShouldDraw = false
					
					for _, v in pairs(PDA.Markers.Stashes) do
						if (v != nil && v.entity != nil && IsValid(v.entity)) then
							if (v.entity:EntIndex() == ent:EntIndex()) then
								bShouldDraw = true
							end
						end
					end
				end
				
				if (bShouldDraw && hMat) then
					surface.SetDrawColor(255, 255, 255, 230)
					surface.SetMaterial(hMat)
					surface.DrawTexturedRect(px-6, py2-6, iMarkW, iMarkH)
				
					if (IsHovered(px-6, py2-6, iMarkW + 4, iMarkH + 4)) then
						if (iMarkType == 0) then
							
							if (bShouldDraw && ent.GetStashName != nil && ent.GetStashDesc != nil) then
								draw.SimpleText(ent:GetStashName(), font, px, py2+6, COLOR_MARKER_STASH, TEXT_ALIGN_CENTER)
								draw.SimpleText(ent:GetStashDesc(), font, px, py2+14, COLOR_MARKER_STASH, TEXT_ALIGN_CENTER)
							end
						elseif (iMarkType == 2) then
							if (bShouldDraw && ent.GetStashName != nil && ent.GetStashDesc != nil) then
								if (ent:GetStashName() != "" || ent:GetStashDesc() != "") then
									draw.SimpleText(ent:GetStashName(), font, px, py2+6, COLOR_MARKER_QUEST, TEXT_ALIGN_CENTER)
									draw.SimpleText(ent:GetStashDesc(), font, px, py2+14, COLOR_MARKER_QUEST, TEXT_ALIGN_CENTER)
								end
							end
							
							-- TODO: Не помню, зачем это сделал. Если можно ставить название в StashName
							-- for i = 1, #PDA.Tasks do
								-- if (!PDA.Tasks[i].steps) then continue end
								
								-- for k = 1, #PDA.Tasks[i].steps do
									-- if (!PDA.Tasks[i].steps[k].done && PDA.Tasks[i].steps[k].ent_marker && PDA.Tasks[i].steps[k].ent_marker:EntIndex() == ent:EntIndex()) then
										-- draw.SimpleText(PDA.Tasks[i].steps[k].text, "PDA_Small", px, py2+6, color_white, TEXT_ALIGN_CENTER)
									-- end
								-- end
							-- end
						end
					end
				end
			end
		end
    else
        surface.SetDrawColor(28,38,28,255)
        surface.DrawRect(mx, my, mw, mh)
        local gs = 50
        surface.SetDrawColor(42,58,42,255)
        for gx = mx, mx+mw, gs do surface.DrawLine(gx,my,gx,my+mh) end
        for gy = my, my+mh, gs do surface.DrawLine(mx,gy,mx+mw,gy) end
        local font = GetMapFont(zoom, zoomMin)
        draw.SimpleText("Карта недоступна", font, cx, cy,
            COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

	-- Отображение игрока
    if IsValid(ply) then
		local eyeAngles = ply:EyeAngles()
		eyeAngles:RotateAroundAxis(eyeAngles:Up(), 90)
		
		local yaw = eyeAngles.y
        local rad = math.rad(yaw)

        local markerX, markerY

        if fullMode then
            -- Панель полностью покрыта текстурой (растянутой).
            -- Позиция = UV * размер панели
            markerX = mx + pu * mw
            markerY = my + pv * mh
        elseif syncMode then
            -- Игрок всегда в центре
            markerX = cx
            markerY = cy
        else
            -- Позиция = начало текстуры + UV * размер текстуры
            markerX = tx + pu * texPx
            markerY = ty + pv * texPx
        end

        -- Стрелка направления
        surface.SetDrawColor(0, 255, 100, 255)
        surface.DrawLine(markerX, markerY,
            markerX + math.sin(rad)*16,
            markerY + math.cos(rad)*16)

        -- Точка игрока
        surface.SetDrawColor(0, 200, 255, 230)
        surface.DrawRect(markerX-5, markerY-5, 10, 10)
    end

    render.SetScissorRect(0,0,0,0,false)

    local font = GetMapFont(zoom, zoomMin)

    -- Координаты и название карты
    draw.SimpleText(string.format("X:%.0f Y:%.0f", wpos.x, wpos.y),
        font, mx+8, my+mh-20, COLOR_GREEN)
    draw.SimpleText(game.GetMap(), font,
        mx+mw-8, my+mh-20, COLOR_TEXT_DIM, TEXT_ALIGN_RIGHT)

    -- Полоска зума (только в обычном режиме)
    if not fullMode then
        local bW = 80; local bH = 6
        local bX = cx - bW/2; local bY2 = my+8
        local filled = math.Clamp((zoom-zoomMin)/(MAP_ZOOM_MAX-zoomMin), 0, 1)
        draw.RoundedBox(2, bX, bY2, bW, bH, Color(30,30,30,180))
        if filled > 0 then
            draw.RoundedBox(2, bX, bY2, math.floor(bW*filled), bH, COLOR_TAB_ACT)
        end
        draw.SimpleText("−","MAP_Font_S",bX-10,   bY2+bH/2,COLOR_TEXT_DIM,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        draw.SimpleText("+","MAP_Font_S",bX+bW+10, bY2+bH/2,COLOR_TEXT_DIM,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end

    -- ---- Кнопки в левом верхнем углу карты ----
    local btnR  = 10
    local btnX1 = mx + 16   -- кнопка SYNC
    local btnX2 = mx + 38   -- кнопка FULL
    local btnY  = my + 16

    if DrawMapToggleButton(btnX1, btnY, btnR, syncMode, Color(40,80,200,230), "●", clicks) then
        if dragTarget=="tasks" then
            PDA.MapSyncTasks = not PDA.MapSyncTasks
            if PDA.MapSyncTasks then PDA.MapPanTasks = {x=0,y=0} end
        else
            PDA.MapSyncPlan = not PDA.MapSyncPlan
            if PDA.MapSyncPlan then PDA.MapPanPlan = {x=0,y=0} end
        end
    end

    if DrawMapToggleButton(btnX2, btnY, btnR, fullMode, Color(160,100,20,230), "⊞", clicks) then
        if dragTarget=="tasks" then
            PDA.MapFullTasks = not PDA.MapFullTasks
        else
            PDA.MapFullPlan = not PDA.MapFullPlan
        end
    end
	
	-- TODO: Колесико мыши не хукается, поэтому так, используем кнопки
	
	if (DrawMapToggleButton(btnX2 + 22, btnY, btnR, _, Color(255, 255, 255, 255), "+", clicks)) then
		pendingWheel = 1
	end
	
	if (DrawMapToggleButton(btnX2 + 44, btnY, btnR, _, Color(255, 255, 255, 255), "-", clicks)) then
		pendingWheel = -1
	end

    if not MapDrag.active and not syncMode and not fullMode then
        for _, cl in ipairs(clicks) do
            if  ClickIn(cl, mx, my, mw, mh)
            and not ClickIn(cl, btnX1-btnR, btnY-btnR, btnR*2, btnR*2)
            and not ClickIn(cl, btnX2-btnR, btnY-btnR, btnR*2, btnR*2) then
                MapDrag.active    = true
                MapDrag.target    = dragTarget
                MapDrag.startMX   = cl.x
                MapDrag.startMY   = cl.y
                MapDrag.startPanX = panX
                MapDrag.startPanY = panY
            end
        end
    end
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
		
		if (PDA.CurrentTab == 4) then
			for i = 1, #m_hAvatarsContacts do
				if (m_hAvatarsContacts[i] != nil && m_hAvatarsContacts[i].avatar != nil) then
					m_hAvatarsContacts[i].avatar:Remove()
				end
			end
			m_hAvatarsContacts = {}
		end
	end
	
    if not PDA.Open then return end

    local sw, sh = ScrW(), ScrH()
    PX = math.floor((sw - PW) / 2)
    PY = math.floor((sh - PH) / 2)

    draw.RoundedBox(10, PX-BORDER,   PY-BORDER-36, PW+BORDER*2, PH+BORDER*2+36+TAB_H, COLOR_FRAME)
    draw.RoundedBox(8,  PX-BORDER+4, PY-BORDER-32, PW+BORDER*2-8, PH+BORDER*2+28+TAB_H, COLOR_BG)

    draw.RoundedBox(4, PX, PY-32, PW, 30, COLOR_HEADER)
    draw.SimpleText("КПК / ЛИЧНЫЙ ПОМОЩНИК", "PDA_Header",
        PX+PW/2, PY-17, COLOR_TAB_ACT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText(os.date("%H:%M  %d/%m/%Y"), "PDA_Small",
        PX+PW-6, PY-17, COLOR_TEXT_DIM, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)

    local tabW = PW / #PDA.Tabs
    for i, name in ipairs(PDA.Tabs) do
        local tx  = PX + (i-1)*tabW
        local ty  = PY + PH
        local act = PDA.CurrentTab == i
        draw.RoundedBox(3, tx+1, ty+1, tabW-2, TAB_H-2, COLOR_HEADER)
        if act then
            surface.SetDrawColor(COLOR_TAB_ACT)
            surface.DrawRect(tx+1, ty+1, tabW-2, 3)
        end
        draw.SimpleText(name, "PDA_Tab", tx+tabW/2, ty+TAB_H/2,
            act and COLOR_TAB_ACT or COLOR_TAB_INACT,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    draw.RoundedBox(4, PX, PY, PW, PH, COLOR_PANEL)

    local clicks = clickQueue
    clickQueue   = {}

    for _, cl in ipairs(clicks) do
        for i=1,#PDA.Tabs do
            local tx = PX + (i-1)*tabW
            if ClickIn(cl, tx, PY+PH, tabW, TAB_H) then
                PDA.CurrentTab = i
            end
        end
    end

    local t = PDA.CurrentTab
    if     t==1 then DrawTabTasks(clicks)
    elseif t==2 then DrawTabPlan(clicks)
    elseif t==3 then DrawTabJournal(clicks)
    elseif t==4 then DrawTabContacts(clicks)
    elseif t==5 then DrawTabRanks(clicks)
    elseif t==6 then DrawTabData(clicks)
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
	
	if (PDA.CurrentTab != 4) then
		for i = 1, #m_hAvatarsContacts do
			if (m_hAvatarsContacts[i] != nil && m_hAvatarsContacts[i].avatar != nil) then
				m_hAvatarsContacts[i].avatar:Remove()
			end
		end
		m_hAvatarsContacts = {}
	end
end)

-- ============================================================
-- TAB 1 — ЗАДАЧИ
-- ============================================================
function DrawTabTasks(clicks)
    local leftW  = 380
    local cx, cy = PX, PY

    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(cx+leftW, cy, 1, PH)

    local itemH  = 110
    local listH  = PH
    local maxOff = math.max(0, #PDA.Tasks * itemH - listH)
    PDA.TaskScrollOffset = math.Clamp(PDA.TaskScrollOffset, 0, maxOff)

    Scissor(cx, cy, leftW-SCROLL_W, listH, function()
        for i, task in ipairs(PDA.Tasks) do
            local iy  = cy + (i-1)*itemH - PDA.TaskScrollOffset
            if iy+itemH < cy or iy > cy+listH then continue end

            local sel = PDA.SelectedTask == i
            local hov = IsHovered(cx, iy, leftW-SCROLL_W, itemH)
            draw.RoundedBox(0, cx, iy, leftW-SCROLL_W, itemH,
                sel and COLOR_ITEM_SEL or (hov and COLOR_ITEM_HOV or COLOR_PANEL))

            
			local hMat = nil
			
			if (task.iconPath) then
				hMat = CStalkerCore:GetMaterial(task.iconPath)
			end
			
			if (hMat && !hMat:IsError()) then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(hMat)
				--surface.DrawTexturedRect(cx+8, iy+8, 70, 58)
				surface.DrawTexturedRect(cx+8, iy+8, 70, 47)
			else
				draw.RoundedBox(3, cx+8, iy+8, 70, 58, COLOR_HEADER)
				draw.SimpleText("?","PDA_Huge",cx+43,iy+37,COLOR_TEXT_DIM,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			end

            draw.SimpleText(task.title,"PDA_Body",cx+86,iy+8,
                sel and COLOR_TAB_ACT or COLOR_TEXT,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)
            draw.SimpleText(task.date,"PDA_Small",cx+86,iy+26,COLOR_TEXT_DIM,TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP)

            local sy = iy+44
            for _, step in ipairs(task.steps) do
                if sy > iy+itemH-4 then break end
                draw.SimpleText(
                    (step.done and "●" or "○").." "..step.text,
                    "PDA_Small", cx+86, sy,
                    step.done and COLOR_GREEN or COLOR_TEXT_DIM,
                    TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
                sy = sy+15
            end

            local btnX = cx+leftW-SCROLL_W-26
            local btnY = iy+6
            draw.RoundedBox(4, btnX, btnY, 20, 20, COLOR_HEADER)
            draw.SimpleText("i","PDA_Body",btnX+10,btnY+10,COLOR_TAB_ACT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)

            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawRect(cx, iy+itemH-1, leftW-SCROLL_W, 1)

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

    local rx = cx+leftW+1
    local rw = PW-leftW-1

    if PDA.ShowTaskDesc and PDA.SelectedTask then
        local task = PDA.Tasks[PDA.SelectedTask]
        draw.RoundedBox(0, rx, cy, rw, PH, COLOR_HEADER)
        draw.SimpleText("Детальная информация о задании","PDA_Small",rx+8,cy+8,COLOR_TEXT_DIM)
        local wrapped = WrapText(task.desc,"PDA_Body",rw-20)
        local ty = cy+28
        for _, line in ipairs(wrapped) do
            draw.SimpleText(line,"PDA_Body",rx+10,ty,COLOR_TEXT); ty=ty+18
        end
    else
        DrawMiniMap(rx, cy, rw, PH,
            PDA.MapZoomTasks, MAP_ZOOM_MIN_TASKS,
            PDA.MapPanTasks.x, PDA.MapPanTasks.y,
            PDA.MapSyncTasks, PDA.MapFullTasks,
            "tasks", clicks)
    end
end

-- ============================================================
-- TAB 2 — ПЛАН
-- ============================================================
function DrawTabPlan(clicks)
    DrawMiniMap(PX, PY, PW, PH,
        PDA.MapZoomPlan, MAP_ZOOM_MIN_PLAN,
        PDA.MapPanPlan.x, PDA.MapPanPlan.y,
        PDA.MapSyncPlan, PDA.MapFullPlan,
        "plan", clicks)
end

-- ============================================================
-- TAB 3 — ЖУРНАЛ
-- ============================================================
function DrawTabJournal(clicks)
    local leftW = 280
    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(PX+leftW, PY, 1, PH)

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
    local maxOff = math.max(0, #items*itemH - listH+10)
    PDA.JournalScrollOff = math.Clamp(PDA.JournalScrollOff, 0, maxOff)

    Scissor(PX, PY, leftW-SCROLL_W, listH, function()
        for idx, item in ipairs(items) do
            local iy = PY + (idx-1)*itemH - PDA.JournalScrollOff
            if iy+itemH < PY or iy > PY+listH then continue end

            if item.type == "group" then
                draw.SimpleText(
                    (item.group.open and "▾ " or "▸ ")..item.group.group,
                    "PDA_Body", PX+8, iy+4, COLOR_TAB_ACT)
                for _, cl in ipairs(clicks) do
                    if ClickIn(cl, PX, iy, leftW-SCROLL_W, itemH) then
                        item.group.open = not item.group.open
                        PDA.SelectedNote = nil
                    end
                end
            else
                local sel = PDA.SelectedNote
                    and PDA.SelectedNote.gi==item.gi
                    and PDA.SelectedNote.ni==item.ni
                local hov = IsHovered(PX, iy, leftW-SCROLL_W, itemH)
                if sel then draw.RoundedBox(0,PX,iy,leftW-SCROLL_W,itemH,COLOR_ITEM_SEL) end
                if hov and not sel then draw.RoundedBox(0,PX,iy,leftW-SCROLL_W,itemH,COLOR_ITEM_HOV) end
                draw.SimpleText("   "..item.note.title,"PDA_Small",PX+20,iy+5,COLOR_GREEN)
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

    local rx = PX+leftW+1
    local rw = PW-leftW-1
    if PDA.SelectedNote then
        local note    = PDA.SelectedNote.note
        local wrapped = WrapText(note.text,"PDA_Body",rw-20)
        local ty = PY+12
        draw.SimpleText(note.title,"PDA_Header",rx+10,ty,COLOR_TAB_ACT)
        ty = ty+24
        for _, line in ipairs(wrapped) do
            draw.SimpleText(line,"PDA_Body",rx+10,ty,COLOR_TEXT); ty=ty+18
        end
    else
        draw.SimpleText("Выберите заметку","PDA_Body",
            rx+rw/2,PY+PH/2,COLOR_TEXT_DIM,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
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
	local flDistSqr = 2500 * 2500
	
	for _, ent in ents.Iterator() do
		if (IsValid(ent) && (ent:IsNPC() || ent:IsNextBot() || ent:IsPlayer())) then
			if (ent:GetPos():DistToSqr(pos) > flDistSqr) then continue end
			--Если не появляются на мини-карте, значит в контактах не нужно оторбражать, логично?
			if (ent:IsPlayer() && !CStalkerCore:ShowPlayerInMinimap(ent, LocalPlayer())) then continue end
			
			if ((ent:IsNPC() || ent:IsNextBot()) && !CStalkerCore:ShowNPCInMinimap(ent)) then continue end
			
			table.insert(npcs, ent)
		end
	end

    local leftW = 360
    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(PX+leftW, PY, 1, PH)

    local itemH  = 86
    local listH  = PH
    local maxOff = math.max(0, #npcs*itemH - listH)
	
	if (PDA.ContactsOnline != #npcs) then
		for i = 1, #m_hAvatarsContacts do
			if (m_hAvatarsContacts[i] != nil && m_hAvatarsContacts[i].avatar != nil) then
				m_hAvatarsContacts[i].avatar:Remove()
			end
		end
		m_hAvatarsContacts = {}
		
		PDA.ContactsOnline = #npcs
	end
	
    PDA.ContactScroll = math.Clamp(PDA.ContactScroll, 0, maxOff)

    Scissor(PX, PY, leftW-SCROLL_W, listH, function()
        if #npcs == 0 then
            draw.SimpleText("Контакты не обнаружены","PDA_Body",
                PX+leftW/2,PY+PH/2,COLOR_TEXT_DIM,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
            return
        end
        for i, npc in ipairs(npcs) do
            local iy  = PY + (i-1)*itemH - PDA.ContactScroll
            if iy+itemH < PY or iy > PY+listH then continue end

            local sel   = (PDA.SelectedContact == i)
            local hov   = IsHovered(PX, iy, leftW-SCROLL_W, itemH)
            draw.RoundedBox(0, PX, iy, leftW-SCROLL_W, itemH,
                sel and COLOR_ITEM_SEL or (hov and COLOR_ITEM_HOV or COLOR_PANEL))
			
			local PXOffset = 0
				
			if (npc:IsPlayer()) then
				-- FIXME: Если опустить скроллбар вниз или вверх, то аватарка останется на том же месте, а так же аватар будет за пределами скроллбара
				-- Это заметно когда очень много контактов (игроков или сталкеров-нпс)
				-- Это происходит из-за того что SetPlayer доступен только vgui панели, но никак не в draw и surface
				-- Может есть возможность получение аватара игрока через Material()? Движок полюбому где-то хранит в памяти аватарки
				-- if (!HasAvatar(m_hAvatarsContacts, npc:EntIndex())) then
					-- local Avatar = vgui.Create("AvatarImage")
					-- Avatar:SetSize(54, 54)
					-- Avatar:SetPos(PX+8, iy+8)
					-- Avatar:SetPlayer(npc, 64)
					-- table.insert(m_hAvatarsContacts, { id = npc:EntIndex(), avatar = Avatar, userid = npc:UserID() })
				-- end
				
				-- Пока так
				draw.RoundedBox(3, PX+8, iy+8, 54, 54, COLOR_HEADER)
				draw.SimpleText(npc:Nick():sub(1, 1), "PDA_Huge", PX+35, iy+35,
					COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			else
				
				local szIcon = npc:GetNWString("StalkerIcon")
				
				if (szIcon && szIcon != "") then
					PXOffset = 40
					
					local hMat = CStalkerCore:GetMaterial(szIcon)
			
					if (hMat && !hMat:IsError()) then
						surface.SetDrawColor(255, 255, 255, 255)
						surface.SetMaterial(hMat)
						surface.DrawTexturedRect(PX+8, iy+8, 92, 60)
					end
				else
					draw.RoundedBox(3, PX+8, iy+8, 54, 44, COLOR_HEADER)
					draw.SimpleText("NPC", "PDA_Small", PX+35, iy+30,
						COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
				end
			end

            -- Статус-точка
			-- TODO: Придумать фичу с этим
            surface.SetDrawColor(COLOR_GREEN)
            surface.DrawRect(PX+68+PXOffset, iy+10, 9, 9)

            -- Имя
			if (npc:IsPlayer()) then
				draw.SimpleText(npc:Nick(), "PDA_Body", PX+82+PXOffset, iy+8, COLOR_TEXT)
			else
				--local szName = npc.m_szName or npc:GetClass()
				local szName = npc:GetNWString("StalkerName", npc:GetClass())
				draw.SimpleText(szName, "PDA_Body", PX+82+PXOffset, iy+8, COLOR_TEXT)
			end

            -- Инфо
            local ry = iy+26
            for k, row in ipairs({{"группа",npc:GetNWString("Community", "Одиночка")},{"репутация",npc:GetNWString("Reputation","нейтрал")},{"отношение",""},{"ранг",npc:GetNWString("Rank", "новичок")}}) do
				
				local iAttitude = 0
				local clrText = COLOR_ATTITUDE_NEUTRAL
				local szAttitude = "нейтрал"
				
				-- Отношение
				if (k == 3) then
					-- Переопределение через CStalkerMM::GetNPC
					iAttitude = npc.m_iAttitude || npc:GetNWInt("Attitude", 0)
					
					if (iAttitude == CD_HT) then
						clrText = COLOR_ATTITUDE_RED
						szAttitude = "враг"
					elseif (iAttitude == CD_LI) then
						clrText = COLOR_ATTITUDE_GREEN
						szAttitude = "друг"
					end
					
					row[2] = szAttitude
				end
                draw.SimpleText(row[1], "PDA_Small", PX+82+PXOffset, ry, COLOR_TEXT_DIM)
                draw.SimpleText(row[2], "PDA_Small", PX+160+PXOffset, ry, clrText)
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

    local rx = PX+leftW+1
    local rw = PW-leftW-1
    if PDA.SelectedContact and npcs[PDA.SelectedContact] then
        -- local npc = npcs[PDA.SelectedContact]
        -- draw.SimpleText(npc:GetClass(),"PDA_Header",rx+132,PY+22,COLOR_TEXT)
		
		local contact  = npcs[PDA.SelectedContact]
        local ay = PY+24
		local szIcon = contact:GetNWString("StalkerIcon")
		local szName = contact:GetNWString("StalkerName", "Сталкер")
		local PXOffset = 0
		
		if (contact:IsPlayer()) then
			szName = contact:Nick()
		end
		
		if (szIcon && szIcon != "") then
			PXOffset = 52
			
			local hMat = CStalkerCore:GetMaterial(szIcon)
			
			if (hMat && !hMat:IsError()) then
				surface.SetDrawColor(255, 255, 255, 255)
				surface.SetMaterial(hMat)
				surface.DrawTexturedRect(rx+12, ay, 153, 100)
			end
		else
			if (contact:IsPlayer()) then
				draw.RoundedBox(3, rx+12, ay, 100, 100, COLOR_HEADER)
				draw.SimpleText(string.sub(contact:Nick(),1,2),"PDA_Huge",rx+62,ay+50,COLOR_TEXT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			else
				draw.RoundedBox(3, rx+12, ay, 100, 100, COLOR_HEADER)
				draw.SimpleText(string.sub(contact:GetClass(),1,2),"PDA_Huge",rx+62,ay+50,COLOR_TEXT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
			end
		end
		
        local infoX = rx+122; local ry = ay+10
        for i, row in ipairs({
            {"Игрок",szName},{"Ранг",contact:GetNWString("Rank", "новичок")},
            {"Группа",contact:GetNWString("Community", "Одиночка")},{"Репутация",contact:GetNWString("Reputation", "нейтрал")},{"Отношение","нейтрал"}
        }) do
			local iAttitude = 0
			local clrText = COLOR_ATTITUDE_NEUTRAL
			local szAttitude = "нейтрал"
			
			-- Отношение
			if (i == 3) then
				-- Переопределение через CStalkerMM::GetNPC
				iAttitude = contact.m_iAttitude || contact:GetNWInt("Attitude", 0)
				
				if (iAttitude == CD_HT) then
					clrText = COLOR_ATTITUDE_RED
					szAttitude = "враг"
				elseif (iAttitude == CD_LI) then
					clrText = COLOR_ATTITUDE_GREEN
					szAttitude = "друг"
				end
				
				row[2] = szAttitude
			end
			
            draw.SimpleText(row[1],"PDA_Small",infoX+PXOffset,ry,COLOR_TEXT_DIM)
            draw.SimpleText(row[2],"PDA_Body",infoX+100+PXOffset,ry,COLOR_TEXT)
            ry = ry+22
        end
		
		-- У NWString ограничение в 199 символов
		ry = ry + 10
		
		local szBio = contact.m_szBio || contact:GetNWString("StalkerBio", "Детальная информация отсутствует.")
		
		-- TODO: Сделать так, что если у игрока есть кастомное описание, то отображать его вместо "Это ты!"
		if (contact:EntIndex() == LocalPlayer():EntIndex()) then
			szBio = "Это ты!"
		end
		draw.SimpleText(szBio, "PDA_Body", rx + 10, ry, COLOR_TEXT)
    else
        draw.SimpleText("Выберите контакт","PDA_Body",
            rx+rw/2,PY+PH/2,COLOR_TEXT_DIM,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
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
	
	table.sort(players, function(a, b) return a:GetNWInt("RankPoints") > b:GetNWInt("RankPoints") end)

    Scissor(PX, PY, leftW-SCROLL_W, listH, function()
        for i, p in ipairs(players) do
            local iy  = PY + (i-1)*itemH - PDA.RankScroll
            if iy+itemH < PY or iy > PY+listH then continue end

            local sel = PDA.SelectedRankPlayer == i
            local hov = IsHovered(PX, iy, leftW-SCROLL_W, itemH)
            draw.RoundedBox(0, PX, iy, leftW-SCROLL_W, itemH,
                sel and COLOR_ITEM_SEL or (hov and COLOR_ITEM_HOV or COLOR_PANEL))

            -- Аватар игрока
			-- FIXME: Закомментировано до фикса, смотрите выше в контактах почему
			-- if (!HasAvatar(m_hAvatars, p:EntIndex())) then
				-- local Avatar = vgui.Create("AvatarImage")
				-- Avatar:SetSize(32, 32)
				-- Avatar:SetPos(PX+6, iy+5)
				-- Avatar:SetPlayer(p, 32)
				-- table.insert(m_hAvatars, { id = p:EntIndex(), avatar = Avatar, userid = p:UserID() })
			-- end
			
			-- Аватар (первая буква ника)
            draw.RoundedBox(3, PX+6, iy+5, 32, 32, COLOR_HEADER)
            draw.SimpleText(string.sub(p:Nick(),1,1), "PDA_Body",
               PX+22, iy+21, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			
            draw.SimpleText(p:Nick(),"PDA_Body",PX+44,iy+6,COLOR_TEXT)
            draw.SimpleText("ранг: " .. p:GetNWString("Rank", "новичок"),"PDA_Small",PX+44,iy+22,COLOR_TEXT_DIM)
			draw.SimpleText(p:GetNWInt("RankPoints", 0), "PDA_Small", PX+300, iy+12, COLOR_TEXT_DIM, TEXT_ALIGN_RIGHT)

            surface.SetDrawColor(COLOR_BORDER)
            surface.DrawRect(PX, iy+itemH-1, leftW-SCROLL_W, 1)

            for _, cl in ipairs(clicks) do
                if ClickIn(cl, PX, iy, leftW-SCROLL_W, itemH) then PDA.SelectedRankPlayer=i end
            end
        end
    end)

    DrawScrollbar(PX+leftW-SCROLL_W, PY, SCROLL_W, listH,
                  PDA.RankScroll, maxOff, "ranks", clicks)

    local rx = PX+leftW+1
    local rw = PW-leftW-1
    if PDA.SelectedRankPlayer and players[PDA.SelectedRankPlayer] then
        local p  = players[PDA.SelectedRankPlayer]
        local ay = PY+24
        draw.RoundedBox(3, rx+12, ay, 100, 100, COLOR_HEADER)
        draw.SimpleText(string.sub(p:Nick(),1,2),"PDA_Huge",rx+62,ay+50,COLOR_TEXT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
        local infoX = rx+122; local ry = ay+10
        for _, row in ipairs({
            {"Игрок",p:Nick()},{"Ранг",p:GetNWString("Rank", "новичок")},
            {"Группа",p:GetNWString("Community", "Одиночка")},{"Репутация",p:GetNWString("Reputation", "нейтрал")},{"Отношение","нейтрал"}
        }) do
            draw.SimpleText(row[1],"PDA_Small",infoX,ry,COLOR_TEXT_DIM)
            draw.SimpleText(row[2],"PDA_Body",infoX+100,ry,COLOR_TEXT)
            ry = ry+22
        end
    else
        draw.SimpleText("Выберите игрока","PDA_Body",
            rx+rw/2,PY+PH/2,COLOR_TEXT_DIM,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    end
end

-- ============================================================
-- TAB 6 — ДАННЫЕ
-- ============================================================
function DrawTabData(clicks)
    local leftW = 340
    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(PX+leftW, PY, 1, PH)

    local ply = LocalPlayer()
	
	if (m_hMyLocalAvatar == nil) then
		local Avatar = vgui.Create("AvatarImage")
		Avatar:SetSize(90, 90)
		Avatar:SetPos(PX+12, PY+12)
		Avatar:SetPlayer(ply, 64)
		m_hMyLocalAvatar = Avatar
	end
	-- draw.RoundedBox(3, PX+12, PY+12, 90, 90, COLOR_HEADER)
    -- draw.SimpleText(string.sub(ply:Nick(),1,2), "PDA_Huge", PX+57, PY+57, COLOR_TEXT, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    
	draw.SimpleText(ply:Nick(),"PDA_Header",PX+112,PY+16,COLOR_TEXT)

    local ry = PY+40
    for _, row in ipairs({{"Ранг",ply:GetNWString("Rank", "новичок")},{"Группа",ply:GetNWString("Community", "Одиночка")},{"Репутация",ply:GetNWString("Reputation", "нейтрал")}}) do
        draw.SimpleText(row[1],"PDA_Small",PX+112,ry,COLOR_TEXT_DIM)
        draw.SimpleText(row[2],"PDA_Small",PX+210,ry,COLOR_TEXT)
        ry = ry+18
    end

    draw.SimpleText("Статистика","PDA_Header",PX+12,PY+114,COLOR_TAB_ACT)
    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(PX+12, PY+132, leftW-24, 1)

    local sy = PY+140
    for i, row in ipairs({
        {"Убийство сталкеров",PDA.Stats.npc_kills},
        {"Убийство мутантов",PDA.Stats.mutant_kills},
        {"Выполненные квесты",PDA.Stats.quests_done},
        {"Всего",PDA.Stats.npc_kills+PDA.Stats.mutant_kills},
    }) do
		if (IsHovered(PX+12, sy, 140, 20) && i < 4) then
			row[1] = row[1] .. " <"
		end
        draw.SimpleText(row[1],"PDA_Body",PX+12,sy,COLOR_TEXT)
        draw.SimpleText(tostring(row[2]),"PDA_Body",PX+leftW-14,sy,COLOR_YELLOW,TEXT_ALIGN_RIGHT)
		sy = sy+24
    end
	
	-- Возможность переключаться между списком
	local sy2 = PY+140
	for _, cl in ipairs(clicks) do
		for i=1, 3 do
			if (ClickIn(cl, PX+12, sy2, 140, 20)) then
				PDA.SelectedKillList = i
			end
			sy2 = sy2 + 24
		end
	end
	
	local titles = { "Убийство сталкеров", "Убийство мутантов", "Выполненные квесты" }
	local tblList = PDA.Stats.kill_list
	if (PDA.SelectedKillList == 2) then
		tblList = PDA.Stats.kill_mutant_list
	elseif (PDA.SelectedKillList == 3) then
		tblList = PDA.Stats.quests_done_list
	end

    local rx     = PX+leftW+1
    local rw     = PW-leftW-1
    local itemH  = 22
    local listH  = PH-34
	local maxOff = math.max(0, #tblList*itemH - listH)
    PDA.StatsKillScroll = math.Clamp(PDA.StatsKillScroll, 0, maxOff)

    draw.SimpleText(titles[PDA.SelectedKillList],"PDA_Header",
        rx+rw/2,PY+10,COLOR_TAB_ACT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    surface.SetDrawColor(COLOR_BORDER)
    surface.DrawRect(rx, PY+30, rw, 1)

    Scissor(rx, PY+32, rw-SCROLL_W, listH, function()
        for i, row in ipairs(tblList) do
            local iy  = PY+32 + (i-1)*itemH - PDA.StatsKillScroll
            local hov = IsHovered(rx, iy, rw-SCROLL_W, itemH)
			local points = row.total * row.mult
            if hov then draw.RoundedBox(0,rx,iy,rw-SCROLL_W,itemH,COLOR_ITEM_HOV) end
            draw.SimpleText(tostring(i-1)..".","PDA_Small",rx+8,iy+4,COLOR_TEXT_DIM)
            draw.SimpleText(row.name,"PDA_Small",rx+32,iy+4,COLOR_TEXT)
            draw.SimpleText("x"..row.total,"PDA_Small",rx+rw-SCROLL_W-68,iy+4,COLOR_TEXT_DIM,TEXT_ALIGN_RIGHT)
            draw.SimpleText(tostring(points),"PDA_Small",rx+rw-SCROLL_W-8,iy+4,COLOR_YELLOW,TEXT_ALIGN_RIGHT)
        end
    end)
	
    -- local maxOff = math.max(0, #PDA.Stats.kill_list*itemH - listH)
    -- PDA.StatsKillScroll = math.Clamp(PDA.StatsKillScroll, 0, maxOff)

    -- draw.SimpleText("Убийство сталкеров","PDA_Header",
        -- rx+rw/2,PY+10,COLOR_TAB_ACT,TEXT_ALIGN_CENTER,TEXT_ALIGN_CENTER)
    -- surface.SetDrawColor(COLOR_BORDER)
    -- surface.DrawRect(rx, PY+30, rw, 1)

    -- Scissor(rx, PY+32, rw-SCROLL_W, listH, function()
        -- for i, row in ipairs(PDA.Stats.kill_list) do
            -- local iy  = PY+32 + (i-1)*itemH - PDA.StatsKillScroll
            -- local hov = IsHovered(rx, iy, rw-SCROLL_W, itemH)
			-- local points = row.total * row.mult
            -- if hov then draw.RoundedBox(0,rx,iy,rw-SCROLL_W,itemH,COLOR_ITEM_HOV) end
            -- draw.SimpleText(tostring(i-1)..".","PDA_Small",rx+8,iy+4,COLOR_TEXT_DIM)
            -- draw.SimpleText(row.name,"PDA_Small",rx+32,iy+4,COLOR_TEXT)
            -- draw.SimpleText("x"..row.total,"PDA_Small",rx+rw-SCROLL_W-68,iy+4,COLOR_TEXT_DIM,TEXT_ALIGN_RIGHT)
            -- draw.SimpleText(tostring(points),"PDA_Small",rx+rw-SCROLL_W-8,iy+4,COLOR_YELLOW,TEXT_ALIGN_RIGHT)
        -- end
    -- end)

    DrawScrollbar(rx+rw-SCROLL_W, PY+32, SCROLL_W, listH,
                  PDA.StatsKillScroll, maxOff, "stats", clicks)
end

-- ============================================================
-- F4 TOGGLE
-- ============================================================
hook.Add("PlayerButtonDown", "StalkerPDA_Toggle", function(ply, btn)
    if ply ~= LocalPlayer() then return end
	
	if !IsFirstTimePredicted() then return end
	
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

hook.Add("HUDShouldDraw", "Stalker_PDA_HideCrosshair", function(name)
	if (PDA.Open) then
		if (name == "CHudCrosshair") then return false end
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