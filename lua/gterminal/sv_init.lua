include("sh_init.lua")
include("sv_filesystem.lua")
include("sv_compcore.lua")
include("gterminal/sv_gnet.lua")

AddCSLuaFile("sh_init.lua")
AddCSLuaFile("gterminal/cl_editor.lua")
AddCSLuaFile("gterminal/cl_luapad_editor.lua")

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

function gTerminal:Broadcast(entity, text, colorType, position, xposition, onlyColor)
	if ( !IsValid(entity) ) then
		return
	end
	if ( !entity:GetActive() ) then
		return
	end

	if !onlyColor then onlyColor = false end
	text = tostring(text)

	local index = entity:EntIndex()
	local output
	local maxChars = entity.maxChars or 50

	if (utf8.len(text) > maxChars) then
		output = {}

		local expected = math.floor(utf8.len(text) / maxChars)

		for i = 0, expected do
			output[i + 1] = utf8.sub(text, i * maxChars, (i * maxChars) + maxChars - 1)
		end
	end

	if (output) then
		for k, v in ipairs(output) do
			net.Start("gT_AddLine")
				net.WriteUInt(index, 16)
				net.WriteString(v)
				net.WriteUInt(colorType or GT_COL_MSG, 8)
				net.WriteInt(position and position + (k - 1) or -1, 16)
				net.WriteInt(xposition and xposition or 0, 7)
				net.WriteBool(onlyColor)
			net.Broadcast()
		end
	else
		net.Start("gT_AddLine")
			net.WriteUInt(index, 16)
			net.WriteString(text)
			net.WriteUInt(colorType or GT_COL_MSG, 8)
			net.WriteInt(position or -1, 16)
			net.WriteInt(xposition and xposition or 0, 7)
			net.WriteBool(onlyColor)
		net.Broadcast()
	end
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
			pitch = 38
		elseif pitch > 32767 then
			pitch = 32766
		end
		net.Start("gT_EmitSound")
		net.WriteUInt(entity:EntIndex(), 13)
		net.WriteUInt(pitch, 15)
		net.Broadcast()
		timer.Simple( del, function()
			net.Start("gT_StopSound")
			net.WriteUInt(entity:EntIndex(), 13)
			net.WriteUInt(pitch, 15)
			net.Broadcast()
		end )
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

local files, folders = file.Find("gterminal/os/*", "LUA")

for k, v in pairs(folders) do
	OS = {}
		OS.commands = {}

		function OS:NewCommand(name, Callback, help)
			self.commands[name] = {Callback = Callback, help = help}
		end

		include("os/"..v.."/sv_init.lua")

		gTerminal.os[ OS:GetUniqueID() ] = OS
	OS = nil
end 

MsgC(Color(0, 255, 0), "Initialized gTerminalUNI!\n")