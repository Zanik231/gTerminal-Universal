AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Spawnable = false
ENT.Category = "gTerminal"
ENT.Model = "models/props_phx/rt_screen.mdl"
ENT.BackgroundColor = Color(0, 0, 0, 255)

function ENT:OnRemove()
	if (SERVER) then
		for k, v in pairs( player.GetAll() ) do
			v[ "pass_authed_"..self:EntIndex() ] = nil
		end
		
		if !table.IsEmpty(self.destructor) then
			for k, v in pairs(self.destructor) do
				v(self)
			end
		end
	end
	if (CLIENT) then
		gTerminal[ self:EntIndex() ] = nil
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Active")
	self:NetworkVar("Entity", 0, "User")
	self:NetworkVar("Int", 0, "InputMode")
end

if SERVER then
	function ENT:Initialize()
		self:SetModel(self.Model)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:DrawShadow(false)
		self.os = gTerminal.os[ GetConVar("gterminal_default_os"):GetString() ]
		self.WarmedUp = false
		self.periphery = {}
		self.destructor = {}
		self.DefaultBackgroundColor = self.BackgroundColor
		local physicsObject = self:GetPhysicsObject()
		self.colors = table.Copy(GT_colors)

		if ( IsValid(physicsObject) ) then
			physicsObject:Wake()
			physicsObject:EnableMotion(true)
		end
		if self.CustomInit then
			self:CustomInit()
		end
	end

	function ENT:ShutDown()
		self:SetActive(false)
		self.WarmedUp = false
		self:SetInputMode(GT_INPUT_NIL)
		gTerminal:ClearConsole(self)
	end

	function ENT:WarmUp()
		self.WarmedUp = true
		gTerminal:SPK_Beep(self)
		local WarmUpText = self.os:GetWarmUpText()

		if GetConVar("gterminal_fast_launch"):GetBool() then
			if WarmUpText then
				for i = 1, #WarmUpText do
					gTerminal:Broadcast(self, WarmUpText[i])
				end
				gTerminal:Broadcast(self, "")
			end
			gTerminal:Broadcast(self, "Welcome to gTerminal!")
			gTerminal:Broadcast(self, "To list all commands, type " .. GetConVar("gterminal_command_prefix"):GetString() .."help")
			self:SetInputMode(GT_INPUT_INP)
			return
		end
		if (WarmUpText) then
			local time = math.random(3, 8)

			for i = 1, #WarmUpText do
				timer.Simple( i * (#WarmUpText / time), function()
					if ( IsValid(self) ) then
						gTerminal:Broadcast(self, WarmUpText[i], GT_COL_INT)

						if (i == #WarmUpText) then
							timer.Simple(math.Rand(2, 4), function()
								if ( IsValid(self) ) then
									gTerminal:Broadcast(self, "")
									gTerminal:Broadcast(self, "Welcome to gTerminal!")
									gTerminal:Broadcast(self, "To list all commands, type " .. GetConVar("gterminal_command_prefix"):GetString() .."help")
									self:SetInputMode(GT_INPUT_INP)
								end
							end)
						end
					end
				end)
			end
		else
			gTerminal:Broadcast(self, "Welcome to gTerminal!")
			gTerminal:Broadcast(self, "To list all commands, type " .. GetConVar("gterminal_command_prefix"):GetString() .. "help")
			self:SetInputMode(GT_INPUT_INP)
		end
	end

	function ENT:SpawnFunction(ply, trace, client)
		if (!trace.Hit) then
			return false
		end
		local SpawnAng = ply:EyeAngles()
		SpawnAng.p = 0
		SpawnAng.y = SpawnAng.y + 180
		local entity = ents.Create(self.ClassName)
		entity:Initialize()
		entity:SetPos( trace.HitPos )
		entity:SetAngles( SpawnAng )
		entity:Spawn()
		entity:Activate()

		return entity
	end

	function ENT:Use(activator, caller)
		if ( !self.WarmedUp ) then
			self:SetActive(true)
			self:WarmUp()
		elseif ( self:GetActive()) then
			if ( !IsValid( self:GetUser() ) ) then
				self:SetUser(activator)

				net.Start("gT_ActiveConsole")
					net.WriteUInt(self:EntIndex(), 16)
				net.Send(activator)
			end
		end
	end 

	function ENT:Think()
		local user = self:GetUser()

		if ( IsValid(user) ) then
			local distance = user:GetPos():Distance( self:GetPos() )

			if ( !self:GetActive() or distance > 96 ) then
				net.Start("gT_EndTyping")
				net.Send(user)

				self:SetUser(nil)
			end 
		end 
	end 
else

	function ENT:Initialize()
		self.scrW = self.scrW or 905
		self.scrH = self.scrH or 768
		self.maxChars = self.maxChars or 50
		self.maxLines = self.maxLines or 24
		self.lineHeight = self.lineHeight or 28.7
		self.consoleText = ""
		self.consoleStory = {}
		self.AsyncKeys = {}
		self.colors = table.Copy(GT_colors)
		gTerminal[self:EntIndex()] = {}
	end

	function ENT:Draw()
		self:DrawModel()

		if ( self:GetActive() ) then
			local angle
			if self.GetScreenAngles then
				angle = self:GetScreenAngles()
			else
				angle = self:GetAngles()
				angle:RotateAroundAxis(angle:Forward(), 90)
				angle:RotateAroundAxis(angle:Right(), -90)
			end

			local pos = self.GetScreenPos and self:GetScreenPos() or self:GetPos()


			cam.Start3D2D(pos, angle, 0.0215)
				render.PushFilterMin(TEXFILTER.POINT)
				render.PushFilterMag(TEXFILTER.POINT)

					surface.SetDrawColor(self.BackgroundColor)
					surface.DrawRect(0, 0, self.scrW, self.scrH)

					local lines = gTerminal[ self:EntIndex() ]
					for i = 1, self.maxLines do
						if ( lines[i] ) then
							local color = gTerminal:ColorFromIndex(lines[i].color, self)

							draw.SimpleText(lines[i].text or "", "gT_ConsoleFont", 1, (self.lineHeight * i) - self.lineHeight, color, 0, 0)
						end
					end

					local y = (self.maxLines + 1) * self.lineHeight
					surface.SetDrawColor(255, 255, 255, 15)
					surface.DrawRect(1, y, self.scrW - 1, self.lineHeight)


					if IsValid(self:GetUser()) then
						if self:GetUser() != LocalPlayer() then
							self.consoleText = self:GetUser():Name().." is typing..."
						end
					else
						self.consoleText = ""
					end
					draw.SimpleText("> ".. (utf8.sub(self.consoleText,1,self.maxChars) or ""), "gT_ConsoleFont", 1, y, color_white, 0, 0)

				render.PopFilterMin()
				render.PopFilterMag()
			cam.End3D2D()
		end
	end
end