local MailOpener = LibStub("AceAddon-3.0"):GetAddon("MailOpener");
local mod = MailOpener:NewModule("FailSafe", "AceEvent-3.0", "AceTimer-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("MailOpener");

mod.moduleDescription = L["Prevents the mail opening from completely stopping when the opening of a single mail gets stuck."];
mod.moduleRequired = false;

function mod:OnInitialize()
	local defaults = {
		profile = {
			timeout = 20,
		},
	};
	
	-- Register our saved variables NameSpace
	self.db = MailOpener.db:RegisterNamespace("FailSafe", defaults);
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
	
	-- If we were toggling this module off while the mailbox is opened we must unregister all events
	if MailFrame:IsVisible() then
		self:MAIL_CLOSED();
	end
end

function mod:MAIL_SHOW()
	self:Debug("MAIL_SHOW");
	
	self:RegisterEvent("MAIL_CLOSED");
	
	self:RegisterMessage("MO_OPENING_MAIL");
	self:RegisterMessage("MO_MAIL_EMPTIED");
end

function mod:MAIL_CLOSED()
	self:Debug("MAIL_CLOSED");
	
	self:UnregisterEvent("MAIL_CLOSED");
	
	self:UnregisterMessage("MO_OPENING_MAIL");
	self:UnregisterMessage("MO_OPENING_MAIL_FINISHED");
	
	self:CancelTimer(self.tmrTimeout, true);
end

function mod:MO_OPENING_MAIL()
	-- Single mail being opened
	
	self:CancelTimer(self.tmrTimeout, true); -- insurance
	self.tmrTimeout = self:ScheduleTimer("Continue", self.db.profile.timeout);
end

function mod:MO_MAIL_EMPTIED()
	-- Single mail has been opened
	
	self:CancelTimer(self.tmrTimeout, true);
end

function mod:Continue()
	MailOpener:GetModule("OpenAll"):Continue();
	
	MailOpener:Print(L["(FailSafe) Mail opening timeout, continuing with the next mail."]);
end

function mod:GetOptionsGroup()
	local configGroup = {
		order = 0,
		type = "modulesSubGroup",
		name = L["FailSafe"],
		desc = L["Change settings for the FailSafe module."],
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
			SingleMailTimeout = {
				order = 20,
				type = "group",
				inline = true,
				name = L["Single Mail Opening Timeout"],
				args = {
					description = {
						order = 10,
						type = "description",
						name = L["Change how long FailSafe should wait before skipping the last mail and continuing with the next. This will prevent mail opening getting stuck forever because a single mail is frozen for whatever reason."],
					},
					timeout = {
						order = 20,
						type = "range",
						width = "double",
						min = 1,
						max = 60,
						step = 0.5,
						name = L["Single Mail Timeout"],
						desc = L["Change how long FailSafe should wait before skipping the last mail and continuing with the next. This should prevent mail opening getting stuck because a single mail is stuck for whatever reason.\n\nDefault value is 20 seconds."],
						get = function() return self.db.profile.timeout; end,
						set = function(i, v) self.db.profile.timeout = v; end,
					},
				},
			},
		},
	};
	
	return configGroup;
end

function mod:Debug(t)
	return MailOpener:Debug("|cffff0000FailSafe|r:" .. t);
end