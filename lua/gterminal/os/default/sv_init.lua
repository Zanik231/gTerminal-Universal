local OS = OS

function OS:GetName()
	return "PBCS"
end

function OS:GetUniqueID()
	return "default"
end

function OS:GetWarmUpText()
	return {
		"Initializing boot sequence.",
		"Finalizing Primary Boot Computing System."
	}
end

include("sv_commands.lua")