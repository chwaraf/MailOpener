local L = LibStub("AceLocale-3.0"):NewLocale("MailOpener", "enUS", true, false);
if not L then return; end

-- Core
L["|cff00ff00Enabled|r"] = true -- Needs review
L["|cff00ff00Enabling|r automatic opening of mail."] = true -- Needs review
L["|cff15ff00Mail Opener|r: %s"] = true -- Needs review
L["|cffff0000Disabling|r automatic opening of mail."] = true -- Needs review
L["|cffff0000Disabling|r automatic opening of mail, shift key was down when opening the mailbox."] = true -- Needs review
L["Click here to completely toggle this module on or off."] = true -- Needs review
L["Click to open the configuration window for Mail Opener."] = true -- Needs review
L["Config"] = true -- Needs review
L["Disable Module"] = true -- Needs review
L["Enable Module"] = true -- Needs review
L["General"] = true -- Needs review
L["Mail Opener"] = true -- Needs review
L["Mail Opener Config"] = true -- Needs review
L["Mail Opener status"] = true -- Needs review
L["Press CTRL-C to copy."] = true -- Needs review
L["Shift key was held down, so |cff00ff00enabling|r the entire addon as well as automatic opening of mail."] = true -- Needs review
L["Shift key was held down, so |cffff0000disabling|r the entire addon."] = true -- Needs review
L["Status: %s"] = true -- Needs review
L[ [=[Toggle automatic mail opening |cff00ff00on|r or |cffff0000off|r (you can also enforce this by holding shift when opening the mailbox).

You can toggle this addon |cff00ff00on|r or |cffff0000off|r by |cfffed000shift-clicking|r this checkbox.]=] ] = true -- Needs review
L["With this button you can completely toggle this module |cff00ff00on|r or |cffff0000off|r. This setting will be remembered and the module will be automatically toggled |cff00ff00on|r or |cffff0000off|r upon logon as it was last set."] = true -- Needs review
L[ [=[You are using |cff15ff00Mail Opener|r for the first time. Do you wish to always |cf00ff000enable|r |cfffed000automatic mail opening when you open the mailbox|r?

You can always change the standard behavior in the General options.]=] ] = true -- Needs review
L["You can always change the default status in the General config (|cff00ffff/mo c|r)."] = true -- Needs review


-- BeanCounterSupport
L[ [=[Are you sure you want to disable this module?

It will only be active when needed and disabling it may cause your BeanCounter data to become incomplete. Leaving it on causes no harm.]=] ] = true -- Needs review
L["BeanCounter Support"] = true -- Needs review
L["|cfffed000Please note this module will only be enabled when the addon \"BeanCounter\" is enabled. This module will be disabled when BeanCounter could not be found and enabled when it can unless you manually disabled this module.|r"] = true -- Needs review
L["|cffff0000You are strongly adviced to leave this module enabled unless you have very good reasons not to.|r"] = true -- Needs review
L["Change settings for the BeanCounter Support module."] = true -- Needs review
L["Prevents mail opening while BeanCounter is still scanning. Does nothing when BeanCounter is disabled."] = true -- Needs review


-- Collected
L["Also show a summary of the recorded stats within the entire session"] = true -- Needs review
L["Also show a summary of the recorded stats within the entire session (since your last login or /reload)."] = true -- Needs review
L["Also show a summary of the recorded stats within the entire session whenever the batch summary is shown after opening the current batch has finished. By default the session summary is only shown when the mailbox is closed."] = true -- Needs review
L["Also show the session summary whenever the batch summary is shown"] = true -- Needs review
L["|cfffed000Shift-click|r the |cfffed000open all|r button to temporarily override your filters and loot every single mail containing attachments and/or gold."] = true -- Needs review
L["Change settings for the collected module."] = true -- Needs review
L["Collected"] = true -- Needs review
L["Collected a total of %d mail."] = true -- Needs review
L["Collected a total of %d mail this session."] = true -- Needs review
L["Collected a total of %d mail within %d minutes and %d seconds."] = true -- Needs review
L["Collected a total of %d mail within %d minutes and %d seconds this session."] = true -- Needs review
L["Collected a total of %d mail within %d seconds."] = true -- Needs review
L["Collected a total of %d mail within %d seconds this session."] = true -- Needs review
L["(Required module)"] = true -- Needs review
L["(Session summary)"] = true -- Needs review
L["Show a summary of the recorded stats whenever it has been updated after opening the current batch of mails has finished."] = true -- Needs review
L["Show a summary of the recorded stats whenever it updated after opening the current batch has finished"] = true -- Needs review
L["Shows a simple summary of what has been collected at the mailbox."] = true -- Needs review
L["Spent %d minutes and %d seconds collecting mail."] = true -- Needs review
L["Spent %d minutes and %d seconds collecting mail this session."] = true -- Needs review
L["Spent %d seconds collecting mail."] = true -- Needs review
L["Spent %d seconds collecting mail this session."] = true -- Needs review
L["Summarize"] = true -- Needs review
L["Track |cfffed000gold gained|r"] = true -- Needs review
L["Track |cfffed000items gained|r"] = true -- Needs review
L["Track |cfffed000mail opened|r"] = true -- Needs review
L["Track |cfffed000time spent|r"] = true -- Needs review
L["Track Stats"] = true -- Needs review
L["Track the amount of gold gained and display it when closing the mailbox."] = true -- Needs review
L["Track the amount of items gained and display it when closing the mailbox."] = true -- Needs review
L["Track the amount of mail received and display it when closing the mailbox."] = true -- Needs review
L["Track the amount of time spent at the mailbox."] = true -- Needs review
L["You can select what things to track. Toggling something off will stop tracking of it completely and reduce the resources used by Mail Opener (although you shouldn't notice a difference)."] = true -- Needs review
L["You gained %d items and %s from this."] = true -- Needs review
L["You gained %d items from this."] = true -- Needs review
L["You gained %s from this."] = true -- Needs review


-- Config
L["Addon Disabled"] = true -- Needs review
L["Announce when |cfffed000finished opening the current batch|r"] = true -- Needs review
L["Announce when |cfffed000the mailbox is completely empty|r"] = true -- Needs review
L["Announce when mail is processed because..."] = true -- Needs review
L["Announce when mail is processed because it's |cfffed000any other kind of mail|r (e.g. plain text)."] = true -- Needs review
L["Announce when mail is processed because it's |cfffed000auction canceled mail|r."] = true -- Needs review
L["Announce when mail is processed because it's |cfffed000auction expired mail|r."] = true -- Needs review
L["Announce when mail is processed because it's |cfffed000auction outbid mail|r."] = true -- Needs review
L["Announce when mail is processed because it's |cfffed000auction successful mail|r."] = true -- Needs review
L["Announce when mail is processed because it's |cfffed000auction won mail|r."] = true -- Needs review
L["Announce when mail is processed because it's |cfffed000normal mail containing gold|r."] = true -- Needs review
L["Announce when mail is processed because it's |cfffed000normal mail containing items|r."] = true -- Needs review
L["Announce when mail is processed for |cfffed000any|r reason."] = true -- Needs review
L["Announce when mail is skipped because..."] = true -- Needs review
L["Announce when mail is skipped because |cfffed000the keep free space limit has been reached|r."] = true -- Needs review
L["Announce when mail is skipped because |cfffed000your inventory is full|r."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000a Cost On Delivery mail|r."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000any other kind of mail|r (e.g. plain text)."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000auction canceled mail|r."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000auction expired mail|r."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000auction outbid mail|r."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000auction successful mail|r."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000auction won mail|r."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000mail sent by Blizzard|r."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000normal mail containing gold|r."] = true -- Needs review
L["Announce when mail is skipped because it's |cfffed000normal mail containing items|r."] = true -- Needs review
L["Announce when mail is skipped for |cfffed000any|r reason."] = true -- Needs review
L["Announce when opening of the current batch of mail has been completed."] = true -- Needs review
L["Announce when there is nothing left for Mail Opener to open."] = true -- Needs review
L["Auction canceled mail"] = true -- Needs review
L["Auction expired mail"] = true -- Needs review
L["Auction outbid mail"] = true -- Needs review
L["Auction successful mail"] = true -- Needs review
L["Auction won mail"] = true -- Needs review
L["Auto opening disabled"] = true -- Needs review
L["Blizzard mail"] = true -- Needs review
L["Builds and loads the config frame(s) and handles the slash commands. Automatically loaded when needed."] = true -- Needs review
L["|cff00ff00Enabled|r"] = true -- Needs review
L["|cfffed000Cost on Delivery|r and |cfffed000Blizzard|r mail will always be skipped, regardless of any filters."] = true -- Needs review
L["|cfffed000Default Status|r"] = true -- Needs review
L["|cfffed000Mail Opener|r is not meant to be a full replacement of |cfffed000Postal|r, it will only handle the opening of your mail and you can run both addons simultaneously."] = true -- Needs review
L["|cfffed000Module Name|r"] = true -- Needs review
L["|cfffed000Postal|r allows you to return mail by |cfffed000alt-clicking|r the mail icon."] = true -- Needs review
L["|cfffed000Right-click|r the |cfffed000open all|r button to quickly adjust your mail opening filters."] = true -- Needs review
L["|cfffed000Status|r"] = true -- Needs review
L["|cffff0000Disabled|r"] = true -- Needs review
L["Change general Mail Opener settings."] = true -- Needs review
L["Change settings for modules or toggle them on or off."] = true -- Needs review
L["C.O.D. mail"] = true -- Needs review
L["Completely enabled"] = true -- Needs review
L["Continue trying to open mail after your bags are full"] = true -- Needs review
L["Copy URL"] = true -- Needs review
L["Create a new character specific profile"] = true -- Needs review
L["Create a new profile for this user. You can also make profile groups at the profiles tab to the left."] = true -- Needs review
L["Default mail opener status"] = true -- Needs review
L["Default QA Auto Mail status"] = true -- Needs review
L["Disabled"] = true -- Needs review
L["Display help tooltips at the mailbox buttons added by Mail Opener."] = true -- Needs review
L["Display the help tooltips when hovering at any of the mailbox buttons added by Mail Opener."] = true -- Needs review
L["Don't refresh the mailbox while there is still mail waiting to be opened"] = true
L["Do you wish to enable \"continue opening mail\"? Read the tip at the bottom of the \"General\" config for more information."] = true -- Needs review
L["Enabled"] = true -- Needs review
L["Enabling the functionality. Remember you can always change this setting in the \\\"Open All\\\" config (|cff00ffff/mo c|r)."] = true -- Needs review
L["General Notifications"] = true -- Needs review
L[ [=[Having this option toggled on will prevent the mailbox from automatically refreshing while there is still openable mail remaining.

If you close the mailbox while there is still mail remaining, your client will always try to refresh the inbox when you reopen it. This feature will wait with refreshing until there is no openable mail remaining, possibly saving a few seconds.]=] ] = true
L[ [=[If there are a lot of stackable items in your mailbox (e.g. glyphs) you may want to toggle this option on.

This will cause your Blizzard error frame to get extremely spammy if there's a lot of mail remaining. With this disabled, Mail Opener will completely stop opening mail while your inventory is full.]=] ] = true -- Needs review
L["If you are looking for an addon with many handy modifications for |cfffed000sending|r mail, you might want to consider |cfffed000Postal|r (click the button below for a download link)."] = true -- Needs review
L["Instead of always turning Quick Auction's auto mail on after mail opening you can choose to set it back to the value it was prior to opening mail."] = true -- Needs review
L["Inventory is full"] = true -- Needs review
L["Keep free space limit reached"] = true -- Needs review
L["Mail Opening Tip"] = true -- Needs review
L["Mail Processed Notifications"] = true -- Needs review
L["Mail Skipped Notifications"] = true -- Needs review
L["Modules"] = true -- Needs review
L["Modules Status"] = true -- Needs review
L["New Character Specific Profile"] = true -- Needs review
L["Next Tip"] = true -- Needs review
L["No"] = true -- Needs review
L["No more mail can be opened"] = true -- Needs review
L["Normal mail with attachments"] = true -- Needs review
L["Normal mail with gold"] = true -- Needs review
L["Notifications"] = true -- Needs review
L["Only once"] = true -- Needs review
L["Only play this sound once each time new mail has been arrived."] = true -- Needs review
L["Only play this sound once each time new mail has been arrived or your bags are updated."] = true -- Needs review
L["Only play this sound once each time you visit the mailbox."] = true -- Needs review
L["Other mail (e.g. plain text)"] = true -- Needs review
L["...per mailbox visit"] = true -- Needs review
L["Play a sound when..."] = true -- Needs review
L["Play a sound when no more mail can be opened. You can select what sound in the select box next to this."] = true -- Needs review
L["Play a sound when your inventory is full. You can select what sound in the select box next to this."] = true -- Needs review
L["Please report |cfffed000issues|r and |cfffed000suggestions|r/|cfffed000requests|r at the |cfffed000CurseForge ticket tracker|r, I will try to process and respond to them all (you can get a link to the ticket tracker by clicking the button below)."] = true -- Needs review
L[ [=[Quick Auction's auto mail is buggy when using other mail opening addons. If you are collecting mail while auto mailer is enabled wrong items may be send to the wrong character.

To solve this you must disable Quick Auction's auto mail while opening mail and you can re-enable it when mail opening is finished.]=] ] = true -- Needs review
L["Remember"] = true -- Needs review
L["Select the default Mail Opener status when you open a mailbox for the first time since your log on."] = true -- Needs review
L["Select the default Quick Auctions auto mail status whenever you open a mailbox."] = true -- Needs review
L["Set Quick Auction's auto mail status |cff00ffffback|r after opening mail has finished (remember it)"] = true -- Needs review
L["Sound File"] = true -- Needs review
L["Sound file to play when Mail Opener can't open any more mail."] = true -- Needs review
L["Sound file to play when your bags are full."] = true -- Needs review
L["Sound Notifications"] = true -- Needs review
L["Toggle everything"] = true -- Needs review
L["Toggle notifications."] = true -- Needs review
L["Toggle which notification you wish to see."] = true -- Needs review
L["To make Mail Opener automatically continue the opening of a batch of mail that had previously been interrupted, you will have to tick the \"|cfffed000Continue opening mail|r\"-box at the \"|cfffed000Open All|r\" config. By default Mail Opener will always automatically start opening mail right after a server refresh, but you will have to manually resume mail opening if it gets interrupted (e.g. because you closed the mailbox or because your bags were full)."] = true -- Needs review
L["Turn Quick Auction's auto mail status |cff00ff00on|r after opening mail has finished"] = true -- Needs review
L["Turn Quick Auction's auto mail status |cffff0000off|r when opening mail"] = true -- Needs review
L["Wrong command, available: /mo config (or /mo c)"] = true -- Needs review
L["Yes"] = true -- Needs review
L["You can always change this setting in the \\\"Open All\\\" config (|cff00ffff/mo c|r)."] = true -- Needs review
L["You can |cfffed000shift-click|r a mail icon to loot all attachments from that single mail."] = true -- Needs review
L["You can click the time remaining text to get it into a popup dialog so you can copy it (with |cfffed000CTRL-C|r) and then paste it (with |cfffed000CTRL-V|r) elsewhere."] = true -- Needs review
L["You can create a new profile to allow different behaviour for different characters. Imagine setting up a profile for your AH banker which will retrieve all sorts of mail containing items while other characters don't automatically open mail with items sent by other players."] = true -- Needs review
L["You may have to increase the mail opening interval if this sound effect gets spammy. The recommended value is 10 seconds."] = true -- Needs review
L["Your chance to contribute to this addon! Please help localizing Mail Opener if you master a second language supported by WoW. You can do so by clicking the button below to get a link to the localization pages, login with your Curse account and then you can start localizing."] = true -- Needs review
L["Your inventory is full"] = true -- Needs review


-- FailSafe
L[ [=[Change how long FailSafe should wait before skipping the last mail and continuing with the next. This should prevent mail opening getting stuck because a single mail is stuck for whatever reason.

Default value is 20 seconds.]=] ] = true -- Needs review
L["Change how long FailSafe should wait before skipping the last mail and continuing with the next. This will prevent mail opening getting stuck forever because a single mail is frozen for whatever reason."] = true -- Needs review
L["Change settings for the FailSafe module."] = true -- Needs review
L["FailSafe"] = true -- Needs review
L["(FailSafe) Mail opening timeout, continuing with the next mail."] = true -- Needs review
L["Prevents the mail opening from completely stopping when the opening of a single mail gets stuck."] = true -- Needs review
L["Single Mail Opening Timeout"] = true -- Needs review
L["Single Mail Timeout"] = true -- Needs review


-- Indicator
L["Change settings for the Indicator module."] = true -- Needs review
L["Indicator"] = true -- Needs review
L["This mail includes mail sent by:"] = true -- Needs review
L["Uses the minimap mail icon to indicate when there is still unread mail waiting for you at the mailbox."] = true -- Needs review
L["You have %d unread mail remaining in your mailbox."] = true -- Needs review
L["You have unread mail remaining in your mailbox."] = true -- Needs review


-- OpenAll
L["Allow shift-clicking of the |cfffed000Open All|r button to autoloot |cfffed000everything|r, regardless of the above filters."] = true -- Needs review
L["Allow shift-clicking of the |cfffed000Open All|r button to autoloot |cfffed000everything|r with attachments, temporarily overriding all filters."] = true -- Needs review
L["Auction canceled"] = true -- Needs review
L["Auction expired"] = true -- Needs review
L["Auction House Mail"] = true -- Needs review
L["Auction outbid"] = true -- Needs review
L["Auction successful"] = true -- Needs review
L["auction won"] = true -- Needs review
L["Auction won"] = true -- Needs review
L["Automatically loot all auction canceled mail from the auction house."] = true -- Needs review
L["Automatically loot all auction expired mail from the auction house."] = true -- Needs review
L["Automatically loot all auction outbid mail from the auction house."] = true -- Needs review
L["Automatically loot all auction successful mail from the auction house."] = true -- Needs review
L["Automatically loot all auction won mail from the auction house."] = true -- Needs review
L["Automatically loot all normal mail containing attachments (CoDs and Blizzard mail will be skipped)."] = true -- Needs review
L["Automatically loot all normal mail containing gold (CoDs and Blizzard mail will be skipped)."] = true -- Needs review
L["Blizzard mail"] = true -- Needs review
L["canceled auction"] = true -- Needs review
L["|cffff0000There is currently no mail available.|r"] = true -- Needs review
L["|cffffffff%d|r/|cffffffff%d|r mail remaining - everything will be opened soon..."] = true -- Needs review
L["|cffffffff%d|r/|cffffffff%d|r mail remaining, next refresh in |cffffffff%d|r seconds."] = true -- Needs review
L["|cffffffff%d|r/|cffffffff%d|r mail remaining, opening everything will take about |cffffffff%d|r minutes and |cffffffff%d|r seconds (next refresh in |cffffffff%d|r seconds)."] = true -- Needs review
L["|cffffffff%d|r/|cffffffff%d|r mail remaining, opening everything will take about |cffffffff%d|r minutes (next refresh in |cffffffff%d|r seconds)."] = true -- Needs review
L["|cffffffff%d|r/|cffffffff%d|r mail remaining, opening everything will take about |cffffffff%d|r seconds (next refresh in |cffffffff%d|r seconds)."] = true -- Needs review
L["|cffffffff%d|r/|cffffffff%d|r mail remaining - waiting for something from the current batch to be opened..."] = true -- Needs review
L["|cffffffff%d|r/|cffffffff%d|r mail remaining - waiting for the next mailbox refresh..."] = true -- Needs review
L["Change open all settings."] = true -- Needs review
L[ [=[Change the amount of space to reserve for other things when opening mail.

Enabling this functionality by setting this value above 0 may increase resource usage slightly.]=] ] = [=[Change the amount of space to reserve for other things when opening mail.

Enabling this functionality by setting this value above 0 may slightly increase resource usage.]=] -- Needs review
L[ [=[Change the delay before Mail Opener tries opening mail after opening the mailbox or new mail has been received from the server.

The default value is 0.5 seconds.]=] ] = true -- Needs review
L[ [=[Change the interval at which Mail Opener tries to continue opening mail after opening the mailbox. Please note that this setting does not reduce the game's normal 60 seconds wait time for mail.

The default value is 5 seconds.]=] ] = true -- Needs review
L["Change the mail opening speed (in microseconds) for each mail. Lower may not always be faster."] = true -- Needs review
L["Change the speed at which mail is opened. You should set the opening speed to the lowest latency you have in a city or experiment with setting it to the minimum."] = true -- Needs review
L["C.O.D."] = true -- Needs review
L["Continued Mail Opening Interval"] = true -- Needs review
L["Continue opening mail"] = true -- Needs review
L["Continue opening mail at the interval set below, even if the mailbox wasn't refreshed recently."] = true -- Needs review
L["expired auction"] = true -- Needs review
L["Filters"] = true -- Needs review
L["Finished opening the current batch."] = true -- Needs review
L[ [=[Hold |cfffed000shift|r while clicking this button to temporarily override your filters and loot every single mail containing attachments and/or gold.

|cfffed000Right|r click this button to quickly adjust mail opening filters for this profile.

|cfffed000Middle|r click or hold |cfffed000alt|r while clicking this button to interrupt mail opening.]=] ] = true
L["Initial Mail Opening Delay"] = true -- Needs review
L["Interrupting mail opening as the alt key was held down while clicking the open all button or the middle mouse-button was used on it."] = true
L["inventory is full"] = true -- Needs review
L["Keep free space"] = true -- Needs review
L["Keep Free Space"] = true -- Needs review
L["keep free space limit"] = true -- Needs review
L["Mail Opener will |cff00ff00continue|r to attempt to open the remaining mail every |cfffed000%d seconds|r."] = true -- Needs review
L["Mail Opener will |cffff0000not|r continue to attempt to open the remaining mail and will only start opening when new mail has just been received from the server."] = true -- Needs review
L["normal mail with attachments"] = true -- Needs review
L["Normal mail with |cfffed000attachments|r"] = true -- Needs review
L["Normal mail with |cfffed000gold|r"] = true -- Needs review
L["normal mail with gold"] = true -- Needs review
L["Open all"] = true -- Needs review
L["Open All"] = true -- Needs review
L["Open all |cfffed000auction canceled|r mail"] = true -- Needs review
L["Open all |cfffed000auction expired|r mail"] = true -- Needs review
L["Open all |cfffed000auction successful|r mail"] = true -- Needs review
L["Open all |cfffed000auction won|r mail"] = true -- Needs review
L["Open all |cfffed000outbid on|r mail"] = true -- Needs review
L["Opening..."] = true -- Needs review
L["Opening Interval"] = true -- Needs review
L["Opening Speed"] = true -- Needs review
L["Open single mail interval"] = true -- Needs review
L["Other mail with attachments"] = true -- Needs review
L["Other mail with gold"] = true -- Needs review
L["outbid on auction"] = true -- Needs review
L["Processing %d: %s"] = true -- Needs review
L["Processing %d: %s (%s)"] = true -- Needs review
L["Remaining Mail"] = true -- Needs review
L["Reload"] = true -- Needs review
L["Reload mail"] = true -- Needs review
L["Click to fetch the mail that is still waiting on the server right away instead of waiting for the next automatic refresh."] = true -- Needs review
L["Shift key was held while pressing the open all button. Temporarily overriding filters; going to open every mail with attachments."] = true -- Needs review
L["Skipping %d: %s"] = true -- Needs review
L["Skipping %d: %s (%s)"] = true -- Needs review
L["successful auction"] = true -- Needs review
L["The actual mail opening initiated by the core."] = true -- Needs review
L["The default behavior for opening mail is to only do so right after new mail was received from the server. If you close the mailbox or your inventory is full before everything is opened you will have to click the open all button manually or wait for a next mailbox refresh."] = true -- Needs review
L["The first batch after each server refresh will be opened after waiting |cfffed000%d seconds|r."] = true -- Needs review
L["Toggle filters for %s profile."] = true -- Needs review
L["Toggle which mail the opener should autoloot."] = true -- Needs review
L["You can set an amount of bag space you wish to reserve when opening mail."] = true -- Needs review

-- Fixes for missing entries reported by user
L["Enabling the functionality. Remember you can always change this setting in the \"Open All\" config (|cff00ffff/mo c|r)."] = true
L["ToDebugString"] = true
