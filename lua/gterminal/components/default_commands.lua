local gTerminal = gTerminal 
local timer = timer 
local OS = OS 

OS:NewCommand("help", function(client, entity, arguments)
	gTerminal:Broadcast(entity, string.rep("=",entity.maxChars))
	gTerminal:Broadcast(entity, "  " .. OS:GetName() .. " Help Menu")
	gTerminal:Broadcast(entity, "")
	gTerminal:Broadcast(entity, "    COMMANDS:")

	for k, v in SortedPairs( OS.commands ) do
		gTerminal:Broadcast(entity, "     ".. GetConVar("gterminal_command_prefix"):GetString() ..k.." - "..v.help)
	end 

	gTerminal:Broadcast(entity, string.rep("=",entity.maxChars))
end, "Provides a list of help.")

OS:NewCommand("cls", function(client, entity)
	gTerminal:ClearConsole(entity)
end, "Clears the screen.")

OS:NewCommand("gid", function(client, entity)
	gTerminal:Broadcast( entity, "TERMINAL ID => "..entity:EntIndex() )
end, "Gets the terminal ID.")

OS:NewCommand("x", function(client, entity)
	entity:SetInputMode(GT_INPUT_NIL)
	gTerminal:Broadcast( entity, "SHUTTING DOWN..." )

	for k, v in pairs( player.GetAll() ) do
		v[ "pass_authed_"..entity:EntIndex() ] = nil 
	end 
	
	timer.Simple(math.Rand(2, 4), function()
		if ( IsValid(entity) ) then
			entity:ShutDown()
			gTerminal:SPK_Beep(entity)
		end 
	end)
end, "Turns off the terminal.")