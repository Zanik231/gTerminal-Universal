local OS = OS

function OS:GetName()
	return "ROOT_DOS"
end

function OS:GetUniqueID()
	return "root_os"
end

function OS:GetWarmUpText()
	return {
		"Root system."
	}
end

include("sv_commands.lua")