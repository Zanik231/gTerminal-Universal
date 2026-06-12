AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.PrintName = "Disk"
ENT.Author = "Zanik"

ENT.Spawnable = true
ENT.Category = "gTerminal"

function ENT:SetupDataTables()
	self:NetworkVar("String", 0, "DName")
end

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

        self:SetDName("NewDisket")
        self.Files = self.Files or {}
    end

	function ENT:Use(ply)
	    ply:PickupObject( self )
	end
else
    function ENT:Draw()
		self:DrawModel()
			local angle = self:GetAngles()
			angle:RotateAroundAxis(angle:Forward(), 180)
			-- angle:RotateAroundAxis(angle:Right(), 90)
			angle:RotateAroundAxis(angle:Up(), 90)
			local pos = self:GetPos() 
                local offset = angle:Up() * 0.25
	pos = pos + offset
        cam.Start3D2D(pos, angle, 0.0215)
			draw.DrawText(self:GetDName(), "gT_ConsoleFont", 5, 70, Color( 255, 255, 255, 255 ),TEXT_ALIGN_CENTER)
		cam.End3D2D()
    end
end