# Troubleshooting

Each of these came up while getting this working. Game logs are in `steamapps/compatdata/244210/pfx/drive_c/users/steamuser/Documents/Assetto Corsa/logs`, mainly `custom_shaders_patch.log` and `log.txt`.

| What you see | Cause | Fix |
|---|---|---|
| The launcher window is black | WebView2's GPU process crashes on Wine's DirectComposition stub | Start the game through Steam so the wrapper can add the flags WebView2 needs |
| The launcher crashes at startup | The WebView2 runtime is missing | Rerun `./install.sh` |
| WebView2's installer says it requires Windows 10 | A Windows 7 override is applying to the installer | Remove any `AppDefaults` override for the installer, or use a fresh prefix |
| WebView2's installer fails from a long folder path | It doesn't cope with long paths | `install.sh` already runs it from `C:\` |
| "Sign in to Steam to join", though you're signed in | The prefix doesn't know the active Steam user | Rerun `./install.sh`, adding `--steam-id <SteamID64>` if it picked the wrong account |
| "Link your Steam account" | Your No Hesi account isn't linked yet | Link it in the launcher. It can take a little while to update |
| Launch options seem to be ignored | Steam overwrote a config file that was edited while it was running | Set them in Steam's own Properties window |
| "No symbols" dialog from Custom Shaders Patch | The symbol map is missing or from another game build | Run `./make-symbol-map.sh` |
| "TRACK NOT FOUND" | The launcher hasn't finished installing that content, or can't see the game folder | Start through Steam so the wrapper links the game folder, then let the launcher finish |
| `verdana.ttf` is missing | CSP's fonts aren't installed | Rerun `./install.sh` |
| "UI IMGUI final" failure or a 0x0 render target | `cfg/video.ini` doesn't exist | Rerun `./install.sh` |
| The world is blue or black, with no textures | The game is running on Proton Experimental (Wine 11) | Use Proton 10.0. Driver and weather settings didn't change this in testing |
| The whole desktop lags while playing | Uncapped frames starve the compositor | Start through Steam so the wrapper applies its frame cap, or lower `DXVK_FRAME_RATE` |
| "Failed to launch the race" | The game was started directly with an old `race.ini` | Join through the launcher |
| "You've been kicked for failing the security check" on Proton Experimental | Wine's signature checks have [known bugs there](https://github.com/ValveSoftware/Proton/issues/148) | Use Proton 10.0, where CSP's `dwrite.dll` passes the same check |
| "You're playing offline" | Still unsolved | See [offline status](offline-status.md) |
