local Filesystem = gTerminal.Filesystem
local GNet = gTerminal.GNet

local gnet_commands = table.Copy(GNet.commands.shared)
table.Merge(gnet_commands, GNet.commands.client)
OS:NewCommand("gnet", function(client, entity, arguments)
	if !entity.cur_dir then
		Filesystem.Initialize(entity)
	end
	if entity.name == nil then
		entity.name = entity.name or "User" .. tostring(entity:EntIndex())
	end
	if entity.gnet_pcspk == nil then
		entity.gnet_pcspk = true 
	end
	if entity.destructor["gnet"] == nil then
		entity.destructor["gnet"] = function(ent) gnet_commands["l"].func(client, ent, arguments) end
	end
	local command = arguments[1]

	if !command or !gnet_commands[command] then
		gTerminal:Broadcast(entity, "Global Network Mark II")
		gTerminal:Broadcast(entity, "  INFO:")
		gTerminal:Broadcast(entity, "    With GNet you are able to communicate")
		gTerminal:Broadcast(entity, "    through user created networks with ease.")
		gTerminal:Broadcast(entity, "  HELP:")
		for name, tbl in pairs(gnet_commands) do
			gTerminal:Broadcast(entity, "    " .. name .. tbl.add_help .. " - " .. tbl.help)
		end

		return
	end

	gnet_commands[command].func(client, entity, arguments)
end, "Global networking platform.")