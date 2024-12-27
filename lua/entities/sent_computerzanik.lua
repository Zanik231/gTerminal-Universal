AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "sent_computer_base"
ENT.Model = "models/props_lab/monitor01a.mdl"

ENT.PrintName = "Computer"
ENT.Category = "gTerminal"
ENT.Spawnable = true

ENT.scrW = 905
ENT.scrH = 768
ENT.lineHeight = 28.7
ENT.maxChars = 50
ENT.maxLines = 24

function ENT:GetScreenPos()
	local angle = self:GetAngles()

	local offset = angle:Up() * 11.8 + angle:Forward() * 11.7 + angle:Right() * 9.7

	return self:GetPos() + offset
end

function ENT:GetScreenAngles()
	local angle = self:GetAngles()
	angle:RotateAroundAxis(angle:Forward(), 180)
	angle:RotateAroundAxis(angle:Right(), 265.5)
	angle:RotateAroundAxis(angle:Up(), 270)

	return angle
end