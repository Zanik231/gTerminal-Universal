AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_gmodentity"

ENT.PrintName = "Disk"
ENT.Author = "chupa"
ENT.Purpose = "Base ore"

ENT.Spawnable = true
ENT.Category = "gTerminal"
if (SERVER) then
    duplicator.RegisterEntityModifier( "gT_Disk", function(p,e,d)
    end)
    duplicator.RegisterEntityModifier( "gT_DiskN", function(p,e,d)
    end)
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
    end

	function ENT:Use(ply)
	    ply:PickupObject( self )
	end
    
    function ENT:OnDuplicated( entTable )
        if entTable.EntityMods.gT_Disk then
            self.Files = entTable.EntityMods.gT_Disk
        end
        if entTable.EntityMods.gT_DiskN then
            self.name = entTable.EntityMods.gT_DiskN[1]
        end
    end

    function ENT:GetNameD()
        return self.name or "NewDisket"
    end

    function ENT:SetNameD(str)
        self.name = str
        duplicator.StoreEntityModifier( self,"gT_DiskN",{self.name} )
        duplicator.CopyEntTable( self )
    end

    function ENT:SetData(data)
        self.Files = data
        duplicator.StoreEntityModifier( self,"gT_Disk",self.Files )
        duplicator.CopyEntTable( self )
    end

    function ENT:GetData()
        return self.Files or {}
    end
else
    function ENT:Draw()
        self:DrawModel()
    end
end