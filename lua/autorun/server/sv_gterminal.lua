include("gterminal/sv_init.lua")
AddCSLuaFile("autorun/client/cl_gterminal.lua")
AddCSLuaFile("gterminal/cl_init.lua")

resource.AddFile("models/zanik/pc/floppy.mdl")
resource.AddFile("models/zanik/pc/pc_speaker.mdl")
resource.AddFile("materials/")

local gTerminalSettings = {
    gterminal_default_os = "default",
    gterminal_default_os_root = "root_os",
    gterminal_command_prefix = ":",
    gterminal_allow_user_execute = "1",
    gterminal_fast_launch = "0",
    gterminal_fast_install = "0"
}

local a = file.Read( "gterminal.json", "DATA" )
if a then
    gTerminalSettings = table.Inherit(util.JSONToTable(a), gTerminalSettings)
else
    file.Write( "gterminal.json", util.TableToJSON(gTerminalSettings) )
end
a = nil

CreateConVar("gterminal_default_os", "default", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Os for all gterminal computers")
CreateConVar("gterminal_default_os_root", "root_os", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Os for root computer \"sent_computerzanik_root\"")
CreateConVar("gterminal_command_prefix", ":", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Command prefix for all gterminal computers")

CreateConVar("gterminal_allow_user_execute", "1", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Allow users to execute commands on non-root_os")
CreateConVar("gterminal_fast_launch", "0", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Pc fast launching")
CreateConVar("gterminal_fast_install", "0", {FCVAR_LUA_SERVER, FCVAR_NOTIFY}, "Fast installing os")

GetConVar("gterminal_default_os"):SetString(gTerminalSettings.gterminal_default_os)
GetConVar("gterminal_default_os_root"):SetString(gTerminalSettings.gterminal_default_os_root)
GetConVar("gterminal_command_prefix"):SetString(gTerminalSettings.gterminal_command_prefix)

GetConVar("gterminal_allow_user_execute"):SetString(gTerminalSettings.gterminal_allow_user_execute)
GetConVar("gterminal_fast_launch"):SetString(gTerminalSettings.gterminal_fast_launch)
GetConVar("gterminal_fast_install"):SetString(gTerminalSettings.gterminal_fast_install)

gameevent.Listen( "server_cvar" )

hook.Add( "server_cvar", "gTerminalServerCvars", function( data )
	local cvarname = data.cvarname
	local cvarvalue = data.cvarvalue
    if (cvarname == "gterminal_command_prefix") then
        if (#cvarvalue > 1 and cvarvalue != " ") then
            GetConVar("gterminal_command_prefix"):SetString(":")
            gTerminalSettings.gterminal_command_prefix = ":"
        else
            gTerminalSettings.gterminal_command_prefix = cvarvalue
        end
        file.Write( "gterminal.json", util.TableToJSON(gTerminalSettings) )
    elseif (cvarname == "gterminal_default_os" ) then
        local tab1 = {}
        local int1 = 1
        for i in pairs(gTerminal.os) do
            tab1[int1] = i
            int1 = int1 + 1
        end
        if (!table.HasValue(tab1, data.cvarvalue)) then
            GetConVar("gterminal_default_os"):SetString("default")
            gTerminalSettings.gterminal_default_os = "default"
        else
            gTerminalSettings.gterminal_default_os = cvarvalue
        end
        file.Write( "gterminal.json", util.TableToJSON(gTerminalSettings) )
    elseif (cvarname == "gterminal_default_os_root") then
        local tab1 = {}
        local int1 = 1
        for i in pairs(gTerminal.os) do
            tab1[int1] = i
            int1 = int1 + 1
        end
        if (!table.HasValue(tab1, data.cvarvalue)) then
            GetConVar("gterminal_default_os_root"):SetString("root_os")
            gTerminalSettings.gterminal_default_os_root = "root_os"
        else
            gTerminalSettings.gterminal_default_os_root = cvarvalue
        end
        file.Write( "gterminal.json", util.TableToJSON(gTerminalSettings) )
    elseif (cvarname == "gterminal_allow_user_execute") then
        local a = tonumber(data.cvarvalue)
        if (a != nil) then
            if (a > 0) then
                GetConVar("gterminal_allow_user_execute"):SetString("1")
                gTerminalSettings.gterminal_allow_user_execute = "1"
            else
                GetConVar("gterminal_allow_user_execute"):SetString("0")
                gTerminalSettings.gterminal_allow_user_execute = "0"
            end
            file.Write( "gterminal.json", util.TableToJSON(gTerminalSettings) )
        end
    elseif (cvarname == "gterminal_fast_launch") then
        local a = tonumber(data.cvarvalue)
        if (a != nil) then
            if (a > 0) then
                GetConVar("gterminal_fast_launch"):SetString("1")
                gTerminalSettings.gterminal_fast_launch = "1"
            else
                GetConVar("gterminal_fast_launch"):SetString("0")
                gTerminalSettings.gterminal_fast_launch = "0"
            end
            file.Write( "gterminal.json", util.TableToJSON(gTerminalSettings) )
        end
    elseif (cvarname == "gterminal_fast_install") then
        local a = tonumber(data.cvarvalue)
        if (a != nil) then
            if (a > 0) then
                GetConVar("gterminal_fast_install"):SetString("1")
                gTerminalSettings.gterminal_fast_install = "1"
            else
                GetConVar("gterminal_fast_install"):SetString("0")
                gTerminalSettings.gterminal_fast_install = "0"
            end
            file.Write( "gterminal.json", util.TableToJSON(gTerminalSettings) )
        end
    end
end )