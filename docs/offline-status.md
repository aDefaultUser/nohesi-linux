# "You're playing offline"

**Status: not solved.** You can join and drive, but the HUD says "You're playing offline" and "unable to get leaderboard data", and scores aren't submitted. Other Linux players report the same message in [CSP issue #609](https://github.com/ac-custom-shaders-patch/acc-extension-config/issues/609).

## What happens

- The in-game chat works and shows your correct No Hesi username.
- No Hesi's server rejects the game's separate score login with "Auth failed", and the game keeps retrying.
- The game log then reports `Run ended (offline)` and resets the score locally.

## Ruled out

Each of these was tested on Proton 10:

| Possible cause | Test | Result |
|---|---|---|
| CSP's signature check failing, as in [Proton #148](https://github.com/ValveSoftware/Proton/issues/148) | Ran `WinVerifyTrust` on the game's files | CSP's real `dwrite.dll` passes and a tampered copy fails, as they should |
| Wine damaging websocket messages | Sent test messages through Wine's winhttp to a local server | All arrived unchanged |
| The `WIN10_LISTENER` crash in CSP's log, blamed in issue #609 | Inspected `AcTools.CurrentlyPlaying.exe`, CSP's helper behind it | It's a now-playing media helper with no Steam or login code, so it's unlikely to be involved |
| Wrong Steam account | Checked `race.ini` and the game log | Both had the right account, and it's linked in No Hesi |
| Clock drift | Checked NTP and the server's `Date` header | They match |

## Not tested

- **The DLL overrides suggested in issue #609** (`wininet`, `iertutil`, `winhttp`). CSP's binary doesn't mention `wininet`, so that part looks unlikely to help, and the issue's author reports no success with native versions.
- **Whether the server's check depends on something Wine reports differently.** This is unknown, and it could turn out to be a check that only No Hesi can explain.

## Please don't

Don't try to fake the login, or to break the encrypted scripts to get scores through. That could get your account banned, and it wouldn't be a real fix.

## If you get it working

Please open an issue with your distro, GPU, Proton version and what you changed.
