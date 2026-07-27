-- AceGUI-3.0-SharedMediaWidgets stub
local AceGUI = LibStub("AceGUI-3.0")
local Media = LibStub("LibSharedMedia-3.0")

-- Register a dummy Sound widget so LSM30_Sound works
do
    local widgetType = "LSM30_Sound"
    local widgetVersion = 1

    local function Constructor()
        local self = AceGUI:Create("Dropdown")
        self.type = widgetType
        self.frame:SetScript("OnShow", function() end)
        return self
    end

    AceGUI:RegisterWidgetType(widgetType, Constructor, widgetVersion)
end
