local gTerminal = gTerminal 
local Periph = gTerminal.Periph
local Filesystem = gTerminal.Filesystem
local OS = OS 
OS:NewCommand("color", function(client, entity, arguments)
	if arguments[1] == nil and arguments[2] == nil and arguments[3] == nil and arguments[4] == nil then
		gTerminal:Broadcast(entity, "Usage - " ..GetConVar("gterminal_command_prefix"):GetString() .. "color <b/f> <red> <green> <blue>")
	elseif arguments[2] == "default" then
		if arguments[1] == "b" then
			gTerminal:ChangeBackgroundColor(entity, entity.DefaultBackgroundColor)
		else
			gTerminal:ChangeForegroundColor(entity, Color(GT_colors[tonumber(arguments[3]) or GT_COL_MSG]), tonumber(arguments[3]) or GT_COL_MSG )
		end
	elseif arguments[1] != "f" and arguments[1] != "b" then
		gTerminal:Broadcast(entity, "Second argument must be 'f' or 'b'!")
	elseif tonumber(arguments[2]) == nil or tonumber(arguments[3]) == nil or tonumber(arguments[4]) == nil then
		gTerminal:Broadcast(entity, "One of argument not a number or some argument missing!")
	else
		if arguments[1] == "b" then
			gTerminal:ChangeBackgroundColor(entity, Color(tonumber(arguments[2]),tonumber(arguments[3]),tonumber(arguments[4]), tonumber(arguments[5]) or entity.DefaultBackgroundColor:ToTable()[4]) )
			return
		end
		gTerminal:ChangeForegroundColor(entity, Color(tonumber(arguments[2]),tonumber(arguments[3]),tonumber(arguments[4]),255), tonumber(arguments[5]) or GT_COL_MSG )
	end
	end, "Change color for (back/fore)ground.")

OS:NewCommand("inp", function(client, entity)
	gTerminal:GetInput(entity, function(cl,str)
		gTerminal:Broadcast(entity, str)
	end)
end, "Input and output all on screen.")

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
if WireAddon then
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
end
OS:NewCommand("pass", function(client, entity, arguments)
	local password = table.concat(arguments, " ")

	if (password and password != "") then
		entity.password = password 
		gTerminal:Broadcast(entity, "Password set to '"..entity.password.."'.")
	else
		entity.password = nil 
		gTerminal:Broadcast(entity, "Removed password.")
	end 
end, "Sets the password for the terminal.")

OS:NewCommand("math", function(client, entity, arguments)
	
	local first = tonumber( arguments[1] )
	local prefix = GetConVar("gterminal_command_prefix"):GetString()

	if (!first) then
		gTerminal:Broadcast(entity, "Mathematics")
		gTerminal:Broadcast(entity, "  INFO:")
		gTerminal:Broadcast(entity, "    With math you can perform simple arithmetic.")
		gTerminal:Broadcast(entity, "  HELP:")
		gTerminal:Broadcast(entity, "    " .. prefix .. "math <number> + <number> - Adds two numbers.")
		gTerminal:Broadcast(entity, "    " .. prefix .. "math <number> - <number> - Subtracts two numbers.")
		gTerminal:Broadcast(entity, "    " .. prefix .. "math <number> * <number> - Multiplies two numbers.")
		gTerminal:Broadcast(entity, "    " .. prefix .. "math <number> / <number> - Divides two numbers.")
		gTerminal:Broadcast(entity, "    " .. prefix .. "math <number> ** <number> - The first number to the power of the second.")
		gTerminal:Broadcast(entity, "    " .. prefix .. "math <number> rand <number> - Random number.")
		gTerminal:Broadcast(entity, "    " .. prefix .. "math <number> // - The square root of the first number.")
	else
		local operation = arguments[2]
		local second = tonumber( arguments[3] )
		
		if (first and second) then
			if (operation == "+") then
				gTerminal:Broadcast( entity, first.." + "..second.." = "..(first + second), GT_COL_SUCC )
			elseif (operation == "-") then
				gTerminal:Broadcast( entity, first.." - "..second.." = "..(first - second), GT_COL_SUCC )
			elseif (operation == "*") then
				gTerminal:Broadcast( entity, first.." * "..second.." = "..(first * second), GT_COL_SUCC )
			elseif (operation == "/") then
				gTerminal:Broadcast( entity, first.." / "..second.." = "..(first / second), GT_COL_SUCC )
			elseif (operation == "**") then
				gTerminal:Broadcast( entity, first.." ** "..second.." = "..math.pow(first, second), GT_COL_SUCC )
			elseif (operation == "rand") then
				gTerminal:Broadcast( entity, first.." rand "..second.." = "..math.random(first, second), GT_COL_SUCC )
			end 
		elseif (first and operation) then
			if (operation == "//") then
				gTerminal:Broadcast( entity, first.." //  = "..math.sqrt(first), GT_COL_SUCC )
			end 
		elseif (!second) then
			gTerminal:Broadcast(entity, "Second number is invalid!", GT_COL_ERR)
		else
			gTerminal:Broadcast(entity, "Operation is invalid!", GT_COL_ERR)
		end 
	end 
end, "Peform simple arithmetic.")

OS:NewCommand("guess", function(client, entity, arguments)
	local answer = math.random(1, 10)

	gTerminal:Broadcast(entity, "Guess a number from one to ten:")
	gTerminal:GetInput(entity, function(client, str)
		if ( !str ) then
			gTerminal:Broadcast(entity, "You didn't give an answer! Game over.")

			return 
		end 

		if ( answer == tonumber( str ) ) then
			gTerminal:Broadcast(entity, "You got it right! Good job.")
		else
			gTerminal:Broadcast(entity, "Wrong! The answer was "..answer..".")
		end 
	end)
end, "Guess a number from 1-10.")

local f_commands = Filesystem.commands
OS:NewCommand("f", function(client, entity, arguments)
	if !entity.cur_dir then
		Filesystem.Initialize(entity)
	end

	local command = arguments[1]

	if !command or !f_commands[command] then
		gTerminal:Broadcast(entity, "File System")
		gTerminal:Broadcast(entity, "  INFO:")
		gTerminal:Broadcast(entity, "    This is the terminal's file system.")
		gTerminal:Broadcast(entity, "  HELP:")
		for key, value in SortedPairs(f_commands) do
			gTerminal:Broadcast(entity, "    " .. key .. value.add_help .. " - " .. value.help)
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
		gTerminal:Broadcast(entity, "Periphery System")
		gTerminal:Broadcast(entity, "  INFO:")
		gTerminal:Broadcast(entity, "    Configuration of the computer periphery.")
		gTerminal:Broadcast(entity, "  HELP:")
		for name, tbl in pairs(p_commands) do
			gTerminal:Broadcast(entity, "    " .. name .. tbl.add_help .. " - " .. tbl.help)
		end

		return
	end

	p_commands[command].func(client, entity, arguments)
end, "Configuration of periphery.")

include("gterminal/default_commands.lua")
