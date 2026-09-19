-- You can access this addon's object through: LibStub("AceAddon-3.0"):GetAddon("MailOpener")
local MailOpener = LibStub("AceAddon-3.0"):NewAddon("MailOpener", "AceEvent-3.0", "AceTimer-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("MailOpener");

-- You can check if MailOpener is busy with the global MailAddonBusy (if not MailAddonBusy then ...do something... end)
-- MailAddonBusy will be nil when nothing is happening or filled with the addon name when MO is working
-- Another addon can use this variable to indicate they're working too, MailOpener will then wait for that to finish

local AutoOpenMail, MailOpenerConfig, lastAmount, lastQuickAuctionsStatus, freshList, mailboxEmptySoundPlayed, mailboxEmptySoundPlayedThisVisit, hasOpenedMailAlready, originalCheckInbox;

function MailOpener:OnInitialize()
	self:Debug("OnInitialize");
	
	-- Some clients ship no mailbox UI at all (e.g. World of Warcraft: Forever,
	-- whose Blizzard_MailFrame is currently enabled for the retail client only).
	-- We have nothing to hook into there, so stay loadable but fully dormant:
	-- disabling here skips our OnEnable and every module's OnEnable, and the
	-- addon becomes active again as soon as a mailbox exists on such a client.
	if not MailFrame then
		if MailOpenerIsForever then
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Mail Opener:|r " .. L["WoW Forever beta has no mailbox yet - Mail Opener is disabled until one is available."]);
		else
			DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Mail Opener:|r " .. L["No mailbox UI on this client - Mail Opener is disabled until one is available."]);
		end
		self:SetDisabled("NoMailUI");
		return;
	end
	
	
	
	-- SAVED VARIABLES
	
	local defaults = {
		global = {
			currentTip = -1, -- even though LUA table indexes start at one, Config's OnEnable will increase this value by one the first time you run it and another 1 to adjust for the % modifier, so we still actually start at the table index 1
		},
		profile = {
			uses = 0,
			general = {
				defaultStatus = "disabled", -- addon enabled, but mail opening not auto on
				defaultQAStatus = "__remember",
				continueOpeningStackableItems = false,
				showHelpTooltips = true,
				autoDisableQAAutoMail = true,
				autoReenableQAAutoMail = false,
				autoSetBackQAAutoMail = true,
				continueOpening = false,
				waitTime = 5,
				initialDelay = 0.5,
				overrideCheckInbox = true,
			},
			modules = {
				BeanCounterSupport = true,
				Config = false,
				Collected = true,
				FailSafe = true,
			},
			notifications = {
				welcome = false,
				bye = false,
				finishedCurrentBatch = true,
				mailboxIsEmpty = true,
				
				skipped = {
					all = true,
					inventoryFull = true,
					keepFreeSpaceLimit = true,
					GMMail = true,
					COD = true,
					normalGoldMail = true,
					normalItemsMail = true,
					AHexpired = true,
					AHsuccess = true,
					AHwon = true,
					AHcanceled = true,
					AHoutbid = true,
					other = true,
				},
				processed = {
					all = true,
					normalGoldMail = true,
					normalItemsMail = true,
					AHexpired = true,
					AHsuccess = true,
					AHwon = true,
					AHcanceled = true,
					AHoutbid = true,
					other = true,
				},
				
				bagsFullSound = false,
				bagsFullSoundFile = "Sound\\Spells\\SimonGame_Visual_BadPress.wav",
				bagsFullSoundFileName = "Simon Error",
				bagsFullSoundOnlyOnce = true,
				bagsFullSoundOnlyOncePerMailboxVisit = false,
				mailboxEmptySound = false,
				mailboxEmptySoundFile = "Sound\\Spells\\SimonGame_Visual_GameStart.wav",
				mailboxEmptySoundFileName = "Simon Start",
				mailboxEmptySoundOnlyOnce = true,
				mailboxEmptySoundOnlyOncePerMailboxVisit = false,
			},
		},
	};
	
	-- Register our saved variables database
	self.db = LibStub("AceDB-3.0"):New("MailOpenerDB", defaults, true);
	
	
	
	
	
	-- MODULE TOGGLING
	
	-- Don't enable the config module until we need it
	for name, module in self:IterateModules() do
		if self.db.profile.modules[name] ~= nil then
			if self.db.profile.modules[name] then
				self:Debug(("|cff00ff00Enabling|r module: "):format(name));
			else
				self:Debug(("|cffff0000Disabling|r module: "):format(name));
			end
			
			module:SetEnabledState(self.db.profile.modules[name]);
		end
	end
	
	
	
	
	
	-- SLASH COMMANDS
	
	-- Disable the AddonLoader slash commands
	SLASH_MO1 = nil;
	SLASH_MAILOPEN1 = nil;
	SLASH_MAILOPENER1 = nil;
	
	-- Register our own slash commands
	SLASH_MAILOPENER1 = "/mo";
	SLASH_MAILOPENER2 = "/mailopen";
	SLASH_MAILOPENER3 = "/mailopener";
	SlashCmdList["MAILOPENER"] = function(msg)
		MailOpener:EnableConfigModule();
		
		MailOpenerConfig:CommandHandler(msg);
	end
	
	
	
	
	
	-- INTERFACE OPTIONS
		
	 -- Attempt to remove the interface options added by AddonLoader (if enabled)
	if AddonLoader and AddonLoader.RemoveInterfaceOptions then
		AddonLoader:RemoveInterfaceOptions("Mail Opener");
	end
	
	-- Build and register our real options panel with Blizzard's AddOns list right away.
	-- If we wait until the user runs "/mo config" or clicks the in-mailbox config button,
	-- nothing ever calls AceConfigDialog:AddToBlizOptions("Mail Opener"), so the entry we
	-- just cleaned up above (the AddonLoader stub) is never replaced with a real one and
	-- "Mail Opener" disappears from the Addons tab entirely. Registering it here means the
	-- stub is gone (removed just above) and the real panel takes its place immediately,
	-- so a single click on it opens the options instead of inserting a second entry.
	-- We call Load() directly (not EnableConfigModule/:Enable()) so this doesn't touch the
	-- module's own enable flow or its one-time "welcome" popup, which should still only
	-- appear the first time the player actually opens the config UI themselves.
	self:GetModule("Config"):Load();
	
	-- ADDON / MAIL OPENING STATUS TOGGLER
	
	-- Make the open all checkbox
	local check = CreateFrame("CheckButton", "cbMailOpenerEnable", MailFrame, "UICheckButtonTemplate");
	check:SetHeight(26);
	check:SetWidth(26);
	check:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", 68, -13);
	check:SetChecked(true);
	check:SetHitRectInsets(0, -80, 0, 0);
	check:SetScript("OnClick", function(cbSelf)
		if IsShiftKeyDown() then
			-- Shift key = toggle addon on or off, since addon is already on there's only one option
			
			if not self:IsEnabled() then
				self:Print(L["Shift key was held down, so |cff00ff00enabling|r the entire addon as well as automatic opening of mail."]);
				
				self:Enable();
				
				-- The above calls MAIL_SHOW which changes AutoOpenMail, so we can't remember the old setting
				AutoOpenMail = true;
				
				cbSelf:SetChecked(true);
			else
				self:Print(L["Shift key was held down, so |cffff0000disabling|r the entire addon."]);
				
				self:Disable();
				
				cbSelf:SetChecked(false);
			end
		else
			-- Normal click
			
			if cbSelf:GetChecked() then
				self:Print(L["|cff00ff00Enabling|r automatic opening of mail."]);
				
				AutoOpenMail = true;
				self:ScheduleOpen(false);
			else
				self:Print(L["|cffff0000Disabling|r automatic opening of mail."]);
				
				AutoOpenMail = false;
			end
		end
	end);
	check.tooltipTitle = L["Mail Opener status"];
	check.tooltip = L["Toggle automatic mail opening |cff00ff00on|r or |cffff0000off|r (you can also enforce this by holding shift when opening the mailbox).\n\nYou can toggle this addon |cff00ff00on|r or |cffff0000off|r by |cfffed000shift-clicking|r this checkbox."];
	check:SetScript("OnEnter", function(cbSelf)
		if self.db.profile.general.showHelpTooltips then
			GameTooltip:SetOwner(cbSelf, "ANCHOR_BOTTOM")
			GameTooltip:SetPoint("BOTTOM", cbSelf, "BOTTOM")
			GameTooltip:SetText(cbSelf.tooltipTitle, 1, .82, 0, 1)
			
			if type(cbSelf.tooltip) == "string" then
				GameTooltip:AddLine(cbSelf.tooltip, 1, 1, 1, 1);
			end
			
			GameTooltip:Show();
		end
	end);
	check:SetScript("OnLeave", function(cbSelf)
		GameTooltip:Hide();
	end);
	
	-- Get reference to the text field
	local checkboxText = _G[check:GetName() .. "Text"];
	checkboxText:SetText(L["Mail Opener"]);
	
	self.cbOpenAll = check;
	
	
	
	
	-- CONFIG BUTTON
	
	-- Make the config button
	local button = CreateFrame("Button", "btnMailOpenerConfig", MailFrame, "UIPanelButtonTemplate")
	button:SetText(L["Config"])
	button:SetHeight(23)
	button:SetWidth(55)
        button:SetScale(0.8)
	button:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -100, 0);
	button:SetScript("OnClick", function()
		MailOpener:EnableConfigModule();
		
		MailOpenerConfig:Show();
	
		--BETA:if MailOpener.db.profile.uses >= 15 then
		--BETA:	MailOpener:ShowBetaPopup();
		--BETA:end
	end);
	button.tooltipTitle = L["Mail Opener Config"];
	button.tooltip = L["Click to open the configuration window for Mail Opener."];
	button:SetScript("OnEnter", function(btnSelf)
		if self.db.profile.general.showHelpTooltips then
			GameTooltip:SetOwner(btnSelf, "ANCHOR_BOTTOM")
			GameTooltip:SetPoint("BOTTOM", btnSelf, "TOP")
			GameTooltip:SetText(btnSelf.tooltipTitle, 1, .82, 0, 1)
			
			if type(btnSelf.tooltip) == "string" then
				GameTooltip:AddLine(btnSelf.tooltip, 1, 1, 1, 1);
			end
			
			GameTooltip:Show();
		end
	end);
	button:SetScript("OnLeave", function(btnSelf)
		GameTooltip:Hide();
	end);
	
	self.btnConfig = button;
	
	
	
	
	
	-- ADDON LOADING
	-- THE BELOW WILL TAKE SOME TIME; WE WILL BE LOADING OTHER ADDONS
	
	if select(6, C_AddOns.GetAddOnInfo("Postal")) == nil then
		self.PostalEnabled = true; -- Set this as an object variable so we can use it in our modules
		
		-- Ensure this addon is loaded if AddonLoader is installed
		if AddonLoader and AddonLoader.LoadAddOn and not IsAddOnLoaded("Postal") and not Postal then
			AddonLoader:LoadAddOn("Postal");
		end
	end
	
	if select(6, C_AddOns.GetAddOnInfo("ZeroAuctions")) == nil then
		self.ZeroAuctionsEnabled = true; -- Set this as an object variable so we can use it in our modules
		
		-- Ensure this addon is loaded if AddonLoader is installed
		if AddonLoader and AddonLoader.LoadAddOn and not IsAddOnLoaded("ZeroAuctions") then
			AddonLoader:LoadAddOn("ZeroAuctions");
		end
	end
	
	if select(6, C_AddOns.GetAddOnInfo("AuctionProfitMaster")) == nil then
		self.ZeroAuctionsEnabled = true; -- Set this as an object variable so we can use it in our modules
		
		-- Ensure this addon is loaded if AddonLoader is installed
		if AddonLoader and AddonLoader.LoadAddOn and not IsAddOnLoaded("AuctionProfitMaster") then
			AddonLoader:LoadAddOn("AuctionProfitMaster");
		end
	end
	
	if select(6, C_AddOns.GetAddOnInfo("TradeSkillMaster_Mailing")) == nil then
		self.TSMMailingEnabled = true; -- Set this as an object variable so we can use it in our modules
		
		-- Ensure this addon is loaded if AddonLoader is installed
		if AddonLoader and AddonLoader.LoadAddOn and not IsAddOnLoaded("TradeSkillMaster_Mailing") then
			AddonLoader:LoadAddOn("TradeSkillMaster_Mailing");
		end
	end
	
	
	
	
	
	-- ADJUST POSITIONS
	
	if self.ZeroAuctionsEnabled then
		-- QA is enabled so move the checkbox further to the right
		
		self.cbOpenAll:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", 155, -13);
	end
	
	if self.PostalEnabled then
		self.btnConfig:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -75, -13);
	end
end


-- Helper to open the addon's options in a way compatible with both old and new UIs
function MailOpener:OpenOptions()
    if MailOpenerConfig then
        MailOpenerConfig:Show()
    end
end

function MailOpener:OnEnable()
	self:RegisterEvent("MAIL_SHOW");
	self:RegisterEvent("PLAYER_ENTERING_WORLD");
	
	self.btnConfig:Show();
	
	-- Reset variables
	lastAmount = 0;
	self.debugChannel = nil;
	
	if not originalCheckInbox then
		-- Override the CheckInbox function
		-- Remember the original
		originalCheckInbox = CheckInbox;
		-- Then override that
		CheckInbox = NewCheckInbox;
	end
	
	-- If we were toggling this addon on while the mailbox is opened we must register all events again
	if MailFrame:IsVisible() then
		self:MAIL_SHOW();
	end
end

function MailOpener:OnDisable()
	self:UnregisterEvent("MAIL_SHOW");
	
	self.btnConfig:Hide();
	
	if originalCheckInbox then
		-- Change checkinbox back to the original value
		CheckInbox = originalCheckInbox;
		-- Forget the other reference
		originalCheckInbox = nil;
	end
	
	MailOpener:Stop();
end

-- We must disable Quick Auction's auto mail (if set up that way in the settings) before opening the mailbox or it will instantly start sending stuff
function MailOpener:PLAYER_ENTERING_WORLD()
	self:UnregisterEvent("PLAYER_ENTERING_WORLD");
	
	self:ToggleQAStatus();
end

-- Fired when the mailbox is opened
function MailOpener:MAIL_SHOW()
	-- To stop the timer when the mailbox is closed
	self:RegisterEvent("MAIL_CLOSED", "Stop");
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "Stop");
	
	-- To set the timer for when to refresh again
	self:RegisterEvent("MAIL_INBOX_UPDATE");
	
	-- We need to know when opening has completed
	self:RegisterMessage("MO_OPEN_COMPLETE");
	
	if self.db.profile.uses == 0 and MailOpener.db.profile.general.defaultStatus ~= "_enabled" then
		StaticPopupDialogs["MailOpenerFirstUseConfirmBox"] = {
			text = L["You are using |cff15ff00Mail Opener|r for the first time. Do you wish to always |cf00ff000enable|r |cfffed000automatic mail opening when you open the mailbox|r?\n\nYou can always change the standard behavior in the General options."],
			button1 = L["Yes"],
			button2 = L["No"],
			OnAccept = function()
				MailOpener.db.profile.general.defaultStatus = "_enabled";
				MailOpener:Print(L["You can always change the default status in the General config (|cff00ffff/mo c|r)."]);
				
				MailOpener:Print(L["|cff00ff00Enabling|r automatic opening of mail."]);
				MailOpener.cbOpenAll:SetChecked(true);
				
				AutoOpenMail = true;
				MailOpener:ScheduleOpen(false);
			end,
			OnCancel = function ()
				MailOpener:Print(L["You can always change the default status in the General config (|cff00ffff/mo c|r)."]);
			end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
		};
		StaticPopup_Show("MailOpenerFirstUseConfirmBox");
	end
	
	self.db.profile.uses = ( self.db.profile.uses + 1 );
	
	self:Debug("defaultStatus:" .. self.db.profile.general.defaultStatus);
	-- Change the mail opening status according to our settings
	if self.db.profile.general.defaultStatus == "_enabled" then
		AutoOpenMail = true;
		self.cbOpenAll:SetChecked(true);
	elseif self.db.profile.general.defaultStatus == "disabled" then
		-- Disable auto opening but leave mail opener enabled
		
		AutoOpenMail = false;
		self.cbOpenAll:SetChecked(false);
	elseif self.db.profile.general.defaultStatus == "xdisabled" then
		-- Disable entire addon
		
		MailOpener:Disable();
		self.cbOpenAll:SetChecked(false);
	end
	
	if IsShiftKeyDown() then
		self:Print(L["|cffff0000Disabling|r automatic opening of mail, shift key was down when opening the mailbox."]);
		
		AutoOpenMail = false;
		self.cbOpenAll:SetChecked(false);
	end
	
	self:ToggleQAStatus();
	
	-- Hide the InboxTooMuchMail warning to allow room for our mail remaining info line
	InboxTooMuchMail:Hide()
	InboxTooMuchMail.Show = function() end
	
	if self.ZeroAuctionsEnabled then
		local AHAddon = LibStub("AceAddon-3.0"):GetAddon("ZeroAuctions", true) or LibStub("AceAddon-3.0"):GetAddon("AuctionProfitMaster", true);
		if AHAddon then
			local QAMail = AHAddon:GetModule("Mail", true);
			
			if QAMail then
				if QAMail.massOpening then
					-- Hide the open all button
					QAMail.massOpening:Hide();
				end
				if QAMail.totalMail then
					-- Hide the x mail remaining text
					QAMail.totalMail:Hide();
				end
			end
		end
	end
	
	-- Reset the mail amount baseline for this visit. It must not carry over from the
	-- previous one: when the mailbox is closed before the mail was opened (or in the
	-- middle of opening) and reopened, the next sync would then see exactly the same
	-- amount of mail as before the close, no "new mail arrived" condition would
	-- trigger, and automatic opening would stay dead until a /reload. It also keeps
	-- the CheckInbox override from blocking every sync of a fresh visit, since its
	-- strict path only kicks in when lastAmount > 0 and mail hasn't been opened yet
	lastAmount = 0;
	
	hasOpenedMailAlready = nil;
	mailboxEmptySoundPlayed = nil;
	mailboxEmptySoundPlayedThisVisit = nil;
	
	self:Recheck();
	
	if self.db.profile.general.continueOpening then
		-- Continue opening mail, but use the "initial mail opening interval" as time
		self:ScheduleOpen(false);
	end
end

-- Fired after a successful server sync
-- Fired when mail is deleted (which happens after taking all attachments from a mail sent by the game)
function MailOpener:MAIL_INBOX_UPDATE()
	local current, total = GetInboxNumItems();
	
	-- Calculate the amount of mail waiting that actually have attachments
	-- If we just compare numbers we won't be including mail that isn't automatically deleted when opened, such as mail with attachments sent by other players
	local currentMailWithAttachments = 0;
	for i = 1, current do
		local _, _, _, _, money, _, _, items = GetInboxHeaderInfo(i);
		
		if (items and items > 0) or (money and money > 0) then
			currentMailWithAttachments = currentMailWithAttachments + 1;
		end
	end
	
	local tempLastAmount = lastAmount;
	lastAmount = currentMailWithAttachments;
	
	--if currentMailWithAttachments ~= tempLastAmount then
	--	self:Debug("MAIL_INBOX_UPDATE - lastAmount:" .. tempLastAmount .. " - current:" .. currentMailWithAttachments);
	--end
	
	if currentMailWithAttachments > tempLastAmount then
		-- New messages arrived in our mailbox, so this was a refresh, so set a timer
		
		self:Debug("MO_SERVER_SYNCED");
		
		-- Yell that we successfully synced with the server
		self:SendMessage("MO_SERVER_SYNCED");
		
		if MailAddonBusy == MailOpener:GetName() then
			MailAddonBusy = nil;
		end
		
		-- This list is fresh
		freshList = true;
		mailboxEmptySoundPlayed = nil;
		
		-- Stop previous timer
		self:CancelTimer(self.tmrRecheck, true);
		-- More will arrive in 60 seconds
		self.tmrRecheck = self:ScheduleTimer(function()
			self:Debug("tmrRecheck 61 finished");
			
			-- We can get a fresh list now, so query the server
			freshList = false;
			
			-- Look for mail
			self:Recheck();
		end, 61);
		self:Debug("tmrRecheck 61");
		
		-- Open the current mail
		self:ScheduleOpen(false);
	elseif currentMailWithAttachments < tempLastAmount then
		-- We lost a mail
		
		--TODO: NYI: May need to delay this until the mail is actually deleted to keep the mail count more realtime
		
		self:Debug("MO_MAIL_EMPTIED");
		
		-- Yell that we successfully opened/removed a mail
		self:SendMessage("MO_MAIL_EMPTIED");
	elseif (currentMailWithAttachments == 50 and tempLastAmount == 50) then
		-- Open the current mail
		self:ScheduleOpen(false);
	end
end

function MailOpener:ScheduleOpen(continued)
	if lastAmount > 0 then
		local waitTime;
		if continued then
			waitTime = self.db.profile.general.waitTime;
		else
			-- Even though this is not a continuation and should be instant, we set a .5 second timer to prevent multiple calls of the OpenNow function
			waitTime = self.db.profile.general.initialDelay;
		end
		
		-- Stop previous timer
		self:CancelTimer(self.tmrOpenNow, true);
		-- Schedule the next open
		self.tmrOpenNow = self:ScheduleTimer("OpenNow", waitTime);
	end
end

function MailOpener:OpenNow()
	self:Debug("OpenNow (" .. ((MailAddonBusy and "1") or "0") .. ")");
	if MailFrame:IsVisible() and AutoOpenMail then
		self:Debug("OpenNow");
			
		-- BeanCounter is the only addon hiding the mail close button while busy, so we can look for that
		--local BeanCounterActive = not InboxCloseButton:IsVisible();
		
		--if not BeanCounterActive and not MailAddonBusy then
		if not MailAddonBusy then
			-- No other addon is currently active
			
			self:CancelTimer(self.tmrTryAgain, true); -- Insurance
			
			if self.ZeroAuctionsEnabled and ZeroAuctionsAutoMail then
				-- Remember the last known quick auctions status
				lastQuickAuctionsStatus = ZeroAuctionsAutoMail:GetChecked();
			end
			if self.db.profile.general.autoDisableQAAutoMail and self.ZeroAuctionsEnabled and ZeroAuctionsAutoMail and ZeroAuctionsAutoMail:GetChecked() then
				-- If auto disable "QA Auto mail" is enabled and QA's auto mail is currently toggled on, turn it off
				-- We need to do this with a :click to trigger the right events
				
				self:Debug("Turning automail |cffff0000off|r.");
				
				ZeroAuctionsAutoMail:Click();
			end
			
			
			MailAddonBusy = self:GetName();
			
			self:Debug("MO_OPEN_MAIL");
			
			-- Summon the mail opening gods
			self:SendMessage("MO_OPEN_MAIL");
		elseif MailAddonBusy ~= self:GetName() then
			-- Another addon is ACTIVE
			self:Debug("Another addon active, waiting .5 seconds... (" .. MailAddonBusy .. ")");
			
			self:CancelTimer(self.tmrTryAgain, true); -- Insurance
			-- Try again every 0.5 seconds
			self.tmrTryAgain = self:ScheduleTimer("OpenNow", 0.5);
		end
	end
end

function MailOpener:MO_OPEN_COMPLETE()
	if MailAddonBusy == self:GetName() then
		MailAddonBusy = nil;
	end
	
	hasOpenedMailAlready = true;
	
	-- Try a recheck
	self:Recheck();
	
	local current, total = GetInboxNumItems();
	
	if (total - current) == 0 then
		-- There is probably no unopenable mail remaining, so play the sound (if enabled)
		
		if self.db.profile.notifications.mailboxEmptySound and (not MailOpener.db.profile.notifications.mailboxEmptySoundOnlyOnce or not mailboxEmptySoundPlayed) and (not MailOpener.db.profile.notifications.mailboxEmptySoundOnlyOncePerMailboxVisit or not mailboxEmptySoundPlayedThisVisit) then
			PlaySoundFile(self.db.profile.notifications.mailboxEmptySoundFile);
			mailboxEmptySoundPlayed = true;
			mailboxEmptySoundPlayedThisVisit = true;
		end
	end
	
	if self.ZeroAuctionsEnabled then
		-- Zero Auctions enabled?
		-- Toggle automailing as per settings
		
		if self.db.profile.general.autoReenableQAAutoMail and ZeroAuctionsAutoMail and not ZeroAuctionsAutoMail:GetChecked() then
			-- If auto re-enable "QA Auto mail" is enabled and QA's auto mail is currently toggled OFF, turn it on
			-- We need to do this with a :click to trigger the right events
			
			self:Debug("Turning automail |cff00ff00on|r.");
			
			ZeroAuctionsAutoMail:Click();
		elseif self.db.profile.general.autoSetBackQAAutoMail and ZeroAuctionsAutoMail and lastQuickAuctionsStatus ~= ZeroAuctionsAutoMail:GetChecked() then
			-- If auto set back "QA Auto mail" is enabled and QA's auto mail is currently not the same as it was before starting, toggle it
			-- We need to do this with a :click to trigger the right events
			
			if lastQuickAuctionsStatus then
				self:Debug("Turning automail |cff00ff00on|r.");
			else
				self:Debug("Turning automail |cffff0000off|r.");
			end
				
			ZeroAuctionsAutoMail:Click();
		end
	end
	
	if self.db.profile.general.continueOpening then
		self:ScheduleOpen(true);
	end
end

-- Run another CheckInbox
function MailOpener:Recheck()
	self:Debug("|cffffff00Recheck|r");
	
	-- Freshlist prevents this from being run too often
	-- It is set to true after a server sync
	-- and set to false 61 seconds afterwards with a recheck called instantly after it
	
	-- We're not refreshing while we're opening because it is automatically done when current batch was completely opened
	if not freshList and MailFrame:IsVisible() then
		self:Debug("|cff00ff00Recheck|r");
		
		-- If this isn't a fresh list (so messages weren't received within the last 60 seconds) and the mailbox wasn't closed
	
		-- BeanCounter is the only addon hiding the mail close button while busy, so we can look for that
		--local BeanCounterActive = not InboxCloseButton:IsVisible();
		
		--if not BeanCounterActive and AutoOpenMail and not MailAddonBusy then
		--if AutoOpenMail and not MailAddonBusy then
		if not MailAddonBusy then
			-- Query the server
			CheckInbox();
		end
		
		-- Stop previous timer
		self:CancelTimer(self.tmrRecheck, true);
		-- Keep trying until it works
		self.tmrRecheck = self:ScheduleTimer("Recheck", 2);
		
		self:Debug("tmrRecheck 2");
	end
end

-- Stop checking for new mail and unregister the events we needed
function MailOpener:Stop()
	if MailAddonBusy == self:GetName() then
		MailAddonBusy = nil;
	end
	
	hasOpenedMailAlready = nil;
	
	-- We won't need this anymore
	self:UnregisterEvent("MAIL_CLOSED");
	self:UnregisterEvent("PLAYER_LEAVING_WORLD");
	self:UnregisterEvent("MAIL_INBOX_UPDATE");
	
	-- Messages
	self:UnregisterMessage("MO_OPEN_COMPLETE");
	
	-- Timers
	self:CancelTimer(self.tmrTryAgain, true);
	self:CancelTimer(self.tmrOpenNow, true);
	
	-- If we wait with disabling QA automail until MAIL_SHOW, QA will beat us to it and already start sending stuff
	self:ToggleQAStatus();
end

function MailOpener:Debug(t)
	if not self.debugChannel and self.debugChannel ~= false then
		-- We want to check just once, so if you add a debug channel later just do a /reload (registering an event for this is wasted resources)
		self.debugChannel = false;
		
		for i = 1, NUM_CHAT_WINDOWS do
			local name = GetChatWindowInfo(i);
			
			if name:upper() == "DEBUG" then
				self.debugChannel = _G["ChatFrame" .. i];
			end
		end
	end
	
	if self.debugChannel then
		self.debugChannel:AddMessage(t);
	end
end

function MailOpener:Print(text)
	print(L["|cff15ff00Mail Opener|r: %s"]:format(text));
end

-- Enable our config module if it's disabled and make a reference to it
function MailOpener:EnableConfigModule()
	if not MailOpenerConfig then
		MailOpenerConfig = self:GetModule("Config");
		MailOpenerConfig:Enable();
	end
end

-- Toggle Postal's opening modules on or off
function MailOpener:TogglePostalModule(name, status)
	if self.PostalEnabled and Postal then
		-- Postal must be enabled
		
		-- Toggle module (let Postal handle this)
		Postal.ToggleModule(nil, name, Postal:GetModule(name), status);
	end
	
	if self.TSMMailingEnabled then
		local TSMMailing = LibStub("AceAddon-3.0"):GetAddon("TradeSkillMaster_Mailing");
		if TSMMailing and TSMMailing.massOpening then
			if not status then
				TSMMailing.massOpening:Hide();
			else
				TSMMailing.massOpening:Show();
			end
		end
	end
end

-- Change Quick Auction's auto mail status based on our prefered settings
function MailOpener:ToggleQAStatus()
	self:Debug("defaultQAStatus:" .. self.db.profile.general.defaultQAStatus);
	
	if self.ZeroAuctionsEnabled and self.db.profile.general.defaultQAStatus ~= "__remember" and ZeroAuctionsAutoMail then
		if self.db.profile.general.defaultQAStatus == "_enabled" and not ZeroAuctionsAutoMail:GetChecked() then
			self:Debug("Turning automail |cff00ff00on|r.");
			
			ZeroAuctionsAutoMail:Click();
		elseif self.db.profile.general.defaultQAStatus == "disabled" and ZeroAuctionsAutoMail:GetChecked() then
			self:Debug("Turning automail |cffff0000off|r.");
			
			ZeroAuctionsAutoMail:Click();
		end
	end
end

function MailOpener:FormatMoney(copper)
	local gold = floor( copper / 10000 );
	local silver = floor( ( copper - ( gold * 10000 ) ) / 100 );
	local copper = mod(copper, 100);
	
	if gold > 0 then
		return format(GOLD_AMOUNT_TEXTURE .. " " .. SILVER_AMOUNT_TEXTURE .. " " .. COPPER_AMOUNT_TEXTURE, gold, 0, 0, silver, 0, 0, copper, 0, 0);
	elseif silver > 0 then
		return format(SILVER_AMOUNT_TEXTURE .. " " .. COPPER_AMOUNT_TEXTURE, silver, 0, 0, copper, 0, 0);
	else
		return format(COPPER_AMOUNT_TEXTURE, copper, 0, 0);
	end
end

-- General copy window for multiple things (clickable URLs, the time remaining, and such) - Fixed for TBC Anniversary empty popup bug
StaticPopupDialogs["MailOpenerCopyWindow"] = {
	text = L["Press CTRL-C to copy."],
	button2 = CLOSE,
	hasEditBox = 1,
	editBoxWidth = 360,
	OnShow = function(self)
		local editBox = self.editBox or (self.GetEditBox and self:GetEditBox()) or _G[self:GetName().."EditBox"]
		if editBox and MailOpener.currentPopupContents and MailOpener.currentPopupContents:find("%S") then
			editBox:SetText(MailOpener.currentPopupContents);
			editBox:SetFocus();
			editBox:HighlightText(0);
		end
		
		-- Position the close button in the middle
		if self.button2 then
			-- Remove previous know position
			self.button2:ClearAllPoints();
			self.button2:SetWidth(200);
			-- Reposition in the center
			local anchor = editBox or self.editBox
			if anchor then
				self.button2:SetPoint("CENTER", anchor, "CENTER", 0, -30);
			end
		end
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide();
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	maxLetters = 1024,
};


-- The idea for this is to wait with refresing while there is still mail remaining which can be opened
-- This should speed things up a tiny bit, but might become buggy if coded wrong
-- We actually override the function in the onenable
function NewCheckInbox(...)
	if not MailOpener.db.profile.general.overrideCheckInbox or not MailOpener.db.profile.general.continueOpening or not AutoOpenMail or not lastAmount or lastAmount == 0 then
		-- If the override Check Inbox option is off
		-- or continuous opening is off
		-- or there's currently no mail visible
		
		MailOpener:Debug("CheckInbox:" .. tostring((not MailOpener.db.profile.general.overrideCheckInbox)) .. "/" .. tostring((not MailOpener.db.profile.general.continueOpening)) .. "/" .. tostring(lastAmount == 0));
		
		-- Just call the original function
		return originalCheckInbox(...);
	end
	
	if not hasOpenedMailAlready then
		-- If MO hasn't opened mail yet, we wait.
		-- MO will call this function when mail opening is done
		
		MailOpener:Debug("CheckInbox:Waiting...");
		
		return false;
	else
		MailOpener:Debug("CheckInbox:Refresh!");
		
		return originalCheckInbox(...);
	end
end

-- Hide Blizzard's "Open All" button if it exists
local function MailOpener_HideBlizzOpenAll()
    if OpenAllMail and OpenAllMail:IsShown() then
        OpenAllMail:Hide()
        if OpenAllMail.UnregisterAllEvents then
            OpenAllMail:UnregisterAllEvents() -- prevent it from re-showing
        end
    end
end

-- Hook mailbox UI load
if MailFrame_OnEvent then
    hooksecurefunc("MailFrame_OnEvent", function()
        MailOpener_HideBlizzOpenAll()
    end)
end

-- Also hide immediately
MailOpener_HideBlizzOpenAll()
