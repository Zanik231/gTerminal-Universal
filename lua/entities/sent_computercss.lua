AddCSLuaFile()
    
ENT.Type = "anim"
ENT.Base = "sent_computer_base"
ENT.Model = "models/props/cs_office/computer_monitor.mdl"

ENT.PrintName = "CSS Monitor"
ENT.Category = "gTerminal"
ENT.Spawnable = true

ENT.scrW = 963
ENT.scrH = 728
ENT.lineHeight = 28
ENT.maxChars = 53
ENT.maxLines = 24

function ENT:CustomInit()
    self:SetSkin(1)
end
function ENT:GetScreenPos()
    local angle = self:GetAngles()
    local offset = angle:Up() * 24.52 + angle:Forward() * 3.25 + angle:Right() * 10.355
    return self:GetPos() + offset
end

function ENT:GetScreenAngles()
    local angle = self:GetAngles()
    angle:RotateAroundAxis(angle:Forward(), 180)
    angle:RotateAroundAxis(angle:Right(), 270)
    angle:RotateAroundAxis(angle:Up(), 270)
    
    return angle
end