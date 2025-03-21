local gTerminal = gTerminal;
local Periph = gTerminal.Periph
local Filesystem = gTerminal.Filesystem
local timer = timer;
local OS = OS;

OS:NewCommand("help", function(client, entity, arguments)
	gTerminal:Broadcast(entity, string.rep("=",entity.maxChars));
	gTerminal:Broadcast(entity, "  " .. OS:GetName() .. " Help Menu");
	gTerminal:Broadcast(entity, "");
	gTerminal:Broadcast(entity, "    COMMANDS:");

	for k, v in SortedPairs( OS:GetCommands() ) do
		gTerminal:Broadcast(entity, "     ".. GetConVar("gterminal_command_prefix"):GetString() ..k.." - "..v.help);
	end;

	gTerminal:Broadcast(entity, string.rep("=",entity.maxChars));
end, "Provides a list of help.");

OS:NewCommand("color", function(client, entity, arguments)
	if arguments[1] == nil and arguments[2] == nil and arguments[3] == nil and arguments[4] == nil then
		gTerminal:Broadcast(entity, "Usage - " ..GetConVar("gterminal_command_prefix"):GetString() .. "color <b/f> <red> <green> <blue>");
	elseif arguments[1] != "f" and arguments[1] != "b" then
		gTerminal:Broadcast(entity, "Second argument must be 'f' or 'b'!")
	elseif tonumber(arguments[2]) == nil or tonumber(arguments[3]) == nil or tonumber(arguments[4]) == nil then
		gTerminal:Broadcast(entity, "One of argument not a number or some argument missing!");
	else
		if arguments[1] == "b" then
			net.Start("gT_ChangeBackgroundColor");
			net.WriteUInt(entity:EntIndex(),16);
			if entity.BackgroundColor == nil then
				net.WriteColor(Color(tonumber(arguments[2]),tonumber(arguments[3]),tonumber(arguments[4]),255));
			else
				net.WriteColor(Color(tonumber(arguments[2]),tonumber(arguments[3]),tonumber(arguments[4]),entity.BackgroundColor:ToTable()[4] or 255));
			end
			net.Broadcast();
		else
			if tonumber(arguments[5]) != nil then
				if tonumber(arguments[5]) then
					gTerminal:Broadcast(entity, "arguments[5] is above 7");
				end
			else
			net.Start("gT_ChangeForegroundColor");
			net.WriteUInt(entity:EntIndex(),16);
			net.WriteColor(Color(tonumber(arguments[2]),tonumber(arguments[3]),tonumber(arguments[4]),255));
			net.WriteUInt(tonumber(arguments[5]) or GT_COL_MSG, 3);
			net.Broadcast();
			end
		end
	end
	end, "Change color for (back/fore)ground.");

OS:NewCommand("inp", function(client, entity)
	gTerminal:GetInput(entity, function(cl,args)
		if args then
			gTerminal:Broadcast(entity, table.concat(args, " ", 1));
		end
	end)
end, "Input and output all on screen.");

OS:NewCommand("cls", function(client, entity)
	for i = 0, entity.maxLines do
		timer.Simple(i * 0.05, function()
			if ( IsValid(entity) ) then
				gTerminal:Broadcast(entity, "", MSG_COL_NIL, i);
			end;
		end);
	end;
end, "Clears the screen.");

OS:NewCommand("gid", function(client, entity)
	gTerminal:Broadcast( entity, "TERMINAL ID => "..entity:EntIndex() );
end, "Gets the terminal ID.");

OS:NewCommand("claim", function(client, entity, arguments)

	local nearest = nil
	local range = 128
	local override = false
	local search_str = "Searching for nearest open I/O device..."
	
	if (arguments[1] == "override") then
		override = true
		search_str = "Searching for nearest overridable I/O device..."
	end
	
	gTerminal:Broadcast(entity, "")
	gTerminal:Broadcast(entity, search_str)
	
	for k, v in pairs(ents.FindByClass("sent_iodevice")) do
		if (!IsValid(v:GetComputer()) or override) then
			local dist = entity:GetPos():Distance(v:GetPos())
			if (dist <= range) then
				nearest = v
				range = dist
			end
		end
	end
	
	if (nearest == nil) then
		gTerminal:Broadcast(entity, "No I/O devices were found nearby.", GT_COL_WRN)
	else
		gTerminal:Broadcast(entity, "Nearest I/O device: [" .. nearest:EntIndex() .. "]")
		gTerminal:Broadcast(entity, "Claiming this device...")
		nearest:SetComputer(entity)
		gTerminal:Broadcast(entity, "I/O Device [" .. nearest:EntIndex() .. "] claimed.")
	end
	
end, "Connects to an unclaimed I/O device.")

OS:NewCommand("wset", function(client, entity, arguments)

	local nearest = nil
	local range = 128
	
	for k, v in pairs(ents.FindByClass("sent_iodevice")) do
		if (v:GetComputer() == entity) then
			local dist = entity:GetPos():Distance(v:GetPos())
			if (dist <= range) then
				nearest = v
				range = dist
			end
		end
	end
	
	gTerminal:Broadcast(entity, "")
	
	if (nearest != nil) then
		if (arguments[1] == nil or arguments[2] == nil) then
			gTerminal:Broadcast(entity, "Usage(:set <letter> <string>)")
		else
			local input = string.lower(arguments[1])
			if (input == "a") then
				nearest:SetOP0(arguments[2])
			elseif (input == "b") then
				nearest:SetOP1(arguments[2])
			else
				gTerminal:Broadcast(entity, "Unknown output stream!", GT_COL_WRN)
			end
		end
	else
		gTerminal:Broadcast(entity, "Connection could not be made to I/O device!", GT_COL_WRN)
	end
	
end, "Sets a value in an I/O device.")

OS:NewCommand("wget", function(client, entity, arguments)

	local nearest = nil
	local range = 128
	
	for k, v in pairs(ents.FindByClass("sent_iodevice")) do
		if (v:GetComputer() == entity) then
			local dist = entity:GetPos():Distance(v:GetPos())
			if (dist <= range) then
				nearest = v
				range = dist
			end
		end
	end
	
	if (nearest != nil) then
		gTerminal:Broadcast(entity, "")
		if (arguments[1] == nil) then
			gTerminal:Broadcast(entity, "Data returned from I/O Device:", GT_COL_INFO)
			gTerminal:Broadcast(entity, "A: " .. nearest:GetIP0())
			gTerminal:Broadcast(entity, "B: " .. nearest:GetIP1())
		else
			local input = string.lower(arguments[1])
			if (input == "a") then
				gTerminal:Broadcast(entity, "Data returned from I/O Device:", GT_COL_INFO)
				gTerminal:Broadcast(entity, "A: " .. nearest:GetIP0())
			elseif (input == "b") then
				gTerminal:Broadcast(entity, "Data returned from I/O Device:", GT_COL_INFO)
				gTerminal:Broadcast(entity, "B: " .. nearest:GetIP1())
			else
				gTerminal:Broadcast(entity, "Unknown input stream!", GT_COL_WRN)
			end
		end
	else
		gTerminal:Broadcast(entity, "")
		gTerminal:Broadcast(entity, "Connection could not be made to I/O device!", GT_COL_WRN)
	end
	
end, "Gets a value in an I/O device.")

OS:NewCommand("pass", function(client, entity, arguments)
	local password = table.concat(arguments, " ");

	if (password and password != "") then
		entity.password = password;
		gTerminal:Broadcast(entity, "Password set to '"..entity.password.."'.");
	else
		entity.password = nil;
		gTerminal:Broadcast(entity, "Removed password.");
	end;
end, "Sets the password for the terminal.");

OS:NewCommand("x", function(client, entity)
	gTerminal:Broadcast( entity, "SHUTTING DOWN..." );

	for k, v in pairs( player.GetAll() ) do
		v[ "pass_authed_"..entity:EntIndex() ] = nil;
	end;
	
	gTerminal.os:Call(entity, "ShutDown");
	
	timer.Simple(math.Rand(2, 5), function()
		if ( IsValid(entity) ) then
			for i = 0, entity.maxLines do
				if ( IsValid(entity) ) then
					gTerminal:Broadcast(entity, "");
				end;
			end;
			entity:SetActive(false);
			gTerminal:SPK_Beep(entity);
		end;
	end);
end, "Turns off the terminal.");

OS:NewCommand("math", function(client, entity, arguments)
	
	local first = tonumber( arguments[1] );
	
	if (!first) then
		gTerminal:Broadcast(entity, "Mathematics");
		gTerminal:Broadcast(entity, "  INFO:");
		gTerminal:Broadcast(entity, "    With math you can perform simple arithmetic.");
		gTerminal:Broadcast(entity, "  HELP:");
		gTerminal:Broadcast(entity, "    " .. GetConVar("gterminal_command_prefix"):GetString() .. "math <number> + <number> - Adds two numbers.");
		gTerminal:Broadcast(entity, "    " .. GetConVar("gterminal_command_prefix"):GetString() .. "math <number> - <number> - Subtracts two numbers.");
		gTerminal:Broadcast(entity, "    " .. GetConVar("gterminal_command_prefix"):GetString() .. "math <number> * <number> - Multiplies two numbers.");
		gTerminal:Broadcast(entity, "    " .. GetConVar("gterminal_command_prefix"):GetString() .. "math <number> / <number> - Divides two numbers.");
		gTerminal:Broadcast(entity, "    " .. GetConVar("gterminal_command_prefix"):GetString() .. "math <number> ** <number> - The first number to the power of the second.");
		gTerminal:Broadcast(entity, "    " .. GetConVar("gterminal_command_prefix"):GetString() .. "math <number> rand <number> - Random number.");
		gTerminal:Broadcast(entity, "    " .. GetConVar("gterminal_command_prefix"):GetString() .. "math <number> // - The square root of the first number.");
	else
		local operation = arguments[2];
		local second = tonumber( arguments[3] );
		
		if (first and second) then
			if (operation == "+") then
				gTerminal:Broadcast( entity, first.." + "..second.." = "..(first + second), GT_COL_SUCC );
			elseif (operation == "-") then
				gTerminal:Broadcast( entity, first.." - "..second.." = "..(first - second), GT_COL_SUCC );
			elseif (operation == "*") then
				gTerminal:Broadcast( entity, first.." * "..second.." = "..(first * second), GT_COL_SUCC );
			elseif (operation == "/") then
				gTerminal:Broadcast( entity, first.." / "..second.." = "..(first / second), GT_COL_SUCC );
			elseif (operation == "**") then
				gTerminal:Broadcast( entity, first.." ** "..second.." = "..math.pow(first, second), GT_COL_SUCC );
			elseif (operation == "rand") then
				gTerminal:Broadcast( entity, first.." rand "..second.." = "..math.random(first, second), GT_COL_SUCC );
			end;
		elseif (first and operation) then
			if (operation == "//") then
				gTerminal:Broadcast( entity, first.." //  = "..math.sqrt(first), GT_COL_SUCC );
			end;
		elseif (!second) then
			gTerminal:Broadcast(entity, "Second number is invalid!", GT_COL_ERR);
		else
			gTerminal:Broadcast(entity, "Operation is invalid!", GT_COL_ERR);
		end;
	end;
end, "Peform simple arithmetic.");

OS:NewCommand("guess", function(client, entity, arguments)
	local answer = math.random(1, 10);

	gTerminal:Broadcast(entity, "Guess a number from one to ten:");
	gTerminal:GetInput(entity, function(client, arguments)
		if ( !arguments[1] ) then
			gTerminal:Broadcast(entity, "You didn't give an answer! Game over.");

			return;
		end;

		if ( answer == tonumber( arguments[1] ) ) then
			gTerminal:Broadcast(entity, "You got it right! Good job.");
		else
			gTerminal:Broadcast(entity, "Wrong! The answer was "..answer..".");
		end;
	end);
end, "Guess a number from 1-10.");

local f_commands = Filesystem.commands
OS:NewCommand("f", function(client, entity, arguments)
	if !entity.cur_dir then
		Filesystem.Initialize(entity)
		entity.destructor["fs"] = function(ent)
			if entity.Disk then
				local disk = ents.Create( "sent_disk" )
				disk:SetPos( entity:LocalToWorld(Vector(0,0,25)) )
				disk:SetNameD(entity.files["F:\\"]._dname)
				disk:SetData(entity.files["F:\\"])
				disk:SetOwner(entity.DiskO)
				disk:Spawn()
			end
			ent.files = nil
		end
	end

	local command = arguments[1]

	if !command or !f_commands[command] then
		gTerminal:Broadcast(entity, "File System");
		gTerminal:Broadcast(entity, "  INFO:");
		gTerminal:Broadcast(entity, "    This is the terminal's file system.");
		gTerminal:Broadcast(entity, "  HELP:");
		for key, value in ipairs(Filesystem.names) do
			gTerminal:Broadcast(entity, "    " .. value .. f_commands[value].add_help .. " - " .. f_commands[value].help)
		end

		return
	end

	f_commands[command].func(client, entity, arguments)
end, "Terminal file protocol.")

local p_commands = Periph.commands
OS:NewCommand("periph", function(client, entity, arguments)
	if entity.destructor["periph"] == nil then
		entity.destructor["disk"] = function(ent)
			if !table.IsEmpty(ent.periphery) then
				for i = 1, #ent.periphery do
					local per_ent = ents.Create( ent.periphery[i] )
                    per_ent:SetPos( entity:LocalToWorld(Vector(0,0,25 + i * 5)) )
                    per_ent:Spawn()
				end
				ent.periphery = nil
			end
			ent.periphery = nil
		end
	end
	local command = arguments[1]

	if !command or !p_commands[command] then
		gTerminal:Broadcast(entity, "Periphery System");
		gTerminal:Broadcast(entity, "  INFO:");
		gTerminal:Broadcast(entity, "    Configuration of the computer periphery.");
		gTerminal:Broadcast(entity, "  HELP:");
		for name, tbl in pairs(p_commands) do
			gTerminal:Broadcast(entity, "    " .. name .. tbl.add_help .. " - " .. tbl.help)
		end

		return
	end

	p_commands[command].func(client, entity, arguments)
end, "Configuration of periphery.")