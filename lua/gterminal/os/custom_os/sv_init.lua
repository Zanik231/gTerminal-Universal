local OS = OS 

function OS:GetName()
	return "Custom System" 
end 

function OS:GetUniqueID()
	return "custom_os" 
end 

function OS:GetWarmUpText()
	return nil
end 

include("sv_commands.lua") 