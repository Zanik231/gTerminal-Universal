local OS = OS

function OS:GetName()
	return "VEX-DOS"
end

function OS:GetUniqueID()
	return "vex_dos"
end

function OS:GetWarmUpText()
	return {
		" __   __ ___ _   _      ___   ___  ___  ",
		" \\ \\ / /| __| \\/ / ___ |   \\ / _ \\/ __| ",
		"  \\   / | _| >  < |___|| |) | (_) |__ \\ ",
		"   \\_/  |___|_/\\_\\     |___/ \\___/|___/ ",
		" The operating system for your personal needs.",
		"   Build 200101",
	}
end

include("sv_commands.lua")