local MailOpener = LibStub("AceAddon-3.0"):GetAddon("MailOpener");
local mod = MailOpener:NewModule("OpenAll", "AceEvent-3.0", "AceTimer-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("MailOpener");

mod.moduleDescription = L["The actual mail opening initiated by the core."];
mod.moduleRequired = true;

--[[
Dev notes:
When shift clicking the Open All button it should override all filters.
]]

local MAIL_ITEM_INDEX, MAIL_OPEN_EVERYTHING, mailTimer, inventoryFull, inventoryFullSoundPlayed, inventoryFullSoundPlayedThisVisit, opening, lastSync, numCurrentMail, numHiddenMail, continue, firstOpenThisSync, takingSingleItem;

function mod:OnInitialize()
	local defaults = {
		profile = {
			speed = 0.05,
			keepFreeSpace = 0,
			filter = {
				AH = {
					canceled = true,
					expired = true,
					outbid = true,
					success = true,
					won = true,
				},
				normalAttachments = false,
				normalMoney = true,
				allowShiftClick = true,
			},
		},
	};
	
	-- Register our saved variables NameSpace
	self.db = MailOpener.db:RegisterNamespace("OpenAll", defaults);
end

function mod:OnEnable()
	self:RegisterEvent("MAIL_SHOW");
	
	if not self.btnOpenAll then
		-- Open all button
		local button = CreateFrame("Button", "btnMailOpenerOpenAll", InboxFrame, "UIPanelButtonTemplate");
		button:SetText(L["Open all"]);
		button:SetHeight(26);
		button:SetWidth(120);
		button:SetPoint("BOTTOM", InboxFrame, "CENTER", -10, -165);
		button:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp");
		button:SetScript("OnClick", function(self, mouseButton)
			local action = "open";
			if mouseButton == "RightButton" then
				action = "menu";
			elseif mouseButton == "MiddleButton" or (mouseButton == "LeftButton" and IsAltKeyDown()) then
				action = "stop";
			end
			
			if action == "menu" then
				-- Hide the gametooltip
				GameTooltip:Hide();
				
				if not mod.ddmFilters then
					-- Build the drop down menu
					local info = {};
					
					local dropDownMenu = CreateFrame("Frame", "MailOpenerFiltersDropDownMenu");
					dropDownMenu.displayMode = "MENU";
					dropDownMenu.initialize = function(s, level)
					    if not level then return; end
					    
					    if level == 1 then
							-- Create the title of the menu
							info.isTitle = true;
							info.text = L["Toggle filters for %s profile."]:format(MailOpener.db:GetCurrentProfile());
							info.notCheckable = true;
							UIDropDownMenu_AddButton(info, level);
							
							-- Reset title specific values
							info.isTitle = nil;
							info.disabled = nil;
							info.notCheckable = nil;
							
							-- We don't want to close the DDM when something is toggled
							info.keepShownOnClick = true;
							
							-- Make Auction canceled option
							info.text = L["Auction canceled"];
							info.func = function(this) mod.db.profile.filter.AH.canceled = this.checked; end;
							info.checked = mod.db.profile.filter.AH.canceled;
							UIDropDownMenu_AddButton(info, level);
							
							-- Make Auction expired option
							info.text = L["Auction expired"];
							info.func = function(this) mod.db.profile.filter.AH.expired = this.checked; end;
							info.checked = mod.db.profile.filter.AH.expired;
							UIDropDownMenu_AddButton(info, level);
							
							-- Make Auction outbid option
							info.text = L["Auction outbid"];
							info.func = function(this) mod.db.profile.filter.AH.outbid = this.checked; end;
							info.checked = mod.db.profile.filter.AH.outbid;
							UIDropDownMenu_AddButton(info, level);
							
							-- Make Auction successful option
							info.text = L["Auction successful"];
							info.func = function(this) mod.db.profile.filter.AH.success = this.checked; end;
							info.checked = mod.db.profile.filter.AH.success;
							UIDropDownMenu_AddButton(info, level);
							
							-- Make Auction won option
							info.text = L["Auction won"];
							info.func = function(this) mod.db.profile.filter.AH.won = this.checked; end;
							info.checked = mod.db.profile.filter.AH.won;
							UIDropDownMenu_AddButton(info, level);
							
							-- Make Other mail with attachments
							info.text = L["Other mail with attachments"];
							info.func = function(this) mod.db.profile.filter.normalAttachments = this.checked; end;
							info.checked = mod.db.profile.filter.normalAttachments;
							UIDropDownMenu_AddButton(info, level);
							
							-- Make Other mail with gold
							info.text = L["Other mail with gold"];
							info.func = function(this) mod.db.profile.filter.normalMoney = this.checked; end;
							info.checked = mod.db.profile.filter.normalMoney;
							UIDropDownMenu_AddButton(info, level);
							
							-- Close link
							info.text = CLOSE;
							info.func = function() CloseDropDownMenus(); end;
							info.checked = nil;
							info.notCheckable = true;
							UIDropDownMenu_AddButton(info, level);
							
							wipe(info);
					    end
					end
					
					mod.ddmFilters = dropDownMenu;
				end
				
				ToggleDropDownMenu(1, nil, mod.ddmFilters, self:GetName(), 0, 0);
			elseif action == "stop" then
				MailOpener:Print(L["Interrupting mail opening as the alt key was held down while clicking the open all button or the middle mouse-button was used on it."]);
				
				mod:StopOpening(true);
			else
				mod:Open(true, IsShiftKeyDown());
			end
		end);
		button.tooltipTitle = L["Open all"];
		button.tooltip = L["Hold |cfffed000shift|r while clicking this button to temporarily override your filters and loot every single mail containing attachments and/or gold.\n\n|cfffed000Right|r click this button to quickly adjust mail opening filters for this profile.\n\n|cfffed000Middle|r click or hold |cfffed000alt|r while clicking this button to interrupt mail opening."];
		button:SetScript("OnEnter", function(self)
			if MailOpener.db.profile.general.showHelpTooltips then
				GameTooltip:SetOwner(self, "ANCHOR_NONE")
				GameTooltip:SetPoint("BOTTOM", self, "TOP")
				GameTooltip:SetText(self.tooltipTitle, 1, .82, 0, 1)
				
				if type(self.tooltip) == "string" then
					GameTooltip:AddLine(self.tooltip, 1, 1, 1, 1);
				end
				
				GameTooltip:Show();
			end
		end);
		button:SetScript("OnLeave", function(self)
			GameTooltip:Hide();
		end);
		
		self.btnOpenAll = button;
	end
	
	self.btnOpenAll:Show();
	
	if not self.timeLeftFrame then
		-- If the timeLeftFrame doesn't exist we will have to build it
		
		self:Debug("Building text frame");
		
		local frame = CreateFrame("Button", "MailOpenerTimeLeftButton", InboxFrame);
		
		-- Mail counter
		frame.text = frame:CreateFontString("MailOpenerTimeLeftFrameMailCount", "OVERLAY", "GameFontHighlight");
		frame.text:SetPoint("CENTER", MailFrame, "TOPLEFT", 40, -35);
		
		-- Long time left indicator
		frame.smallText = frame:CreateFontString("MailOpenerTimeLeftFrameTimeRemaining", "OVERLAY", "GameFontNormal");
		frame.smallText:SetFont(GameFontHighlight:GetFont(), 11, "OUTLINE");
		frame.smallText:SetPoint("TOPLEFT", MailFrame, "TOPLEFT", 75, -38);
		-- No fixed width: the label is sized from the mailbox frame's width (see
		-- GetTimeLeftTextWidth) so it always wraps within the frame and leaves 1/5 of
		-- the frame empty on the right, no matter how wide the mailbox frame is
		frame.smallText:SetWidth(self:GetTimeLeftTextWidth());
		frame.smallText:SetJustifyH("LEFT");
		frame.smallText:SetJustifyV("MIDDLE");
		
		-- SMALLER CLICKABLE AREA: the label starts 75px from the left edge and wraps at
		-- 4/5 of the mailbox frame's width, but a click layer that wide swallows clicks
		-- meant for the MailFrame underneath.
		-- Halve the previous 120px hit box to 60px and centre it on the label instead of
		-- anchoring it at the left edge, so only clicks around the middle of the text copy it.
		frame:SetPoint("CENTER", MailFrame, "TOPLEFT", 75 + 60, -38 - 7);
		frame:SetWidth(60);
		frame:SetHeight(14);
		frame:RegisterForClicks("LeftButtonUp", "RightButtonUp");
		frame:SetScript("OnClick", function(self)
			local timeRemainingUntillOpened = frame.smallText:GetText();
			if timeRemainingUntillOpened and timeRemainingUntillOpened ~= "" and timeRemainingUntillOpened:find("%S") then
				-- Strip color codes for clean copy in TBC Anniversary
				local clean = timeRemainingUntillOpened:gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
				MailOpener.currentPopupContents = clean;
				
				StaticPopup_Show("MailOpenerCopyWindow");
			end
		end);
		-- Tooltip to hint it's clickable but small
		frame:SetScript("OnEnter", function(self)
			if MailOpener.db.profile.general.showHelpTooltips and self.smallText:GetText() and self.smallText:GetText() ~= "" then
				GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
				GameTooltip:SetText("Click to copy", 1, .82, 0, 1)
				GameTooltip:AddLine(self.smallText:GetText(), 1,1,1,1)
				GameTooltip:Show()
			end
		end)
		frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
		
		self.timeLeftFrame = frame;
	end
	
	self.timeLeftFrame:Show();
	
	if not self.btnReload then
		-- Manual refresh button, built into the free 1/5 of the frame width that the
		-- time left label no longer uses. It is only shown while mail is still waiting
		-- for the next server refresh (one batch picked up, more still in the queue)
		local reloadButton = CreateFrame("Button", "btnMailOpenerReload", MailFrame, "UIPanelButtonTemplate");
		reloadButton:SetText(L["Reload"]);
		reloadButton:SetHeight(23);
		reloadButton:SetWidth(60);
		reloadButton:SetScale(0.8);
		reloadButton:SetPoint("TOPRIGHT", MailFrame, "TOPRIGHT", -10, -36);
		reloadButton:SetScript("OnClick", function()
			-- Fetch the waiting mail from the server right away instead of waiting for the automatic refresh
			CheckInbox();
		end);
		reloadButton.tooltipTitle = L["Reload mail"];
		reloadButton.tooltip = L["Click to fetch the mail that is still waiting on the server right away instead of waiting for the next automatic refresh."];
		reloadButton:SetScript("OnEnter", function(btnSelf)
			if MailOpener.db.profile.general.showHelpTooltips then
				GameTooltip:SetOwner(btnSelf, "ANCHOR_BOTTOM")
				GameTooltip:SetPoint("BOTTOM", btnSelf, "TOP")
				GameTooltip:SetText(btnSelf.tooltipTitle, 1, .82, 0, 1)
				
				if type(btnSelf.tooltip) == "string" then
					GameTooltip:AddLine(btnSelf.tooltip, 1, 1, 1, 1);
				end
				
				GameTooltip:Show();
			end
		end);
		reloadButton:SetScript("OnLeave", function()
			GameTooltip:Hide();
		end);
		
		self.btnReload = reloadButton;
	end
	
	self.btnReload:Hide();
	
	-- Go through all children of the mail frame to find QA's element and hide it
	-- There's no other way to do this because QuickAuctions has a local referrence to it (not as a property of the object like most other frames)
	local kids = { MailFrame:GetChildren() };
	
	for _, child in ipairs(kids) do
		if child and child.text then
			child.text:Hide();
		end
	end
	
	-- If we were toggling this module on while the mailbox is opened we must register all events again
	if MailFrame:IsVisible() then
		self:MAIL_SHOW();
	end
end

function mod:OnDisable()
	self:UnregisterEvent("MAIL_SHOW");
	
	if self.btnOpenAll then
		self.btnOpenAll:Hide();
	end
	
	if self.timeLeftFrame then
		self.timeLeftFrame:Hide();
	end
	
	if self.btnReload then
		self.btnReload:Hide();
	end

	if MailOpener.PostalEnabled then
		-- Enable Postal's openers again
		
		MailOpener:TogglePostalModule("OpenAll", true);
		MailOpener:TogglePostalModule("Select", true);
	end
	
	-- Go through all children of the mail frame to find QA's elements and SHOW these
	-- There's no other way to do this because QuickAuctions has a local referrence to it (not as a property of the object like most other frames)
	local kids = { MailFrame:GetChildren() };
	
	for _, child in ipairs(kids) do
		if child and child.text then
			child.text:Show();
		end
	end
	
	self:Stop();
end

function mod:MAIL_SHOW()
	self:Debug("MAIL_SHOW");
	
	self:StopOpening(false);

	inventoryFullSoundPlayedThisVisit = nil;
	
	if MailOpener.PostalEnabled then
		-- Disable Postal's openers so we can do it ourselves
		
		MailOpener:TogglePostalModule("OpenAll", false);
		MailOpener:TogglePostalModule("Select", false);
	end
	
	-- Keep an eye for closing of the mailbox
	self:RegisterEvent("MAIL_CLOSED", "Stop");
	self:RegisterEvent("PLAYER_LEAVING_WORLD", "Stop");
	
	-- Look if the mailbox is full
    self:RegisterEvent("UI_ERROR_MESSAGE");
    -- Only look again after bags updated
	self:RegisterEvent("BAG_UPDATE");
    
    -- We need to know when to start opening
	self:RegisterMessage("MO_OPEN_MAIL", "Open");
	self:RegisterMessage("MO_SERVER_SYNCED");
	self:RegisterMessage("MO_MAIL_EMPTIED");
	self:RegisterMessage("MO_STOP_MAIL_OPENING");
	
	self:CancelTimer(self.tmrTimeRemaining, true);
	self.tmrTimeRemaining = self:ScheduleRepeatingTimer("UpdateTimer", 1);
	self:UpdateTimer();
end

function mod:Stop()
	self:Debug("Stop");
	
	-- We shutdown, so nothing to do when the mailbox is closed anymore
    self:UnregisterEvent("MAIL_CLOSED");
    self:UnregisterEvent("PLAYER_LEAVING_WORLD");
    
    -- We care about a full inventory just a little
    self:UnregisterEvent("UI_ERROR_MESSAGE");
    self:UnregisterEvent("BAG_UPDATE");
	
	-- We no longer care
	self:UnregisterMessage("MO_OPEN_MAIL");
	self:UnregisterMessage("MO_SERVER_SYNCED");
	self:UnregisterMessage("MO_MAIL_EMPTIED");
	self:UnregisterMessage("MO_STOP_MAIL_OPENING");
    
	self:CancelTimer(self.tmrMailOpener, true);
	self:CancelTimer(self.tmrTimeRemaining, true);
	
	-- No waiting mail to reload while the mailbox is closed
	if self.btnReload then
		self.btnReload:Hide();
	end
	
	self:SetOpeningStatus(false);
end

function mod:MO_SERVER_SYNCED()
	self:Debug("MO_SERVER_SYNCED");
	
	-- Stop opening now to prevent the opener from continueing while BeanCounter is counting
	self:StopOpening(false);
	
	lastSync = GetTime();
	
	self:UpdateMailCount();
	
	-- While this is true, we'll announce mail skipped - will be set to false after opening happened once
	firstOpenThisSync = true;
end

function mod:MO_MAIL_EMPTIED()
	-- A mail has been processed so we can process the next
	continue = true;
	
	self:UpdateTimer();
end

function mod:MO_STOP_MAIL_OPENING()
	self:StopOpening(true);
end

function mod:UpdateMailCount()
	local numItems, totalItems = GetInboxNumItems();
	
	numCurrentMail = numItems;
	numHiddenMail = ( totalItems - numItems );
end

function mod:BAG_UPDATE()
	-- If the bags are updated we should check if the inventory is full again
	inventoryFull = false;
	-- Replay sound
	inventoryFullSoundPlayed = nil;
	
	if opening and takingSingleItem then
		self:ScheduleTimer("Continue", self.db.profile.speed);
	end
end

-- We registered this event to look for the inventory full error message because this is faster than counting the amount of items in the inventory all the time
function mod:UI_ERROR_MESSAGE(e, errorMessage)
	if errorMessage == ERR_INV_FULL then
		-- Inventory is full.
		
		if not inventoryFull then
			inventoryFull = true;
			
			-- Play the sound
			if MailOpener.db.profile.notifications.bagsFullSound and (not MailOpener.db.profile.notifications.bagsFullSoundOnlyOnce or not inventoryFullSoundPlayed) and (not MailOpener.db.profile.notifications.bagsFullSoundOnlyOncePerMailboxVisit or not inventoryFullSoundPlayedThisVisit) then
				PlaySoundFile(MailOpener.db.profile.notifications.bagsFullSoundFile);
				inventoryFullSoundPlayed = true;
				inventoryFullSoundPlayedThisVisit = true;
			end
		end
		
		-- Continue opening mail (we still want to open gold mail)
		continue = true;
	elseif errorMessage == ERR_ITEM_MAX_COUNT or errorMessage == ERR_MAIL_DATABASE_ERROR then
		-- Can't carry more of this item OR mail database error
		
		-- Continue opening mail (we still want to retrieve other items or gold)
		continue = true;
	end
end

function mod:Open(forced, everything)
	self:Debug("Open (" .. ((everything and "1") or "0") .. ")");
	
	if not opening or forced == true then
		local numItems, totalItems = GetInboxNumItems();
		-- Start at the end, add one because OpenNext will take it away again
		local newMailItemIndex = ( ( numItems or 0 ) + 1 );
		
		if newMailItemIndex > 1 then
			self:Debug("Open succes");
			
			-- Stop the previous opening and restart
			if forced == true then
				-- Show skips again
				firstOpenThisSync = true;
				
				self:StopOpening(false); -- this is not a "simple" stop, so also reset inventory full warning
			else
				self:StopOpening(true); -- forced is false - automated action - simple reset, skip inventory full reset to avoid sound spam
			end
			
			-- Update the caret
			MAIL_ITEM_INDEX = newMailItemIndex;
			-- Do we want to override filters and open every single mail?
			if everything and self.db.profile.filter.allowShiftClick then
				MAIL_OPEN_EVERYTHING = true;
				
				MailOpener:Print(L["Shift key was held while pressing the open all button. Temporarily overriding filters; going to open every mail with attachments."]);
			else
				MAIL_OPEN_EVERYTHING = nil;
			end
			
			-- We're now going to be busy again
			self:SetOpeningStatus(true);
			
			-- Open the next mail in line
			self:OpenNext();
		else
			if MailOpener.db.profile.notifications.mailboxIsEmpty then
				print(L["|cffff0000There is currently no mail available.|r"]);
			end
			
			self:Debug("MO_OPEN_COMPLETE");
			
			-- Report that we're all done
			self:SendMessage("MO_OPEN_COMPLETE");
		end
	end
end

-- Return the type of mail a message subject is
local knownAHSubjectPatterns = {
	canceled = AUCTION_REMOVED_MAIL_SUBJECT:format(""),
	expired = AUCTION_EXPIRED_MAIL_SUBJECT:format(""),
	outbid = AUCTION_OUTBID_MAIL_SUBJECT:format(""),
	success = AUCTION_SOLD_MAIL_SUBJECT:format(""),
	won = AUCTION_WON_MAIL_SUBJECT:format(""),
};
function mod:GetAuctionMailType(subject)
	if subject then
		-- Check if any of our patterns match, sorted by most likely matches first (if one is true the rest shouldn't be evaluated)
		if subject:find(knownAHSubjectPatterns.expired) then
			return "expired";
		elseif subject:find(knownAHSubjectPatterns.success) then
			return "success";
		elseif subject:find(knownAHSubjectPatterns.won) then
			return "won";
		elseif subject:find(knownAHSubjectPatterns.canceled) then
			return "canceled";
		elseif subject:find(knownAHSubjectPatterns.outbid) then
			return "outbid";
		end
	end
	
	return; -- not auction mail
end

local slotsAvailable;

function mod:OpenMail(index)
	if index and index > 0 then
		-- LUA arrays start at 1, so mail with index 0 doesn't exist, so we're finished
		
		local sender, subject, gold, cod, _, items, _, _, _, _, isGM = select(3, GetInboxHeaderInfo(index));
		local auctionMailType = self:GetAuctionMailType(subject);
		
		if not subject then subject = ""; end
		
		local onlyShowOnceCheck = firstOpenThisSync;
		
		local skippingString = L["Skipping %d: %s (%s)"];
		
		if isGM then
			-- Blizzard Mail
			if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped.GMMail then
				print(skippingString:format(index, subject, L["Blizzard mail"]));
			end
			
			self:OpenNext();
			
			return;
		elseif cod and cod > 0 then
			-- Cost on delivery
			if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped.COD then
				print(skippingString:format(index, subject, L["C.O.D."]));
			end
			
			self:OpenNext();
			
			return;
		elseif ((gold and gold > 0) or (items and items > 0)) then
			-- Mail with some sort of attachments
			
			if self.db.profile.keepFreeSpace > 0 then
				slotsAvailable = 0;
				
				-- First find out the amount of empty bag slots
				for bag = 0, NUM_BAG_SLOTS do
					local numberOfFreeSlots, _ = C_Container.GetContainerNumSlots(bag);
					slotsAvailable = ( slotsAvailable + numberOfFreeSlots );
				end
				
				-- Then calculate how much is available after the space we need to leave empty
				slotsAvailable = ( slotsAvailable - self.db.profile.keepFreeSpace );
			end
			
			-- and not MAIL_OPEN_EVERYTHING
			-- Removed above part from below if statement, I forgot why I put it here and now it makes no sense
			if inventoryFull and not MailOpener.db.profile.general.continueOpeningStackableItems and items and items > 0 then
				if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped.inventoryFull then
					print(skippingString:format(index, subject, L["inventory is full"]));
				end
				
				self:OpenNext();
				
				return;
			elseif self.db.profile.keepFreeSpace > 0 and items and slotsAvailable ~= nil and slotsAvailable <= 0 then
				if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped.keepFreeSpaceLimit then
					print(skippingString:format(index, subject, L["keep free space limit"]));
				end
				
				self:OpenNext();
				
				return;
			else
				-- This string will hold the mailtype, MailOpener.db.profile.notifications.skipped/processed[mailType] will be checked if this should be announced
				local mailType = "other";
				
				if not auctionMailType then
					-- This is a normal mail
					
					if gold and gold > 0 then
						mailType = "normalGoldMail";
					elseif items and items > 0 then
						mailType = "normalItemsMail";
					end
				else
					-- This is an auction house mail
					
					mailType = "AH" .. auctionMailType;
				end
				
				if not MAIL_OPEN_EVERYTHING and not self.db.profile.filter.normalMoney and mailType == "normalGoldMail" then
					if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped[mailType] then
						print(skippingString:format(index, subject, L["normal mail with gold"]));
					end
					
					self:OpenNext();
					
					return;
				elseif not MAIL_OPEN_EVERYTHING and not self.db.profile.filter.normalAttachments and mailType == "normalItemsMail" then
					if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped[mailType] then
						print(skippingString:format(index, subject, L["normal mail with attachments"]));
					end
					
					self:OpenNext();
					
					return;
				elseif not MAIL_OPEN_EVERYTHING and not self.db.profile.filter.AH.expired and mailType == "AHexpired" then
					if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped[mailType] then
						print(skippingString:format(index, subject, L["expired auction"]));
					end
					
					self:OpenNext();
					
					return;
				elseif not MAIL_OPEN_EVERYTHING and not self.db.profile.filter.AH.success and mailType == "AHsuccess" then
					if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped[mailType] then
						print(skippingString:format(index, subject, L["successful auction"]));
					end
					
					self:OpenNext();
					
					return;
				elseif not MAIL_OPEN_EVERYTHING and not self.db.profile.filter.AH.won and mailType == "AHwon" then
					if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped[mailType] then
						print(skippingString:format(index, subject, L["auction won"]));
					end
					
					self:OpenNext();
					
					return;
				elseif not MAIL_OPEN_EVERYTHING and not self.db.profile.filter.AH.canceled and mailType == "AHcanceled" then
					if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped[mailType] then
						print(skippingString:format(index, subject, L["canceled auction"]));
					end
					
					self:OpenNext();
					
					return;
				elseif not MAIL_OPEN_EVERYTHING and not self.db.profile.filter.AH.outbid and mailType == "AHoutbid" then
					if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped[mailType] then
						print(skippingString:format(index, subject, L["outbid on auction"]));
					end
					
					self:OpenNext();
					
					return;
				else
					continue = false;
					
					self:Debug("MO_OPENING_MAIL (#" .. index .. ")");
					
					if self.db.profile.keepFreeSpace > 0 and items and slotsAvailable and items > slotsAvailable then
						-- If this mail contains more items than the space available, we must only take a few attachments
						-- Notifiy other modules of opening (no gold passed: the mail isn't necessarily
						-- emptied on this pass, so its gold may not be credited yet)
						self:SendMessage("MO_OPENING_MAIL");
						
						for attachIndex = 1, ATTACHMENTS_MAX_RECEIVE do
							if GetInboxItemLink(index, attachIndex) then
								-- If this attachment actually exists
								
								if slotsAvailable > 0 then
									-- If we still have slots available, then loot this one item
									
									self:Debug("Taking attachment " .. attachIndex);
									
									TakeInboxItem(index, attachIndex);
									takingSingleItem = true;
									
									-- We want to open the next attachment for this same mail again, so set the index one back
									MAIL_ITEM_INDEX = ( MAIL_ITEM_INDEX + 1 );
									
									-- Gained an item, lost an available slot
									slotsAvailable = ( slotsAvailable - 1 );
									
									break;
								else
									-- No more room available, announce and go to next item
									if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped.keepFreeSpaceLimit then
										print(skippingString:format(index, subject, L["keep free space limit"]));
									end
									
									-- We're done with this mail, it isn't empty so that event won't be triggered, but we may still continue
									continue = true;
									
									self:OpenNext();
									
									return;
								end
							end
						end
					else
						-- Take everything from this mail
						-- Notifiy other modules of opening, passing along the mail's gold so it can
						-- be accounted for right away instead of waiting for the PLAYER_MONEY event
						-- (which can arrive after the batch summary, see Collected:MO_OPENING_MAIL)
						self:SendMessage("MO_OPENING_MAIL", gold);
						AutoLootMailItem(index);
					end
					
					if MailOpener.db.profile.notifications.processed.all and MailOpener.db.profile.notifications.processed[mailType] then
						if gold and gold > 0 then
							print(L["Processing %d: %s (%s)"]:format(index, subject, MailOpener:FormatMoney(gold)));
						else
							print(L["Processing %d: %s"]:format(index, subject));
						end
					end
					
					self:CancelTimer(self.tmrMailOpener, true);
					-- And prepare for the next
					self.tmrMailOpener = self:ScheduleTimer("OpenNext", self.db.profile.speed);
				end
			end
		else
			-- Unknown, probably just text
			if MailOpener.db.profile.notifications.skipped.all and onlyShowOnceCheck and MailOpener.db.profile.notifications.skipped.other then
				print(L["Skipping %d: %s"]:format(index, subject));
			end
			
			self:OpenNext();
		end
	else
		-- Finished!
		if MailOpener.db.profile.notifications.finishedCurrentBatch and firstOpenThisSync then
			print(L["Finished opening the current batch."]);
		end
		
		-- We have opened mail once this batch, so quit notifying
		firstOpenThisSync = nil;
		
		self:SetOpeningStatus(false);
		
		self:Debug("MO_OPEN_COMPLETE");
		
		-- Report that we're all done
		self:SendMessage("MO_OPEN_COMPLETE");
	end
end

function mod:OpenNext()
	if continue then
		-- If the previous mail was opened successful, open the next
		
		-- Next mail in line
		MAIL_ITEM_INDEX = ( MAIL_ITEM_INDEX - 1 );
		
		-- Open it
		self:OpenMail(MAIL_ITEM_INDEX);
	else
		-- Try again at the next interval
		
		self:CancelTimer(self.tmrMailOpener, true);
		self.tmrMailOpener = self:ScheduleTimer("OpenNext", self.db.profile.speed);
	end
end

function mod:Continue()
	continue = true;
	takingSingleItem = nil;
end

local mailRemainingPatterns = {
	minutesSeconds = L["|cffffffff%d|r/|cffffffff%d|r mail remaining, opening everything will take about |cffffffff%d|r minutes and |cffffffff%d|r seconds (next refresh in |cffffffff%d|r seconds)."],
	minutes = L["|cffffffff%d|r/|cffffffff%d|r mail remaining, opening everything will take about |cffffffff%d|r minutes (next refresh in |cffffffff%d|r seconds)."],
	seconds = L["|cffffffff%d|r/|cffffffff%d|r mail remaining, opening everything will take about |cffffffff%d|r seconds (next refresh in |cffffffff%d|r seconds)."],
	nextRefresh = L["|cffffffff%d|r/|cffffffff%d|r mail remaining, next refresh in |cffffffff%d|r seconds."],
	waitingBatch = L["|cffffffff%d|r/|cffffffff%d|r mail remaining - waiting for something from the current batch to be opened..."],
	waitingSync = L["|cffffffff%d|r/|cffffffff%d|r mail remaining - waiting for the next mailbox refresh..."],
	soon = L["|cffffffff%d|r/|cffffffff%d|r mail remaining - everything will be opened soon..."],
};

-- The time left label is anchored 75px from the left edge of the mailbox frame and must
-- leave 1/5 of the frame's width empty on the right, so it can only use 4/5 of the frame
-- width minus that left offset. Calculating it from the frame's actual width (instead of
-- a fixed 270px) keeps the text from ever extending beyond the mailbox frame
function mod:GetTimeLeftTextWidth()
	return math.max(20, ( MailFrame:GetWidth() * 4 / 5 ) - 75);
end

function mod:UpdateTimer()
	if lastSync then
		self:UpdateMailCount();
		
		-- Only show the manual reload button while mail is still waiting for the next refresh
		if self.btnReload then
			if numHiddenMail and numHiddenMail > 0 then
				self.btnReload:Show();
			else
				self.btnReload:Hide();
			end
		end
		
		-- Calculate the total amount of mail waiting
		local numTotalMail = ( numHiddenMail + numCurrentMail );
		
		-- Resize the font based on mail left so the counter always fits perfectly
		if numTotalMail < 100 then
			self.timeLeftFrame.text:SetFont(GameFontHighlight:GetFont(), 30, "THICKOUTLINE");
		elseif numTotalMail < 1000 then
			self.timeLeftFrame.text:SetFont(GameFontHighlight:GetFont(), 24, "THICKOUTLINE");
		else
			self.timeLeftFrame.text:SetFont(GameFontHighlight:GetFont(), 18, "THICKOUTLINE");
		end
		self.timeLeftFrame.text:SetText(numTotalMail);
		
		-- Calculate the next server sync based on the last server sync plus sync interval
		local nextSync = ( lastSync + 61 );
	
		-- Calculate the timer remaining untill the next sync
		local timeRemaining = floor( nextSync - GetTime() );
		
		if numHiddenMail > 0 or timeRemaining > 0 then
			-- If there is still mail being hidden or the timer is still know, display stuff
			
			-- If the next sync was already due, our nextSync calculation was wrong and we must wait a little longer (lag?)
			local syncTimeOut = false;
			-- If time remaining is below 0, next sync should be soon
			if timeRemaining < 0 then
				timeRemaining = 0;
				syncTimeOut = true;
			end
			
			-- Calculate the amount of server syncs required to open all mail
			local syncsRequired = ceil( numHiddenMail / 50 );
			-- Calculate the time required to execute all these syncs
			local timeRequired = ( ( syncsRequired - 1 ) * 61 ) + timeRemaining;
			
			local minutes = floor( timeRequired / 60 );
			local seconds = floor( timeRequired % 60 );
			
			local remainingText;
			if syncTimeOut then
				-- Previous server sync was expected earlier, notify user
				
				if numCurrentMail == 50 then
					-- Sync couldn't occur because we were still waiting for the current batch to be opened
					remainingText = format(mailRemainingPatterns.waitingBatch, numCurrentMail, numTotalMail);
				else
					remainingText = format(mailRemainingPatterns.waitingSync, numCurrentMail, numTotalMail);
				end
			elseif numHiddenMail == 0 then
				-- If no hidden mail is remaining, only show the timer for as long as we can be sure
				
				remainingText = format(mailRemainingPatterns.nextRefresh, numCurrentMail, numTotalMail, timeRemaining);
			elseif minutes ~= 0 then
				if seconds ~= 0 then
					remainingText = format(mailRemainingPatterns.minutesSeconds, numCurrentMail, numTotalMail, minutes, seconds, timeRemaining);
				else
					remainingText = format(mailRemainingPatterns.minutes, numCurrentMail, numTotalMail, minutes, timeRemaining);
				end
			elseif seconds ~= 0 then
				remainingText = format(mailRemainingPatterns.seconds, numCurrentMail, numTotalMail, seconds, timeRemaining);
			else
				remainingText = format(mailRemainingPatterns.soon, numCurrentMail, numTotalMail);
			end
			
			-- Re-derive the wrap width from the current frame width so the label still
			-- leaves 1/5 of the mailbox frame empty on the right if it was resized
			self.timeLeftFrame.smallText:SetWidth(self:GetTimeLeftTextWidth());
			self.timeLeftFrame.smallText:SetText(remainingText);
			-- Dynamically shrink clickable button to text width (TBC fix)
			if self.timeLeftFrame and self.timeLeftFrame.smallText then
				local w = self.timeLeftFrame.smallText:GetStringWidth()
				local h = self.timeLeftFrame.smallText:GetStringHeight()
				-- +10 padding, clamp to the label's max width to avoid a huge block
				self.timeLeftFrame:SetWidth(math.min(self:GetTimeLeftTextWidth(), math.max(20, w + 10)))
				self.timeLeftFrame:SetHeight(math.max(12, h + 2))
			end
		else
			self.timeLeftFrame.smallText:SetText("");
			-- No text = no clickable area (prevents empty popup)
			if self.timeLeftFrame then
				self.timeLeftFrame:SetWidth(1)
				self.timeLeftFrame:SetHeight(1)
			end
		end
	end
end

function mod:StopOpening(simple)
	-- Stop opener timer
	self:CancelTimer(self.tmrMailOpener, true);
	
	if not simple then
		-- A simple stop is an automated stop, an advanced stop is one manually or after a sever sync
		
		-- Recheck inventory full
		inventoryFull = false;
		-- Replay sound
		inventoryFullSoundPlayed = nil;
	end
	
	-- Reset opener position
	MAIL_ITEM_INDEX = 0;
	-- Reset open everything state
	MAIL_OPEN_EVERYTHING = nil;
	-- Stopped opening, so allow to continue
	continue = true;
	
	takingSingleItem = nil;
	
	self:SetOpeningStatus(false);
end

function mod:SetOpeningStatus(openingStatus)
	opening = openingStatus;
	
	if openingStatus then
		self.btnOpenAll:SetText(L["Opening..."]);
	else
		self.btnOpenAll:SetText(L["Open all"]);
	end
end

function mod:GetOptionsGroup()
	local configGroup = {
		order = 300,
		type = "group",
		name = L["Open All"],
		desc = L["Change open all settings."],
		args = {
			filters = {
				order = 10,
				type = "group",
				inline = true,
				name = L["Filters"],
				args = {
					description = {
						order = 10,
						type = "description",
						name = L["Toggle which mail the opener should autoloot."],
					},
					AHHeader = {
						order = 15,
						type = "header",
						name = L["Auction House Mail"],
					},
					canceled = {
						order = 20,
						type = "toggle",
						name = L["Open all |cfffed000auction canceled|r mail"],
						desc = L["Automatically loot all auction canceled mail from the auction house."],
						set = function(i, v) self.db.profile.filter.AH.canceled = v; end,
						get = function() return self.db.profile.filter.AH.canceled; end,
						width = "double",
					},
					expired = {
						order = 21,
						type = "toggle",
						name = L["Open all |cfffed000auction expired|r mail"],
						desc = L["Automatically loot all auction expired mail from the auction house."],
						set = function(i, v) self.db.profile.filter.AH.expired = v; end,
						get = function() return self.db.profile.filter.AH.expired; end,
						width = "double",
					},
					outbid = {
						order = 22,
						type = "toggle",
						name = L["Open all |cfffed000outbid on|r mail"],
						desc = L["Automatically loot all auction outbid mail from the auction house."],
						set = function(i, v) self.db.profile.filter.AH.outbid = v; end,
						get = function() return self.db.profile.filter.AH.outbid; end,
						width = "double",
					},
					success = {
						order = 23,
						type = "toggle",
						name = L["Open all |cfffed000auction successful|r mail"],
						desc = L["Automatically loot all auction successful mail from the auction house."],
						set = function(i, v) self.db.profile.filter.AH.success = v; end,
						get = function() return self.db.profile.filter.AH.success; end,
						width = "double",
					},
					won = {
						order = 24,
						type = "toggle",
						name = L["Open all |cfffed000auction won|r mail"],
						desc = L["Automatically loot all auction won mail from the auction house."],
						set = function(i, v) self.db.profile.filter.AH.won = v; end,
						get = function() return self.db.profile.filter.AH.won; end,
						width = "double",
					},
					normalHeader = {
						order = 30,
						type = "header",
						name = L["Remaining Mail"],
					},
					normalAttachments = {
						order = 40,
						type = "toggle",
						name = L["Normal mail with |cfffed000attachments|r"],
						desc = L["Automatically loot all normal mail containing attachments (CoDs and Blizzard mail will be skipped)."],
						set = function(i, v) self.db.profile.filter.normalAttachments = v; end,
						get = function() return self.db.profile.filter.normalAttachments; end,
						width = "double",
					},
					normalMoney = {
						order = 50,
						type = "toggle",
						name = L["Normal mail with |cfffed000gold|r"],
						desc = L["Automatically loot all normal mail containing gold (CoDs and Blizzard mail will be skipped)."],
						set = function(i, v) self.db.profile.filter.normalMoney = v; end,
						get = function() return self.db.profile.filter.normalMoney; end,
						width = "double",
					},
					allowShiftClick = {
						order = 60,
						type = "toggle",
						name = L["Allow shift-clicking of the |cfffed000Open All|r button to autoloot |cfffed000everything|r, regardless of the above filters."],
						desc = L["Allow shift-clicking of the |cfffed000Open All|r button to autoloot |cfffed000everything|r with attachments, temporarily overriding all filters."],
						set = function(i, v) self.db.profile.filter.allowShiftClick = v; end,
						get = function() return self.db.profile.filter.allowShiftClick; end,
						width = "full",
					},
				},
			},
			-- Continuous opening config inline group
			continuousOpening = {
				order = 20,
				type = "group",
				inline = true,
				name = L["Opening Interval"],
				args = {
					description = {
						order = 10,
						type = "description",
						name = function()
							local defaultString = L["The default behavior for opening mail is to only do so right after new mail was received from the server. If you close the mailbox or your inventory is full before everything is opened you will have to click the open all button manually or wait for a next mailbox refresh."] .. "\n\n";
							
							local currentSettings = "";
							if MailOpener.db.profile.general.continueOpening then
								currentSettings = currentSettings .. L["Mail Opener will |cff00ff00continue|r to attempt to open the remaining mail every |cfffed000%d seconds|r."]:format(MailOpener.db.profile.general.waitTime) .. " ";
							else
								currentSettings = currentSettings .. L["Mail Opener will |cffff0000not|r continue to attempt to open the remaining mail and will only start opening when new mail has just been received from the server."] .. " ";
							end
							currentSettings = currentSettings .. L["The first batch after each server refresh will be opened after waiting |cfffed000%d seconds|r."]:format(MailOpener.db.profile.general.initialDelay);
							return defaultString .. currentSettings;
						end,
					},
					header = {
						order = 15,
						type = "header",
						name = "",
					},
					continueOpening = {
						order = 20,
						type = "toggle",
						name = L["Continue opening mail"],
						desc = L["Continue opening mail at the interval set below, even if the mailbox wasn't refreshed recently."],
						width = "full",
						get =  function() return MailOpener.db.profile.general.continueOpening; end,
						set = function(i, v) MailOpener.db.profile.general.continueOpening = v; end,
					},
					waitTime = {
						order = 30,
						type = "range",
						width = "double",
						min = 0.5,
						max = 60,
						step = 0.5,
						name = L["Continued Mail Opening Interval"],
						desc = L["Change the interval at which Mail Opener tries to continue opening mail after opening the mailbox. Please note that this setting does not reduce the game's normal 60 seconds wait time for mail.\n\nThe default value is 5 seconds."],
						get = function() return MailOpener.db.profile.general.waitTime; end,
						set = function(i, v) MailOpener.db.profile.general.waitTime = v; end,
						disabled = function() return (not MailOpener.db.profile.general.continueOpening); end,
					},
					initialDelay = {
						order = 40,
						type = "range",
						width = "double",
						min = 0.5,
						max = 60,
						step = 0.5,
						name = L["Initial Mail Opening Delay"],
						desc = L["Change the delay before Mail Opener tries opening mail after opening the mailbox or new mail has been received from the server.\n\nThe default value is 0.5 seconds."],
						get = function() return MailOpener.db.profile.general.initialDelay; end,
						set = function(i, v) MailOpener.db.profile.general.initialDelay = v; end,
					},
				},
			}, -- end Continuous opening config inline group
			keepFree = {
				order = 30,
				type = "group",
				inline = true,
				name = L["Keep Free Space"],
				args = {
					description = {
						order = 10,
						type = "description",
						name = L["You can set an amount of bag space you wish to reserve when opening mail."],
					},
					header = {
						order = 15,
						type = "header",
						name = "",
					},
					keepFreeSpace = {
						order = 20,
						type = "range",
						min = 0,
						max = 100,
						step = 1,
						width = "double",
						name = L["Keep free space"],
						desc = L["Change the amount of space to reserve for other things when opening mail.\n\nEnabling this functionality by setting this value above 0 may increase resource usage slightly."],
						set = function(i, v) self.db.profile.keepFreeSpace = v; end,
						get = function() return self.db.profile.keepFreeSpace; end,
					},
				},
			},
			speed = {
				order = 40,
				type = "group",
				inline = true,
				name = "Opening Speed",
				args = {
					description = {
						order = 10,
						type = "description",
						name = L["Change the speed at which mail is opened. You should set the opening speed to the lowest latency you have in a city or experiment with setting it to the minimum."],
					},
					header = {
						order = 15,
						type = "header",
						name = "",
					},
					openMailInterval = {
						order = 20,
						type = "range",
						min = 5,
						max = 2500,
						step = 5,
						width = "double",
						name = L["Open single mail interval"],
						desc = L["Change the mail opening speed (in microseconds) for each mail. Lower may not always be faster."],
						get = function() return ( self.db.profile.speed * 1000 ); end,
						set = function(i, v) self.db.profile.speed = ( v / 1000 ); end,
					},
				},
			},
		},
	};
	
	return configGroup;
end

function mod:Debug(t)
	return MailOpener:Debug(("|cff00ff00OpenAll|r:%s"):format(t));
end