-- This file is listed ONLY in MailOpener_Camelot.toc, so it loads only on
-- the World of Warcraft: Forever (Camelot) client - never on retail or the
-- classic clients.
--
-- At runtime that client is indistinguishable from retail: same engine and
-- UI, WOW_PROJECT_ID == WOW_PROJECT_MAINLINE, GetBuildInfo() 1.60.1/16001.
-- No runtime API check can tell the two apart, so this load-time flag is
-- the only reliable way for the addon code to know it runs on Forever
-- (the same approach BetterBags uses for its isForever flag).
MailOpenerIsForever = true;
