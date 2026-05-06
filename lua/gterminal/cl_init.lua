include("sh_init.lua")
include("gterminal/ui/cl_editor.lua")
include("gterminal/ui/cl_luapad_editor.lua")
gt_generated_snd = {}
gt_computers_status = {}
surface.CreateFont("gT_ConsoleFont", {
	size = 28,
	weight = 800,
	antialias = true,
	font = "Lucida Console"
})

local table = table
local gTerminal = gTerminal
local net = net
local utf8 = utf8
local function utf8totable(str)
	local tbl = {}
	for _, b in utf8.codes(str) do
		table.insert(tbl, utf8.char(b))
	end
	return tbl
end

net.Receive("gT_AddLine", function(length)
    local ent = net.ReadEntity()
    if not IsValid(ent) then return end

    local text = net.ReadString()
    
    -- ЛОГИКА ЦВЕТА: Читаем флаг и определяем, индекс это или RGB объект
    local isCustom = net.ReadBool()
    local colorData
    if isCustom then
        colorData = net.ReadColor()
    else
        colorData = net.ReadUInt(8)
    end

    local position = net.ReadInt(16)
    local xposition = net.ReadInt(7)
    
    local index = ent:EntIndex()
    local maxChars = ent.maxChars or 50
    local maxLines = ent.maxLines or 24

    if not gTerminal[index] then gTerminal[index] = {} end

    -- Инициализация переменных состояния
    gTerminal[index].cursorX = gTerminal[index].cursorX or 1
    gTerminal[index].cursorY = gTerminal[index].cursorY or 1
    gTerminal[index].pendingNewLine = gTerminal[index].pendingNewLine or false
    
    -- Установка текущего цвета (может быть числом или объектом Color)
    if isCustom then
        gTerminal[index].currentColor = colorData
    elseif colorData and colorData > 0 then
        gTerminal[index].currentColor = colorData
    end
    gTerminal[index].currentColor = gTerminal[index].currentColor or GT_COL_MSG

    -- Функция создания новой строки
    local function createLine()
        if #gTerminal[index] >= maxLines then table.remove(gTerminal[index], 1) end
        local newLine = {}
        for i = 1, maxChars do
            newLine[i] = {
                char = " ",
                col = gTerminal[index].currentColor
            }
        end

        table.insert(gTerminal[index], newLine)
        gTerminal[index].cursorY = #gTerminal[index]
        gTerminal[index].cursorX = 1
        gTerminal[index].pendingNewLine = false
        return gTerminal[index][gTerminal[index].cursorY]
    end

    -- ПРОВЕРКА ОТЛОЖЕННОГО ПЕРЕНОСА
    if gTerminal[index].pendingNewLine and position <= 0 then createLine() end

    local line
    if position == -1 then
        line = createLine()
    else
        local targetY = (position == 0) and gTerminal[index].cursorY or position
        targetY = math.Clamp(targetY, 1, maxLines)
        
        if #gTerminal[index] < targetY then
            for i = #gTerminal[index] + 1, targetY do
                createLine()
            end
        end

        line = gTerminal[index][targetY]
        gTerminal[index].cursorY = targetY
        
        if xposition >= 0 then
            gTerminal[index].cursorX = (xposition == 0) and 1 or xposition
            gTerminal[index].pendingNewLine = false
        end
    end

    if text == "" then return end

    local chars = utf8totable(text)
    for i = 1, #chars do
        local char = chars[i]
        
        if char == "\b" then
            gTerminal[index].cursorX = math.max(1, gTerminal[index].cursorX - 1)
            if line then
                line[gTerminal[index].cursorX] = {
                    char = " ",
                    col = gTerminal[index].currentColor
                }
            end
        elseif char == "\n" then
            if position <= 0 then
                gTerminal[index].pendingNewLine = true
                if i < #chars then line = createLine() end
            end
        elseif char == "\t" then
            for t = 1, 4 do
                if gTerminal[index].cursorX > maxChars then line = createLine() end
                if line then
                    line[gTerminal[index].cursorX] = {
                        char = " ",
                        col = gTerminal[index].currentColor
                    }
                    gTerminal[index].cursorX = gTerminal[index].cursorX + 1
                end
            end
        else
            -- Автоперенос по ширине
            if gTerminal[index].cursorX > maxChars then
                if position <= 0 then
                    line = createLine()
                else
                    break 
                end
            end

            if line then
                line[gTerminal[index].cursorX] = {
                    char = char,
                    col = gTerminal[index].currentColor -- Здесь сохраняется либо индекс, либо Color()
                }
                gTerminal[index].cursorX = gTerminal[index].cursorX + 1
            end
        end
    end
end)

net.Receive("gT_StartAsyncKey", function()
	local ent = net.ReadEntity()
	gTerminal[ent:EntIndex()] = {}
end)

net.Receive("gT_ClsScreen", function()
	local ent = net.ReadEntity()
	gTerminal[ent:EntIndex()] = {}
end)

net.Receive("gT_ActiveConsole", function()
	local entity = net.ReadEntity()
	local client = LocalPlayer()
	local ind = #entity.consoleStory + 1
	if IsValid(entity) then
		client.gT_Entity = entity
		client.gT_TextEntry = vgui.Create("DTextEntry")
		local gT_TextEntry = client.gT_TextEntry
		gT_TextEntry:SetSize(10, 10)
		gT_TextEntry:SetPos(-20, -20)
		gT_TextEntry:SetAlpha(0)
		gT_TextEntry:MakePopup()
		local function changeCaret()
			timer.Simple(0, function()
				local maxChars = entity.maxChars
				local text = gT_TextEntry:GetValue()
				local caretPos = gT_TextEntry:GetCaretPos()
				local len = utf8.len(text)
				if len > maxChars then
					entity.consoleCaretPos = math.max(0, caretPos - (len - maxChars+2))
				else
					entity.consoleCaretPos = caretPos
				end
			end)
		end

		gT_TextEntry.OnTextChanged = function(textEntry)
			if entity:GetInputMode() == GT_INPUT_NIL then
				textEntry:SetText("")
				entity.consoleText = ""
				return
			end

			local text = textEntry:GetValue()
			local caretPos = textEntry:GetCaretPos()
			local maxChars = entity.maxChars
			local len = utf8.len(text)
			if len > maxChars then
				entity.consoleText = utf8.sub(text, len - maxChars+3)
				entity.consoleCaretPos = math.max(0, caretPos - (len - maxChars+2))
			else
				entity.consoleText = text
				entity.consoleCaretPos = caretPos
			end

			if entity:GetInputMode() == GT_INPUT_CHAR then textEntry:OnEnter() end
		end

		gT_TextEntry.OnEnter = function(textEntry)
			local text = util.Compress(tostring(textEntry:GetValue()))
			net.Start("gT_EndConsole")
			net.WriteEntity(entity)
			net.WriteUInt(#text, 16)
    		net.WriteData(text, #text)
			net.SendToServer()
			if text ~= "" then
				entity.consoleText = ""
				textEntry:SetText("")
				textEntry:SetCaretPos(0)
				table.RemoveByValue(entity.consoleStory, text)
				entity.consoleStory[#entity.consoleStory + 1] = text
				if #entity.consoleStory > 10 then table.remove(entity.consoleStory, 1) end
				ind = #entity.consoleStory + 1
			end
		end

		gT_TextEntry.OnKeyCode = function(textEntry, keyCode)
			if entity:GetInputMode() == GT_INPUT_INP then
				if #entity.consoleStory ~= 0 then
					if keyCode == KEY_UP then
						local offset = 0
						if ind > 1 then ind = ind - 1 end
						textEntry:SetText(entity.consoleStory[ind])
						textEntry:SetCaretPos(#entity.consoleStory[ind])
						local maxChars = entity.maxChars
						if utf8.len(entity.consoleStory[ind]) > maxChars then offset = textEntry:GetCaretPos() - maxChars - 3 end
						entity.consoleText = utf8.sub(entity.consoleStory[ind], offset)
						
						changeCaret()
					elseif keyCode == KEY_DOWN and ind < #entity.consoleStory then
						local offset = 0
						if ind < #entity.consoleStory then ind = ind + 1 end
						textEntry:SetText(entity.consoleStory[ind])
						textEntry:SetCaretPos(#entity.consoleStory[ind])
						local maxChars = entity.maxChars
						if utf8.len(entity.consoleStory[ind]) > maxChars then offset = textEntry:GetCaretPos() - maxChars - 3 end
						entity.consoleText = utf8.sub(entity.consoleStory[ind], offset)

						changeCaret()
					end
				end

				if keyCode == KEY_LEFT or keyCode == KEY_RIGHT then changeCaret() end
			end
		end
	end
end)

net.Receive("gT_EndTyping", function(length)
	local client = LocalPlayer()
	if not IsValid(client.gT_TextEntry) then return end
	client.gT_TextEntry:Remove()
	if IsValid(client.gT_Entity) then client.gT_Entity.consoleText = "" end
end)

net.Receive("gT_ChangeBackgroundColor", function()
	local ent = net.ReadEntity()
	local color = net.ReadColor()
	ent.BackgroundColor = color
end)

net.Receive("gT_ChangeForegroundColor", function()
	local ent = net.ReadEntity()
	local color = net.ReadColor()
	local pos = net.ReadUInt(GT_colors_bit_count)
	ent.colors[pos] = color
end)

-- BEEP SOUNDS --
local gTerminalGenerateSpkSound
do
	local function data(t, f)
		return math.sin(t * math.pi * 2 / 44100 * f)
	end

	gTerminalGenerateSpkSound = function(frequency, cached_str, cached_freq)
		if not gt_generated_snd[frequency] then
			sound.Generate(cached_str or "gt_pc_spk_" .. (cached_freq or tostring(frequency)), 44100, math.Round(44100 / frequency) / 44100, function(t) return data(t, frequency) end, 0)
			gt_generated_snd[frequency] = true
		end
	end
end

net.Receive("gT_EmitSound", function()
	local entity = net.ReadEntity()
	local frequency = net.ReadUInt(15)
	local duration = net.ReadUInt(32) / 1000
	local cached_freq = tostring(frequency)
	local snd_name = "gt_pc_spk_" .. cached_freq
	gTerminalGenerateSpkSound(frequency, snd_name, cached_freq)
	entity:EmitSound(snd_name, 75)
	timer.Simple(duration, function() entity:StopSound(snd_name) end)
end)

MsgC(Color(179, 255, 0), "gTerminal: Universal loaded!\n")