local MailOpener = LibStub("AceAddon-3.0"):GetAddon("MailOpener");
local mod = MailOpener:NewModule("Collected", "AceEvent-3.0", "AceTimer-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("MailOpener");

mod.moduleDescription = L["Shows a simple summary of what has been collected at the mailbox."];
mod.moduleRequired = false;

-- Gold
local previousGold, earned, sessionEarned;
-- Items
local previousFreeSlotsAvailable, itemsGained, sessionItemsgained;
-- Mail
local previousMailCount, mailOpened, sessionMailOpened;
-- Time
local timeStarted, sessionTimeSpent; -- even though the first contains GetTime(), the second var will be filled with actual seconds

local updated;

function mod:OnInitialize()
	local defaults = {
		profile = {
			trackGold = true,
			trackItems = true,
			trackMail = true,
			trackTimeSpent = true,
			sessionSummary = false,
			batchSummary = false,
		},
	};
	
	-- Register our saved variables NameSpace
	self.db = MailOpener.db:RegisterNamespace("Collected", defaults);
end

function mod:OnEnable()
	self:Debug("OnEnable");
	
	self:RegisterEvent("MAIL_SHOW");
	
	MailOpener:TogglePostalModule("Rake", false);
	
	sessionEarned = 0;
	sessionItemsgained = 0;
	sessionMailOpened = 0;
	sessionTimeSpent = 0;
	
	-- If we were toggling this module on while the mailbox is opened we must register all events again
	if MailFrame:IsVisible() then
		self:MAIL_SHOW();
	end
end

-- Even though Ace can unregister our events it's neater to do it manually too
function mod:OnDisable()
	self:Debug("OnDisable");
	
	self:UnregisterEvent("MAIL_SHOW");
	
	self:Stop();
	
	MailOpener:TogglePostalModule("Rake", true);
end

function mod:MAIL_SHOW()
	self:Debug("MAIL_SHOW");
	
	-- Unbind / reset all previous events and settings
	self:Stop();
	
	self:RegisterEvent("MAIL_CLOSED");
	
	if self.db.profile.batchSummary then
		self:RegisterMessage("MO_OPEN_COMPLETE");
	end
	
	-- Money
	if self.db.profile.trackGold then
		self:RegisterEvent("PLAYER_MONEY");
	
		previousGold = GetMoney();
		earned = 0;
	end
	
	-- Items
	if self.db.profile.trackItems then
		self:RegisterEvent("BAG_UPDATE");
	
		previousFreeSlotsAvailable = self:GetNumFreeSlots();
		itemsGained = 0;
	end
	
	-- Mail
	if self.db.profile.trackMail then
		self:RegisterEvent("MAIL_INBOX_UPDATE");
		
		previousMailCount = nil;
		mailOpened = 0;
	end
	
	-- Time Spent
	if self.db.profile.trackTimeSpent then
		timeStarted = GetTime();
	end
end

function mod:MAIL_CLOSED()
	self:Debug("MAIL_CLOSED");
	
	self:Summarize(true);
	
	self:Stop();
end

function mod:PLAYER_MONEY()
	-- Sending mail does not interest us, so only remember what we earned
	local currentGold = GetMoney();
	
	if currentGold > previousGold then
		local goldEarned = ( currentGold - previousGold );
		
		earned = ( earned + goldEarned );
		
		updated = true;
		
		if self.db.profile.sessionSummary then
			sessionEarned = ( sessionEarned + goldEarned );
		end
	end
	
	previousGold = currentGold;
end

function mod:BAG_UPDATE()
	-- Sending mail does not interest us, so only remember what we earned
	local freeSlotAvailable = self:GetNumFreeSlots();
	
	if freeSlotAvailable < previousFreeSlotsAvailable then
		-- we lost a slot, so gained an item
		
		local gained = ( previousFreeSlotsAvailable - freeSlotAvailable );
		
		itemsGained = ( itemsGained + gained  );
		
		updated = true;
		
		if self.db.profile.sessionSummary then
			sessionItemsgained = ( sessionItemsgained + gained );
		end
	
			--We may need the lines below if we get inaccurate counts
			--	previousFreeSlotsAvailable = ( previousFreeSlotsAvailable - gained );
			--elseif freeSlotAvailable > previousFreeSlotsAvailable then
				-- an additional slot available, so we lost an item
				
			--	local lost = ( freeSlotAvailable - previousFreeSlotsAvailable );
			
			--	previousFreeSlotsAvailable = ( previousFreeSlotsAvailable + lost );
	end
	
	previousFreeSlotsAvailable = freeSlotAvailable;
end

function mod:MAIL_INBOX_UPDATE()
	local numItems, _ = GetInboxNumItems();
	
	if previousMailCount == nil then
		previousMailCount = numItems;
	else
		if numItems < previousMailCount then
			-- We lost a mail, which means we opened one without text
			
			--local opened = ( previousMailCount - numItems );
			
			mailOpened = ( mailOpened + 1 );
		
			updated = true;
		
			if self.db.profile.sessionSummary then
				sessionMailOpened = ( sessionMailOpened + 1 );
			end
		end
		
		previousMailCount = numItems;
	end
end

function mod:MO_OPEN_COMPLETE()
	-- Only summarize when changed
	if updated then
		self:Summarize(false);
		
		updated = false;
	end
end

function mod:Stop()
	self:UnregisterEvent("MAIL_CLOSED");
	
	-- Batch summary
	self:UnregisterMessage("MO_OPEN_COMPLETE");
	
	-- Clear any var in the memory remaining
	
	-- Money
	self:UnregisterEvent("PLAYER_MONEY");
	previousGold = nil;
	earned = nil;
	
	-- Items
	self:UnregisterEvent("BAG_UPDATE");
	previousFreeSlotsAvailable = nil;
	itemsGained = nil;
		
	-- Mail
	self:UnregisterEvent("MAIL_INBOX_UPDATE");
	previousMailCount = nil;
	mailOpened = nil;
	
	-- Time Spent
	timeStarted = nil;
end

function mod:Summarize(full)
	-- Message buffer, append details we have data for
	local printMessage = "";
	
	local timeSpent, tempSessionTimeSpent;
	if timeStarted then
		timeSpent = ceil( GetTime() - timeStarted );
		
		if self.db.profile.sessionSummary and self.db.profile.trackTimeSpent then
			tempSessionTimeSpent = ( sessionTimeSpent + timeSpent );
			
			if full then
				-- Only remember the timespent when the mailbox is closed
				sessionTimeSpent = tempSessionTimeSpent;
			end
		end
	end
	
	-- Did we record any mail being opened?
	if mailOpened and mailOpened > 0 then
		-- Time Spent
		if timeSpent and timeSpent > 0 then
			local timeSpentMinutes = floor( timeSpent / 60 );
			local timeSpentSeconds = ( timeSpent % 60 );
			if timeSpentMinutes ~= 0 then
				printMessage = printMessage .. format(L["Collected a total of %d mail within %d minutes and %d seconds."], mailOpened, timeSpentMinutes, timeSpentSeconds) .. " ";
			else
				printMessage = printMessage .. format(L["Collected a total of %d mail within %d seconds."], mailOpened, timeSpentSeconds) .. " ";
			end
		else
			printMessage = printMessage .. format(L["Collected a total of %d mail."], mailOpened) .. " ";
		end
	elseif timeSpent and timeSpent > 0 then
		local timeSpentMinutes = floor( timeSpent / 60 );
		local timeSpentSeconds = ( timeSpent % 60 );
		if timeSpentMinutes ~= 0 then
			printMessage = printMessage .. format(L["Spent %d minutes and %d seconds collecting mail."], timeSpentMinutes, timeSpentSeconds) .. " ";
		else
			printMessage = printMessage .. format(L["Spent %d seconds collecting mail."], timeSpentSeconds) .. " ";
		end
	end
	
	-- Did we record any items or gold being looted?
	if (itemsGained and itemsGained > 0) and (earned and earned > 0) then
		printMessage = printMessage .. format(L["You gained %d items and %s from this."], itemsGained, MailOpener:FormatMoney(earned));
	elseif itemsGained and itemsGained > 0 then
		printMessage = printMessage .. format(L["You gained %d items from this."], itemsGained);
	elseif earned and earned > 0 then
		printMessage = printMessage .. format(L["You gained %s from this."], MailOpener:FormatMoney(earned));
	end
	
	-- Did we record anything? print that!
	if printMessage ~= "" then
		MailOpener:Print(printMessage);
	end
	
	if self.db.profile.sessionSummary and ((sessionMailOpened and (not mailOpened or sessionMailOpened > mailOpened)) or (tempSessionTimeSpent and (not timeSpent or tempSessionTimeSpent > timeSpent)) or (sessionEarned and (not earned or sessionEarned > earned)) or (sessionItemsgained and (not itemsGained or sessionItemsgained > itemsGained))) then
		-- Message buffer, append details we have data for
		printMessage = L["(Session summary)"] .. " ";
	
		-- Did we record any mail being opened?
		if sessionMailOpened and sessionMailOpened > 0 then
			-- Time Spent
			if tempSessionTimeSpent and tempSessionTimeSpent > 0 then
				local timeSpentMinutes = floor( tempSessionTimeSpent / 60 );
				local timeSpentSeconds = ( tempSessionTimeSpent % 60 );
				if timeSpentMinutes ~= 0 then
					printMessage = printMessage .. format(L["Collected a total of %d mail within %d minutes and %d seconds this session."], sessionMailOpened, timeSpentMinutes, timeSpentSeconds) .. " ";
				else
					printMessage = printMessage .. format(L["Collected a total of %d mail within %d seconds this session."], sessionMailOpened, timeSpentSeconds) .. " ";
				end
			else
				printMessage = printMessage .. format(L["Collected a total of %d mail this session."], sessionMailOpened) .. " ";
			end
		elseif tempSessionTimeSpent then
			local timeSpentMinutes = floor( tempSessionTimeSpent / 60 );
			local timeSpentSeconds = ( tempSessionTimeSpent % 60 );
			if timeSpentMinutes ~= 0 then
				printMessage = printMessage .. format(L["Spent %d minutes and %d seconds collecting mail this session."], timeSpentMinutes, timeSpentSeconds) .. " ";
			else
				printMessage = printMessage .. format(L["Spent %d seconds collecting mail this session."], timeSpentSeconds) .. " ";
			end
		end
		
		-- Did we record any items or gold being looted?
		if (sessionItemsgained and sessionItemsgained > 0) and (sessionEarned and sessionEarned > 0) then
			printMessage = printMessage .. format(L["You gained %d items and %s from this."], sessionItemsgained, MailOpener:FormatMoney(sessionEarned));
		elseif sessionItemsgained and sessionItemsgained > 0 then
			printMessage = printMessage .. format(L["You gained %d items from this."], sessionItemsgained);
		elseif sessionEarned and sessionEarned > 0 then
			printMessage = printMessage .. format(L["You gained %s from this."], MailOpener:FormatMoney(sessionEarned));
		end
	
		-- Did we record anything? print that!
		if printMessage ~= "" then
			MailOpener:Print(printMessage);
		end
	end
end

function mod:GetNumFreeSlots()
	local slotsAvailable = 0;
	for bag = 0, 4 do
		slotsAvailable = ( slotsAvailable + ((C_Container and C_Container.GetContainerNumFreeSlots and C_Container.GetContainerNumFreeSlots(bag)) or (GetContainerNumFreeSlots and GetContainerNumFreeSlots(bag))) );
	end
	
	return slotsAvailable;
end

function mod:GetOptionsGroup()
	local configGroup = {
		order = 0,
		type = "modulesSubGroup",
		name = L["Collected"],
		desc = L["Change settings for the collected module."],
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
			TrackStats = {
				order = 20,
				type = "group",
				inline = true,
				name = L["Track Stats"],
				args = {
					description = {
						order = 10,
						type = "description",
						name = L["You can select what things to track. Toggling something off will stop tracking of it completely and reduce the resources used by Mail Opener (although you shouldn't notice a difference)."],
					},
					AHHeader = {
						order = 15,
						type = "header",
						name = "",
					},
					trackGold = {
						order = 20,
						type = "toggle",
						name = L["Track |cfffed000gold gained|r"],
						desc = L["Track the amount of gold gained and display it when closing the mailbox."],
						set = function(i, v)
							self.db.profile.trackGold = v;
							
							if MailFrame:IsVisible() then
								self:MAIL_SHOW();
							end
						end,
						get = function() return self.db.profile.trackGold; end,
					},
					trackItems = {
						order = 30,
						type = "toggle",
						name = L["Track |cfffed000items gained|r"],
						desc = L["Track the amount of items gained and display it when closing the mailbox."],
						set = function(i, v)
							self.db.profile.trackItems = v;
							
							if MailFrame:IsVisible() then
								self:MAIL_SHOW();
							end
						end,
						get = function() return self.db.profile.trackItems; end,
					},
					trackMail = {
						order = 40,
						type = "toggle",
						name = L["Track |cfffed000mail opened|r"],
						desc = L["Track the amount of mail received and display it when closing the mailbox."],
						set = function(i, v)
							self.db.profile.trackMail = v;
							
							if MailFrame:IsVisible() then
								self:MAIL_SHOW();
							end
						end,
						get = function() return self.db.profile.trackMail; end,
					},
					trackTimeSpent = {
						order = 50,
						type = "toggle",
						name = L["Track |cfffed000time spent|r"],
						desc = L["Track the amount of time spent at the mailbox."],
						set = function(i, v)
							self.db.profile.trackTimeSpent = v;
							
							if MailFrame:IsVisible() then
								self:MAIL_SHOW();
							end
						end,
						get = function() return self.db.profile.trackTimeSpent; end,
					},
				},
			},
			Summarize = {
				order = 30,
				type = "group",
				inline = true,
				name = L["Summarize"],
				args = {
					sessionSummary = {
						order = 20,
						type = "toggle",
						name = L["Also show a summary of the recorded stats within the entire session"],
						desc = L["Also show a summary of the recorded stats within the entire session (since your last login or /reload)."],
						set = function(i, v)
							self.db.profile.sessionSummary = v;
							
							if MailFrame:IsVisible() then
								self:MAIL_SHOW();
							end
						end,
						get = function() return self.db.profile.sessionSummary; end,
						width = "full",
					},
					batchSummary = {
						order = 30,
						type = "toggle",
						name = L["Show a summary of the recorded stats whenever it updated after opening the current batch has finished"],
						desc = L["Show a summary of the recorded stats whenever it has been updated after opening the current batch of mails has finished."],
						set = function(i, v)
							self.db.profile.batchSummary = v;
							
							if MailFrame:IsVisible() then
								self:MAIL_SHOW();
							end
						end,
						get = function() return self.db.profile.batchSummary; end,
						width = "full",
					},
				},
			},
		},
	};
	
	return configGroup;
end

function mod:Debug(t)
	return MailOpener:Debug("|cffff0000Collected|r:" .. t);
end