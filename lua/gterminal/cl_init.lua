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
} )

local table = table 
local gTerminal = gTerminal 
local net = net 

-- net.Receive("gT_AddLine", function(length)
-- 	local index = net.ReadUInt(16)
-- 	local text = net.ReadString()
-- 	local colorType = net.ReadUInt(8)
-- 	local position = net.ReadInt(16)
-- 	local xposition = net.ReadInt(7)
-- 	local only_color = net.ReadBool()

-- 	local ent = Entity(index)
-- 	local maxChars = ent.maxChars


-- 	if ( !gTerminal[index] ) then
-- 		gTerminal[index] = {} 
-- 	end 

-- 	if only_color then
-- 		if gTerminal[index][position] then
-- 			gTerminal[index][position].color = colorType
-- 		end
-- 		return
-- 	end

-- 	if (!position or position == -1) then
-- 		table.insert( gTerminal[index], {text = text, color = colorType} )
-- 	else
-- 		if xposition == 0 then
-- 			gTerminal[index][position] = {text = text, color = colorType} 
-- 		else
-- 			local str = gTerminal[index][position].text
-- 			local nlen = maxChars + 1 - utf8.len(str)

-- 			if nlen > 0 then
-- 				for i = 0, nlen do
-- 					str = str .. " "
-- 				end
-- 			end

-- 			local t = {}

-- 			if utf8.len(text) < 1 then
-- 				for i = 1, utf8.len(str) do
-- 					table.insert(t, string.sub(str, i, i))
-- 				end
-- 				table.remove(t, xposition)
-- 				table.insert(t, xposition, text)

-- 				local new_str = ""

-- 				for k, v in pairs(t) do
-- 					new_str = new_str .. t[k]
-- 				end
-- 				gTerminal[index][position] = {text = new_str, color = colorType}
-- 			else
-- 				local tl = utf8.len(text)
-- 				if tl + xposition > maxChars + 1 then
-- 					text = string.sub(text, 0, maxChars + 1 - xposition)
-- 				end
-- 				for i = 1, utf8.len(str) do
-- 					table.insert(t, string.sub(str, i, i))
-- 				end
-- 				for i = 1, tl do
-- 					table.remove(t, xposition)
-- 				end
-- 				for i = tl, 1, -1 do
-- 					table.insert(t, xposition, string.sub(text, i, i))
-- 				end

-- 				local new_str = ""
-- 				for k, v in pairs(t) do
-- 					new_str = new_str .. t[k]
-- 				end
-- 				gTerminal[index][position] = {text = new_str, color = colorType}
-- 			end
-- 		end
-- 	end 

-- 	if (#gTerminal[index] > (ent.maxLines or 24) ) then
-- 		table.remove(gTerminal[index], 1)
-- 	end 
-- end)
net.Receive("gT_AddLine", function(length)
	local index = net.ReadUInt(16)
	local text = net.ReadString()
	local colorType = net.ReadUInt(8)
	local position = net.ReadInt(16)
	local xposition = net.ReadInt(7)
	local only_color = net.ReadBool()

	local ent = Entity(index)
	local maxChars = ent.maxChars


	if ( !gTerminal[index] ) then
		gTerminal[index] = {} 
	end 

	if only_color then
		if gTerminal[index][position] then
			gTerminal[index][position].color = colorType
		end
		return
	end

	if (!position or position == -1) then
		table.insert( gTerminal[index], {text = text, color = colorType} )
	else
		if xposition == 0 then
			gTerminal[index][position] = {text = text, color = colorType} 
		else
			local str = gTerminal[index][position].text
			local nlen = maxChars + 1 - utf8.len(str)

			if nlen > 0 then
				-- for i = 0, nlen do
					str = str .. string.rep(" ", nlen) // ЧЕК
				-- end
			end

			local t = {}

			if utf8.len(text) < 1 then
				for i = 1, utf8.len(str) do
					table.insert(t, string.sub(str, i, i))
				end
				table.remove(t, xposition)
				table.insert(t, xposition, text)

				local new_str = ""

				for k, v in pairs(t) do
					new_str = new_str .. t[k]
				end
				gTerminal[index][position] = {text = new_str, color = colorType}
			else
				local tl = utf8.len(text)
				if tl + xposition > maxChars + 1 then
					text = string.sub(text, 0, maxChars + 1 - xposition)
				end
				for i = 1, utf8.len(str) do
					table.insert(t, string.sub(str, i, i))
				end
				for i = 1, tl do
					table.remove(t, xposition)
				end
				for i = tl, 1, -1 do
					table.insert(t, xposition, string.sub(text, i, i))
				end

				local new_str = ""
				for k, v in pairs(t) do
					new_str = new_str .. t[k]
				end
				gTerminal[index][position] = {text = new_str, color = colorType}
			end
		end
	end 

	if (#gTerminal[index] > (ent.maxLines or 24) ) then
		table.remove(gTerminal[index], 1)
	end 
end)
net.Receive("gT_StartAsyncKey", function ()
	local ent = net.ReadEntity()
	gTerminal[ent:EntIndex()] = {}
end)
net.Receive("gT_ClsScreen", function ()
	local ent = net.ReadEntity()
	gTerminal[ent:EntIndex()] = {}
end)
net.Receive("gT_ActiveConsole", function()
	local index = net.ReadUInt(16)
	local entity = Entity(index)
	local client = LocalPlayer()
	local ind = #entity.consoleStory + 1

	if ( IsValid(entity) ) then
		client.gT_Entity = entity 
		client.gT_TextEntry = vgui.Create("DTextEntry")
		client.gT_TextEntry:SetSize(0, 0)
		client.gT_TextEntry:SetPos(0, 0)
		client.gT_TextEntry:MakePopup()


		client.gT_TextEntry.OnTextChanged = function(textEntry)
			local offset = 0
			if entity:GetInputMode() == GT_INPUT_NIL then
				textEntry:SetText("")
				entity.consoleText = ""
				return
			end
			local text = textEntry:GetValue()
			local maxChars = entity.maxChars or 50

			if (utf8.len(text) > maxChars) then
				offset = textEntry:GetCaretPos() - maxChars - 3
			end 

			entity.consoleText = utf8.sub(text, offset)
			if entity:GetInputMode() == GT_INPUT_CHAR then
				textEntry:OnEnter()
			end
		end 

		client.gT_TextEntry.OnEnter = function(textEntry)
			local text = tostring(textEntry:GetValue())

			net.Start("gT_EndConsole")
				net.WriteUInt(index, 16)
				net.WriteString( text )
			net.SendToServer()

			if text != "" then
				entity.consoleText = ""
				textEntry:SetText("")
				textEntry:SetCaretPos(0)
				table.RemoveByValue(entity.consoleStory, text)
				entity.consoleStory[#entity.consoleStory + 1] = text
				if #entity.consoleStory > 10 then
					table.remove(entity.consoleStory, 1)
				end
				ind = #entity.consoleStory + 1
			end
		end

		client.gT_TextEntry.OnKeyCode = function( textEntry, keyCode )
			if entity:GetInputMode() == GT_INPUT_INP and #entity.consoleStory != 0 then
				if (keyCode == KEY_UP) then
					local offset = 0
					if ind > 1 then
						ind = ind - 1
					end

					textEntry:SetText(entity.consoleStory[ind])
					textEntry:SetCaretPos(#entity.consoleStory[ind])

					local maxChars = entity.maxChars or 50

					if (utf8.len(entity.consoleStory[ind]) > maxChars) then
						offset = textEntry:GetCaretPos() - maxChars - 3
					end 

					entity.consoleText = utf8.sub(entity.consoleStory[ind], offset)
				elseif (keyCode == KEY_DOWN and ind < #entity.consoleStory) then
					local offset = 0
					if ind < #entity.consoleStory then
						ind = ind + 1
					end

					textEntry:SetText(entity.consoleStory[ind])
					textEntry:SetCaretPos(#entity.consoleStory[ind])

					local maxChars = entity.maxChars or 50

					if (utf8.len(entity.consoleStory[ind]) > maxChars) then
						offset = textEntry:GetCaretPos() - maxChars - 3
					end 

					entity.consoleText = utf8.sub(entity.consoleStory[ind], offset)
				end
			end
		end 
	end 
end)

net.Receive("gT_EndTyping", function(length)
	local client = LocalPlayer()

	if ( !IsValid(client.gT_TextEntry) ) then
		return 
	end 

	client.gT_TextEntry:Remove()

	if ( IsValid(client.gT_Entity) ) then
		client.gT_Entity.consoleText = "" 
	end 
end)

net.Receive("gT_ChangeBackgroundColor", function()
	local index = net.ReadUInt(16)
	local color = net.ReadColor()

	local ent = Entity(index)
	ent.BackgroundColor = color
end)

net.Receive("gT_ChangeForegroundColor", function()
	local index = net.ReadUInt(16)
	local color = net.ReadColor()
	local pos = net.ReadUInt(GT_colors_bit_count)

	local ent = Entity(index)
	ent.colors[pos] = color
end)

-- BEEP SOUNDS --
local gTerminalGenerateSpkSound
do
	local function data( t, f )
		return math.sin( t * math.pi * 2 / 44100 * f )
	end
	gTerminalGenerateSpkSound = function(frequency, cached_str, cached_freq)
		if !gt_generated_snd[frequency] then
			sound.Generate( cached_str or "gt_pc_spk_" .. (cached_freq or tostring(frequency)) , 44100, math.Round(44100 / frequency) / 44100, function(t) return data(t, frequency) end, 0)
			gt_generated_snd[frequency] = true
		end
	end
end

-- net.Receive("gT_GenerateSoundtbl", function()
	-- for freq in pairs(net.ReadTable()) do
		-- gTerminalGenerateSpkSound(freq)
	-- end
-- end)

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

MsgC(Color(0, 255, 0), "gTerminal: Universal loaded!\n") 