local MailOpener = LibStub("AceAddon-3.0"):GetAddon("MailOpener");
local mod = MailOpener:NewModule("BeanCounterSupport", "AceEvent-3.0", "AceHook-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("MailOpener");

mod.moduleDescription = L["Prevents mail opening while BeanCounter is still scanning. Does nothing when BeanCounter is disabled."];
mod.moduleRequired = false;

local MailAddonName = "BeanCounter"; -- what to fill the global MailAddonBusy with
local refMonitoredFrame; -- reference to the frame we will be monitoring

function mod:OnInitialize()
	if select(6, C_AddOns.GetAddOnInfo("BeanCounter")) ~= nil then
		-- BeanCounter is DISABLED, so we don't need this module
		self:Debug("Disabling");
		self:SetEnabledState(false);
		
		if self:IsEnabled() then
			self:Disable();
		end
	end
end

function mod:OnEnable()
	self:Debug("OnEnable");
	
	self:RegisterEvent("MAIL_SHOW");
	
	-- If we were toggling this module on while the mailbox is opened we must register all events again
	if MailFrame:IsVisible() then
		self:MAIL_SHOW();
	end
end

-- Even though Ace can unregister our events it's neater to do it manually too
function mod:OnDisable()
	self:Debug("OnDisable");
	
	self:UnregisterEvent("MAIL_SHOW");
end

function mod:MAIL_SHOW()
	self:Debug("MAIL_SHOW");
	
	self:RegisterEvent("MAIL_CLOSED");
	
	refMonitoredFrame = InboxCloseButton;
	
	if not self:IsHooked(refMonitoredFrame, "OnHide") then
		-- Hook the OnHide of refMonitoredFrame indicating BeanCounter has started
		self:HookScript(refMonitoredFrame, "OnHide", "BeanCounterActivated");
	end
end

function mod:MAIL_CLOSED()
	self:Debug("MAIL_CLOSED");
	
	self:UnregisterEvent("MAIL_CLOSED");
	
	refMonitoredFrame = nil;
	
	-- We don't need any hooks anymore
	self:UnhookAll();
	
	-- Make sure we don't get stuck for the entire session (restart every mailbox close)
	if MailAddonBusy == MailAddonName then
		MailAddonBusy = nil;
	end
end

-- Called when the refMonitoredFrame is hidden
function mod:BeanCounterActivated()
	if refMonitoredFrame:GetParent():IsVisible() then
		-- Ensure this isn't called when the container is being hidden
		
		mod:Debug("BeanCounterActivated");
		
		-- Unhook the current hook (and reapply it after the OnShow was triggered)
		self:Unhook(refMonitoredFrame, "OnHide");
		
		if not self:IsHooked(refMonitoredFrame, "OnShow") then
			-- Hook the OnShow of refMonitoredFrame indicating BeanCounter is finished
			self:HookScript(refMonitoredFrame, "OnShow", "BeanCounterDeactivated");
		end
		
		MailAddonBusy = MailAddonName;
	end
end

-- Called when the refMonitoredFrame is shown
function mod:BeanCounterDeactivated()
	if refMonitoredFrame:GetParent():IsVisible() then
		-- Ensure this isn't called when the container is being shown
		
		mod:Debug("BeanCounterDeactivated");
		
		-- Unhook the current hook (and reapply it after the OnHide was triggered)
		self:Unhook(refMonitoredFrame, "OnShow");
		
		if not self:IsHooked(refMonitoredFrame, "OnHide") then
			-- Hook the OnHide of the refMonitoredFrame again which is trigged when BeanCounter starts
			self:HookScript(refMonitoredFrame, "OnHide", "BeanCounterActivated");
		end
		
		if MailAddonBusy == MailAddonName then
			MailAddonBusy = nil;
		end
	end
end

function mod:GetOptionsGroup()
	local configGroup = {
		order = 0,
		type = "modulesSubGroup",
		name = L["BeanCounter Support"],
		desc = L["Change settings for the BeanCounter Support module."],
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
							
							-- Behavior info
							descText = descText .. L["|cfffed000Please note this module will only be enabled when the addon \"BeanCounter\" is enabled. This module will be disabled when BeanCounter could not be found and enabled when it can unless you manually disabled this module.|r"] .. "\n\n";
							
							-- Final warning
							descText = descText .. L["|cffff0000You are strongly adviced to leave this module enabled unless you have very good reasons not to.|r"] .. "\n\n";
							
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
								
								MailOpener.db.profile.modules[self:GetName()] = nil;
							end
						end,
						confirm = function()
							if self:IsEnabled() then
								return L["Are you sure you want to disable this module?\n\nIt will only be active when needed and disabling it may cause your BeanCounter data to become incomplete. Leaving it on causes no harm."];
							else
								return false;
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
	return MailOpener:Debug("|cff993300BeanCounterSupport|r:" .. t);
end