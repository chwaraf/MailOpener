# Mail Opener

A World of Warcraft addon that automatically retrieves all your mail from the mailbox.

Originally written by **Zerotorescue** (EU – Al'Akir). This repository is a maintained fork,
updated to keep working on modern/Classic-era clients (`## Interface: 11507`).

Mail Opener adds its own **Open all** button, a status checkbox and a config button to the
default mail frame, and does the opening itself — you do not need Postal (or any other mail
addon) for looting. Postal can stay enabled for its mail *sending* features.

---

## Install

Copy the repository folder into your WoW AddOns directory so that the `.toc` sits at:

```
World of Warcraft/_classic_/Interface/AddOns/MailOpener/MailOpener.toc
```

Then restart the client (a reload is not enough after a first install, because the
localization files are declared in the TOC).

Ace3 and `!LibUIDropDownMenu` ship inside `Libs/` and are loaded via `embeds.xml`, so there
are no external dependencies.

### World of Warcraft: Forever

[World of Warcraft: Forever](https://news.blizzard.com/en-us/article/24302093/carve-a-new-path-with-world-of-warcraft-forever)
is Blizzard's official "Classic Plus" client (codename *Camelot*, build `1.60.1`, game type
`camelot`, TOC interface `16001`); Battle.net installs it as the `wow_classic_beta` product.
It runs the modern (retail-generation) API, so the same addon code targets it — only the
manifest differs:

* Install the folder into the Forever client's AddOns directory:
  `World of Warcraft/_classic_beta_/Interface/AddOns/MailOpener/`.
* The Forever loader picks `MailOpener_Camelot.toc` (`## Interface: 16001`); the retail
  client keeps using `MailOpener.toc`. Same code, same saved variables (`MailOpenerDB`).
* **Current limitation (beta 1.60.1):** Blizzard's mailbox UI (`Blizzard_MailFrame`) is
  only enabled for the retail client there (`AllowLoadGameType: mainline`), so the Forever
  client has no mailbox yet. Mail Opener detects the missing mailbox at load time, prints
  a notice in chat and disables itself instead of erroring. As soon as a mailbox UI ships
  in the Forever client, the addon is functional again without any code changes.
* Forever is indistinguishable from retail at runtime (same engine and UI,
  `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE`), so the small `Forever.lua` — listed only in
  `MailOpener_Camelot.toc` — sets the `MailOpenerIsForever` global at load time. That is
  the only reliable client signal (the same approach BetterBags uses for its
  `isForever` flag).
* **Known beta bug (1.60.1):** the Forever client writes SavedVariables on exit but
  never reads them back, so Mail Opener's settings (`MailOpenerDB`) reset to defaults
  every launch. That is a client bug, confirmed by several authors
  ([forever-addon-kit](https://github.com/Thunderz96/forever-addon-kit), EU forums);
  the addon itself works normally once a mailbox exists.

## Usage

| Action | Result |
| --- | --- |
| `/mo`, `/mailopen`, `/mailopener` | Slash commands (`/mo config` or `/mo c` opens the options) |
| Interface → AddOns → Mail Opener | Same options panel, registered at load |
| **Open all** button | Starts opening mail with your current filters |
| **Shift** + click Open all | Temporarily overrides filters: loots *every* mail with attachments/gold |
| **Right** click Open all | Quick drop-down to toggle the mail-opening filters for this profile |
| **Middle** click / **Alt** + click Open all | Interrupts an in-progress mail opening |
| Mailbox checkbox | Toggles automatic opening on/off for this visit |

`MailAddonBusy` is exposed globally: it is `nil` when nothing is happening and set to the
addon name while Mail Opener is working, so other mail addons can cooperate.

## Layout

```
Core.lua              Addon object, saved variables, mail frame widgets, copy popup
Utils.lua             C_Container / legacy container-API shims (MO_GetContainerItemInfo, …)
Forever.lua           Load-time MailOpenerIsForever flag — listed only in MailOpener_Camelot.toc
embeds.xml            Library loader
Localization/         enUS (default) + deDE esES esMX frFR koKR ruRU zhCN zhTW
Modules/              Feature modules (see below)
Libs/                 Ace3 + !LibUIDropDownMenu
```

## Modules

Every module can be toggled in the **Modules** config group; the setting is remembered
across sessions. Only `OpenAll` is required.

| Module | Required | What it does |
| --- | --- | --- |
| **OpenAll** | ✔ | The actual mail opening initiated by the core, plus the Open all button and the mail-count / time-remaining readout. |
| **Config** | | Builds the config frames and handles slash commands. Loaded on demand. |
| **Collected** | | Shows a summary of what was collected during the mailbox visit. |
| **FailSafe** | | Keeps opening going when a single mail gets stuck. |
| **Indicator** | | Shows/hides the minimap mail icon based on unread mail still waiting on the server, and rewrites its tooltip with the remaining count and the latest three senders. |
| **BeanCounterSupport** | | Blocks opening while BeanCounter is scanning. |

### The mailbox status text (OpenAll)

`OpenAll` builds a small frame, `MailOpenerTimeLeftButton`, parented to `InboxFrame` and
anchored to the top-left of the mail frame. It carries two font strings:

* `MailOpenerTimeLeftFrameMailCount` — how much mail is left to process.
* `MailOpenerTimeLeftFrameTimeRemaining` — the estimated time remaining, a 270px-wide
  left-justified label running left→right across the top of the mail frame.

The frame itself is an invisible, interactive click layer stacked on that text. Clicking it
strips the colour escape codes out of the time-remaining string and shows it in the
`MailOpenerCopyWindow` static popup, where **CTRL-C** copies it out. Hovering shows a
"Click to copy" tooltip (only while *Show help tooltips* is on in the general config).

**Hit area.** The label is far wider than it is tall, and a click layer spanning its full
width covered chunks of the mail frame underneath, eating clicks meant for Blizzard's own
UI. The layer is therefore deliberately smaller than the text:

* it was originally a 270×35 invisible block, then trimmed to 120×14;
* it is now **60×14, centred on the label** (`SetPoint("CENTER", MailFrame, "TOPLEFT", 135, -45)`)
  instead of anchored at the label's left edge.

So only clicking around the **middle** of the status text copies it — the left and right
thirds of the text are inert and pass through to whatever is behind them. If you want the
old, easier-to-hit behaviour, raise `frame:SetWidth(60)` in `Modules/OpenAll.lua` (and shift
the `CENTER` anchor's x-offset if you also want it off-centre).

## Notable behaviour

* Bag handling goes through `Utils.lua`, which prefers the `C_Container` API and falls back
  to the pre-10.0 globals, so the same code runs on Classic and retail-derived clients.
* On a client with no mailbox UI (e.g. the WoW Forever beta), the addon loads in a dormant,
  self-disabled state and re-activates by itself once a mailbox exists.
* Mail near the *keep free space* limit is partially looted rather than skipped entirely.
* Blizzard's `CheckInbox` is overridden (optional) to delay refreshes while mail remains.
* TradeSkillMaster's own Open All button is hidden so its text doesn't overlap.

## History

See [`Changelog.txt`](Changelog.txt) — it goes back to the v1.0.0 standalone rewrite
(September 2010) and the v1.2.x line.

## Credits

Zerotorescue — original author. Ace3 by the Ace3 team; `!LibUIDropDownMenu` by its
respective author (see `Libs/!LibUIDropDownMenu/Docs/`).
