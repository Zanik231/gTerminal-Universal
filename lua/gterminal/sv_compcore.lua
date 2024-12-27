local gTerminal = gTerminal;
local Periph = Periph or {}

local periphery = {"sent_pc_spk", "TESTNULL"}
local periphery_namereal = {"PC Speaker", "TESTNULL"}
Periph.commands = {
	["con"] = {
		func = function(client, entity, arguments)
            local succes = false
            for var = 1, #periphery do
                if table.HasValue(entity.periphery, periphery[var]) == true then
                else 
                    for k, v in pairs(ents.FindByClass(periphery[var])) do
                        local dist = entity:GetPos():Distance(v:GetPos())
                        if (dist <= 64) then
                            table.insert(entity.periphery, periphery[var])
                            v:Remove()
                            gTerminal:Broadcast(entity, periphery_namereal[var] .. " connected.")
                            succes = true
                            break 
                        end
                    end
                    if succes == true then break end
                end
                if var == #periphery and succes == false then
                    gTerminal:Broadcast(entity, "There's no periphery nearby",GT_COL_ERR)
                end
            end
		end,
		help = "Connect the nearest periphery.",
		add_help = "",
	}, 
    ["discon"] = {
		func = function(client, entity, arguments)
            local succes = false
            if tonumber(arguments[2]) != nil then
                if tonumber(arguments[2]) < #entity.periphery + 1 and tonumber(arguments[2]) > 0 then
                    local keyv = table.KeyFromValue(periphery, entity.periphery[tonumber(arguments[2])])
                    local per_ent = ents.Create( periphery[keyv] )
                    per_ent:SetPos( entity:LocalToWorld(Vector(0,0,25)) )
                    per_ent:Spawn()
                    table.RemoveByValue(entity.periphery, periphery[keyv])
                    gTerminal:Broadcast(entity, periphery_namereal[keyv] .. " is disconnected")
                else
                    gTerminal:Broadcast(entity,"Number not valid",GT_COL_ERR)
                end
            else
                gTerminal:Broadcast(entity,"Value is not a number",GT_COL_ERR)
            end
		end,
		help = "Disconnect eriphery.",
		add_help = " <num>",
	}, 
    ["list"] = {
		func = function(client, entity, arguments)
            local succes = false
            if table.IsEmpty(entity.periphery) then
                gTerminal:Broadcast(entity, "Periphery is not connected")
            else
                for var = 1, #entity.periphery do
                    local keyv = table.KeyFromValue(periphery, entity.periphery[var])
                    gTerminal:Broadcast(entity, var .. ". " .. periphery_namereal[keyv])
                end
            end
		end,
		help = "List of connected periphery.",
		add_help = "",
	}, 
}
gTerminal.Periph = Periph