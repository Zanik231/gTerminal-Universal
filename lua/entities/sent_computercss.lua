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
    ENT.maxChars = 51
    ENT.maxLines = 24
    
	function ENT:SpawnFunction(ply, trace, client)
        if !IsMounted("cstrike") then
            ply:PrintMessage( HUD_PRINTTALK, "Server don't have CSS content!" )
            return false;
        end
		if (!trace.Hit) then
			return false;
		end;
		local SpawnAng = ply:EyeAngles()
		SpawnAng.p = 0
		SpawnAng.y = SpawnAng.y + 180
		local entity = ents.Create(self.ClassName);
		entity:Initialize();
		entity:SetPos( trace.HitPos );
		entity:SetAngles( SpawnAng )
		entity:Spawn();
        entity:SetSkin(1);
		entity:Activate();
		return entity;
	end;

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