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

function gTerminal:SendSmartChunk(entity, text, color, pos, xpos)
    net.Start("gT_AddLine")
        net.WriteUInt(entity:EntIndex(), 16)
        net.WriteString(text)
        net.WriteUInt(color or GT_COL_MSG, 8)
        net.WriteInt(pos, 16)   -- -1 новая, 0 последняя, >0 конкретный номер
        net.WriteInt(xpos, 7)  -- -1 авто-курсор, 0 или >0 конкретный X
        net.WriteBool(false)
    net.Broadcast()
end



function gTerminal:ParseAndSend(entity, text, defaultColor, pos, xpos)
	if not IsValid(entity) then return end
	
	local index = entity:EntIndex()
	local escapedText = tostring(text):gsub("{{", "\1"):gsub("}}", "\2")
	
	local currentPos = pos or -1
	
	-- Умная логика X: если строка задана числом (18, 20), а X не указан, 
	-- то принудительно ставим 1 (начало строки), чтобы не ломать анимацию.
	local currentX = xpos
	if not currentX then
		if currentPos > 0 then
			currentX = 1
		else
			currentX = -1 -- Для новых строк или Append используем курсор
		end
	end

	-- Если в тексте нет цветовых тегов
	if not escapedText:find("{.-}") then
		local final = escapedText:gsub("\1", "{"):gsub("\2", "}")
		self:SendSmartChunk(entity, final, defaultColor or GT_COL_MSG, currentPos, currentX)
		return
	end

	-- Если это новая строка (pos == -1), сначала создаем её
	if currentPos == -1 then
		self:SendSmartChunk(entity, "", defaultColor or GT_COL_MSG, -1, 0)
		currentPos = 0 -- Переключаемся в режим "последняя строка"
		currentX = 1   -- Начинаем с начала этой строки
	end

	-- Гарантируем начальный цвет
	if not escapedText:find("^{") then 
		escapedText = "{white}" .. escapedText 
	end

	-- Цикл парсинга тегов
	for tag, content in escapedText:gmatch("{(.-)}([^{]*)") do
		local col = colorTags[tag]
		
		if col then
			local clean = content:gsub("\1", "{"):gsub("\2", "}")
			self:SendSmartChunk(entity, clean, col, currentPos, currentX)
			-- После первого куска в этой строке всегда переходим в режим дозаписи (-1)
			currentX = -1 
		else
			local raw = "{" .. tag .. "}" .. content
			local cleanRaw = raw:gsub("\1", "{"):gsub("\2", "}")
			self:SendSmartChunk(entity, cleanRaw, defaultColor or GT_COL_MSG, currentPos, currentX)
			currentX = -1
		end
	end
end




function gTerminal:Broadcast(entity, text, colorType, position, xposition)
    if !IsValid(entity) then return end
    self:ParseAndSend(entity, tostring(text), colorType or GT_COL_MSG, position, xposition)
end

function gTerminal:WriteText(entity, text, colorType)
    if !IsValid(entity) then return end
    self:ParseAndSend(entity, tostring(text), colorType or GT_COL_MSG, 0, -1)
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