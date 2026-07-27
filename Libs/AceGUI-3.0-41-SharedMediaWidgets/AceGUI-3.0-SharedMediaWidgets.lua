-- AceGUI-3.0-SharedMediaWidgets stub
local MAJOR, MINOR = "AceGUI-3.0-SharedMediaWidgets", 1
local AceGUI = LibStub and LibStub("AceGUI-3.0", true)
if not AceGUI then return end

-- Normally this library registers extra widget types (LSM30_Sound, etc.)
-- For safety, load widget files
local widgetFiles = {
    "LSM30_Sound.lua",
}

for _, file in ipairs(widgetFiles) do
    local path = "MailOpener/Libs/AceGUI-3.0-41-SharedMediaWidgets/widgets/" .. file
    local loadedFunc, err = loadfile(path)
    if loadedFunc then
        pcall(loadedFunc)
    else
        -- fallback dummy widget if missing
        AceGUI:RegisterWidgetType("LSM30_Sound", function() return {} end, 1)
    end
end
