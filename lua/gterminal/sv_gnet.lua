local GNet = gTerminal.GNet or {}
local Filesystem = gTerminal.Filesystem

GNet.commands = {
    shared = {
        ["ls"] = {
            func = function(cl, ent, args)
                gTerminal:Broadcast(ent, "ACTIVE NETWORKS:");

                local index = 0
                for name, gnet in pairs(GNet.list) do
                    index = index + 1

                    gTerminal:Broadcast(ent, "    " .. index .. ". " .. name .. (gnet._pass and " (PRIVATE)" or " (PUBLIC)"))
                end

                gTerminal:Broadcast(ent, "");
                gTerminal:Broadcast(ent, "    Found " .. index .. " active network(s).");
            end,
            help = "List all networks",
            add_help = ""
        },
        ["lu"] = {
            func = function(cl, ent, args)
                if !ent.gnet_client then gTerminal:Broadcast("You aren't connected to a network", GT_COL_ERR) return end

                gTerminal:Broadcast(ent, "ACTIVE USERS:")

                local index = 0
                for _, client in ipairs(ent.gnet_client.clients) do
                    index = index + 1
                    local ent_ind = client:EntIndex()
                    local ent_client = Entity(ent_ind)
                    local ent_name = ent_client.name

                    gTerminal:Broadcast(ent, "    " .. index .. ". " .. ent_ind .. " - " .. ent_name .. (client.gnet_host and " (HOST)" or "") )
                end

                gTerminal:Broadcast(ent, "")
                gTerminal:Broadcast(ent, "    Found " .. index .. " active user(s)")
            end,
            help = "List all users",
            add_help = ""
        },
        ["m"] = {
            func = function(cl, ent, args)
                local id, msg = args[2], table.concat(args, " ", 3)

                if !ent.gnet_client then gTerminal:Broadcast(ent, "You aren't connected to a network!", GT_COL_ERR) return end
                if id != "@" then
                    if tonumber(id) != nil then
                        if !IsValid(Entity(tonumber(id))) then
                            gTerminal:Broadcast(ent, "Invalid UserID!", GT_COL_ERR)
                            return
                        end
                    else
                        gTerminal:Broadcast(ent, "Invalid UserID!", GT_COL_ERR)
                        return
                    end
                end
                if !msg then gTerminal:Broadcast(ent, "Invalid message!", GT_COL_ERR) return end
                GNet.SendMessage(ent, ent.gnet_client, id, msg)
            end,
            help = "Send message",
            add_help = " <id> <message>"
        },
        ["mf"] = {
            func = function(cl, ent, args)
                if !ent.gnet_client then gTerminal:Broadcast(ent, "You aren't connected to a network!", GT_COL_ERR) return end
                if !args[2] then gTerminal:Broadcast(ent, "Invalid UserID!", GT_COL_ERR) return end
			    if !ent.cur_dir[args[3]] then gTerminal:Broadcast(ent, "File is not exists!", GT_COL_ERR) return end

                GNet.SendFile(ent, ent.gnet_client, args[2], ent.cur_dir[args[3]], args[3])
            end,
            help = "Send file",
            add_help = " <id> <filename>"
        },
        ["conf"] = {
            func = function(cl, ent, args)
                if args[2] == nil then
                    gTerminal:Broadcast(ent, "GNET CONFIG:")
                    gTerminal:Broadcast(ent,  "user_name - " .. ent.name)
                    gTerminal:Broadcast(ent, "spk_in_msg - " .. tostring(ent.gnet_pcspk))
                else
                    if args[2] == "user_name" then
                        if args[3] == "" or args[3] == " " then
                            gTerminal:Broadcast(ent, "User name is not valid!")
                        else
                            ent.name = table.concat(args," ", 3,#args)
                            gTerminal:Broadcast(ent, "User name changed to - " .. ent.name)
                        end
                    elseif args[2] == "spk_in_msg" then
                        if args[3] != "true" and args[3] != "false" then
                            gTerminal:Broadcast(ent, "spk_in_msg must be true or false!")
                        else
                            ent.gnet_pcspk = tobool(args[3])
                            gTerminal:Broadcast(ent, "spk_in_msg changed to - " .. tostring(ent.gnet_pcspk))
                        end
                    else
                        gTerminal:Broadcast(ent, "Not valid variable!")
                    end
                end
            end,
            help = "Config for gnet",
            add_help = " [var] [value]"
        }
    },
    server = {
        ["c"] = {
            func = function(cl, ent, args)
                GNet.Create(ent, args[2], args[3])
            end,
            help = "Create network",
            add_help = " <name> [password]"
        },
        ["r"] = {
            func = function(cl, ent, args)
                GNet.Remove(ent)
            end,
            help = "Remove network",
            add_help = ""
        },
        ["ban"] = {
            func = function(cl, ent, args)
                local id = args[2]

                if !ent.gnet_host then gTerminal:Broadcast(ent, "You don't have active network!", GT_COL_ERR) return end
                if !id then gTerminal:Broadcast(ent, "Invalid UserID!", GT_COL_ERR) return end

                GNet.Ban(ent.gnet_host, id)
            end,
            help = "Ban user",
            add_help = " <id>"
        },
        ["unban"] = {
            func = function(cl, ent, args)
                local id = args[2]

                if !ent.gnet_host then gTerminal:Broadcast(ent, "You don't have active network!", GT_COL_ERR) return end
                if !id then gTerminal:Broadcast(ent, "Invalid UserID!", GT_COL_ERR) return end

                GNet.UnBan(ent.gnet_host, id)
            end,
            help = "Unban user",
            add_help = " <id>"
        },
        ["kick"] = {
            func = function(cl, ent, args)
                local id = args[2]

                if !ent.gnet_host then gTerminal:Broadcast(ent, "You don't have active network!", GT_COL_ERR) return end
                if !id then gTerminal:Broadcast(ent, "Invalid UserID!", GT_COL_ERR) return end

                GNet.Kick(ent.gnet_host, id)
            end,
            help = "Kick user",
            add_help = " <id>"
        },
    },
    client = {
        ["j"] = {
            func = function(cl, ent, args)
                GNet.Join(ent, args[2], args[3])
            end,
            help = "Join network",
            add_help = " <name> [password]"
        },
        ["l"] = {
            func = function(cl, ent, args)
                GNet.Leave(ent, "Disconnected by user.")
            end,
            help = "Leave network",
            add_help = ""
        }
    },
}

GNet.list = GNet.list or {}


function GNet.Create(ent, name, pass)
    if GNet.list[name] then gTerminal:Broadcast(ent, "Network already exists!", GT_COL_ERR) return end
    if ent.gnet_host then gTerminal:Broadcast(ent, 'You are currently hosting "' .. ent.gnet_host._name .. '"', GT_COL_ERR) return end
    if !name then gTerminal:Broadcast(ent, "Invalid name!", GT_COL_ERR) return end


    local str = 'Network "' .. name .. '"'
    if pass then str = str .. ' with password "' .. pass .. '"' end
    str = str .. " created!"

    gTerminal:Broadcast(ent, str, GT_COL_SUCC)


    ent.gnet_host = {
        _name = name,
        _pass = pass,
        clients = {
            ent
        }
    }
    ent.gnet_client = ent.gnet_host

    GNet.list[name] = ent.gnet_host
end

function GNet.Remove(ent)
    if !ent.gnet_host then gTerminal:Broadcast(ent, "You don't have active network!", GT_COL_ERR) return end


    for _, ent in ipairs(ent.gnet_host.clients) do
        gTerminal:Broadcast(ent, "[GNET] Disconnected")
        ent.gnet_client = nil
    end

    gTerminal:Broadcast(ent, 'Network "' .. ent.gnet_host._name .. '" removed!', GT_COL_SUCC)

    GNet.list[ent.gnet_host._name] = nil
    ent.gnet_host = nil
end

function GNet.Get(name)
    return GNet.list[name]
end


function GNet.Join(ent, name, pass)
    if !name then gTerminal:Broadcast(ent, "Invalid name!", GT_COL_ERR) return end
    if ent.gnet_client then gTerminal:Broadcast(ent, "You are already connected to a network!", GT_COL_ERR) return end

    local gnet = GNet.Get(name)

    if !gnet then gTerminal:Broadcast(ent, "Invalid network!", GT_COL_ERR) return end

    if gnet._pass then
        if !pass then gTerminal:Broadcast(ent, "Password required!", GT_COL_ERR) return end
        if pass != gnet._pass then gTerminal:Broadcast(ent, "Incorrect password!", GT_COL_ERR) return end
    end

    if gnet.bans and gnet.bans[ent] then gTerminal:Broadcast(ent, "You are banned from this network!", GT_COL_ERR) return end


    gTerminal:Broadcast(ent, "Connected to server " .. name .. "!", GT_COL_INFO)


    table.insert(gnet.clients, ent)
    ent.gnet_client = gnet
end

function GNet.Leave(ent, reason)
    if !ent.gnet_client then gTerminal:Broadcast(ent, "You aren't connected to a network!", GT_COL_ERR) return end

    local gnet = ent.gnet_client

    for i, client in ipairs(gnet.clients) do
        if client == ent then table.remove(gnet.clients, i) break end
    end


    reason = reason and " (" .. reason .. ")" or ""
    
    --GNet.Broadcast(gnet, 'Client "' .. ent:EntIndex() ..  '" disconnected!' .. reason, GT_COL_INFO)
    gTerminal:Broadcast(ent, '[GNET] Dropped from "' .. gnet._name .. '"' .. reason, GT_COL_INFO)


    ent.gnet_client = nil
end


function GNet.Broadcast(gnet, msg, colorType)
    for _, client in ipairs(gnet.clients) do
        gTerminal:Broadcast(client, "[GNET] " .. msg, colorType)
    end
end

function GNet.GetUserByID(gnet, id)
    for _, ent in ipairs(gnet.clients) do
        if ent:EntIndex() == tonumber(id) then return ent end
    end
end

function GNet.Ban(gnet, id)
    local user = Entity(id)
    if user then
        gnet.bans = gnet.bans or {}
        gnet.bans[user] = true

        GNet.Leave(user, "Banned!")
    end
end

function GNet.UnBan(gnet, id)
    local user = Entity(id)
    if gnet.bans and user then
        gnet.bans[user] = nil
    end
end

function GNet.Kick(gnet, id)
    local user = GNet.GetUserByID(gnet, id)
    if user then
        GNet.Leave(user, "Kicked!")
    end
end

function GNet.SendMessage(sender, gnet, id, msg)
    local sender_id = sender:EntIndex()
    local ent_client = Entity(sender_id)
    local ent_name = ent_client.name

    if sender.gnet_host then sender_id = sender_id .. "(HOST)" end
    if id == "@" then
        GNet.Broadcast(gnet, sender_id .. " - " .. ent_name .. " > Everyone: " .. msg, GT_COL_INFO)
    else
        local user = Entity(tonumber(id))
        local user_name = user.name
        if user.gnet_pcspk then
            gTerminal:SPK_Beep(user, 660)
        end
        gTerminal:Broadcast(user, "[GNET] " .. sender_id .. " - " .. ent_name .. " > You: " .. msg, GT_COL_INFO)
        gTerminal:Broadcast(sender, "[GNET] You > " .. id .. " - " .. user_name .. ": " .. msg, GT_COL_INFO)
    end
end

function GNet.SendFile(sender, gnet, id, file, filename)
    local sender_id = sender:EntIndex()
    local ent_client = Entity(sender_id)
    local ent_name = ent_client.name
    if sender.gnet_host then sender_id = sender_id .. "(HOST)" end

    local user = Entity(tonumber(id))
    local user_name = user.name
    if !user then gTerminal:Broadcast(sender, "Invalid UserID", GT_COL_ERR) return end


    user.gnet_file_request = true
    gTerminal:Broadcast(user, '[GNET] Would you like to accept file "' .. filename .. '" from ' .. sender_id .. " - " .. ent_name .. "? (Y/N)", GT_COL_INFO)
    timer.Create("GNet.File.Request." .. id, 60, 1, function()
        if IsValid(user) and user.gnet_file_request then
            gTerminal:Broadcast(user, "[GNET] File request from " .. sender_id .. " - " .. ent_name .. " timed out...", GT_COL_INFO)
            gTerminal:Broadcast(sender, "[GNET] File request to " .. id .. " - " .. user_name .. " timed out...", GT_COL_INFO)

            user.gnet_file_request = nil
        end
    end)

    gTerminal:GetInput(user, function(cl, args)
        if (args[1] and args[1]:lower() == "y") then
            gTerminal:Broadcast(user, "[GNET] Request from " .. sender_id .. " - " .. ent_name .. " accepted!", GT_COL_INFO)
            gTerminal:Broadcast(sender, "[GNET] Request to " .. id .. " - " .. user_name .. " accepted!", GT_COL_INFO)

            if !user.files["C:\\"]["Downloads"] then
                user.files["C:\\"]["Downloads"] = {_parent = user.files["C:\\"], _name = "Downloads"}
            end
            user.files["C:\\"]["Downloads"][filename] = file
        else
            gTerminal:Broadcast(user, "[GNET] Request from " .. sender_id .. " - " .. ent_name .. " denied!", GT_COL_INFO)
            gTerminal:Broadcast(sender, "[GNET] Request to " .. id .. " - " .. user_name .. " denied!", GT_COL_INFO)
        end

        user.gnet_file_request = nil
    end)
end


gTerminal.GNet = GNet