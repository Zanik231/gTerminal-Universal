include("sh_init.lua")
include("components/sv_filesystem.lua")
include("components/sv_compcore.lua")
include("components/sv_gnet.lua")

AddCSLuaFile("sh_init.lua")
AddCSLuaFile("ui/cl_editor.lua")
AddCSLuaFile("ui/cl_luapad_editor.lua")

util.AddNetworkString("gT_ActiveConsole")
util.AddNetworkString("gT_EndConsole")
util.AddNetworkString("gT_AddLine")
util.AddNetworkString("gT_ClsScreen")
util.AddNetworkString("gT_EndTyping")
util.AddNetworkString("gT_ChangeBackgroundColor")
util.AddNetworkString("gT_ChangeForegroundColor")
util.AddNetworkString("gT_EmitSound")

gTerminal = gTerminal or {}
gTerminal.os = gTerminal.os or {}

local gTerminal = gTerminal
local net = net

function gTerminal:ChangeForegroundColor(entity, color, color_index)
	net.Start("gT_ChangeForegroundColor")
	net.WriteEntity(entity)
	net.WriteColor(color)
	net.WriteUInt(color_index, GT_colors_bit_count)
	net.Broadcast()
end
function gTerminal:ChangeBackgroundColor(entity, color)
	net.Start("gT_ChangeBackgroundColor")
	net.WriteEntity(entity)
	net.WriteColor(Color(color.r, color.g, color.b, entity.DefaultBackgroundColor.a))
	net.Broadcast()
end

function gTerminal:ClearConsole(entity)
	net.Start("gT_ClsScreen")
	net.WriteEntity(entity)
	net.Broadcast()
end

-- OUTPUT TEXT --

gTerminal.CurrentColors = gTerminal.CurrentColors or {}

function gTerminal:SetColor(entity, colorIndex)
    gTerminal.CurrentColors[entity:EntIndex()] = colorIndex or GT_COL_MSG
end

function gTerminal:SendSmartChunk(entity, text, color, pos, xpos)
    net.Start("gT_AddLine")
        net.WriteEntity(entity)
        net.WriteString(text)
        
        local isCustom = IsColor(color)
        net.WriteBool(isCustom)
        if isCustom then
            net.WriteColor(color)
        else
            net.WriteUInt(color or GT_COL_MSG, 8)
        end
        
        net.WriteInt(pos, 16)
        net.WriteInt(xpos or -1, 7)
    net.Broadcast()
end

function gTerminal:Broadcast(entity, text, colorType, position, xposition)
    if not IsValid(entity) then return end
    
    local index = entity:EntIndex()
    local oldColor = gTerminal.CurrentColors[index] or GT_COL_MSG
    local activeColor = colorType or oldColor

    local isStaticPos = position and position > 0

    self:SendSmartChunk(entity, tostring(text or ""), activeColor, position or 0, xposition or (isStaticPos and 1 or -1))
    
    if colorType and colorType != oldColor then
        self:SendSmartChunk(entity, "", oldColor, 0, -1)
    end

    if not isStaticPos then
        self:SendSmartChunk(entity, "\n", oldColor, 0, -1)
    end
end

function gTerminal:WriteText(entity, text, colorType)
    if not IsValid(entity) then return end

    local index = entity:EntIndex()
    local oldColor = gTerminal.CurrentColors[index] or GT_COL_MSG
    local activeColor = colorType or oldColor

    self:SendSmartChunk(entity, tostring(text), activeColor, 0, -1)

    if colorType and colorType != oldColor then
        self:SendSmartChunk(entity, "", oldColor, 0, -1)
    end
end

function gTerminal:GetEntityCurrentLine(ent)
    if not IsValid(ent) then return nil end
    local index = ent:EntIndex()
    local data = gTerminal[index]
    if not data then return nil end

    local y = data.cursorY or 1
    return data.cursorX or 1, y, data[y] 
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
		net.WriteEntity(entity)
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
	local entity = net.ReadEntity()
	local text = util.Decompress(net.ReadData(net.ReadUInt(16)))

	if (IsValid(entity) and entity.GetUser and IsValid( entity:GetUser() ) and entity:GetUser() == client) then
		if (text == "") then
			entity:SetUser(nil)

			net.Start("gT_EndTyping")
			net.Send(client)

			return
		end 
		if entity.os == "custom_os" then
			entity:InputHandler()
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
			local system = gTerminal.os[entity.os].commands

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
		gTerminal.os[ OS:GetUniqueID() ] = OS
	OS = nil
	end 
end
ALL_OS_INIT()
concommand.Add("gterminal_reload_lua_files", function() if CLIENT then return end ALL_OS_INIT() end)

-- hook.Add('LoadGModSave', 'GterminalReload', function() timer.Simple(0.5, ALL_OS_INIT) end)
MsgC(Color(0, 255, 0), "Initialized gTerminalUNI!\n")