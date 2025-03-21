include("gterminal/sv_init.lua");
AddCSLuaFile("autorun/client/cl_gterminal.lua");
AddCSLuaFile("gterminal/cl_init.lua");
CreateConVar("gterminal_default_os", "default", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Os for all gterminal computers");
CreateConVar("gterminal_default_os_root", "root_os", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Os for root computer \"sent_computerzanik_root\"");
CreateConVar("gterminal_command_prefix", ":", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Command prefix for all gterminal computers");
CreateConVar("gterminal_allow_user_execute", "1", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Allow users to execute commands on non-root_os");
gameevent.Listen( "server_cvar" )
hook.Add( "server_cvar", "server_cvar_example", function( data )
	local cvarname = data.cvarname
	local cvarvalue = data.cvarvalue
    if (cvarname == "gterminal_command_prefix" and #cvarvalue > 1) then
        GetConVar("gterminal_command_prefix"):SetString(":")
    elseif (cvarname == "gterminal_default_os" ) then
        local tab1 = {}
        local int1 = 1
        for i in pairs(gTerminal.os) do
            tab1[int1] = i
            int1 = int1 + 1
        end
        if (!table.HasValue(tab1, data.cvarvalue)) then
            GetConVar("gterminal_default_os"):SetString("default")
        end
    elseif (cvarname == "gterminal_default_os_root") then
        local tab1 = {}
        local int1 = 1
        for i in pairs(gTerminal.os) do
            tab1[int1] = i
            int1 = int1 + 1
        end
        if (!table.HasValue(tab1, data.cvarvalue)) then
            GetConVar("gterminal_default_os_root"):SetString("root_os")
        end
    elseif (cvarname == "gterminal_allow_user_execute") then
        local a = tonumber(data.cvarvalue)
        if (a != nil) then
            if (a > 0) then
                GetConVar("gterminal_allow_user_execute"):SetString("1")
            else
                GetConVar("gterminal_allow_user_execute"):SetString("0")
            end
        end
    end
end )