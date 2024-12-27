AddCSLuaFile()
DEFINE_BASECLASS("base_wire_entity")
ENT.PrintName = "Wire I/O Device"
ENT.WireDebugName = "I/O Device"
ENT.Author = "Busterdash"
ENT.Contact = "bstrdash@gmail.com"
ENT.Purpose = "Used to connect wiremod and gTerminal."
ENT.Spawnable = true
ENT.AdminOnly = false
ENT.Category = "gTerminal"

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 0, "Computer")
	self:NetworkVar("String", 0, "IP0")
	self:NetworkVar("String", 1, "IP1")
	self:NetworkVar("String", 2, "OP0")
	self:NetworkVar("String", 3, "OP1")
end

if (SERVER) then

	function ENT:Initialize()
	
		self:SetModel("models/props_lab/reciever01a.mdl")
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		
		if (WireAddon) then
			self.Inputs = WireLib.CreateSpecialInputs(self, { "INPUT A", "INPUT B"}, {"STRING", "STRING"})
			self.Outputs = WireLib.CreateSpecialOutputs(self, { "OUTPUT A", "OUTPUT B"}, {"STRING", "STRING"})
		end
		
		local phys = self:GetPhysicsObject()
		
		if (IsValid(phys)) then
			phys:Wake()
			phys:EnableMotion(true)
		end
		
		self:UpdateOverlay()
		
	end

	function ENT:Use(ply)
		ply:PickupObject(self)
	end

	function ENT:TriggerInput(name, value)
	
		if (name == "INPUT A") then
			self:SetIP0(value)
		elseif (name == "INPUT B") then
			self:SetIP1(value)
		end
		
	end
	
	function ENT:Think()
		self:UpdateOverlay()
		if (!IsValid(self:GetComputer())) then return end
		Wire_TriggerOutput(self, "OUTPUT A", self:GetOP0())
		Wire_TriggerOutput(self, "OUTPUT B", self:GetOP1())
	end
	
	function ENT:UpdateOverlay()
		if (!IsValid(self:GetComputer())) then
			self:SetOverlayText("Unclaimed")
		else
			self:SetOverlayText("Claimed by [" .. self:GetComputer():EntIndex() .. "]")
		end
	end
else

end