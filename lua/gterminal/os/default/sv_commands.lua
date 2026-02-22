local gTerminal = gTerminal
local timer = timer
local OS = OS
include("gterminal/default_commands.lua")

OS:NewCommand("os", function(client, entity, arguments)
	local command = arguments[1]

	if (command == "install" or command == "install_disk") then
		local info = arguments[2]
		local system = command == 'install_disk' and gTerminal.os['custom_os'] or gTerminal.os[info]
		if command != "install_disk" then
			if (!info) then
				gTerminal:Broadcast(entity, "Invalid OS identifier!", GT_COL_ERR)

				return 
			elseif (info == "default") then
				gTerminal:Broadcast(entity, "Cannot use primary system!", GT_COL_ERR)

				return 
			elseif (info == "root_os") then
				gTerminal:Broadcast(entity, "Cannot use root system!", GT_COL_ERR)

				return 
			elseif (info == "custom_os") then
				gTerminal:Broadcast(entity, "For custom system you need disk with os!", GT_COL_ERR)
				gTerminal:Broadcast(entity, "Check command :os install_disk!", GT_COL_ERR)

				return 
			end 


			if (!system) then
				gTerminal:Broadcast(entity, "Couldn't find OS!", GT_COL_ERR)

				return
			end
		else
			if entity.Disk then
				gTerminal:Broadcast(entity,"Eject disk first!", GT_COL_ERR)
				return
			end
			for k, v in pairs(ents.FindByClass("sent_disk")) do
				local dist = entity:GetPos():Distance(v:GetPos())
				
				if dist <= 64 and v:GetData()['os.lua'] then
					gTerminal.Filesystem.Initialize(entity)
					entity.Disk = v
					v:Remove()
					entity.files["C:\\"] = table.Copy(entity.Disk:GetData())
					entity.files["C:\\"]._dname = "System Disk"
					gTerminal:Broadcast(entity,"Disk has been founded!", GT_COL_SUCC)
					
					break
				end
			end
			if !entity.Disk then gTerminal:Broadcast(entity, "Disk has not been founded!", GT_COL_ERR) return end
		end

		if GetConVar("gterminal_fast_install"):GetBool() then
			gTerminal:Broadcast(entity, "Installation complete!", GT_COL_SUCC)
			entity:SetInputMode(GT_INPUT_NIL)
			timer.Simple(math.Rand(1, 2), function()
				if ( IsValid(entity) ) then
					entity:ShutDown()
					entity.os = system
				end
			end)
			return
		end

		gTerminal:Broadcast(entity, "Preparing installation...", GT_COL_INTL)

		timer.Simple(1, function()
			if ( !IsValid(entity) ) then
				return
			end
			gTerminal:ClearConsole(entity)
			entity:SetInputMode(GT_INPUT_NIL)
			gTerminal:Broadcast(entity, string.rep("=", entity.maxChars), GT_COL_MSG, 16)
			gTerminal:Broadcast(entity, "Idle...", GT_COL_MSG, 18)
			gTerminal:Broadcast(entity, "", GT_COL_MSG, 19)
			gTerminal:Broadcast(entity, "     [                         ] 0%", GT_COL_MSG, 20)
			gTerminal:Broadcast(entity, "", GT_COL_MSG, 21)
			gTerminal:Broadcast(entity, string.rep("=", entity.maxChars), GT_COL_MSG, 22)

			local messages = {
				"Inspecting disk space.",
				"Allocating disk space.",
				"Retrieving required resources.",
				"Unpacking resources.",
				"Retrieving system requirements.",
				"Validating file integrity.",
				"Compiling packages.",
				"Exporting packages to file system.",
				"Setting up access data.",
				"Setting up system profile.",
				"Setting up commands.",
				"Finalizing product."
			}

			local time = math.Rand(0.5, 1.5)

			for i = 1, 25 do
				time = time + math.Rand(0.05, 0.25)

				timer.Simple(time, function()
					if ( IsValid(entity) ) then
						local msgID = math.Clamp(i, 1, #messages)

						gTerminal:Broadcast(entity, "     "..messages[msgID], GT_COL_MSG, 18)
						gTerminal:Broadcast(entity, "     ["..string.rep("=", i)..string.rep(" ", 25 - i).."] "..( 100 * math.Round(i / 25, 2) ).."%", GT_COL_MSG, 20)

						if (i == 25) then
							for i = 0, 25 do
								if ( IsValid(entity) ) then
									gTerminal:Broadcast(entity, "", nil, i)
								end
							end

							timer.Simple(math.Rand(1, 2), function()
								if ( IsValid(entity) ) then
									entity:ShutDown()
									entity.os = system
								end
							end)
						end
					end
				end)
			end
		end)
	elseif (command == "list") then
		local info = arguments[2]

		gTerminal:Broadcast(entity, "Available OS Packages:")

		local count = 0

		for k, v in SortedPairs(gTerminal.os) do
			if (type(v) == "table" and v.GetName and v.GetUniqueID and v:GetUniqueID() != "default" and v:GetUniqueID() != "root_os" and v:GetUniqueID() != "custom_os") then
				count = count + 1

				gTerminal:Broadcast(entity, "     "..count..". "..v:GetUniqueID().." ("..v:GetName()..")")
			end 
		end 
	else
		gTerminal:Broadcast(entity, "Operation System Config")
		gTerminal:Broadcast(entity, "  INFO:")
		gTerminal:Broadcast(entity, "    Allows configuration of the operation system.")
		gTerminal:Broadcast(entity, "  HELP:")
		gTerminal:Broadcast(entity, "    install <name> - Installs an OS package.")
		gTerminal:Broadcast(entity, "    install_disk - Installs an OS from disk.")
		gTerminal:Broadcast(entity, "    list - Lists the available OS packages.")
	end 
end, "Operation system configuration.")