#!/bin/bash
# Sets up the No Hesi Launcher in Assetto Corsa's Proton 10 prefix. Safe to run again: finished steps are skipped.
# Usage: ./install.sh [--resolution 1920x1080@60] [--steam-id <SteamID64>]
set -u
source "$(dirname "$(readlink -f "$0")")/scripts/common.sh"

RESOLUTION=1920x1080@60
STEAM_ID=
while [ $# -gt 0 ]; do
    case "$1" in
        --resolution) RESOLUTION=${2:-}; shift 2 ;;
        --steam-id) STEAM_ID=${2:-}; shift 2 ;;
        -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
        *) die "unknown option: $1" ;;
    esac
done
[[ $RESOLUTION =~ ^([0-9]+)x([0-9]+)@([0-9]+)$ ]] || die "--resolution must look like 1920x1080@60"
WIDTH=${BASH_REMATCH[1]} HEIGHT=${BASH_REMATCH[2]} REFRESH=${BASH_REMATCH[3]}

for tool in python3 curl unzip winetricks x86_64-w64-mingw32-gcc; do
    command -v "$tool" >/dev/null || die "$tool is missing; install it with your package manager"
done

LIB=$(find_game_library) || die "Assetto Corsa isn't installed in any Steam library under $STEAM_ROOT"
P10=$(find_proton "Proton 10.0") || die "Proton 10.0 isn't installed; get it from Steam's Tools list"
PREFIX=$LIB/steamapps/compatdata/$APPID
C=$PREFIX/pfx/drive_c
GAME=$LIB/steamapps/common/assettocorsa
DOC="$C/users/steamuser/Documents/Assetto Corsa"
CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/nohesi-linux
LAUNCHER="$C/users/steamuser/AppData/Local/NoHesi Launcher/NoHesiLauncher.exe"
WV_ROOT="$C/Program Files (x86)/Microsoft/EdgeWebView/Application"

if [ ! -d "$C/users/steamuser" ]; then
    die "the game's Proton prefix doesn't exist yet. Set the game to Proton 10.0 in Steam, start it once, then quit"
fi
case "$(cat "$PREFIX/version" 2>/dev/null)" in
    10.*) ;;
    *) die "the game's prefix wasn't made by Proton 10 (found: $(cat "$PREFIX/version" 2>/dev/null)). See step 2 of the README" ;;
esac
if pgrep -f '^[CZ]:.*[a]cs\.exe' >/dev/null; then
    die "Assetto Corsa is running; close it first"
fi

in_prefix() {
    timeout 480 env -u SteamAppId -u SteamGameId STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAM_ROOT" STEAM_COMPAT_DATA_PATH="$PREFIX" \
        "$P10/proton" run "$@" >/dev/null 2>&1
}
stop_prefix() { WINEPREFIX="$PREFIX/pfx" "$P10/files/bin/wineserver" -k 2>/dev/null; sleep 2; }
fetch() { # url, file name in the download cache
    [ -s "$CACHE/$2" ] && return
    mkdir -p "$CACHE"
    curl -fL --retry 3 -A 'Mozilla/5.0' -o "$CACHE/$2.part" "$1" || die "couldn't download $1"
    mv -f "$CACHE/$2.part" "$CACHE/$2"
}
webview2_installed() { compgen -G "$WV_ROOT/[0-9]*/msedgewebview2.exe" >/dev/null; }

step "WebView2 runtime"
if webview2_installed; then
    echo "already installed"
else
    fetch 'https://go.microsoft.com/fwlink/?linkid=2124701' MicrosoftEdgeWebView2RuntimeInstallerX64.exe
    # The installer fails on long paths, so it runs from the root of C:. Its updater never exits by itself.
    cp "$CACHE/MicrosoftEdgeWebView2RuntimeInstallerX64.exe" "$C/wv2setup.exe"
    in_prefix 'C:\wv2setup.exe' /silent /install &
    SETUP=$!
    for _ in $(seq 1 420); do webview2_installed && break; sleep 1; done
    # The files appear before the installer has finished, so give it time to finish by itself.
    for _ in $(seq 1 90); do kill -0 "$SETUP" 2>/dev/null || break; sleep 1; done
    stop_prefix
    wait "$SETUP"
    rm -f "$C/wv2setup.exe"
    webview2_installed || die "WebView2 didn't install"
    echo "installed"
fi
WV_VERSION=$(ls "$WV_ROOT" | grep -E '^[0-9]+\.' | sort -V | tail -1)

step "No Hesi Launcher"
if [ -f "$LAUNCHER" ]; then
    echo "already installed"
else
    fetch 'https://cdn.nohesi.gg/assets/launcher/NoHesiLauncher-Setup.exe' NoHesiLauncher-Setup.exe
    cp "$CACHE/NoHesiLauncher-Setup.exe" "$C/nohesi-setup.exe"
    in_prefix 'C:\nohesi-setup.exe' /VERYSILENT /SUPPRESSMSGBOXES /NORESTART
    stop_prefix
    rm -f "$C/nohesi-setup.exe"
    [ -f "$LAUNCHER" ] || die "the launcher didn't install; its download link may have changed, see https://nohesi.gg/launcher"
    echo "installed"
fi

step "Registry settings"
if [ -z "$STEAM_ID" ]; then
    STEAM_ID=$(python3 -I - "$STEAM_ROOT/config/loginusers.vdf" <<'EOF'
import re, sys
text = open(sys.argv[1], errors="replace").read()
users = re.findall(r'"(7656\d{13})"\s*\{(.*?)\}', text, re.S)
stamp = lambda body: int((re.search(r'"timestamp"\s*"(\d+)"', body, re.I) or [0, 0])[1])
print(max(users, key=lambda u: stamp(u[1]))[0] if users else "")
EOF
    )
    [ -n "$STEAM_ID" ] || die "couldn't work out your Steam account; pass --steam-id <SteamID64>"
    echo "using the most recent Steam login, $STEAM_ID. If that's not the account that owns the game, rerun with --steam-id"
fi
[[ $STEAM_ID =~ ^7656[0-9]{13}$ ]] || die "--steam-id must be a 17-digit SteamID64"
ACCOUNT_HEX=$(printf '%08x' $((STEAM_ID - 76561197960265728)))
sed -e "s/@WEBVIEW2_VERSION@/$WV_VERSION/" -e "s/@STEAM_ACCOUNT_HEX@/$ACCOUNT_HEX/" "$REPO/patches/prefix-settings.reg" > "$C/nohesi-settings.reg"
in_prefix regedit /S 'C:\nohesi-settings.reg'
sleep 3
stop_prefix
rm -f "$C/nohesi-settings.reg"
grep -q 'AppDefaults\\\\msedgewebview2.exe' "$PREFIX/pfx/user.reg" || die "the registry settings weren't applied"
echo "applied"

step "Microsoft shader compiler"
if grep -qs '^d3dcompiler_47$' "$PREFIX/pfx/winetricks.log"; then
    echo "already installed"
else
    WINEPREFIX="$PREFIX/pfx" WINE="$P10/files/bin/wine" WINESERVER="$P10/files/bin/wineserver" WINEDEBUG=-all \
        winetricks -q d3dcompiler_47 >/dev/null 2>&1 || die "winetricks d3dcompiler_47 failed"
    stop_prefix
    echo "installed"
fi

step "Fonts Custom Shaders Patch expects"
if [ -f "$GAME/content/fonts/system/verdana.ttf" ]; then
    echo "already installed"
else
    fetch 'https://acstuff.club/u/blob/ac-fonts.zip' ac-fonts.zip
    mkdir -p "$GAME/content/fonts"
    unzip -qo "$CACHE/ac-fonts.zip" 'system/*' -d "$GAME/content/fonts/" || die "couldn't unpack the fonts"
    echo "installed"
fi

step "Game video settings"
if [ -f "$DOC/cfg/video.ini" ]; then
    echo "kept your existing video.ini"
else
    mkdir -p "$DOC/cfg"
    sed -e "s/@WIDTH@/$WIDTH/" -e "s/@HEIGHT@/$HEIGHT/" -e "s/@REFRESH@/$REFRESH/" -e "s/@FULLSCREEN@/1/" \
        "$REPO/patches/video.ini" > "$DOC/cfg/video.ini"
    echo "wrote video.ini for $RESOLUTION"
fi

step "Launch wrapper"
mkdir -p "$STATE" "$HOME/.local/bin"
printf '%s\n' "$LIB" > "$STATE/library"
x86_64-w64-mingw32-gcc -municode -mwindows -O1 -s -o "$STATE/webview2-flags.exe" "$REPO/patches/webview2-flags.c" || die "couldn't build webview2-flags.c"
cp "$REPO/scripts/nohesi-launcher" "$HOME/.local/bin/nohesi-launcher"
chmod +x "$HOME/.local/bin/nohesi-launcher"
echo "installed $HOME/.local/bin/nohesi-launcher"

cat <<EOF

Done. Next:
  1. In Steam, open Assetto Corsa > Properties > General, and set Launch Options to:
       $HOME/.local/bin/nohesi-launcher %command%
  2. Press Play. Sign in to No Hesi, link your Steam account, and let the launcher install its content.
  3. Close the launcher and run: $REPO/make-symbol-map.sh
  4. Press Play again and join a server.
EOF
