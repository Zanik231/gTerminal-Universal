local Filesystem = Filesystem or {}
local gTerminal = gTerminal;


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
			if !args[2] then gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR) return end
			if string.find(args[2], "/") then
				string.Replace(args[2], "/", "\\")
			end
			if string.find(args[2], "\\") then
				if !ent.files[string.upper(args[2])] then gTerminal:Broadcast(ent, "Disk is not exists!", GT_COL_ERR) return end
				ent.cur_dir = ent.files[string.upper(args[2])]
				ent.cur_disk = string.upper(args[2])
				return
			end
			if !ent.files[string.upper(args[2]) .. "\\"] then gTerminal:Broadcast(ent, "Disk is not exists!", GT_COL_ERR) return end
			ent.cur_dir = ent.files[string.upper(args[2]) .. "\\"]
			ent.cur_disk = string.upper(args[2]) .. "\\"
		end,
		help = "Change disk.",
		add_help = " <disk>",
	},
	["disk_in"] = {
		func = function(cl, entity, args)
			if !entity.Disk then
				for k, v in pairs(ents.FindByClass("sent_disk")) do
					local dist = entity:GetPos():Distance(v:GetPos())
					if (dist <= 64) then
						entity.Disk = v
						entity.DiskO = v:GetOwner()
						v:Remove()
						gTerminal:Broadcast(entity,"A floppy disk is inserted")
						entity.files["F:\\"] = entity.Disk:GetData()
						entity.files["F:\\"]._dname = entity.Disk:GetNameD()
						gTerminal:Broadcast(entity,"Disk has been initialized")
						break
					end
				end
				if entity.Disk == nil then return end
			else
				gTerminal:Broadcast(entity,"Already inserted disk", GT_COL_ERR)
			end
		end,
		help = "Insert a disk",
		add_help = "",
	},
	["disk_ej"] = {
		func = function(cl, entity, args)
			if entity.Disk then
				local disk = ents.Create( "sent_disk" )
				disk:SetPos( entity:LocalToWorld(Vector(0,0,25)) )
				disk:SetNameD(entity.files["F:\\"]._dname)
				entity.files["F:\\"]._dname = nil
				disk:SetData(entity.files["F:\\"])
				disk:SetOwner(entity.DiskO)
				disk:Spawn()
				entity.Disk = nil
				if entity.cur_disk == "F:\\" then
					entity.cur_disk = "C:\\"
					entity.cur_dir = ent.files["C:\\"]
				end
				entity.files["F:\\"] = nil
				gTerminal:Broadcast(entity, "The disk is disconnected");
			else
				gTerminal:Broadcast(entity,"No disk", GT_COL_ERR)
			end
		end,
		help = "Eject disk",
		add_help = "",
	},
	["md"] = {
		func = function(cl, ent, args)
			Filesystem.CreateDir(ent, args[2])
		end,
		help = "Make Directory.",
		add_help = " <name>",
	},
	["dir"] = {
		func = function(cl, ent, args)
			local const_n_dir = ent.cur_dir
			local n_dir = ent.cur_dir
			if args[2] != nil then
				if args[2][1] == "/" or args[2][1] == "\\" then
					args[2] = string.sub(args[2], 2,#args[2])
				end
				if args[2][#args[2]] == "/" or args[2][#args[2]] == "\\" then
					args[2] = string.sub(args[2], 1,#args[2] - 1)
				end
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
				if type(v) == "table" and !table.HasValue(ent.bad_words, k) then
					gTerminal:Broadcast(ent, k .. string.rep(" ", math.Round(ent.maxChars / 2.5) - utf8.len(k) + 5) .. "<DIR>", GT_COL_INFO)
				elseif type(v) == "string" and !table.HasValue(ent.bad_words, k) then
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
			if args[2][1] == "/" or args[2][1] == "\\" then
				args[2] = string.sub(args[2], 2,#args[2])
			end
			if args[2][#args[2]] == "/" or args[2][#args[2]] == "\\" then
				args[2] = string.sub(args[2], 1,#args[2] - 1)
			end
			if string.find(args[2], "/") then
				string.Replace(args[2], "/", "\\")
			end
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
			if ent.os != "root_os" then
				if string.sub(args[2], #args[2] - 3, #args[2]) == ".lua" then
					return
				end
			end
			if !args[2] or table.HasValue(ent.bad_words, args[2]) then gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR) return end
			if ent.cur_dir[args[2]] != nil then 
				if type(ent.cur_dir[args[2]]) != "string" then gTerminal:Broadcast(ent, "Object is directory!", GT_COL_ERR) return end
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
	["ren"] = {
		func = function(cl, ent, args)
			if ent.os != "root_os" then
				if string.sub(args[2], #args[2] - 3, #args[2]) == ".lua" or string.sub(args[3], #args[3] - 3, #args[3]) == ".lua" then
					return 
				end
			end
			if ent.cur_dir[args[3]] != nil then
				if type(ent.cur_dir[args[3]]) == "table" then
					ent.cur_dir[args[3]] = ent.cur_dir[args[2]]
					ent.cur_dir[args[2]] = nil
				else
					ent.cur_dir[args[3]] = ent.cur_dir[args[2]]
					ent.cur_dir[args[2]] = nil
				end
			end
		end,
		help = "Rename file.",
		add_help = " <oldname> <newname>",
	},
	["cat"] = {
		func = function(cl, ent, args)
			if ent.os != "root_os" then
				if string.sub(args[2], #args[2] - 3, #args[2]) == ".lua" then
					return 
				end
			end
			--ent.cur_dir[args[2]]
			if !args[2] or table.HasValue(ent.bad_words, args[2]) then gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR) return end
			if !ent.cur_dir[args[2]] then gTerminal:Broadcast(ent, "File is not exists!", GT_COL_ERR) return end
			if type(ent.cur_dir[args[2]]) != "string" then gTerminal:Broadcast(ent, "Object is directory!", GT_COL_ERR) return end
		
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
							gTerminal:GetInput(ent, function() gTerminal:Broadcast(ent, utf8.sub(file.content, constnum * (ind - 1), ind * constnum)) foo() end)
						else
							gTerminal:Broadcast(ent, utf8.sub(file.content, constnum * (ind - 1), ind * constnum))
						end
					end
					foo()
				end
				]]--
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
			if (table.HasValue(ent.periphery, "sent_pc_spk")) then
				if !args[2] or table.HasValue(ent.bad_words, args[2]) then gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR) return end
				if !ent.cur_dir[args[2]] then gTerminal:Broadcast(ent, "File is not exists!", GT_COL_ERR) return end
				if type(ent.cur_dir[args[2]]) != "string" then gTerminal:Broadcast(ent, "Object is directory!", GT_COL_ERR) return end
				
				Filesystem.PlaySoundFile(ent, ent.cur_dir[args[2]])
			else gTerminal:Broadcast(ent, "PC SPEAKER is not connected or is disabled!", GT_COL_ERR) end
		end,
		help = "Play sound from file.",
		add_help = " <filename>",
	},
	["sizeof"] = {
		func = function(cl, ent, args)
			if !args[2] or table.HasValue(ent.bad_words, args[2]) then gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR) return end
			if !ent.cur_dir[args[2]] then gTerminal:Broadcast(ent, "File is not exists!", GT_COL_ERR) return end
			if type(ent.cur_dir[args[2]]) != "string" then gTerminal:Broadcast(ent, "Oject is directory!", GT_COL_ERR) return end
			gTerminal:Broadcast(ent, "Size of file " .. args[2] .. " - " .. string.len(ent.cur_dir[args[2]]) .. "bytes")
		end,
		help = "Size of file in bytes.",
		add_help = " <filename>",
	},
	["rm"] = {
		func = function(cl, ent, args)
			if !args[2] or table.HasValue(ent.bad_words, args[2]) then gTerminal:Broadcast(ent, "Invalid object name!", GT_COL_ERR) return end
			if !ent.cur_dir[args[2]] then gTerminal:Broadcast(ent, "Object is not exists!", GT_COL_ERR) return end
			ent.cur_dir[args[2]] = nil
		end,
		help = "Remove object",
		add_help = " <name>",
	},
	["exec"] = {
		func = function(cl, ent, args)
			if !GetConVar("gterminal_allow_user_execute"):GetBool() and ent.os != "root_os" then
				gTerminal:Broadcast(ent, "Execute on not root_os is not allowed!")
				return
			end
			if string.sub(args[2], #args[2] - 3, #args[2]) != ".lua" then
				gTerminal:Broadcast(ent, "Not lua file")
				return
			end

			if !args[2] or table.HasValue(ent.bad_words, args[2]) then gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR) return end
			if !ent.cur_dir[args[2]] then gTerminal:Broadcast(ent, "File is not exists!", GT_COL_ERR) return end
			if type(ent.cur_dir[args[2]]) == "table" then gTerminal:Broadcast(ent, "Object is directory!", GT_COL_ERR) return end

			ent.args = args
			ent.cl = cl
			RunString("local entity = Entity(" .. tostring(ent:EntIndex()) .. ") local client = entity.cl local arguments = entity.args local function sleep (dur) local n_thread = coroutine.running() timer.Simple(dur/1000, function() coroutine.resume(n_thread) end) coroutine.wait(dur/1000) end local thr = coroutine.create( function() " .. ent.cur_dir[args[2]] .. " end ) coroutine.resume(thr)")
			ent.args = nil
			ent.cl = nil
		end,
		help = "Execute lua code from file.",
		add_help = " <filename>",
	}
}

function Filesystem.Initialize(ent)
	ent.files = {
		["C:\\"] = {_dname = "System Disk"}
	}
	ent.bad_words = {"_dname", "_parent", "_name"}
	ent.cur_disk = "C:\\"
	ent.cur_dir = ent.files["C:\\"]
end

function Filesystem.ChangeDisk(ent, name)
	if !name or table.HasValue(ent.bad_words, name) then gTerminal:Broadcast(ent, "Invalid disk name!", GT_COL_ERR) return false end
	if !ent.files[name] then gTerminal:Broadcast(ent, "Disk is not exists!", GT_COL_ERR) return false end

	ent.cur_dir = ent.files[name]
end

function Filesystem.CreateDir(ent, name)
	if (tonumber(name) != nil) then gTerminal:Broadcast(entity,"Can't create directory with a name consisting of numbers!", GT_COL_ERR) return end
	if !name or table.HasValue(ent.bad_words, name) then gTerminal:Broadcast(ent, "Invalid directory name!", GT_COL_ERR) return end
	if type(ent.cur_dir[name]) == "string" then gTerminal:Broadcast(ent, "File with same name already exists!", GT_COL_ERR) return end
	if ent.cur_dir[name] then gTerminal:Broadcast(ent, "Directory already exists!", GT_COL_ERR) return end
	if utf8.len(name) > 20 then
		gTerminal:Broadcast(ent, "Max chars in name must be not greater then 20!", GT_COL_ERR)
		return
	end
	if string.match(name, "[\\/:*?\"<>|]") != nil then
		gTerminal:Broadcast(ent, "Name contains unallowable chars!", GT_COL_ERR)
		return
	end
	ent.cur_dir[name] = { _parent = ent.cur_dir, _name = name}
end

function Filesystem.ChangeDir(ent, name)
    if name == ".." then
        ent.cur_dir = ent.cur_dir._parent or ent.cur_dir
        return
    end

	if !ent.cur_dir[name] then gTerminal:Broadcast(ent, "Directory is not exists!", GT_COL_ERR) return false end
	if type(ent.cur_dir[name]) != "table" then gTerminal:Broadcast(ent, "Object is file!", GT_COL_ERR) return false end
	if !name or table.HasValue(ent.bad_words, name) then gTerminal:Broadcast(ent, "Invalid directory name!", GT_COL_ERR) return false end

    ent.cur_dir = ent.cur_dir[name]
end


function Filesystem.CreateFile(ent, name, content, replace)
	if (tonumber(name) != nil) then gTerminal:Broadcast(entity,"Can't create file with a name consisting of numbers!", GT_COL_ERR) return false end
	if !name or table.HasValue(ent.bad_words, name) then gTerminal:Broadcast(ent, "Invalid file name!", GT_COL_ERR) return false end
	if utf8.len(name) > 20 then
		gTerminal:Broadcast(ent, "Max chars in name must be not greater then 20!", GT_COL_ERR)
		return
	end
	if string.match(name, "[\\/:*?\"<>|]") != nil then
		gTerminal:Broadcast(ent, "Name contains unallowable chars!", GT_COL_ERR)
		return
	end
	if replace != true then
		replace = false
	end
	if ent.cur_dir[name] != nil and replace != true then
		if string.find(name, ".") then
			local name_n = string.Split(name, ".")
			for i = 1, 100000 do
				name_n[#name_n - 1] = name_n[#name_n - 1] .. "_copy(".. tostring(i) .. ")"
				if ent.cur_dir[table.concat(name_n, ".")] != nil then 
					continue
				else
					ent.cur_dir[table.concat(name_n, ".")] = content
					return
				end
			end
		else
			for i = 1, 100000 do
				if ent.cur_dir[name .. "_copy(".. tostring(i) .. ")"] then 
					continue
				else
					ent.cur_dir[name .. "_copy(".. tostring(i) .. ")"] = content
					return
				end
			end
		end
	else
		ent.cur_dir[name] = content
		return true
	end
end

net.Receive("gTerminal.Editor.Save", function(len, ply)
	local ent = net.ReadEntity()
	local name = net.ReadString()
	local content = net.ReadString()

	ent.cur_dir[name] = content
end)

--[Sound]--

function Filesystem.PlaySoundFile(ent, sfilecontent)
	sfilecontent = string.Replace(sfilecontent, "\n"," ")
	local GTERM_table_numbers = string.Split(sfilecontent, " ")
	if string.match(sfilecontent, "^[a-z]") != nil then gTerminal:Broadcast(ent, "In sound file has words!", GT_COL_ERR) return end
	if #GTERM_table_numbers % 2 != 0 then gTerminal:Broadcast(ent, "Sum of numbers is odd number!", GT_COL_ERR) return end
	
	local generated_snd = {}
	for i = 1, #GTERM_table_numbers, 2 do
		if GTERM_table_numbers[i] == nil then
			break
		end
		if GTERM_table_numbers[i+1] == "0" then
			gTerminal:Broadcast(ent, "Time must be not 0!", GT_COL_ERR) return
		end
		if GTERM_table_numbers[i] == "0" then
			continue
		elseif tonumber(GTERM_table_numbers[i]) < 37 then
			GTERM_table_numbers[i] = "38"
		elseif tonumber(GTERM_table_numbers[i]) > 32767 then
			GTERM_table_numbers[i] = "32766"
		end
		if !table.HasValue(generated_snd, GTERM_table_numbers[i]) then
			generated_snd[#generated_snd + 1] = tonumber(GTERM_table_numbers[i])
		end
	end
		net.Start("gT_GenerateSoundtbl")
		net.WriteTable(generated_snd)
		net.Broadcast()
	local function PlaySoundFileBase(arguments)
		if arguments == #GTERM_table_numbers + 1 then
			return
		end
		local delay = tonumber(GTERM_table_numbers[arguments + 1]) * 0.001
		if GTERM_table_numbers[arguments] == "0" then
			timer.Simple( delay, function() PlaySoundFileBase(arguments + 2) end )
		else
			net.Start("gT_EmitSound")
			net.WriteUInt(ent:EntIndex(), 14)
			net.WriteUInt(tonumber(GTERM_table_numbers[arguments]), 15)
			net.Broadcast()
			timer.Simple( delay, function()
				net.Start("gT_StopSound")
				net.WriteUInt(ent:EntIndex(), 14)
				net.WriteUInt(tonumber(GTERM_table_numbers[arguments]), 15)
				net.Broadcast()
				PlaySoundFileBase(arguments + 2) 
			end )
		end
	end
	timer.Simple( 5, function()
		PlaySoundFileBase(1)
	end )
end

Filesystem.names = table.GetKeys( Filesystem.commands )
table.sort( Filesystem.names )

gTerminal.Filesystem = Filesystem