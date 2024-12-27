include("sh_init.lua");
include("gterminal/cl_editor.lua")

gt_generated_snd = {}

surface.CreateFont("gT_ConsoleFont", {
	size = 28,
	weight = 800,
	antialias = true,
	font = "Lucida Console"
} );

local table = table;
local gTerminal = gTerminal;
local net = net;

net.Receive("gT_AddLine", function(length)
	local index = net.ReadUInt(16);
	local text = net.ReadString();
	local colorType = net.ReadUInt(8);
	local position = net.ReadInt(16);
	local xposition = net.ReadInt(7)
	local only_color = net.ReadBool()

	local ent = Entity(index)
	local maxChars = ent.maxChars


	if ( !gTerminal[index] ) then
		gTerminal[index] = {};
	end;

	if only_color then
		if gTerminal[index][position] then
			gTerminal[index][position].color = colorType
		end
		return
	end

	if (!position or position == -1) then
		table.insert( gTerminal[index], {text = text, color = colorType} );
	else
		if xposition == 0 then
			gTerminal[index][position] = {text = text, color = colorType};
		else
			local str = gTerminal[index][position].text
			local nlen = maxChars + 1 - utf8.len(str)

			if nlen > 0 then
				for i = 0, nlen do
					str = str .. " "
				end
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
	end;

	if (#gTerminal[index] > (ent.maxLines or 24) ) then
		table.remove(gTerminal[index], 1);
	end;
end);

net.Receive("gT_ActiveConsole", function()
	local index = net.ReadUInt(16);
	local entity = Entity(index);
	local client = LocalPlayer();

	if ( IsValid(entity) ) then
		client.gT_Entity = entity;
		client.gT_TextEntry = vgui.Create("DTextEntry");
		client.gT_TextEntry:SetSize(0, 0);
		client.gT_TextEntry:SetPos(0, 0);
		client.gT_TextEntry:MakePopup();

		client.gT_TextEntry.OnTextChanged = function(textEntry)
			local offset = 0;
			local text = textEntry:GetValue();
			local maxChars = entity.maxChars or 50


			if (utf8.len(text) > maxChars) then
				offset = textEntry:GetCaretPos() - maxChars - 3;
			end;

			entity.consoleText = utf8.sub(text, offset);
		end;

		client.gT_TextEntry.OnEnter = function(textEntry)
			net.Start("gT_EndConsole");
				net.WriteUInt(index, 16);
				net.WriteString( tostring( textEntry:GetValue() ) );
			net.SendToServer();

			textEntry:SetText("");
			textEntry:SetCaretPos(0);

			entity.consoleText = "";
		end;
	end;
end);

net.Receive("gT_EndTyping", function(length)
	local client = LocalPlayer();

	if ( !IsValid(client.gT_TextEntry) ) then
		return;
	end;

	client.gT_TextEntry:Remove();

	if ( IsValid(client.gT_Entity) ) then
		client.gT_Entity.consoleText = "";
	end;
end);

net.Receive("gT_ChangeBackgroundColor", function()
	local index = net.ReadUInt(16);
	local color = net.ReadColor();

	local ent = Entity(index);
	ent.BackgroundColor = color
end);

net.Receive("gT_ChangeForegroundColor", function()
	local index = net.ReadUInt(16);
	local color = net.ReadColor();
	local pos = net.ReadUInt(3);

	local ent = Entity(index);
	ent.colors[pos] = color
end);

net.Receive("gT_GenerateSound", function()
	local frequency = net.ReadUInt(15)
	if gt_generated_snd[frequency] != nil then
		return
	end
	local samplerate = 44100
	local function data( t )
		return math.sin( t * math.pi * 2 / samplerate * frequency )
	end
	
	
	sound.Generate( "gt_pc_spk_" .. tostring(frequency), samplerate, 0.1, data, 0)
	gt_generated_snd[tostring(frequency) .. "_" .. tostring(time)] = true
end);

net.Receive("gT_GenerateSoundtbl", function()
	local tabl = net.ReadTable()
	local freq = 0
	local function data( t )
		return math.sin( t * math.pi * 2 / 44100 * freq )
	end
	for i = 1, #tabl do
		if gt_generated_snd[tabl[i]] != nil then
			continue
		end
		freq = tabl[i]
		sound.Generate( "gt_pc_spk_" .. tostring(freq), 44100, 1, data, 0)
		gt_generated_snd[tabl[i]] = true
	end
end);

net.Receive("gT_EmitSound", function()
	local entity = Entity(net.ReadUInt(14))
	local frequency = net.ReadUInt(15)
	if gt_generated_snd[frequency] == nil then
		local function data( t )
			return math.sin( t * math.pi * 2 / 44100 * frequency )
		end
		
		sound.Generate( "gt_pc_spk_" .. tostring(frequency), 44100, 1, data, 0)
		gt_generated_snd[tostring(frequency)] = true
	end
	entity:EmitSound("gt_pc_spk_" .. tostring(frequency), GT_SPK_LVL)
end);

net.Receive("gT_StopSound", function()
	local entity = Entity(net.ReadUInt(14))
	local frequency = net.ReadUInt(15)
	entity:StopSound("gt_pc_spk_" .. tostring(frequency))
end);

MsgC(Color(0, 255, 0), "Loading gTerminalUNI!\n");