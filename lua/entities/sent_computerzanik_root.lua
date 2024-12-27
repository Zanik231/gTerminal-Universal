AddCSLuaFile();

--ENT.ClassName = "Computer";
ENT.PrintName = "Root Computer";
ENT.Category = "gTerminal";
ENT.Spawnable = true
ENT.AdminOnly = true
ENT.Type = "anim";
ENT.Base = "sent_computer_base";

ENT.Model = "models/props_lab/monitor01a.mdl"
ENT.scrW = 905;
ENT.scrH = 768;
ENT.lineHeight = 28.7;
ENT.maxChars = 50;
ENT.maxLines = 24;

function ENT:GetScreenPos()
	local angle = self:GetAngles()

	local offset = angle:Up() * 11.8 + angle:Forward() * 11.72 + angle:Right() * 9.7

	return self:GetPos() + offset
end

function ENT:GetScreenAngles()
	local angle = self:GetAngles()
	angle:RotateAroundAxis(angle:Forward(), 180)
	angle:RotateAroundAxis(angle:Right(), 265.5)
	angle:RotateAroundAxis(angle:Up(), 270)

	return angle
end

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model);
		self:SetMoveType(MOVETYPE_VPHYSICS);
		self:PhysicsInit(SOLID_VPHYSICS);
		self:SetSolid(SOLID_VPHYSICS);
		self:SetUseType(SIMPLE_USE);
		self:DrawShadow(false);
		self:SetActive(false);
		self:SetOS(GetConVar("gterminal_default_os_root"):GetString());
		self.periphery = {};
		self.destructor = {};
		self.GTERM_beep_sound = {};
		for i = -3, 3 do
			table.insert(self.GTERM_beep_sound, CreateSound(self, GT_SPK_BEEP .. tostring(i) .. ".wav"))
			self.GTERM_beep_sound[i + 4]:SetSoundLevel(GT_SPK_LVL)
		end
		local physicsObject = self:GetPhysicsObject();

		if ( IsValid(physicsObject) ) then
			physicsObject:Wake();
			physicsObject:EnableMotion(true);
		end;
	end;
end