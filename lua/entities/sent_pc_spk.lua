AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "PC Speaker"
ENT.Author = "Zanik"
ENT.Purpose = "Used to play beep sound on computer."

ENT.Spawnable = true
ENT.Category = "gTerminal"
if (SERVER) then
	function ENT:SpawnFunction(client, trace)
		if (!trace.Hit) then
			return false
		end 

		local entity = ents.Create(self.ClassName)
		entity:Initialize()
		entity:SetPos( trace.HitPos + Vector(0, 0, 3) )
		entity:Spawn()
		entity:Activate()

		return entity
	end 
	function ENT:Initialize()
		self:SetModel("models/zanik/pc/pc_speaker.mdl")
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:DrawShadow(true)
	
		local physicsObject = self:GetPhysicsObject()

		if ( IsValid(physicsObject) ) then
			physicsObject:Wake()
			physicsObject:EnableMotion(true)
		end
	end
	function ENT:Use(ply)
	    ply:PickupObject( self )
	end
else
	function ENT:Draw()
	self:DrawModel()
	local oang=self:GetAngles()
	local opos= self:GetPos()	
	local ang=self:GetAngles()
	local pos= self:GetPos()
	end
end