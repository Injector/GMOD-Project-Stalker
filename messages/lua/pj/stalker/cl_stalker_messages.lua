-- ============================================================
-- STALKER MESSAGES — уведомления в левом нижнем углу
-- ============================================================

local Messages = {}

-- Настройки
local MSG_MAX       = 4        -- максимум сообщений на экране
local MSG_LIFETIME  = 10       -- секунд до начала исчезновения
local MSG_FADETIME  = 3        -- секунд на исчезновение
local MSG_W         = 420      -- ширина блока
local MSG_ITEM_H    = 64       -- высота одного сообщения
local MSG_MARGIN    = 6        -- отступ между сообщениями
local MSG_BOTTOM    = 160      -- отступ снизу (оставляем место для HP)

-- Цвета
local C_BG       = Color(10, 10, 10, 200)
local C_BORDER   = Color(80, 80, 80, 255)
local C_TIME     = Color(200, 180, 50, 255)
local C_TITLE    = Color(180, 140, 30, 255)
local C_TEXT     = Color(200, 200, 200, 255)
local C_IMG_BG   = Color(40, 40, 40, 255)

-- Типы сообщений
-- В ТЧ Сообщение и Информация о схроне без : по каким то причинам
local MSG_TYPES = {
    new_task 	= 	{title = "Новое задание:",     	color = Color(80, 200, 80, 255)},
    done    	= 	{title = "Задание выполнено:", 	color = Color(200, 180, 50, 255)},
    updated  	= 	{title = "Задание обновлено:", 	color = Color(100, 180, 255, 255)},
    message  	= 	{title = "Сообщение",          	color = Color(160, 160, 160, 255)},
	new_stash 	= 	{title = "Информация о схроне",	color = Color(137, 120, 208, 255)},
}

surface.CreateFont("MSG_Time",  {font="Trebuchet MS", size=13, weight=600})
surface.CreateFont("MSG_Title", {font="Trebuchet MS", size=13, weight=700})
surface.CreateFont("MSG_Body",  {font="Trebuchet MS", size=13, weight=400})

-- Добавить сообщение
-- msgType: "new_task" | "done" | "updated" | "message"
-- text: строка
-- imageURL: необязательно, путь к материалу (напр. "vgui/avatar_default")
-- TODO: Сделать два выбора для изображения: через готовый Material или путь
-- Определять путь можно через isstring() 
-- TODO: Сделать Messages глобальным
local function AddMessage(msgType, text, imageMat)
    -- Не больше MSG_MAX
    while #Messages >= MSG_MAX do
        table.remove(Messages, 1)
    end
    table.insert(Messages, {
        mtype   = msgType,
        text    = text,
        image   = imageMat,
        born    = CurTime(),
    })
	
	if (msgType == "new_stash") then
		surface.PlaySound("pj/stalker/pda_news.mp3")
	elseif (msgType == "done" || msgType == "updated" || msgType == "new_task") then
		surface.PlaySound("pj/stalker/pda_objective.mp3")
	elseif (msgType == "message") then
		surface.PlaySound("pj/stalker/pda_tip.mp3")
	end
end

-- Перенос текста
local function WrapMsg(text, font, maxW)
    surface.SetFont(font)
    local lines, line = {}, ""
    for _, word in ipairs(string.Explode(" ", text)) do
        local test = line == "" and word or (line.." "..word)
        if surface.GetTextSize(test) > maxW and line ~= "" then
            table.insert(lines, line); line = word
        else line = test end
    end
    if line ~= "" then table.insert(lines, line) end
    return lines
end

hook.Add("HUDPaint", "StalkerMessages_Draw", function()
    local now  = CurTime()
    local sw, sh = 450, ScrH()

    -- Чистим устаревшие
    for i = #Messages, 1, -1 do
        local m = Messages[i]
        if now - m.born > MSG_LIFETIME + MSG_FADETIME then
            table.remove(Messages, i)
        end
    end

    -- Рисуем снизу вверх
    local baseY = sh - MSG_BOTTOM

    for i = #Messages, 1, -1 do
        local m    = Messages[i]
        local age  = now - m.born
        local alpha = 255
        if age > MSG_LIFETIME then
            alpha = 255 * (1 - (age - MSG_LIFETIME) / MSG_FADETIME)
            alpha = math.Clamp(alpha, 0, 255)
        end

        local idx = #Messages - i   -- 0 = нижнее, 1 = выше и т.д.
        local my  = baseY - (idx+1)*(MSG_ITEM_H + MSG_MARGIN)

        local mtype = MSG_TYPES[m.mtype] or MSG_TYPES.message

        -- Фон
        local bg = Color(C_BG.r, C_BG.g, C_BG.b, alpha * (200/255))
        draw.RoundedBox(4, sw - MSG_W - 10, my, MSG_W, MSG_ITEM_H, bg)

        -- Граница слева (цветная полоска)
        surface.SetDrawColor(mtype.color.r, mtype.color.g, mtype.color.b, alpha)
        surface.DrawRect(sw - MSG_W - 10, my, 3, MSG_ITEM_H)

        local mx = sw - MSG_W - 10

        -- Картинка
        local imgW = 80
        draw.RoundedBox(3, mx+8, my+7, imgW, MSG_ITEM_H-14, Color(C_IMG_BG.r,C_IMG_BG.g,C_IMG_BG.b,alpha))
        if m.image then
            local mat = Material(m.image)
            if not mat:IsError() then
                surface.SetDrawColor(255,255,255,alpha)
                surface.SetMaterial(mat)
                surface.DrawTexturedRect(mx+8, my+7, imgW, MSG_ITEM_H-14)
            end
        end

        -- Время
        local timeStr = os.date("%H:%M")
        local tc = Color(C_TIME.r, C_TIME.g, C_TIME.b, alpha)
        draw.SimpleText(timeStr, "MSG_Time", mx+imgW+14, my+6, tc)

        -- Тип сообщения
        local ttc = Color(mtype.color.r, mtype.color.g, mtype.color.b, alpha)
        surface.SetFont("MSG_Title")
        local tw = surface.GetTextSize(timeStr) + 6
        draw.SimpleText(mtype.title, "MSG_Title", mx+imgW+14+tw, my+6, ttc)

        -- Текст (перенос)
        local textX = mx+imgW+14
        local textW = MSG_W - imgW - 22
        local lines = WrapMsg(m.text, "MSG_Body", textW)
        local ty = my+22
        for li = 1, math.min(#lines, 2) do
            draw.SimpleText(lines[li], "MSG_Body", textX, ty, Color(C_TEXT.r,C_TEXT.g,C_TEXT.b,alpha))
            ty = ty + 16
        end
    end
end)

concommand.Add("pda_msg_test", function()
    AddMessage("new_task",  "Узнать у Лиса о Стрелке", "vgui/avatar_default")
    timer.Simple(0.3, function()
        AddMessage("done",    "Пробраться за железнодорожную насыпь", "vgui/avatar_default")
    end)
    timer.Simple(0.6, function()
        AddMessage("message", "Меченый, кстати о Стрелке. Пришел сталкер из глубокого рейда, Лисом кличут. Ему, видимо, худо пришлось — просит о помощи.", "pda/task_icons/stalker.png")
    end)
	
	timer.Simple(5.0, function()
        AddMessage("new_stash", "Рюкзак Дохляка", "pda/task_icons/stash.png")
    end)
end)

-- TODO: Сделать Messages глобальным
function STALKER_AddMessage(msgType, text, imageMat)
    AddMessage(msgType, text, imageMat)
end