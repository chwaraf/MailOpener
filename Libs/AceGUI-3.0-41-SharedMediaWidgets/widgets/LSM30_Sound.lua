-- Minimal LSM30_Sound widget stub
local AceGUI = LibStub("AceGUI-3.0")
local Type, Version = "LSM30_Sound", 1

local function Constructor()
    local widget = {
        type = Type,
        frame = CreateFrame("Frame"),
    }
    return widget
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
