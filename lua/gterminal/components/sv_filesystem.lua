local Filesystem = Filesystem or {}
local gTerminal = gTerminal
util.AddNetworkString("gTerminal.LuaPadEditor.Open")
util.AddNetworkString("gTerminal.Editor.Open")
util.AddNetworkString("gTerminal.Editor.Save")
Filesystem.commands = {
	["disk_g"] = {
		func = function(cl, ent, args)
			for key, value in pairs(ent.files) do
				if key == ent.cur_disk then
					gTerminal:Broadcast(ent, ">" .. key .. "  -  " .. value._dname, GT_COL_WRN)
				else
					gTerminal:Broadcast(ent, " " .. key .. "  -  " .. value._dname, GT_COL_WRN)
				end
			end
		end,
		help = "Get all disks.",
		add_help = "",
	},
	["disk_cd"] = {
		func = function(cl, ent, args)
			if not args[2] then
				gTerminal:Broadcast(ent, "Invalid disk name!", GT_COL_ERR)
				return
			end

			if string.find(args[2], "/") then string.Replace(args[2], "/", "\\") end
			if string.find(args[2], "\\") then
				if not ent.files[string.upper(args[2])] then
					gTerminal:Broadcast(ent, "Disk is not exists!", GT_COL_ERR)
					return
				end

				ent.cur_dir = ent.files[string.upper(args[2])]
				ent.cur_disk = string.upper(args[2])
				return
			end

			if not ent.files[string.upper(args[2]) .. "\\"] then
				gTerminal:Broadcast(ent, "Disk is not exists!", GT_COL_ERR)
				return
			end

			ent.cur_dir = ent.files[string.upper(args[2]) .. "\\"]
			ent.cur_disk = string.upper(args[2]) .. "\\"
		end,
		help = "Change disk.",
		add_help = " <disk>",
	},
	["disk_in"] = {
		func = function(cl, entity, args)
			if not entity.Disk then
				for k, v in pairs(ents.FindByClass("sent_disk")) do
					local dist = entity:GetPos():DistToSqr(v:GetPos())
					if dist <= 4096 then --64
						entity.Disk = v
						v:Remove()
						gTerminal:Broadcast(entity, "A floppy disk is inserted")
						entity.files["F:\\"] = entity.Disk.Files
						entity.files["F:\\"]._dname = entity.Disk.name
						gTerminal:Broadcast(entity, "Disk has been initialized")
						break
					end
				end

				if entity.Disk == nil then return end
			else
				gTerminal:Broadcast(entity, "Already inserted disk", GT_COL_ERR)
			end
		end,
		help = "Insert a disk",
		add_help = "",
	},
	["disk_ej"] = {
		func = function(cl, entity, args)
			if entity.Disk then
				local disk = ents.Create("sent_disk")
				disk:SetPos(entity:LocalToWorld(Vector(0, 0, 25)))
				disk.Files = entity.files["F:\\"]
				disk:Spawn()
				disk:SetDName(entity.files["F:\\"]._dname)
				entity.files["F:\\"]._dname = nil
				entity.Disk = nil
				if entity.cur_disk == "F:\\" then
					entity.cur_disk = "C:\\"
					entity.cur_dir = entity.files["C:\\"]
				end

				entity.files["F:\\"] = nil
				gTerminal:Broadcast(entity, "The disk is disconnected")
			else
				gTerminal:Broadcast(entity, "No disk", GT_COL_ERR)
			end
		end,
		help = "Eject disk",
		add_help = "",
	},
	["disk_ad"] = {
		func = function(cl, entity, args)
			if string.find(args[3], "/") then string.Replace(args[3], "/", "\\") end
			if string.find(args[3], "\\") then
				if not entity.files[string.upper(args[3])] then
					gTerminal:Broadcast(entity, "Disk is not exists!", GT_COL_ERR)
					return
				end

				args[3] = string.upper(args[3])
			else
				if not entity.files[string.upper(args[3]) .. "\\"] then
					gTerminal:Broadcast(entity, "Disk is not exists!", GT_COL_ERR)
					return
				end

				args[3] = string.upper(args[3]) .. "\\"
			end

			if entity.cur_dir[args[2]] ~= nil then entity.files[args[3]][args[2]] = entity.cur_dir[args[2]] end
		end,
		help = "Add file to disk",
		add_help = " <file> <disk>",
	},
	["disk_ren"] = {
		func = function(cl, entity, args)
			if string.find(args[2], "/") then string.Replace(args[2], "/", "\\") end
			if string.find(args[2], "\\") then
				if not entity.files[string.upper(args[2])] then
					gTerminal:Broadcast(entity, "Disk is not exists!", GT_COL_ERR)
					return
				end

				args[2] = string.upper(args[2])
			else
				if not entity.files[string.upper(args[2]) .. "\\"] then
					gTerminal:Broadcast(entity, "Disk is not exists!", GT_COL_ERR)
					return
				end

				args[2] = string.upper(args[2]) .. "\\"
				if not args[3] then
					gTerminal:Broadcast(entity, "There is no name argument!", GT_COL_ERR)
					return
				end
			end
			local new_name = table.concat(args, " ", 3)
			if #new_name > 22 then
				gTerminal:Broadcast(entity, "Maximum chars in name is 22!", GT_COL_ERR)
				return
			end
			entity.files[args[2]]._dname = new_name
		end,
		help = "Disk rename",
		add_help = " <disk> <name>",
	},
	["md"] = {
		func = function(cl, ent, args) Filesystem.CreateDir(ent, args[2]) end,
		help = "Make Directory.",
		add_help = " <name>",
	},
	["dir"] = {
		func = function(cl, ent, args)
			print(1)
			local const_n_dir = ent.cur_dir
			local n_dir = ent.cur_dir
			if args[2] ~= nil then
				if args[2][1] == "/" or args[2][1] == "\\" then args[2] = string.sub(args[2], 2, #args[2]) end
				if args[2][#args[2]] == "/" or args[2][#args[2]] == "\\" then args[2] = string.sub(args[2], 1, #args[2] - 1) end
				if string.find(args[2], "/") then
					string.Replace(args[2], "/", "\\")
					return
				end

				if string.find(args[2], "\\") then
					local spl = string.Split(args[2], "\\")
					for i = 1, #spl do
						if Filesystem.ChangeDir(ent, spl[i]) == false then
							ent.cur_dir = const_n_dir
							return
						end
					end
				else
					if Filesystem.ChangeDir(ent, args[2]) == false then
						ent.cur_dir = const_n_dir
						return
					end
				end

				n_dir = ent.cur_dir
			end

			local str = ""
			while ent.cur_dir._parent do
				str = ent.cur_dir._name .. "\\" .. str
				ent.cur_dir = ent.cur_dir._parent
			end

			ent.cur_dir = n_dir
			gTerminal:Broadcast(ent, ent.cur_disk .. str)
			for k, v in pairs(ent.cur_dir) do
				if type(v) == "table" and not table.HasValue(ent.bad_words, k) then
					gTerminal:Broadcast(ent, k .. string.rep(" ", math.Round(ent.maxChars / 2.5) - utf8.len(k) + 5) .. "<DIR>", GT_COL_INFO)
				elseif type(v) == "string" and not table.HasValue(ent.bad_words, k) then
					gTerminal:Broadcast(ent, k .. string.rep(" ", math.Round(ent.maxChars / 2.5) - utf8.len(k) + 5) .. "<FILE>", GT_COL_SUCC)
				end
			end

			ent.cur_dir = const_n_dir
		end,
		help = "List all files",
		add_help = " [dir]",
	},
	["cd"] = {
		func = function(cl, ent, args)
			local n_dir = ent.cur_dir
			if args[2][1] == "/" or args[2][1] == "\\" then args[2] = string.sub(args[2], 2, #args[2]) end
			if args[2][#args[2]] == "/" or args[2][#args[2]] == "\\" then args[2] = string.sub(args[2], 1, #args[2] - 1) end
			if string.find(args[2], "/") then string.Replace(args[2], "/", "\\") end
			if string.find(args[2], "\\") then
				local spl = string.Split(args[2], "\\")
				for i = 1, #spl do
					if Filesystem.ChangeDir(ent, spl[i]) == false then
						ent.cur_dir = n_dir
						return
					end
				end
			end

			Filesystem.ChangeDir(ent, args[2])
		end,
		help = "Change Directory (.. - is back).",
		add_help = " <dir>",
	},
	["pwd"] = {
		func = function(cl, ent, args)
			local n_dir = ent.cur_dir
			local str = ""
			while ent.cur_dir._parent do
				str = ent.cur_dir._name .. "\\" .. str
				ent.cur_dir = ent.cur_dir._parent
			end

			ent.cur_dir = n_dir
			gTerminal:Broadcast(ent, ent.cur_disk .. str)
		end,
		help = "Print full path.",
		add_help = "",
	},
	["touch"] = {
		func = function(cl, ent, args)
			if not args[2] or table.HasValue(ent.bad_words, args[2]) then
				gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR)
				return
			end

			if ent.cur_dir[args[2]] ~= nil and type(ent.cur_dir[args[2]]) ~= "string" then
				gTerminal:Broadcast(ent, "Object is directory!", GT_COL_ERR)
				return
			end

			if ent.os ~= "root_os" and #args[2] >= 4 and string.sub(args[2], #args[2] - 3, #args[2]) == ".lua" then
				gTerminal:Broadcast(ent, "Can't edit lua files on non root_os system!", GT_COL_ERR)
				return
			end

			net.Start("gTerminal.Editor.Open")
			net.WriteEntity(ent)
			net.WriteString(args[2])
			net.WriteString(ent.cur_dir[args[2]] or "")
			net.Send(cl)
		end,
		help = "Create or edit file.",
		add_help = " <filename>",
	},
	["move"] = {
		func = function(cl, ent, args)
			if not args[2] or table.HasValue(ent.bad_words, args[2]) then
				gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR)
				return
			end

			if not args[3] or table.HasValue(ent.bad_words, args[3]) then
				gTerminal:Broadcast(ent, "Invalid directory name!", GT_COL_ERR)
				return
			end

			if ent.cur_dir[args[2]] ~= nil and type(ent.cur_dir[args[2]]) ~= "string" then
				gTerminal:Broadcast(ent, "Argument filename is directory!", GT_COL_ERR)
				return
			end

			if ent.cur_dir[args[3]] ~= nil and args[3] ~= ".." and type(ent.cur_dir[args[3]]) ~= "table" then
				gTerminal:Broadcast(ent, "Argument directory is file!", GT_COL_ERR)
				return
			end

			if args[3] ~= ".." then
				ent.cur_dir[args[3]][args[2]] = ent.cur_dir[args[2]]
				ent.cur_dir[args[2]] = nil
			else
				if ent.cur_dir["_parent"] ~= nil then
					ent.cur_dir["_parent"][args[2]] = ent.cur_dir[args[2]]
					ent.cur_dir[args[2]] = nil
				else
					gTerminal:Broadcast(ent, "Previous directory is invalid or not exists!", GT_COL_ERR)
				end
			end
		end,
		help = "Move file to directory.",
		add_help = " <file> <dir>",
	},
	["copy"] = {
		func = function(cl, ent, args)
			if not args[2] or table.HasValue(ent.bad_words, args[2]) then
				gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR)
				return
			end

			if not args[3] or table.HasValue(ent.bad_words, args[3]) then
				gTerminal:Broadcast(ent, "Invalid directory name!", GT_COL_ERR)
				return
			end

			if ent.cur_dir[args[2]] ~= nil and type(ent.cur_dir[args[2]]) ~= "string" then
				gTerminal:Broadcast(ent, "Argument filename is directory!", GT_COL_ERR)
				return
			end

			if ent.cur_dir[args[3]] ~= nil and args[3] ~= ".." and type(ent.cur_dir[args[3]]) ~= "table" then
				gTerminal:Broadcast(ent, "Argument directory is file!", GT_COL_ERR)
				return
			end

			if args[3] ~= ".." then
				ent.cur_dir[args[3]][args[2]] = ent.cur_dir[args[2]]
			elseif ent.cur_dir["_parent"] ~= nil then
				ent.cur_dir["_parent"][args[2]] = ent.cur_dir[args[2]]
			else
				gTerminal:Broadcast(ent, "Previous directory is invalid or not exists!", GT_COL_ERR)
			end
		end,
		help = "Copy file to directory.",
		add_help = " <file> <dir>",
	},
	["ren"] = {
		func = function(cl, ent, args)
			if ent.os ~= "root_os" and (string.sub(args[2], #args[2] - 3, #args[2]) == ".lua" or string.sub(args[3], #args[3] - 3, #args[3]) == ".lua") then
				gTerminal:Broadcast(ent, "Cannot rename lua file!", GT_COL_ERR)
				return
			end

			if ent.cur_dir[args[3]] ~= nil then
				gTerminal:Broadcast(ent, "File with newname already exists!", GT_COL_ERR)
				return
			end

			if ent.cur_dir[args[2]] ~= nil then
				ent.cur_dir[args[3]] = ent.cur_dir[args[2]]
				ent.cur_dir[args[2]] = nil
			end
		end,
		help = "Rename file.",
		add_help = " <oldname> <newname>",
	},
	["cat"] = {
		func = function(cl, ent, args)
			if ent.os ~= "root_os" and string.sub(args[2], #args[2] - 3, #args[2]) == ".lua" then
				gTerminal:Broadcast(ent, "Cannot read lua file on non root_os", GT_COL_ERR)
				return
			end

			--ent.cur_dir[args[2]]
			if not args[2] or table.HasValue(ent.bad_words, args[2]) then
				gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR)
				return
			end

			if not ent.cur_dir[args[2]] then
				gTerminal:Broadcast(ent, "File is not exists!", GT_COL_ERR)
				return
			end

			if type(ent.cur_dir[args[2]]) ~= "string" then
				gTerminal:Broadcast(ent, "Object is directory!", GT_COL_ERR)
				return
			end

			--[[
				if utf8.len(file.content) > ent.maxChars * (ent.maxLines - 3) then
					string.Replace(str,"\n"," ")
					local constnum = ent.maxChars * (ent.maxLines - 3)
					local ind = 1
					gTerminal:Broadcast(ent, utf8.sub(file.content, 1, constnum))
					ind = ind + 1
					local function foo()
						if utf8.len(utf8.sub(file.content, constnum * (ind - 1), #file.content)) > constnum then
							ind = ind + 1
							НЕ РАБОЧИЙ КОД!!!!!!!!!!!!!!!!!!!!
							gTerminal:GetInput(ent, function() gTerminal:Broadcast(ent, utf8.sub(file.content, constnum * (ind - 1), ind * constnum)) foo() end)
						else
							gTerminal:Broadcast(ent, utf8.sub(file.content, constnum * (ind - 1), ind * constnum))
						end
					end
					foo()
				end
				]]
			--
			local strtable = string.Split(ent.cur_dir[args[2]], "\n")
			for i = 1, #strtable do
				gTerminal:Broadcast(ent, strtable[i])
			end
		end,
		help = "Read file.",
		add_help = " <filename>",
	},
	["sound_play"] = {
		func = function(cl, ent, args)
			if table.HasValue(ent.periphery, "sent_pc_spk") then
				if not args[2] or table.HasValue(ent.bad_words, args[2]) then
					gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR)
					return
				end

				if not ent.cur_dir[args[2]] then
					gTerminal:Broadcast(ent, "File is not exists!", GT_COL_ERR)
					return
				end

				if type(ent.cur_dir[args[2]]) ~= "string" then
					gTerminal:Broadcast(ent, "Object is directory!", GT_COL_ERR)
					return
				end

				Filesystem.PlaySoundFile(ent, ent.cur_dir[args[2]])
			else
				gTerminal:Broadcast(ent, "PC SPEAKER is not connected or is disabled!", GT_COL_ERR)
			end
		end,
		help = "Play sound from file.",
		add_help = " <filename>",
	},
	["sizeof"] = {
		func = function(cl, ent, args)
			if not args[2] or table.HasValue(ent.bad_words, args[2]) then
				gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR)
				return
			end

			if not ent.cur_dir[args[2]] then
				gTerminal:Broadcast(ent, "File is not exists!", GT_COL_ERR)
				return
			end

			if type(ent.cur_dir[args[2]]) ~= "string" then
				gTerminal:Broadcast(ent, "Oject is directory!", GT_COL_ERR)
				return
			end

			gTerminal:Broadcast(ent, "Size of file " .. args[2] .. " - " .. string.len(ent.cur_dir[args[2]]) .. "bytes")
		end,
		help = "Size of file in bytes.",
		add_help = " <filename>",
	},
	["rm"] = {
		func = function(cl, ent, args)
			if not args[2] or table.HasValue(ent.bad_words, args[2]) then
				gTerminal:Broadcast(ent, "Invalid object name!", GT_COL_ERR)
				return
			end

			if not ent.cur_dir[args[2]] then
				gTerminal:Broadcast(ent, "Object is not exists!", GT_COL_ERR)
				return
			end

			ent.cur_dir[args[2]] = nil
		end,
		help = "Remove object",
		add_help = " <name>",
	},
	["luapad"] = {
		func = function(cl, ent, args)
			if not args[2] or table.HasValue(ent.bad_words, args[2]) then
				gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR)
				return
			end

			if ent.cur_dir[args[2]] ~= nil and type(ent.cur_dir[args[2]]) ~= "string" then
				gTerminal:Broadcast(ent, "Object is directory!", GT_COL_ERR)
				return
			end

			if ent.os ~= "root_os" and #args[2] >= 4 and string.sub(args[2], #args[2] - 3, #args[2]) == ".lua" then
				gTerminal:Broadcast(ent, "Can't edit lua files on non root_os system!", GT_COL_ERR)
				return
			end

			net.Start("gTerminal.LuaPadEditor.Open")
			net.WriteEntity(ent)
			net.WriteString(args[2])
			net.WriteString(ent.cur_dir[args[2]] or "")
			net.Send(cl)
		end,
		help = "Create or edit file.",
		add_help = " <filename>",
	}
}

local GetGTERMEnviroment
do
	local function WrapAPI(ent, apiTable)
		local wrapped = {}
		for name, value in pairs(apiTable) do
			if isfunction(value) then
				wrapped[name] = function(...) return value(ent, ...) end
			elseif istable(value) then
				wrapped[name] = WrapAPI(ent, value)
			else
				wrapped[name] = value
			end
		end
		return wrapped
	end

	GetGTERMEnviroment = function(ent)
		userEnv = WrapAPI(ent, gTerminal.API)
		userEnv.entity = ent
		userEnv.arguments = ent.args
		userEnv.client = ent.cl
		ent.cl = nil
		ent.args = nil
		userEnv.nativePrint = print
		userEnv.nativeTimer = timer
		setmetatable(userEnv, { --AI GENERATED
			__index = _G,
			__newindex = function(t, k, v)
				if isfunction(_G[k]) or istable(_G[k]) then
					rawset(t, k, v)
				else
					_G[k] = v
				end
			end
		})

		userEnv._G = userEnv
		return userEnv
	end
end

local function try_coroutine_resume(ent, thread)
	local status, err = coroutine.resume(thread)
	if not status then
		gTerminal:Broadcast(ent, "Runtime Error: " .. err, GT_COL_ERR)
		gTerminal.API.exit(ent, true)
	end
end

gTerminal.API = {
	["print"] = function(ent, str) gTerminal:Broadcast(ent, str) end,
	["broadcast"] = function(ent, text, colorType, position, xposition) gTerminal:Broadcast(ent, text, colorType, position, xposition) end,
	["write"] = function(ent, str) gTerminal:WriteText(ent, str) end,
	["colorPrint"] = function(ent, str, color) gTerminal:Broadcast(ent, str, color) end,
	["setOutputColor"] = function(ent, color_index) gTerminal:SetColor(ent, color_index) end,
	["setForegroundColor"] = function(ent, color, color_index) gTerminal:ChangeForegroundColor(ent, color, color_index) end,
	["setBackgroundColor"] = function(ent, color) gTerminal:ChangeBackgroundColor(ent, color) end,
	["getCurrentLine"] = function(ent) return gTerminal:GetEntityCurrentLine(ent) end,
	["sleep"] = function(ent, dur)
		local n_thread = coroutine.running()
		local stimer_table = ent.stimer_table
		local next_table_ind = #stimer_table + 1
		stimer_table[next_table_ind] = true
		local override_identifier = 'GTS_' .. ent:EntIndex() .. next_table_ind -- "GTS" because not removable
		timer.Create(override_identifier, dur / 1000, 1, function()
			stimer_table[next_table_ind] = nil
			try_coroutine_resume(ent, n_thread)
		end)

		coroutine.yield()
	end,
	["input"] = function(ent, need_output)
		ent:SetInputMode(GT_INPUT_INP)
		local n_thread = coroutine.running()
		local b
		gTerminal:GetInput(ent, function(_, text)
			b = text
			ent:SetInputMode(GT_INPUT_NIL)
			try_coroutine_resume(ent, n_thread)
		end)

		coroutine.yield()
		if not need_output then gTerminal:Broadcast(ent, b) end
		return b
	end,
	["getch"] = function(ent, need_output)
		ent:SetInputMode(GT_INPUT_CHAR)
		local n_thread = coroutine.running()
		local b
		gTerminal:GetInput(ent, function(_, text)
			b = text
			ent:SetInputMode(GT_INPUT_NIL)
			try_coroutine_resume(ent, n_thread)
		end)

		coroutine.yield()
		if not need_output then gTerminal:Broadcast(ent, b) end
		return b
	end,
	["beep"] = function(ent, freq, dur)
		gTerminal:SPK_Beep(entity, freq, dur)
		gTerminal.API.sleep(ent, dur)
	end,
	["beepAsync"] = function(ent, freq, dur) gTerminal:SPK_Beep(entity, freq, dur) end,
	["exit"] = function(ent, internal)
		ent:SetInputMode(GT_INPUT_INP)
		
		gTerminal:SetColor(ent, GT_COL_MSG)
		gTerminal:ChangeBackgroundColor(ent, ent.DefaultBackgroundColor)

		local ent_index = ent:EntIndex()
		local timer_table = ent.timer_table
		local stimer_table = ent.stimer_table
		local prefix = 'GT_' .. ent_index
		for name in pairs(timer_table) do
			timer.Remove(prefix .. name)
		end

		prefix = 'GTS_' .. ent_index
		for name in pairs(stimer_table) do
			timer.Remove(prefix .. name)
		end

		ent.timer_table = nil
		ent.stimer_table = nil
		ent.scriptExecuting = nil
		collectgarbage()
		if not internal then coroutine.yield() end
	end,
	["timer"] = {
		["Create"] = function(ent, identifier, delay, repetitions, func)
			local override_identifier = 'GT_' .. ent:EntIndex() .. identifier
			local timer_table = ent.timer_table
			timer_table[identifier] = true
			timer.Create(override_identifier, delay, repetitions, function()
				if timer.RepsLeft(override_identifier) == 0 then timer_table[identifier] = nil end
				func()
			end)
		end,
		["Remove"] = function(ent, identifier)
			local override_identifier = 'GT_' .. ent:EntIndex() .. identifier
			local timer_table = ent.timer_table
			timer.Remove(override_identifier)
			timer_table[identifier] = nil
		end,
		["Simple"] = function(ent, delay, func)
			local stimer_table = ent.stimer_table
			local next_table_ind = #stimer_table + 1
			local override_identifier = 'GTS_' .. ent:EntIndex() .. next_table_ind -- "GTS" because not removable
			stimer_table[next_table_ind] = true
			timer.Create(override_identifier, delay, 1, function()
				stimer_table[next_table_ind] = nil
				func()
			end)
		end,
		["Adjust"] = function(ent, identifier, delay, repetitions, func)
			local override_identifier = 'GT_' .. ent:EntIndex() .. identifier
			local timer_table = ent.timer_table
			if timer.Adjust(ent, override_identifier, delay, repetitions, func and function()
				if timer.RepsLeft(override_identifier) == 0 then timer_table[identifier] = nil end
				func()
			end) then
				timer_table[identifier] = true
				return true
			end
			return false
		end,
		["Exists"] = function(ent, identifier) return timer.Exists('GT_' .. ent:EntIndex() .. identifier) end,
		["Pause"] = function(ent, identifier) return timer.Pause('GT_' .. ent:EntIndex() .. identifier) end,
		["RepsLeft"] = function(ent, identifier) return timer.RepsLeft('GT_' .. ent:EntIndex() .. identifier) end,
		["Start"] = function(ent, identifier) return timer.Start('GT_' .. ent:EntIndex() .. identifier) end,
		["Stop"] = function(ent, identifier) return timer.Stop('GT_' .. ent:EntIndex() .. identifier) end,
		["TimeLeft"] = function(ent, identifier) return timer.TimeLeft('GT_' .. ent:EntIndex() .. identifier) end,
		["Toggle"] = function(ent, identifier) return timer.Toggle('GT_' .. ent:EntIndex() .. identifier) end,
		["UnPause"] = function(ent, identifier) return timer.UnPause('GT_' .. ent:EntIndex() .. identifier) end
	}
}

Filesystem.commands.exec = {
	func = function(cl, ent, args)
		if not GetConVar("gterminal_allow_user_execute"):GetBool() and ent.os ~= "root_os" then
			gTerminal:Broadcast(ent, "Execute on not root_os is not allowed!")
			return
		end

		if not args[2] or table.HasValue(ent.bad_words, args[2]) then
			gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR)
			return
		end

		if not ent.cur_dir[args[2]] then
			args[2] = args[2] .. '.lua'
			if not ent.cur_dir[args[2]] then
				gTerminal:Broadcast(ent, "File is not exists!", GT_COL_ERR)
				return
			end
		end

		if type(ent.cur_dir[args[2]]) == "table" then
			gTerminal:Broadcast(ent, "Object is directory!", GT_COL_ERR)
			return
		end

		if string.sub(args[2], #args[2] - 3, #args[2]) ~= ".lua" then
			gTerminal:Broadcast(ent, "Not lua file")
			return
		end

		local program = CompileString(ent.cur_dir[args[2]] .. '\ngTerminal.API.exit(entity, true)', args[2], false)
		if isstring(program) then
			gTerminal:Broadcast(ent, program, GT_COL_ERR)
		else
			ent.args = args
			ent.cl = cl
			ent.timer_table = {}
			ent.stimer_table = {}
			ent.scriptExecuting = true
			setfenv(program, GetGTERMEnviroment(ent))
			ent:SetInputMode(GT_INPUT_NIL)
			try_coroutine_resume(coroutine.create(program))
		end
	end,
	help = "Execute lua code from file.",
	add_help = " <filename>",
}

function Filesystem.Initialize(ent)
	ent.destructor["fs"] = function(entity)
		if entity.Disk then
			local disk = ents.Create("sent_disk")
			disk:SetPos(entity:LocalToWorld(Vector(0, 0, 25)))
			disk.name = entity.files["F:\\"]._dname
			disk.Files = entity.files["F:\\"]
			disk:Spawn()
		end

		entity.files = nil
	end

	ent.files = {
		["C:\\"] = {
			_dname = "System Disk"
		}
	}

	ent.bad_words = {"_dname", "_parent", "_name"}
	ent.cur_disk = "C:\\"
	ent.cur_dir = ent.files["C:\\"]
end

function Filesystem.ChangeDisk(ent, name)
	if not name or table.HasValue(ent.bad_words, name) then
		gTerminal:Broadcast(ent, "Invalid disk name!", GT_COL_ERR)
		return false
	end

	if not ent.files[name] then
		gTerminal:Broadcast(ent, "Disk is not exists!", GT_COL_ERR)
		return false
	end

	ent.cur_dir = ent.files[name]
end

function Filesystem.CreateDir(ent, name)
	if tonumber(name) ~= nil then
		gTerminal:Broadcast(entity, "Can't create directory with a name consisting of numbers!", GT_COL_ERR)
		return
	end

	if not name or table.HasValue(ent.bad_words, name) then
		gTerminal:Broadcast(ent, "Invalid directory name!", GT_COL_ERR)
		return
	end

	if isstring(ent.cur_dir[name]) then
		gTerminal:Broadcast(ent, "File with same name already exists!", GT_COL_ERR)
		return
	end

	if ent.cur_dir[name] then
		gTerminal:Broadcast(ent, "Directory already exists!", GT_COL_ERR)
		return
	end

	if utf8.len(name) > 20 then
		gTerminal:Broadcast(ent, "Max chars in name must be not greater then 20!", GT_COL_ERR)
		return
	end

	if string.match(name, "[\\/:*?\"<>|]") ~= nil then
		gTerminal:Broadcast(ent, "Name contains unallowable chars!", GT_COL_ERR)
		return
	end

	ent.cur_dir[name] = {
		_parent = ent.cur_dir,
		_name = name
	}
end

function Filesystem.ChangeDir(ent, name)
	if name == ".." then
		ent.cur_dir = ent.cur_dir._parent or ent.cur_dir
		return
	end

	if not ent.cur_dir[name] then
		gTerminal:Broadcast(ent, "Directory is not exists!", GT_COL_ERR)
		return false
	end

	if type(ent.cur_dir[name]) ~= "table" then
		gTerminal:Broadcast(ent, "Object is file!", GT_COL_ERR)
		return false
	end

	if not name or table.HasValue(ent.bad_words, name) then
		gTerminal:Broadcast(ent, "Invalid directory name!", GT_COL_ERR)
		return false
	end

	ent.cur_dir = ent.cur_dir[name]
end

-- function Filesystem.CreateFile(ent, name, content, replace)
-- 	if (tonumber(name) != nil) then gTerminal:Broadcast(entity,"Can't create file with a name consisting of numbers!", GT_COL_ERR) return false end
-- 	if !name or table.HasValue(ent.bad_words, name) then gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR) return false end
-- 	if utf8.len(name) > 20 then
-- 		gTerminal:Broadcast(ent, "Max chars in name must be not greater then 20!", GT_COL_ERR)
-- 		return
-- 	end
-- 	if string.match(name, "[\\/:*?\"<>|]") != nil then
-- 		gTerminal:Broadcast(ent, "Name contains unallowable chars!", GT_COL_ERR)
-- 		return
-- 	end
-- 	if replace != true then
-- 		replace = false
-- 	end
-- 	if ent.cur_dir[name] != nil and replace != true then
-- 		if string.find(name, ".") then
-- 			local name_n = string.Split(name, ".")
-- 			for i = 1, 100000 do
-- 				name_n[#name_n - 1] = name_n[#name_n - 1] .. "_copy(".. tostring(i) .. ")"
-- 				if ent.cur_dir[table.concat(name_n, ".")] != nil then 
-- 					continue
-- 				else
-- 					ent.cur_dir[table.concat(name_n, ".")] = content
-- 					return
-- 				end
-- 			end
-- 		else
-- 			for i = 1, 100000 do
-- 				if ent.cur_dir[name .. "_copy(".. tostring(i) .. ")"] then 
-- 					continue
-- 				else
-- 					ent.cur_dir[name .. "_copy(".. tostring(i) .. ")"] = content
-- 					return
-- 				end
-- 			end
-- 		end
-- 	else
-- 		ent.cur_dir[name] = content
-- 		return true
-- 	end
-- end
net.Receive("gTerminal.Editor.Save", function(len, ply)
	local ent = net.ReadEntity()
	local name = net.ReadString()
	local content = util.Decompress(net.ReadData(net.ReadUInt(16)))
	ent.cur_dir[name] = content
end)

--[Sound]--
function Filesystem.PlaySoundFile(ent, sfilecontent)
	sfilecontent = string.Replace(sfilecontent, "\n", " ")
	local GTERM_table_numbers = string.Split(sfilecontent, " ")
	if string.match(sfilecontent, "^[a-z]") ~= nil then
		gTerminal:Broadcast(ent, "In sound file has words!", GT_COL_ERR)
		return
	end

	if #GTERM_table_numbers % 2 ~= 0 then
		gTerminal:Broadcast(ent, "Sum of numbers is odd number!", GT_COL_ERR)
		return
	end

	for i = 1, #GTERM_table_numbers do
		GTERM_table_numbers[i] = tonumber(GTERM_table_numbers[i])
	end

	local generated_snd = {}
	for i = 1, #GTERM_table_numbers, 2 do
		if GTERM_table_numbers[i + 1] == 0 then
			gTerminal:Broadcast(ent, "Time must be not 0! Check your sound file.", GT_COL_ERR)
			return
		end

		if GTERM_table_numbers[i] == 0 then
			continue
		elseif GTERM_table_numbers[i] < 37 then
			GTERM_table_numbers[i] = 37
		elseif GTERM_table_numbers[i] > 32767 then
			GTERM_table_numbers[i] = 32767
		end

		if not generated_snd[GTERM_table_numbers[i]] then generated_snd[GTERM_table_numbers[i]] = true end
	end

	local function PlaySoundFileBase(arg_index)
		if arg_index == #GTERM_table_numbers + 1 then return end
		local delay = GTERM_table_numbers[arg_index + 1]
		local delay_sec = delay / 1000
		local frequency = GTERM_table_numbers[arg_index]
		if frequency == 0 then
			timer.Simple(delay_sec, function() PlaySoundFileBase(arg_index + 2) end)
		else
			net.Start("gT_EmitSound")
			net.WriteEntity(ent)
			net.WriteUInt(frequency, 15)
			net.WriteUInt(delay, 32)
			net.Broadcast()
			timer.Simple(delay_sec, function() PlaySoundFileBase(arg_index + 2) end)
		end
	end

	PlaySoundFileBase(1)
end

gTerminal.Filesystem = Filesystem