local MailOpener = LibStub("AceAddon-3.0"):GetAddon("MailOpener");
local mod = MailOpener:NewModule("Config", "AceEvent-3.0", "AceTimer-3.0");
local L = LibStub("AceLocale-3.0"):GetLocale("MailOpener");

mod.moduleDescription = L["Builds and loads the config frame(s) and handles the slash commands. Automatically loaded when needed."];
mod.moduleRequired = false;

local Media = LibStub("LibSharedMedia-3.0");
Media:Register("sound", "Cartoon FX", [[Sound\Doodad\Goblin_Lottery_Open03.wav]]);
Media:Register("sound", "Cheer", [[Sound\Event Sounds\OgreEventCheerUnique.wav]]);
Media:Register("sound", "Explosion", [[Sound\Doodad\Hellfire_Raid_FX_Explosion05.wav]]);
Media:Register("sound", "Fel Nova", [[Sound\Spells\SeepingGaseous_Fel_Nova.wav]]);
Media:Register("sound", "Fel Portal", [[Sound\Spells\Sunwell_Fel_PortalStand.wav]]);
Media:Register("sound", "Magic Click", [[Sound\interface\MagicClick.wav]]);
Media:Register("sound", "Rubber Ducky", [[Sound\Doodad\Goblin_Lottery_Open01.wav]]);
Media:Register("sound", "Shing!", [[Sound\Doodad\PortcullisActive_Closed.wav]]);
Media:Register("sound", "Simon Chime", [[Sound\Doodad\SimonGame_LargeBlueTree.wav]]);
Media:Register("sound", "Simon Error", [[Sound\Spells\SimonGame_Visual_BadPress.wav]]);
Media:Register("sound", "Simon Start", [[Sound\Spells\SimonGame_Visual_GameStart.wav]]);
Media:Register("sound", "War Drums", [[Sound\Event Sounds\Event_wardrum_ogre.wav]]);
Media:Register("sound", "Wham!", [[Sound\Doodad\PVP_Lordaeron_Door_Open.wav]]);
Media:Register("sound", "Whisper Ping", [[Sound\interface\iTellMessage.wav]]);
Media:Register("sound", "You Will Die!", [[Sound\Creature\CThun\CThunYouWillDIe.wav]]);

local AceConfigDialog;
	
local tip, tipLink; -- if "tip" is nil, it will be filled with a table, once that table is processed, this var will be re-used with the currently selected tip

function mod:OnEnable()
	MailOpener:Debug("Enabling |cff00ffffConfig|r module.");
	
	if MailOpener.db.global.currentTip == -1 and MailOpener.db.profile.general.continueOpening == false then
		StaticPopupDialogs["MailOpenerFirstConfigUseConfirmBox"] = {
			text = L["Do you wish to enable \"continue opening mail\"? Read the tip at the bottom of the \"General\" config for more information."],
			button1 = L["Yes"],
			button2 = L["No"],
			OnAccept = function()
				MailOpener.db.profile.general.continueOpening = true;
				
				MailOpener:Print(L["Enabling the functionality. Remember you can always change this setting in the \"Open All\" config (|cff00ffff/mo c|r)."]);
			end,
			OnCancel = function (_,reason)
				MailOpener:Print(L["You can always change this setting in the \"Open All\" config (|cff00ffff/mo c|r)."]);
			end,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
		};
		StaticPopup_Show("MailOpenerFirstConfigUseConfirmBox");
	end
	
	if tip == nil then
		self:NextTip();
		
		self:GetTip();
	end
end

function mod:GetTip()
	-- First we fill the global "tip" with our table
	-- Then we erase tips that are irrelevant to us
	-- and finally the table will be replaced with the currently selected tip
	
	-- Can't put this in the abive scope as the ADDONEnable vars would then always be empty
	tip = {
		L["To make Mail Opener automatically continue the opening of a batch of mail that had previously been interrupted, you will have to tick the \"|cfffed000Continue opening mail|r\"-box at the \"|cfffed000Open All|r\" config. By default Mail Opener will always automatically start opening mail right after a server refresh, but you will have to manually resume mail opening if it gets interrupted (e.g. because you closed the mailbox or because your bags were full)."],
		L["You can |cfffed000shift-click|r a mail icon to loot all attachments from that single mail."],
		{
			txt = L["|cfffed000Postal|r allows you to return mail by |cfffed000alt-clicking|r the mail icon."],
			shown = (MailOpener.PostalEnabled),
		},
		{
			txt = L["|cfffed000Mail Opener|r is not meant to be a full replacement of |cfffed000Postal|r, it will only handle the opening of your mail and you can run both addons simultaneously."],
			shown = (MailOpener.PostalEnabled),
		},
		L["You can click the time remaining text to get it into a popup dialog so you can copy it (with |cfffed000CTRL-C|r) and then paste it (with |cfffed000CTRL-V|r) elsewhere."],
		{
			txt = L["If you are looking for an addon with many handy modifications for |cfffed000sending|r mail, you might want to consider |cfffed000Postal|r (click the button below for a download link)."],
			shown = (not MailOpener.PostalEnabled),
			url = "http://wow.curse.com/downloads/wow-addons/details/postal.aspx",
		},
		L["|cfffed000Cost on Delivery|r and |cfffed000Blizzard|r mail will always be skipped, regardless of any filters."],
		L["|cfffed000Right-click|r the |cfffed000open all|r button to quickly adjust your mail opening filters."],
		L["|cfffed000Shift-click|r the |cfffed000open all|r button to temporarily override your filters and loot every single mail containing attachments and/or gold."],
		{
			txt = L["Please report |cfffed000issues|r and |cfffed000suggestions|r/|cfffed000requests|r at the |cfffed000CurseForge ticket tracker|r, I will try to process and respond to them all (you can get a link to the ticket tracker by clicking the button below)."],
			url = "http://wow.curseforge.com/addons/mailopener/tickets/",
		},
		{
			txt = L["Your chance to contribute to this addon! Please help localizing Mail Opener if you master a second language supported by WoW. You can do so by clicking the button below to get a link to the localization pages, login with your Curse account and then you can start localizing."],
			url = "http://wow.curseforge.com/addons/mailopener/localization/",
		},
	};
	tipLink = nil;
	
	-- Remove any "hidden" tips
	for i = table.getn(tip), 1 do
		local val = tip[i];
		
		if type(val) == "table" and val.shown == false then
			table.remove(tip, i);
		end
	end
	
	-- Find our current tip
	local tipsAvailable = table.getn(tip);
	local selectedTip = ( ( MailOpener.db.global.currentTip % tipsAvailable ) + 1 ); -- this should return a value between 1 and tipsAvailable
	
	if selectedTip < 1 then
		-- If we're going under zero, we'll use the last tip available instead
		MailOpener.db.global.currentTip = tipsAvailable;
	end
	
	-- We don't need to leave the tip-table in memory, so overwrite it
	if type(tip[selectedTip]) == "table" then
		if tip[selectedTip]['url'] then
			tipLink = tip[selectedTip]['url'];
		end
		
		tip = tip[selectedTip]['txt'];
	else
		tip = tip[selectedTip];
	end
end

function mod:NextTip()
	MailOpener.db.global.currentTip = ( MailOpener.db.global.currentTip + 1 );
end

function mod:CommandHandler(message)
	local cmd, arg = string.split(" ", (message or ""), 2);
	cmd = string.lower(cmd);
	
	if cmd == "c" or cmd == "config" or cmd == "conf" or cmd == "option" or cmd == "options" or cmd == "opt" or cmd == "setting" or cmd == "settings" then
		self:Show();
	elseif cmd == "d" or cmd == "debug" then
		MailOpener.debugChannel = false;
		for i = 1, NUM_CHAT_WINDOWS do
			local name = GetChatWindowInfo(i);
			
			if name:upper() == "DEBUG" then
				MailOpener.debugChannel = _G["ChatFrame" .. i];
			
				print("A debug channel already exists, used the old one. (" .. i .. ")");
				return;
			end
		end
		
		if not MailOpener.debugChannel then
			-- Create a new debug channel
			local chatFrame = FCF_OpenNewWindow('Debug');
			ChatFrame_RemoveAllMessageGroups(chatFrame);
			MailOpener.debugChannel = chatFrame;
			
			print("New debug channel created.");
		end
	else
		print(L["Wrong command, available: /mo config (or /mo c)"]);
	end
end

function mod:Load()
	if not AceConfigDialog then
		local options = self:GetOptions();
		
		-- We have been pretty sloppy with tables in self:GetOptions(), but since this is only executed once and for readability we'll leave it this way
		-- Instead, do a garbage collection
		collectgarbage();
	
		-- Build options dialog
		AceConfigDialog = LibStub("AceConfigDialog-3.0");
		-- Register options table
		LibStub("AceConfig-3.0"):RegisterOptionsTable("Mail Opener", options);
		-- Set a nice default size
		AceConfigDialog:SetDefaultSize("Mail Opener", 950, 600);
		
		 -- Remove our old config tab
		for k, f in ipairs(INTERFACEOPTIONS_ADDONCATEGORIES or {}) do
			if f == "Mail Opener" or f.name == "Mail Opener" then
				tremove(INTERFACEOPTIONS_ADDONCATEGORIES, k);
				break;
			end
		end
		
		-- Add to the blizzard addons options thing
		AceConfigDialog:AddToBlizOptions("Mail Opener");
	end
end

function mod:Show()
	self:Load();
	
	AceConfigDialog:Open("Mail Opener");
end

function mod:GetOptions()
	local options = {
		type = "group",	
		name = L["Mail Opener"],
		childGroups = "tree",
		args = {
		},
	};
	
	options.args.general = self:GetGeneralOptions();
	
	options.args.notifications = self:GetNotificationsOptions();
	
	options = self:GetModuleOptions(options);
	
	options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(MailOpener.db, true);
	options.args.profiles.order = 1000; -- we want this as last group
	
	return options;
end

-- Get the options group for every one of our modules
function mod:GetModuleOptions(options)
	-- Go through all our modules
	for name, module in MailOpener:IterateModules() do
		-- Look if they even have an options group
		if module.GetOptionsGroup then
			-- Get that options group
			local moduleGroup = module:GetOptionsGroup();
			
			-- If it's set to be a subgroup of the modules group, put it there
			if moduleGroup['type'] == "modulesSubGroup" then
				moduleGroup['type'] = "group";
				
				-- If the modules group doesn't exist yet, make it
				if options.args.Modules == nil then
					options.args.Modules = self:GetModuleGroupsContainer();
				end
				
				-- Add to the modules sub group
				options.args.Modules.args[name] = moduleGroup;
			else
				options.args[name] = moduleGroup;
			end
			
		end
	end
	
	return options;
end

function mod:GetModuleGroupsContainer()
	local modulesConfigGroup = {
		order = 400,
		type = "group",
		childGroups = "tree",
		name = L["Modules"],
		desc = L["Change settings for modules or toggle them on or off."],
		args = {
			General = {
				order = 10,
				type = "group",
				inline = true,
				name = L["Modules Status"],
				args = {
					headerName = {
						order = 0,
						width = "normal",
						type = "description",
						fontSize = "medium",
						name = L["|cfffed000Module Name|r"],
					},
					headerStatus = {
						order = 1,
						width = "half",
						type = "description",
						fontSize = "medium",
						name = L["|cfffed000Status|r"],
					},
					headerDefault = {
						order = 2,
						width = "double",
						type = "description",
						fontSize = "medium",
						name = L["|cfffed000Default Status|r"],
					},
					headerseperator = {
						order = 3,
						type = "description",
						name = "",
					},
				},
			},
		},
	};
	
	-- Make a list of modules and their statuses
	local orderNo = 5;
	for moduleName, module in MailOpener:IterateModules() do
		-- Display each module as NAME		CURRENT STATUS		DEFAULT STATUS
		
		-- Name
		modulesConfigGroup.args.General.args[moduleName .. "name"] = {
			order = orderNo,
			width = "normal",
			type = "description",
			fontSize = "medium",
			name = function()
				return moduleName;
			end,
		};
		-- Current status
		modulesConfigGroup.args.General.args[moduleName .. "status"] = {
			order = ( orderNo + 1 ),
			width = "half",
			type = "description",
			fontSize = "medium",
			name = function()
				if module:IsEnabled() then
					return L["|cff00ff00Enabled|r"];
				else
					return L["|cffff0000Disabled|r"];
				end
			end,
		};
		-- Default status
		modulesConfigGroup.args.General.args[moduleName .. "default"] = {
			order = ( orderNo + 2 ),
			width = "double",
			type = "description",
			fontSize = "medium",
			name = function()
				local desc = "";
				if MailOpener.db.profile.modules[moduleName] == nil or MailOpener.db.profile.modules[moduleName] == true then
					desc = L["|cff00ff00Enabled|r"];
				else
					desc = L["|cffff0000Disabled|r"];
				end
				
				if module.moduleRequired then
					desc = desc .. " " .. L["(Required module)"];
				end
				
				return desc;
			end,
		};
		
		-- Seperator
		modulesConfigGroup.args.General.args[moduleName .. "seperator"] = {
			order = ( orderNo + 3 ),
			type = "description",
			name = "",
		};
		
		if module.moduleDescription then
			-- Description
			modulesConfigGroup.args.General.args[moduleName .. "description"] = {
				order = ( orderNo + 4 ),
				type = "description",
				name = function()
					return "|cfffed000" .. module.moduleDescription .. "|r";
				end,
			};
		end
		
		orderNo = orderNo + 5;
	end
	
	return modulesConfigGroup;
end

function mod:GetGeneralOptions()
	local generalConfigGroup = {
		order = 100,
		type = "group",
		name = L["General"],
		desc = L["Change general Mail Opener settings."],
		args = {
			-- General config inline group
			generalConfig = {
				order = 10,
				type = "group",
				inline = true,
				name = L["General"],
				args = {
					defaultStatus = {
						order = 0,
						type = "select",
						name = L["Default mail opener status"],
						desc = L["Select the default Mail Opener status when you open a mailbox for the first time since your log on."],
						values = {
							_enabled = L["Completely enabled"],
							disabled = L["Auto opening disabled"],
							xdisabled = L["Addon Disabled"],
						},
						get = function() return MailOpener.db.profile.general.defaultStatus; end,
						set = function(i, v) MailOpener.db.profile.general.defaultStatus = v; end,
					},
					defaultQAStatus = {
						order = 10,
						type = "select",
						name = L["Default QA Auto Mail status"],
						desc = L["Select the default Quick Auctions auto mail status whenever you open a mailbox."],
						values = {
							__remember = L["Remember"],
							_enabled = L["Enabled"],
							disabled = L["Disabled"],
						},
						get = function() return MailOpener.db.profile.general.defaultQAStatus; end,
						set = function(i, v) MailOpener.db.profile.general.defaultQAStatus = v; end,
						hidden = (not MailOpener.ZeroAuctionsEnabled),
					},
					overrideCheckInbox = {
						order = 12,
						type = "toggle",
						name = L["Don't refresh the mailbox while there is still mail waiting to be opened"],
						desc = L["Having this option toggled on will prevent the mailbox from automatically refreshing while there is still openable mail remaining.\n\nIf you close the mailbox while there is still mail remaining, your client will always try to refresh the inbox when you reopen it. This feature will wait with refreshing until there is no openable mail remaining, possibly saving a few seconds."],
						width = "full",
						get =  function() return MailOpener.db.profile.general.overrideCheckInbox; end,
						set = function(i, v) MailOpener.db.profile.general.overrideCheckInbox = v; end,
					},
					continueOpeningStackableItems = {
						order = 15,
						type = "toggle",
						name = L["Continue trying to open mail after your bags are full"],
						desc = L["If there are a lot of stackable items in your mailbox (e.g. glyphs) you may want to toggle this option on.\n\nThis will cause your Blizzard error frame to get extremely spammy if there's a lot of mail remaining. With this disabled, Mail Opener will completely stop opening mail while your inventory is full."],
						width = "full",
						get =  function() return MailOpener.db.profile.general.continueOpeningStackableItems; end,
						set = function(i, v) MailOpener.db.profile.general.continueOpeningStackableItems = v; end,
					},
					showHelpTooltips = {
						order = 17,
						type = "toggle",
						name = L["Display help tooltips at the mailbox buttons added by Mail Opener."],
						desc = L["Display the help tooltips when hovering at any of the mailbox buttons added by Mail Opener."],
						width = "full",
						get =  function() return MailOpener.db.profile.general.showHelpTooltips; end,
						set = function(i, v) MailOpener.db.profile.general.showHelpTooltips = v; end,
					},
					autoDisableQAAutoMail = {
						order = 20,
						type = "toggle",
						name = L["Turn Quick Auction's auto mail status |cffff0000off|r when opening mail"],
						desc = L["Quick Auction's auto mail is buggy when using other mail opening addons. If you are collecting mail while auto mailer is enabled wrong items may be send to the wrong character.\n\nTo solve this you must disable Quick Auction's auto mail while opening mail and you can re-enable it when mail opening is finished."],
						width = "full",
						get =  function() return MailOpener.db.profile.general.autoDisableQAAutoMail; end,
						set = function(i, v) MailOpener.db.profile.general.autoDisableQAAutoMail = v; end,
						hidden = (not MailOpener.ZeroAuctionsEnabled),
					},
					autoReenableQAAutoMail = {
						order = 30,
						type = "toggle",
						name = L["Turn Quick Auction's auto mail status |cff00ff00on|r after opening mail has finished"],
						desc = L["Quick Auction's auto mail is buggy when using other mail opening addons. If you are collecting mail while auto mailer is enabled wrong items may be send to the wrong character.\n\nTo solve this you must disable Quick Auction's auto mail while opening mail and you can re-enable it when mail opening is finished."],
						width = "full",
						get = function() return MailOpener.db.profile.general.autoReenableQAAutoMail; end,
						set = function(i, v) MailOpener.db.profile.general.autoReenableQAAutoMail = v; end,
						hidden = (not MailOpener.ZeroAuctionsEnabled),
						disabled = function() return (MailOpener.db.profile.general.autoSetBackQAAutoMail and not MailOpener.db.profile.general.autoReenableQAAutoMail); end,
					},
					autoSetBackQAAutoMail = {
						order = 40,
						type = "toggle",
						name = L["Set Quick Auction's auto mail status |cff00ffffback|r after opening mail has finished (remember it)"],
						desc = L["Instead of always turning Quick Auction's auto mail on after mail opening you can choose to set it back to the value it was prior to opening mail."],
						width = "full",
						get = function() return MailOpener.db.profile.general.autoSetBackQAAutoMail; end,
						set = function(i, v) MailOpener.db.profile.general.autoSetBackQAAutoMail = v; end,
						hidden = (not MailOpener.ZeroAuctionsEnabled),
						disabled = function() return (MailOpener.db.profile.general.autoReenableQAAutoMail and not MailOpener.db.profile.general.autoSetBackQAAutoMail); end,
					},
				},
			}, -- end General config inline group
			-- Profile config inline group
			profileConfig = {
				order = 15,
				type = "group",
				inline = true,
				name = L["New Character Specific Profile"],
				args = {
					description = {
						order = 10,
						type = "description",
						name = L["You can create a new profile to allow different behaviour for different characters. Imagine setting up a profile for your AH banker which will retrieve all sorts of mail containing items while other characters don't automatically open mail with items sent by other players."],
					},
					header = {
						order = 15,
						type = "header",
						name = "",
					},
					createNewProfile = {
						order = 20,
						type = "execute",
						name = L["Create a new character specific profile"],
						desc = L["Create a new profile for this user. You can also make profile groups at the profiles tab to the left."],
						width = "double",
						func = function()
							MailOpener.db:SetProfile(UnitName("player") .. " - " .. GetRealmName());
						end,
					},
				},
			}, -- end Profile config inline group
			-- Tip
			tipConfig = {
				order = 20,
				type = "group",
				inline = true,
				name = L["Mail Opening Tip"],
				args = {
					description = {
						order = 10,
						type = "description",
						fontSize = "medium",
						name = function() return tip; end,
					},
					nextTip = {
						order = 20,
						type = "execute",
						name = L["Next Tip"],
						width = "half",
						func = function() self:NextTip(); self:GetTip(); end,
					},
					tipLink = {
						order = 30,
						type = "execute",
						name = L["Copy URL"],
						width = "half",
						func = function()
							MailOpener.currentPopupContents = tipLink;
							
							StaticPopup_Show("MailOpenerCopyWindow");
						end,
						hidden = function() return tipLink == nil; end,
					},
				},
			}, -- end Tip
		},
	};
	
	return generalConfigGroup;
end

function mod:GetNotificationsOptions()
	local notificationsConfigGroup = {
		order = 200,
		type = "group",
		name = L["Notifications"],
		desc = L["Toggle notifications."],
		args = {
			-- Notifications config inline group
			nofitications = {
				order = 10,
				type = "group",
				inline = true,
				name = L["Notifications"],
				args = {
					description = {
						order = 10,
						type = "description",
						name = L["Notifications"],
					},
				},
			}, -- end Notifications config inline group
			
			-- General Notifications config inline group
			general = {
				order = 20,
				type = "group",
				inline = true,
				name = L["General Notifications"],
				args = {
					fishedOpeningBatch = {
						order = 22,
						type = "toggle",
						name = L["Announce when |cfffed000finished opening the current batch|r"],
						desc = L["Announce when opening of the current batch of mail has been completed."],
						set = function(i, v) MailOpener.db.profile.notifications.finishedCurrentBatch = v; end,
						get = function() return MailOpener.db.profile.notifications.finishedCurrentBatch; end,
						width = "double",
					},
					noMoreMailAvailable = {
						order = 23,
						type = "toggle",
						name = L["Announce when |cfffed000the mailbox is completely empty|r"],
						desc = L["Announce when there is nothing left for Mail Opener to open."],
						set = function(i, v) MailOpener.db.profile.notifications.mailboxIsEmpty = v; end,
						get = function() return MailOpener.db.profile.notifications.mailboxIsEmpty; end,
						width = "double",
					},
				},
			}, -- end General Notifications config inline group
			
			-- Mail Skipped Notifications config inline group
			mailSkipped = {
				order = 30,
				type = "group",
				inline = true,
				name = L["Mail Skipped Notifications"],
				args = {
					descriptionMailSkipped = {
						order = 31,
						type = "description",
						name = L["Announce when mail is skipped because..."],
					},
					
					skippedToggleAll = {
						order = 35,
						type = "toggle",
						name = L["Toggle everything"],
						desc = L["Announce when mail is skipped for |cfffed000any|r reason."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.all = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.all; end,
					},
					skippedInventoryFull = {
						order = 36,
						type = "toggle",
						name = L["Your inventory is full"],
						desc = L["Announce when mail is skipped because |cfffed000your inventory is full|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.inventoryFull = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.inventoryFull; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedKeepFreeSpaceLimit = {
						order = 37,
						type = "toggle",
						name = L["Keep free space limit reached"],
						desc = L["Announce when mail is skipped because |cfffed000the keep free space limit has been reached|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.keepFreeSpaceLimit = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.keepFreeSpaceLimit; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedGMMail = {
						order = 38,
						type = "toggle",
						name = L["Blizzard mail"],
						desc = L["Announce when mail is skipped because it's |cfffed000mail sent by Blizzard|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.GMMail = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.GMMail; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedCOD = {
						order = 39,
						type = "toggle",
						name = L["C.O.D. mail"],
						desc = L["Announce when mail is skipped because it's |cfffed000a Cost On Delivery mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.COD = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.COD; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedNormalGoldMail = {
						order = 40,
						type = "toggle",
						name = L["Normal mail with gold"],
						desc = L["Announce when mail is skipped because it's |cfffed000normal mail containing gold|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.normalGoldMail = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.normalGoldMail; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedNormalItemsMail = {
						order = 41,
						type = "toggle",
						name = L["Normal mail with attachments"],
						desc = L["Announce when mail is skipped because it's |cfffed000normal mail containing items|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.normalItemsMail = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.normalItemsMail; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedAHExpired = {
						order = 42,
						type = "toggle",
						name = L["Auction expired mail"],
						desc = L["Announce when mail is skipped because it's |cfffed000auction expired mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.AHexpired = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.AHexpired; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedAHSuccessful = {
						order = 43,
						type = "toggle",
						name = L["Auction successful mail"],
						desc = L["Announce when mail is skipped because it's |cfffed000auction successful mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.AHsuccess = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.AHsuccess; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedAHWon = {
						order = 44,
						type = "toggle",
						name = L["Auction won mail"],
						desc = L["Announce when mail is skipped because it's |cfffed000auction won mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.AHwon = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.AHwon; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedAHCanceled = {
						order = 45,
						type = "toggle",
						name = L["Auction canceled mail"],
						desc = L["Announce when mail is skipped because it's |cfffed000auction canceled mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.AHcanceled = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.AHcanceled; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedAHOutbid = {
						order = 46,
						type = "toggle",
						name = L["Auction outbid mail"],
						desc = L["Announce when mail is skipped because it's |cfffed000auction outbid mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.AHoutbid = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.AHoutbid; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
					skippedOther = {
						order = 47,
						type = "toggle",
						name = L["Other mail (e.g. plain text)"],
						desc = L["Announce when mail is skipped because it's |cfffed000any other kind of mail|r (e.g. plain text)."],
						set = function(i, v) MailOpener.db.profile.notifications.skipped.other = v; end,
						get = function() return MailOpener.db.profile.notifications.skipped.other; end,
						disabled = function() return (not MailOpener.db.profile.notifications.skipped.all); end,
					},
				},
			}, -- end Mail Skipped Notifications config inline group
			
			-- Mail Processed Notifications config inline group
			mailProcessed = {
				order = 40,
				type = "group",
				inline = true,
				name = L["Mail Processed Notifications"],
				args = {
					descriptionMailProcessed = {
						order = 61,
						type = "description",
						name = L["Announce when mail is processed because..."],
					},
					
					processedToggleAll = {
						order = 65,
						type = "toggle",
						name = L["Toggle everything"],
						desc = L["Announce when mail is processed for |cfffed000any|r reason."],
						set = function(i, v) MailOpener.db.profile.notifications.processed.all = v; end,
						get = function() return MailOpener.db.profile.notifications.processed.all; end,
					},
					processedNormalGoldMail = {
						order = 70,
						type = "toggle",
						name = L["Normal mail with gold"],
						desc = L["Announce when mail is processed because it's |cfffed000normal mail containing gold|r."],
						set = function(i, v) MailOpener.db.profile.notifications.processed.normalGoldMail = v; end,
						get = function() return MailOpener.db.profile.notifications.processed.normalGoldMail; end,
						disabled = function() return (not MailOpener.db.profile.notifications.processed.all); end,
					},
					processedNormalItemsMail = {
						order = 71,
						type = "toggle",
						name = L["Normal mail with attachments"],
						desc = L["Announce when mail is processed because it's |cfffed000normal mail containing items|r."],
						set = function(i, v) MailOpener.db.profile.notifications.processed.normalItemsMail = v; end,
						get = function() return MailOpener.db.profile.notifications.processed.normalItemsMail; end,
						disabled = function() return (not MailOpener.db.profile.notifications.processed.all); end,
					},
					processedAHExpired = {
						order = 72,
						type = "toggle",
						name = L["Auction expired mail"],
						desc = L["Announce when mail is processed because it's |cfffed000auction expired mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.processed.AHexpired = v; end,
						get = function() return MailOpener.db.profile.notifications.processed.AHexpired; end,
						disabled = function() return (not MailOpener.db.profile.notifications.processed.all); end,
					},
					processedAHSuccessful = {
						order = 73,
						type = "toggle",
						name = L["Auction successful mail"],
						desc = L["Announce when mail is processed because it's |cfffed000auction successful mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.processed.AHsuccess = v; end,
						get = function() return MailOpener.db.profile.notifications.processed.AHsuccess; end,
						disabled = function() return (not MailOpener.db.profile.notifications.processed.all); end,
					},
					processedAHWon = {
						order = 74,
						type = "toggle",
						name = L["Auction won mail"],
						desc = L["Announce when mail is processed because it's |cfffed000auction won mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.processed.AHwon = v; end,
						get = function() return MailOpener.db.profile.notifications.processed.AHwon; end,
						disabled = function() return (not MailOpener.db.profile.notifications.processed.all); end,
					},
					processedAHCanceled = {
						order = 75,
						type = "toggle",
						name = L["Auction canceled mail"],
						desc = L["Announce when mail is processed because it's |cfffed000auction canceled mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.processed.AHcanceled = v; end,
						get = function() return MailOpener.db.profile.notifications.processed.AHcanceled; end,
						disabled = function() return (not MailOpener.db.profile.notifications.processed.all); end,
					},
					processedAHOutbid = {
						order = 76,
						type = "toggle",
						name = L["Auction outbid mail"],
						desc = L["Announce when mail is processed because it's |cfffed000auction outbid mail|r."],
						set = function(i, v) MailOpener.db.profile.notifications.processed.AHoutbid = v; end,
						get = function() return MailOpener.db.profile.notifications.processed.AHoutbid; end,
						disabled = function() return (not MailOpener.db.profile.notifications.processed.all); end,
					},
					processedOther = {
						order = 77,
						type = "toggle",
						name = L["Other mail (e.g. plain text)"],
						desc = L["Announce when mail is processed because it's |cfffed000any other kind of mail|r (e.g. plain text)."],
						set = function(i, v) MailOpener.db.profile.notifications.processed.other = v; end,
						get = function() return MailOpener.db.profile.notifications.processed.other; end,
						disabled = function() return (not MailOpener.db.profile.notifications.processed.all); end,
					},
				},
			}, -- end Mail Processed Notifications config inline group
			
			-- Sound Notifications config inline group
			sound = {
				order = 50,
				type = "group",
				inline = true,
				name = L["Sound Notifications"],
				args = {
					descriptionMailProcessed = {
						order = 61,
						type = "description",
						name = L["Play a sound when..."],
					},
					bagsFullSound = {
						order = 100,
						type = "toggle",
						name = L["Inventory is full"],
						desc = L["Play a sound when your inventory is full. You can select what sound in the select box next to this."],
						set = function(i, v) MailOpener.db.profile.notifications.bagsFullSound = v; end,
						get = function() return MailOpener.db.profile.notifications.bagsFullSound; end,
						width = "medium",
					},
					bagsFullSoundFile = {
						order = 101,
						type = "select",
						name = L["Sound File"],
						desc = L["Sound file to play when your bags are full."],
						set = function(i, v)
							MailOpener.db.profile.notifications.bagsFullSoundFile = Media:Fetch("sound", v);
							MailOpener.db.profile.notifications.bagsFullSoundFileName = v;
							
							PlaySoundFile(MailOpener.db.profile.notifications.bagsFullSoundFile);
							
							MailOpener:Print(L["You may have to increase the mail opening interval if this sound effect gets spammy. The recommended value is 10 seconds."]);
						end,
						get = function() return MailOpener.db.profile.notifications.bagsFullSoundFileName end,
						values = function () return (Media:HashTable("sound") or nil); end,
						disabled = function() return (not MailOpener.db.profile.notifications.bagsFullSound); end,
					},
					bagsFullSoundOnlyOnce = {
						order = 102,
						type = "toggle",
						name = L["Only once"],
						desc = L["Only play this sound once each time new mail has been arrived or your bags are updated."],
						set = function(i, v) MailOpener.db.profile.notifications.bagsFullSoundOnlyOnce = v; end,
						get = function() return MailOpener.db.profile.notifications.bagsFullSoundOnlyOnce; end,
						disabled = function() return (not MailOpener.db.profile.notifications.bagsFullSound); end,
						--width = "half",
					},
					bagsFullSoundOnlyOncePerMailboxVisit = {
						order = 103,
						type = "toggle",
						name = L["...per mailbox visit"],
						desc = L["Only play this sound once each time you visit the mailbox."],
						set = function(i, v) MailOpener.db.profile.notifications.bagsFullSoundOnlyOncePerMailboxVisit = v; end,
						get = function() return MailOpener.db.profile.notifications.bagsFullSoundOnlyOncePerMailboxVisit; end,
						disabled = function() return (not MailOpener.db.profile.notifications.bagsFullSound or not MailOpener.db.profile.notifications.bagsFullSoundOnlyOnce); end,
					},
					mailboxEmptySound = {
						order = 110,
						type = "toggle",
						name = L["No more mail can be opened"],
						desc = L["Play a sound when no more mail can be opened. You can select what sound in the select box next to this."],
						set = function(i, v) MailOpener.db.profile.notifications.mailboxEmptySound = v; end,
						get = function() return MailOpener.db.profile.notifications.mailboxEmptySound; end,
						--width = "double",
					},
					mailboxEmptySoundFile = {
						order = 111,
						type = "select",
						name = L["Sound File"],
						desc = L["Sound file to play when Mail Opener can't open any more mail."],
						set = function(i, v)
							MailOpener.db.profile.notifications.mailboxEmptySoundFile = Media:Fetch("sound", v);
							MailOpener.db.profile.notifications.mailboxEmptySoundFileName = v;
							
							PlaySoundFile(MailOpener.db.profile.notifications.mailboxEmptySoundFile);
							
							MailOpener:Print(L["You may have to increase the mail opening interval if this sound effect gets spammy. The recommended value is 10 seconds."]);
						end,
						get = function() return MailOpener.db.profile.notifications.mailboxEmptySoundFileName end,
						values = function () return (Media:HashTable("sound") or nil); end,
						disabled = function() return (not MailOpener.db.profile.notifications.mailboxEmptySound); end,
					},
					mailboxEmptySoundOnlyOnce = {
						order = 112,
						type = "toggle",
						name = L["Only once"],
						desc = L["Only play this sound once each time new mail has been arrived."],
						set = function(i, v) MailOpener.db.profile.notifications.mailboxEmptySoundOnlyOnce = v; end,
						get = function() return MailOpener.db.profile.notifications.mailboxEmptySoundOnlyOnce; end,
						disabled = function() return (not MailOpener.db.profile.notifications.mailboxEmptySound); end,
						--width = "half",
					},
					mailboxEmptySoundOnlyOncePerMailboxVisit = {
						order = 113,
						type = "toggle",
						name = L["...per mailbox visit"],
						desc = L["Only play this sound once each time you visit the mailbox."],
						set = function(i, v) MailOpener.db.profile.notifications.mailboxEmptySoundOnlyOncePerMailboxVisit = v; end,
						get = function() return MailOpener.db.profile.notifications.mailboxEmptySoundOnlyOncePerMailboxVisit; end,
						disabled = function() return (not MailOpener.db.profile.notifications.bagsFullSound or not MailOpener.db.profile.notifications.mailboxEmptySoundOnlyOnce); end,
					},
				},
			}, -- end Sound Notifications config inline group
		},
	};
	
	return notificationsConfigGroup;
end