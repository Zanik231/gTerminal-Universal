AddCSLuaFile()
ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.Spawnable = false
ENT.Category = "gTerminal"
ENT.Model = "models/props_phx/rt_screen.mdl"
ENT.BackgroundColor = Color(0, 0, 0, 255)
function ENT:OnRemove()
	if SERVER then
		for k, v in pairs(player.GetAll()) do
			v["pass_authed_" .. self:EntIndex()] = nil
		end

		if not table.IsEmpty(self.destructor) then
			for _, v in pairs(self.destructor) do
				v(self)
			end
		end

		gTerminal.CurrentColors[self:EntIndex()] = nil
	end

	if CLIENT then gTerminal[self:EntIndex()] = nil end
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

		self.os = self.os or GetConVar("gterminal_default_os"):GetString()
		
		self.WarmedUp = false
		self.periphery = {}
		self.destructor = {}
		self.DefaultBackgroundColor = self.BackgroundColor
		local physicsObject = self:GetPhysicsObject()
		self.colors = table.Copy(GT_colors)
		if IsValid(physicsObject) then
			physicsObject:Wake()
			physicsObject:EnableMotion(true)
		end

		if self.CustomInit then self:CustomInit() end
	end

	function ENT:OnDuplicated() --OnSaveLoaded???
		gTerminal:Broadcast(self, "Terminal loaded!", GT_COL_SUCC)
		if self.scriptExecuting then
			self.scriptExecuting = nil
			self.executingCoroutine = nil
			self:SetInputMode(GT_INPUT_INP)
		end
	end

	function ENT:ShutDown()
		self:SetActive(false)
		self.WarmedUp = false
		self:SetInputMode(GT_INPUT_NIL)
		self:SetUser(nil)
		gTerminal:ClearConsole(self)
	end

	function ENT:WarmUp()
		self.WarmedUp = true
		gTerminal:SPK_Beep(self)
		local WarmUpText = gTerminal.os[self.os]:GetWarmUpText()
		if GetConVar("gterminal_fast_launch"):GetBool() then
			if WarmUpText then
				for i = 1, #WarmUpText do
					gTerminal:Broadcast(self, WarmUpText[i])
				end

				gTerminal:Broadcast(self, "")
			end

			gTerminal:Broadcast(self, "Welcome to gTerminal!")
			gTerminal:Broadcast(self, "To list all commands, type " .. GetConVar("gterminal_command_prefix"):GetString() .. "help")
			self:SetInputMode(GT_INPUT_INP)
		else
			if WarmUpText then
				local time = math.random(3, 8)
				for i = 1, #WarmUpText do
					timer.Simple(i * (#WarmUpText / time), function()
						if not IsValid(self) then return end
						gTerminal:Broadcast(self, WarmUpText[i], GT_COL_INT)
						if i == #WarmUpText then
							timer.Simple(math.Rand(2, 4), function()
								if IsValid(self) then
									gTerminal:Broadcast(self, "")
									gTerminal:Broadcast(self, "Welcome to gTerminal!")
									gTerminal:Broadcast(self, "To list all commands, type " .. GetConVar("gterminal_command_prefix"):GetString() .. "help")
									self:SetInputMode(GT_INPUT_INP)
								end
							end)
						end
					end)
				end
			else
				gTerminal:Broadcast(self, "Welcome to gTerminal!")
				gTerminal:Broadcast(self, "To list all commands, type " .. GetConVar("gterminal_command_prefix"):GetString() .. "help")
				self:SetInputMode(GT_INPUT_INP)
			end
		end
	end

	function ENT:Use(activator, caller)
		if not self.WarmedUp then
			self:SetActive(true)
			self:WarmUp()
		elseif self:GetActive() then
			if not IsValid(self:GetUser()) then
				self:SetUser(activator)
				net.Start("gT_ActiveConsole")
				net.WriteEntity(self)
				net.Send(activator)
			end
		end
	end

	function ENT:Think()
		local user = self:GetUser()
		if IsValid(user) and user:Alive() then
			local dist = user:GetPos():DistToSqr(self:GetPos())
			if not self:GetActive() or dist > 9216 then --96
				self:SetUser(nil)
				net.Start("gT_EndTyping")
				net.Send(user)
			end
		end
	end
else
	function ENT:Initialize()
		self.consoleText = ""
		self.consoleStory = {}
		self.colors = table.Copy(GT_colors)
		gTerminal[self:EntIndex()] = {}
	end

	function ENT:Draw()
		self:DrawModel()
		if self:GetActive() then
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
			surface.SetFont("gT_ConsoleFont")
			surface.SetDrawColor(self.BackgroundColor or color_black)
			surface.DrawRect(0, 0, self.scrW, self.scrH)
			local lines = gTerminal[self:EntIndex()]
			if lines then
				for i = 1, self.maxLines do
					local line = lines[i]
					if not line then continue end
					local xOffset = 1
					local yPos = (self.lineHeight * i) - self.lineHeight
					local currentBlockText = ""
					local currentBlockColor = -1
					for charIdx = 1, self.maxChars do
						local data = line[charIdx]
						if not data then continue end
						if data.col ~= currentBlockColor then
							if currentBlockText ~= "" then
								local col
								if IsColor(currentBlockColor) then
									col = currentBlockColor
								else
									col = gTerminal:ColorFromIndex(currentBlockColor, self)
								end

								surface.SetTextColor(col)
								surface.SetTextPos(xOffset, yPos)
								surface.DrawText(currentBlockText)
								local tw, _ = surface.GetTextSize(currentBlockText)
								xOffset = xOffset + tw
							end

							currentBlockColor = data.col
							currentBlockText = data.char
						else
							currentBlockText = currentBlockText .. data.char
						end
					end

					if currentBlockText ~= "" then
						local col = gTerminal:ColorFromIndex(currentBlockColor, self)
						surface.SetTextColor(col)
						surface.SetTextPos(xOffset, yPos)
						surface.DrawText(currentBlockText)
					end
				end
			end

			local y = (self.maxLines + 1) * self.lineHeight
			surface.SetDrawColor(255, 255, 255, 15)
			surface.DrawRect(1, y, self.scrW - 1, self.lineHeight)
			local user = self:GetUser()
			if IsValid(user) and user ~= LocalPlayer() then
				self.consoleText = user:Name() .. " is typing..."
			else
				self.consoleText = self.consoleText or ""
			end

			local rawInput = utf8.sub(self.consoleText, 1, self.maxChars - 2)
			local inputText = "> " .. rawInput
			draw.SimpleText(inputText, "gT_ConsoleFont", 1, y, color_white, 0, 0)
			if LocalPlayer() == user and (CurTime() % 1.0) < 0.5 then
				local textBeforeCaret = "> " .. utf8.sub(rawInput, 1, self.consoleCaretPos or 0)
				local caretXOffset, _ = surface.GetTextSize(textBeforeCaret)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawRect(1 + caretXOffset, y, 5, self.lineHeight)
			end

			render.PopFilterMin()
			render.PopFilterMag()
			cam.End3D2D()
		end
	end
end