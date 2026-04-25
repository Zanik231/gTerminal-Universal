include("sh_init.lua")
include("components/sv_filesystem.lua")
include("components/sv_compcore.lua")
include("components/sv_gnet.lua")

AddCSLuaFile("sh_init.lua")
AddCSLuaFile("ui/cl_editor.lua")
AddCSLuaFile("ui/cl_luapad_editor.lua")

-- util.AddNetworkString("gT_InputMode")

util.AddNetworkString("gT_ActiveConsole")
util.AddNetworkString("gT_EndConsole")
util.AddNetworkString("gT_AddColorLine")
util.AddNetworkString("gT_AddLine")
util.AddNetworkString("gT_ClsScreen")
util.AddNetworkString("gT_EndTyping")
util.AddNetworkString("gT_ChangeBackgroundColor")
util.AddNetworkString("gT_ChangeForegroundColor")
util.AddNetworkString("gT_GenerateSound")
util.AddNetworkString("gT_GenerateSoundtbl")
util.AddNetworkString("gT_EmitSound")
util.AddNetworkString("gT_StopSound")

gTerminal = gTerminal or {}
gTerminal.os = gTerminal.os or {}

local gTerminal = gTerminal
local net = net

function gTerminal:ChangeForegroundColor(entity, color, color_index)
	net.Start("gT_ChangeForegroundColor")
	net.WriteUInt(entity:EntIndex(),16)
	net.WriteColor(color)
	net.WriteUInt(color_index, GT_colors_bit_count)
	net.Broadcast()
end
function gTerminal:ChangeBackgroundColor(entity, color)
	net.Start("gT_ChangeBackgroundColor")
	net.WriteUInt(entity:EntIndex(),16)
	net.WriteColor(color)
	net.Broadcast()
end

function gTerminal:ClearConsole(entity)
	net.Start("gT_ClsScreen")
	net.WriteEntity(entity)
	net.Broadcast()
end


colorTags = {
    ["red"] = GT_COL_ERR,
    ["green"] = GT_COL_SUCC,
    ["white"] = GT_COL_MSG,
    ["blue"] = GT_COL_INFO,
}

function gTerminal:Broadcast(entity, text, colorType, position, xposition)
    if !IsValid(entity) or !entity:GetActive() then return end
    
    text = tostring(text)
    local index = entity:EntIndex()
    local maxChars = entity.maxChars or 50

    -- 1. Проверяем, есть ли в тексте теги цветов
    if text:find("{.-}") then
        -- Если есть теги, создаем новую пустую строку
        -- Мы вызываем саму себя, но с пустым текстом без тегов
        self:Broadcast(entity, "", colorType or GT_COL_MSG, position, xposition)

        local currentX = math.max(1, xposition or 1)
        -- Если текст начинается не с тега, добавляем дефолтный белый
        if not text:find("^{") then text = "{white}" .. text end

        -- Парсим теги
        for tag, content in text:gmatch("{(.-)}([^{]*)") do
            local col = colorTags[tag] or colorType or GT_COL_MSG
            if content and #content > 0 then
                net.Start("gT_AddLine")
                    net.WriteUInt(index, 16)
                    net.WriteString(content)
                    net.WriteUInt(col, 8)
                    net.WriteInt(0, 16) -- 0 = редактировать последнюю созданную строку
                    net.WriteInt(currentX, 7)
                    net.WriteBool(false)
                net.Broadcast()
                currentX = currentX + utf8.len(content)
            end
        end
    else
        -- 2. Обычная логика (если тегов нет или текст пустой)
        local textLen = utf8.len(text)
        
        -- Если текст слишком длинный — режем на куски
        if textLen > maxChars then
            local expected = math.ceil(textLen / maxChars)
            for i = 1, expected do
                local chunk = utf8.sub(text, ((i - 1) * maxChars) + 1, i * maxChars)
                net.Start("gT_AddLine")
                    net.WriteUInt(index, 16)
                    net.WriteString(chunk)
                    net.WriteUInt(colorType or GT_COL_MSG, 8)
                    net.WriteInt(position and (position + i - 1) or -1, 16)
                    net.WriteInt(xposition or 0, 7)
                    net.WriteBool(false)
                net.Broadcast()
            end
        else
            -- Короткий обычный текст
            net.Start("gT_AddLine")
                net.WriteUInt(index, 16)
                net.WriteString(text)
                net.WriteUInt(colorType or GT_COL_MSG, 8)
                net.WriteInt(position or -1, 16)
                net.WriteInt(xposition or 0, 7)
                net.WriteBool(false)
            net.Broadcast()
        end
    end
end

function gTerminal:WriteText(entity, text, colorType)
    if !IsValid(entity) then return end
    
    -- Просто шлем текст с xposition = -1
    -- Это скажет клиенту: "продолжай с того места, где замер cursorX"
    net.Start("gT_AddLine")
        net.WriteUInt(entity:EntIndex(), 16)
        net.WriteString(tostring(text))
        net.WriteUInt(colorType or GT_COL_MSG, 8)
        net.WriteInt(0, 16) 
        net.WriteInt(-1, 7) 
        net.WriteBool(false)
    net.Broadcast()
end


function gTerminal:SPK_Beep(entity, pitch, del)
	if(table.HasValue(entity.periphery, "sent_pc_spk")) then
		if pitch == nil then
			pitch = 2000
		end
		if del == nil then
			del = GT_SPK_DEL
		end
		if del < 0 then
			del = GT_SPK_DEL
		end
		if pitch < 37 then
			pitch = 37
		elseif pitch > 32767 then
			pitch = 32767
		end
		net.Start("gT_EmitSound")
		net.WriteUInt(entity:EntIndex(), 13)
		net.WriteUInt(pitch, 15)
		net.WriteUInt(del, 32)
		net.Broadcast()
	end
end

function gTerminal:GetInput(entity, Callback)
	entity.acceptingInput = true
	entity.inputCallback = Callback
end

net.Receive("gT_EndConsole", function(length, client)
	local index = net.ReadUInt(16)
	local entity = Entity(index)
	local text = net.ReadString()

	if (IsValid(entity) and entity.GetUser and IsValid( entity:GetUser() ) and entity:GetUser() == client) then
		if (text == "") then
			entity:SetUser(nil)

			net.Start("gT_EndTyping")
			net.Send(client)

			return
		end 
		if entity.os == "custom_os" then
			entity:InputHandler() // ДОДЕЛАТЬ!!!
			return
		end
		if ( entity.password and !client["pass_authed_"..index] ) then
			if (text == entity.password) then
				client["pass_authed_"..index] = true
				gTerminal:Broadcast(entity, "Password accepted.")
			else
				gTerminal:Broadcast(entity, "Please enter your password:")
				return
			end
		end

		if (entity.acceptingInput) then
			local Callback = entity.inputCallback
			entity.acceptingInput = nil
			entity.inputCallback = nil

			Callback(client, text)
			return 
		end
		local prefix = GetConVar("gterminal_command_prefix"):GetString()
		local is_space_prefix = prefix == ""

		if (string.sub(text, 1, 1) == prefix or is_space_prefix) then
			local system = entity.os.commands

			if (system) then
				local str = string.Split(text, " ")
				local command = string.sub( string.lower(text), is_space_prefix and 1 or 2, #str[1])
				table.remove(str, 1)
				if (system[command]) then
					if (text) then
						gTerminal:Broadcast(entity, text, GT_COL_CMD)
					end
					local success, value = pcall(system[command].Callback, client, entity, str, text)
					if (value) then
						gTerminal:Broadcast(entity, value, GT_COL_ERR)
					end
					return
				end

				text = "Invalid command! ("..string.sub(text, is_space_prefix and 1 or 2)..")"
			else
				gTerminal:Broadcast(entity, "System error from user response!", GT_COL_INTL)

				return
			end
		end

		local finalized = (entity.name or "User".."@"..entity:EntIndex()).." => "..tostring(text)

		gTerminal:Broadcast(entity, finalized, GT_COL_NIL)
	end 
end)

local function ALL_OS_INIT()
	local _, folders = file.Find("gterminal/os/*", "LUA")
	for k, v in pairs(folders) do
		OS = {}
		OS.commands = {}
		
		function OS:NewCommand(name, Callback, help)
			self.commands[name] = {Callback = Callback, help = help}
		end

		include("gterminal/os/"..v.."/sv_init.lua")

		for _, ent in ents.Iterator() do
			if ent.Base == "sent_computer_base" and ent.os:GetUniqueID() == OS:GetUniqueID() then
				ent.os = OS
			end
		end
		gTerminal.os[ OS:GetUniqueID() ] = OS
	OS = nil
	end 
end
ALL_OS_INIT()
concommand.Add("gterminal_reload_lua_files", function() if CLIENT then return end ALL_OS_INIT() end)

MsgC(Color(0, 255, 0), "Initialized gTerminalUNI!\n")