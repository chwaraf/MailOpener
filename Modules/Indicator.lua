local MailOpener = LibStub("AceAddon-3.0"):GetAddon("MailOpener");
local mod = MailOpener:NewModule("Indicator", "AceEvent-3.0", "AceHook-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("MailOpener");

mod.moduleDescription = L["Uses the minimap mail icon to indicate when there is still unread mail waiting for you at the mailbox."];
mod.moduleRequired = false;

function mod:OnInitialize()
end

function mod:OnEnable()
	self:Debug("OnEnable");
	
	MinimapMailFrameUpdate = NewMinimapMailFrameUpdate;
	
	self:RegisterEvent("MAIL_SHOW");
	
	-- If we were toggling this module on while the mailbox is opened we must register all events again
	if MailFrame:IsVisible() then
		self:MAIL_SHOW();
	end
end

-- Even though Ace can unregister our events it's neater to do it manually too
function mod:OnDisable()
	self:Debug("OnDisable");
	
	MinimapMailFrameUpdate = originalMinimapMailFrameUpdate;
	
	self:UnregisterEvent("MAIL_SHOW");
end

function mod:MAIL_SHOW()
	self:Debug("MAIL_SHOW");
	
	self:RegisterEvent("MAIL_CLOSED");
	
	self:RegisterMessage("MO_SERVER_SYNCED");
	self:RegisterMessage("MO_OPEN_COMPLETE");
end

local lastKnownTotalItems;

function mod:MAIL_CLOSED()
	self:Debug("MAIL_CLOSED");
	
	self:UnregisterEvent("MAIL_CLOSED");
	
	self:UnregisterMessage("MO_SERVER_SYNCED");
	self:UnregisterMessage("MO_OPEN_COMPLETE");
	
	self:UpdateIcon();
end

-- We received new mail, update icon status
function mod:MO_SERVER_SYNCED()
	self:UpdateIcon();
end

-- We processed current mail, update icon status
function mod:MO_OPEN_COMPLETE()
	self:UpdateIcon();
end

function mod:UpdateIcon()
	local numItems, totalItems = GetInboxNumItems();
	lastKnownTotalItems = totalItems;
	
	if totalItems > numItems then
		-- Unread items not currently visible remaining
		MiniMapMailFrame:Show();
	else
		-- Current mail is everything there is
		MiniMapMailFrame:Hide();
	end
end

-- Copy the old updater
local originalMinimapMailFrameUpdate = MinimapMailFrameUpdate;
-- Prepare a function to overwrite the default WoW function updating the tooltip for the mail icon
-- Only apply this function when this module is enabled
function NewMinimapMailFrameUpdate()
	-- A small part of this code was copied from the FrameXML
	
	local toolText;
	if lastKnownTotalItems then
		toolText = L["You have %d unread mail remaining in your mailbox."]:format(lastKnownTotalItems);
	else
		toolText = L["You have unread mail remaining in your mailbox."];
	end
	
	local sender1, sender2, sender3 = GetLatestThreeSenders();
	
	if sender1 or sender2 or sender3 then
		toolText = toolText .. " " .. L["This mail includes mail sent by:"] .. "\n";
	end
	
	if sender1 then
		toolText = toolText .. "\n" .. sender1;
	end
	if sender2 then
		toolText = toolText .. "\n" .. sender2;
	end
	if sender3 then
		toolText = toolText .. "\n" .. sender3;
	end
	
	GameTooltip:SetText(toolText);
end

function mod:GetOptionsGroup()
	local configGroup = {
		order = 0,
		type = "modulesSubGroup",
		name = L["Indicator"],
		desc = L["Change settings for the Indicator module."],
		args = {
			General = {
				order = 10,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					description = {
						order = 10,
						type = "description",
						name = function()
							local descText = L["With this button you can completely toggle this module |cff00ff00on|r or |cffff0000off|r. This setting will be remembered and the module will be automatically toggled |cff00ff00on|r or |cffff0000off|r upon logon as it was last set."] .. "\n\n";
							
							if self:IsEnabled() then
								descText = descText .. L["Status: %s"]:format(L["|cff00ff00Enabled|r"]);
							else
								descText = descText .. L["Status: %s"]:format(L["|cffff0000Disabled|r"]);
							end
							
							return descText;
						end,
					},
					disable = {
						order = 20,
						type = "execute",
						name = function()
							if self:IsEnabled() then
								return L["Disable Module"];
							else
								return L["Enable Module"];
							end
						end,
						desc = L["Click here to completely toggle this module on or off."],
						width = "double",
						func = function()
							if self:IsEnabled() then
								self:Disable();
								
								MailOpener.db.profile.modules[self:GetName()] = false;
							else
								self:Enable();
								
								MailOpener.db.profile.modules[self:GetName()] = true;
							end
						end,
					},
				},
			},
		},
	};
	
	return configGroup;
end

function mod:Debug(t)
	return MailOpener:Debug("|cff993300Indicator|r:" .. t);
end
