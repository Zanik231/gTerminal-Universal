AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sent_computer_base"
ENT.Model = "models/maxofs2d/motion_sensor.mdl"

ENT.PrintName = "Projector"
ENT.Category = "gTerminal"
ENT.Spawnable = true

ENT.BackgroundColor = Color(0, 0, 0, 225)

ENT.scrW = 2048
ENT.scrH = 1024
ENT.lineHeight = 32
ENT.maxChars = 111
ENT.maxLines = 30

function ENT:GetScreenPos()
    local angle = self:GetAngles()

    local offset = angle:Up() * 25 + angle:Forward() * 5 + angle:Right() * 22

    return self:GetPos() + offset
end

function ENT:GetScreenAngles()
    local angle = self:GetAngles()
    angle:RotateAroundAxis(angle:Up(), 90)
    angle:RotateAroundAxis(angle:Forward(), 80)

    return angle
end