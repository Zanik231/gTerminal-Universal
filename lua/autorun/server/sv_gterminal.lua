include("gterminal/sv_init.lua")
AddCSLuaFile("autorun/client/cl_gterminal.lua")
AddCSLuaFile("gterminal/cl_init.lua")

resource.AddFile("models/zanik/pc/floppy.mdl")
resource.AddFile("models/zanik/pc/pc_speaker.mdl")
resource.AddFile("materials/models/conred/floppy_texture.vmt")
resource.AddFile("materials/models/zanik/metallicspk.vmt")

resource.AddSingleFile("materials/models/conred/floppy_texture_bump.vtf")

CreateConVar("gterminal_default_os", "default", {FCVAR_LUA_SERVER, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Os for all gterminal computers")
CreateConVar("gterminal_default_os_root", "root_os", {FCVAR_LUA_SERVER, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Os for root computer \"sent_computerzanik_root\"")
CreateConVar("gterminal_command_prefix", ":", {FCVAR_LUA_SERVER, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Command prefix for all gterminal computers")

CreateConVar("gterminal_allow_user_execute", "1", {FCVAR_LUA_SERVER, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Allow users to execute commands on non-root_os")
CreateConVar("gterminal_fast_launch", "0", {FCVAR_LUA_SERVER, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Pc fast launching")
CreateConVar("gterminal_fast_install", "0", {FCVAR_LUA_SERVER, FCVAR_NOTIFY, FCVAR_ARCHIVE}, "Fast installing os")

gameevent.Listen( "server_cvar" )

hook.Add( "server_cvar", "gTerminalServerCvars", function( data )
	local cvarname = data.cvarname
	local cvarvalue = data.cvarvalue
    if cvarname == "gterminal_command_prefix" and #cvarvalue > 1 and cvarvalue != " " then
        GetConVar("gterminal_command_prefix"):SetString(":")
    elseif (cvarname == "gterminal_default_os" ) and !gTerminal.os[cvarname] then
        GetConVar("gterminal_default_os"):SetString("default")
    elseif cvarname == "gterminal_default_os_root" and !gTerminal.os[cvarname] then
        GetConVar("gterminal_default_os_root"):SetString("root_os")
    elseif (cvarname == "gterminal_allow_user_execute") then
        local a = tonumber(data.cvarvalue)
        if (a != nil) then
            GetConVar("gterminal_allow_user_execute"):SetString(a > 0 and "1" or "0")
        end
    elseif (cvarname == "gterminal_fast_launch") then
        local a = tonumber(data.cvarvalue)
        if (a != nil) then
            GetConVar("gterminal_fast_launch"):SetString(a > 0 and "1" or "0")
        end
    elseif (cvarname == "gterminal_fast_install") then
        local a = tonumber(data.cvarvalue)
        if (a != nil) then
            GetConVar("gterminal_fast_install"):SetString(a > 0 and "1" or "0")
        end
    end
end )