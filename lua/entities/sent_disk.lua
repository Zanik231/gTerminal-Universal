AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Disk"
ENT.Author = "chupa"
ENT.Purpose = "Base ore"

ENT.Spawnable = true
ENT.Category = "gTerminal"
if (SERVER) then
    function ENT:Initialize()
        self:SetModel("models/zanik/pc/floppy.mdl")
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
		self:DrawShadow(true)
        local phys = self:GetPhysicsObject()
        if (IsValid(phys)) then
            phys:Wake()
            phys:EnableMotion(true)
        end

        self.name = self.name or "NewDisket"
        self.Files = self.Files or {}
    end

	function ENT:Use(ply)
	    ply:PickupObject( self )
	end
end