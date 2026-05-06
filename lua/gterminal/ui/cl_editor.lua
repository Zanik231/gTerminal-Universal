local Editor = {}

-- Глобальная переменная для запоминания зума между сессиями
local GlobalEditorZoom = 36 
local fontCache = {}

local function GetZoomedFont(size)
    size = math.Round(size)
    local fontName = "gT_EditorZoom_" .. size
    if not fontCache[size] then
        surface.CreateFont(fontName, {
            font = "Consolas", 
            size = size,
            weight = 500,
            extended = true,
            antialias = true,
        })
        fontCache[size] = true
    end
    return fontName
end

-- Скин для кнопок
local skin = {}
skin.Colours = { Button = { 
    Disabled = Color(255,255,255), Down = Color(138,138,138), 
    Hover = Color(255,255,255), Normal = Color(255,255,255) 
}}
derma.DefineSkin("gTerminalSkin", "gTerminal Skin", skin)

local main = vgui.RegisterTable({
    Init = function(self)
        self:SetSize(ScrW() * .65, ScrH() * .65)
        self:Center()
        self:MakePopup()
        self:SetTitle("Text Editor")
        self:SetDraggable(false)
        
        -- Используем глобальное значение при старте
        self.FontSize = GlobalEditorZoom 

        local scroll = self:Add("DScrollPanel")
        scroll:Dock(FILL)
        scroll.Paint = function(s, w, h)
            draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
        end

        local sbar = scroll:GetVBar()
        sbar:SetWide(10)
        function sbar:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30, 150)) end
        function sbar.btnUp:Paint(w, h) end
        function sbar.btnDown:Paint(w, h) end
        function sbar.btnGrip:Paint(w, h) draw.RoundedBox(0, 0, 0, w, h, Color(100, 100, 100, 200)) end

        local text_entry = scroll:Add("DTextEntry")
        text_entry:SetMultiline(true)
        text_entry:Dock(TOP)
        text_entry:SetPaintBackground(false)
        text_entry:SetTextColor(Color(255, 255, 255, 255))
        text_entry:SetCursorColor(Color(255, 255, 255, 255))
        text_entry:SetHighlightColor(Color(160, 160, 160, 50))
        text_entry:SetTabbingDisabled(true)
        
        text_entry.UpdateHeight = function(s)
            surface.SetFont(s:GetFont())
            local _, lineH = surface.GetTextSize("W")
            local _, lines = string.gsub(s:GetValue(), "\n", "")
            lines = (lines or 0) + 1
            local newH = math.max(scroll:GetTall(), lines * (lineH + 2))
            s:SetSize(scroll:GetWide(), newH + 150)
            scroll:InvalidateLayout(true)
        end

        -- ПРИНУДИТЕЛЬНЫЙ ПЕРЕСЧЕТ ЗУМА
        self.ApplyZoom = function(s)
            local font = GetZoomedFont(s.FontSize)
            text_entry:SetFont(font)
            
            if text_entry.SetFontInternal then
                text_entry:SetFontInternal(font)
            end
            
            text_entry:UpdateHeight()
            -- Сохраняем масштаб в глобальную переменную
            GlobalEditorZoom = s.FontSize 
        end

        -- ПЕРЕХВАТ КОЛЕСИКА
        text_entry.OnMouseWheeled = function(s, delta)
            if input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL) then
                self.FontSize = math.Clamp(self.FontSize + (delta * 2), 10, 80)
                self:ApplyZoom()
                return true
            end
            scroll:GetVBar():OnMouseWheeled(delta)
        end

        -- ПЕРЕХВАТ КЛАВИАТУРЫ
        text_entry.OnKeyCodeTyped = function(s, code)
            if input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL) then
                if code == KEY_PAD_PLUS or code == KEY_EQUAL then
                    self.FontSize = math.Clamp(self.FontSize + 2, 10, 80)
                    self:ApplyZoom()
                    return true
                elseif code == KEY_PAD_MINUS or code == KEY_MINUS then
                    self.FontSize = math.Clamp(self.FontSize - 2, 10, 80)
                    self:ApplyZoom()
                    return true
                end
            end
        end

        text_entry.OnTextChanged = function(s) s:UpdateHeight() end
        self.text_entry = text_entry
        
        -- Кнопка Save
        local save = self:Add("DButton")
        save:Dock(BOTTOM)
        save:SetPaintBackground(false)
        save:SetText("Save")
        save:SetSkin("gTerminalSkin")
        save.DoClick = function(s)
            local val = text_entry:GetValue()
            local comp_text = util.Compress(val)
            net.Start("gTerminal.Editor.Save")
                net.WriteEntity(self.entity)
                net.WriteString(self.name)
                net.WriteUInt(#comp_text, 16)
                net.WriteData(comp_text, #comp_text)
            net.SendToServer()
            self:Close()
        end

        timer.Simple(0, function() if IsValid(self) then self:ApplyZoom() end end)
    end,
}, "DFrame")

function Editor:Open(ent, name, content)
    self:Close()
    self.panel = vgui.CreateFromTable(main)
    self.panel.entity = ent
    self.panel.name = name
    self.panel:SetTitle("Text Editor - " .. name)
    self.panel.text_entry:SetText(content)
    self.panel:ApplyZoom()
end

function Editor:Close()
    if IsValid(self.panel) then self.panel:Remove() end
end

net.Receive("gTerminal.Editor.Open", function()
    Editor:Open(net.ReadEntity(), net.ReadString(), net.ReadString())
end)

gTerminal.Editor = Editor
