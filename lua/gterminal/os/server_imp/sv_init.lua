function OS:GetName()
	return "VEX-SERVER";
end;

function OS:GetUniqueID()
	return "vex_server";
end;

function OS:GetWarmUpText()
	return {
		"__   __ ___ _   _      ___ ___   __ ",
		"\\ \\ / /| __| \\/ / ___ / __|\\  \\ / / ",
		" \\   / | _| >  < |___|\\__ \\ \\    /  ",
		"  \\_/  |___|_/\\_\\     |___/  \\__/   ",
		" The operating system for server hosting.",
		"   Build 160161SV"
	};
end;

function OS:ShutDown(entity)
	if entity.gnet_host then
		gTerminal.GNet.Remove(entity)
	end;
end;

include("sv_commands.lua");