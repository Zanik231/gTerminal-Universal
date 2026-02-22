local Editor = {}

local skin = {}
skin.PrintName 		= "gTerminalSkin" 
skin.Author			= "ZANIK" 
skin.DermaVersion	= 1 
skin.Colours = {}
skin.Colours.Button = {}
skin.Colours.Button.Disabled = Color(255,255,255,255)
skin.Colours.Button.Down = Color(138,138,138)
skin.Colours.Button.Hover = Color(255,255,255,255)
skin.Colours.Button.Normal = Color(255,255,255,255)
derma.DefineSkin("gTerminalSkin","local skin", skin)

local main = vgui.RegisterTable({
    Init = function(self)
        self:SetSize(ScrW() * .65, ScrH() * .65)
        self:Center()
        self:MakePopup()
        self:SetTitle("Text Editor")
        self:SetDraggable(false)
        local BGtext_entry = self:Add("DPanel")
        BGtext_entry:Dock(FILL)
        BGtext_entry:SetBackgroundColor(Color(50,50,50,255))
        local text_entry = self:Add("DTextEntry")
        text_entry:SetFont("gT_ConsoleFont")
        text_entry:Dock(FILL)
        text_entry:SetMultiline(true)
        text_entry:SetPaintBackground(false)
        text_entry:SetTextColor(Color(255,255,255,255))
        text_entry:SetCursorColor(Color(255,255,255,255))
        text_entry:SetHighlightColor(Color(160,160,160,50))
        text_entry:SetTabbingDisabled( true )
        self.text_entry = text_entry
        local save = self:Add("DButton")
        save:Dock(BOTTOM)
        save:SetPaintBackground(false)
        save:SetText("Save")
        save:SetSkin("gTerminalSkin")
        save.DoClick = function(s)
            if #text_entry:GetValue() > 32761 then
                local error_frame = vgui.Create( "DFrame", self )
                error_frame:Center()
                error_frame:SetSize( ScrW()* .4, ScrH() * .25)
                error_frame:SetTitle( "Error!" )
                error_frame:SetVisible( true )
                error_frame:SetDraggable( false )
                error_frame:ShowCloseButton( false )
                self:SetMouseInputEnabled(false)
                error_frame:MakePopup()
                local error_label = vgui.Create( "DLabel", error_frame )
                error_label:SetSize( ScrW()* .4, ScrH() * .25)
                local x,y = error_label:GetPos()
                error_label:SetPos(x + 35, y - 65)
                error_label:SetFont("gT_ConsoleFont")
                error_label:SetText( "File size is above then 64kb.\n\nPlease delete some text." )
                local close_error = self:Add("DButton", error_frame)
                close_error:Dock(BOTTOM)
                close_error:SetParent(error_frame)
                close_error:SetText("OK")
                close_error.DoClick = function()
                    error_frame:Close()
                    self:SetMouseInputEnabled(true)
                    self:MakePopup()
                end
                return
            end
            net.Start("gTerminal.Editor.Save")
                net.WriteEntity(self.entity)
                net.WriteString(self.name)
                net.WriteString(text_entry:GetValue())
            net.SendToServer()
            self:Close()
        end
    end,
}, "DFrame")


function Editor:Open(ent, name, content)
    self:Close()

    self.panel = vgui.CreateFromTable(main)
    self.panel.entity = ent
    self.panel.name = name

    self.panel:SetTitle("Text Editor - " .. name)

    self.panel.text_entry:SetText(content)
end

function Editor:Close()
    if IsValid(self.panel) then self.panel:Remove() end
end


net.Receive("gTerminal.Editor.Open", function()
    Editor:Open(net.ReadEntity(), net.ReadString(), net.ReadString())
end)


gTerminal.Editor = Editor