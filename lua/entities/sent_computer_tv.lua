AddCSLuaFile()

ENT.Type = "anim" 
ENT.Base = "sent_computer_base" 

ENT.PrintName = "TV" 
ENT.Category = "gTerminal" 
ENT.Spawnable = true

ENT.scrW = 2600 
ENT.scrH = 1504 
ENT.lineHeight = 32 
ENT.maxChars = 142 
ENT.maxLines = 45 

function ENT:GetScreenPos()
    local angle = self:GetAngles()

    local offset = angle:Up() * 35.2 + angle:Forward() * 6 + angle:Right() * 27.9  

    return self:GetPos() + offset
end