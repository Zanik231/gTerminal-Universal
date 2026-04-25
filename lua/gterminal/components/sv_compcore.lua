local gTerminal = gTerminal 
local Periph = Periph or {}

local periphery =
{
    ["sent_pc_spk"] = "PC Speaker"
}
Periph.commands = {
	["con"] = {
		func = function(client, entity, arguments)
            local succes = false
            for periphery_ent, periphery_name in pairs(periphery) do
                if table.HasValue(entity.periphery, periphery_ent) then continue end
                
                for k, v in pairs(ents.FindByClass(periphery_ent)) do
                    local dist = entity:GetPos():DistToSqr(v:GetPos())
                    if (dist <= 4096) then --64
                        table.insert(entity.periphery, periphery_ent)
                        v:Remove()
                        gTerminal:Broadcast(entity, periphery_name .. " connected.", GT_COL_SUCC)
                        succes = true
                        break 
                    end
                end
                if succes == true then return end
            end
            if !succes then
                gTerminal:Broadcast(entity, "There's no not connected periphery nearby.", GT_COL_WRN)
            end
		end,
		help = "Connect the nearest periphery.",
		add_help = "",
	}, 
    ["discon"] = {
		func = function(client, entity, arguments)
            local num = tonumber(arguments[2])
            if num == nil then
                gTerminal:Broadcast(entity,"Value is not a number",GT_COL_ERR)
                return
            end
            if num >= #entity.periphery + 1 or num <= 0 then
                gTerminal:Broadcast(entity,"Number not valid",GT_COL_ERR)
                return
            end

            local per_ent = ents.Create( entity.periphery[num] )
            per_ent:SetPos( entity:LocalToWorld(Vector(0,0,25)) )
            per_ent:Spawn()
            per_ent:Activate()

            gTerminal:Broadcast(entity, periphery[entity.periphery[num]] .. " is disconnected", GT_COL_SUCC)
            table.remove(entity.periphery, num)
		end,
		help = "Disconnect periphery.",
		add_help = " <num>",
	}, 
    ["list"] = {
		func = function(client, entity, arguments)
            if table.IsEmpty(entity.periphery) then
                gTerminal:Broadcast(entity, "Periphery is not connected.")
                return
            end
            for var = 1, #entity.periphery do
                gTerminal:Broadcast(entity, var .. ". " .. periphery[entity.periphery[var]])
            end
		end,
		help = "List of connected periphery.",
		add_help = "",
	}, 
}
gTerminal.Periph = Periph