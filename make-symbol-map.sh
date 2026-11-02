#!/bin/bash
# Generates the symbol map Custom Shaders Patch needs on Proton 10. Proton 10 can't read acs.pdb but Proton 9 can,
# so the game runs once under Proton 9 in a throwaway prefix. Run it again after an Assetto Corsa update.
set -u
source "$(dirname "$(readlink -f "$0")")/scripts/common.sh"

LIB=$(find_game_library) || die "Assetto Corsa isn't installed in any Steam library under $STEAM_ROOT"
P9=$(find_proton "Proton 9.0") || die "Proton 9.0 isn't installed; get it from Steam's Tools list"
GAME=$LIB/steamapps/common/assettocorsa
TMP=$LIB/nohesi-symbol-map-prefix
MAP=$GAME/cache/memory_layout.bin

[ -f "$GAME/dwrite.dll" ] || die "Custom Shaders Patch isn't installed yet; let the launcher install its content first"
if pgrep -f '^[CZ]:.*[a]cs\.exe' >/dev/null; then
    die "Assetto Corsa is running; close it first"
fi

export STEAM_COMPAT_CLIENT_INSTALL_PATH=$STEAM_ROOT STEAM_COMPAT_DATA_PATH=$TMP SteamAppId=$APPID SteamGameId=$APPID
export WINEDLLOVERRIDES="dwrite=n,b" PROTON_USE_XALIA=0

finish() {
    WINEPREFIX="$TMP/pfx" "$P9/files/bin/wineserver" -k 2>/dev/null
    sleep 2
    rm -rf "$TMP"
    if [ ! -f "$MAP" ] && [ -f "$MAP.previous" ]; then
        mv -f "$MAP.previous" "$MAP"
    fi
    rm -f "$MAP.previous"
}
trap finish EXIT

step "Preparing a temporary Proton 9 prefix"
rm -rf "$TMP"
mkdir -p "$TMP"
cd "$GAME" || exit 1
timeout 180 "$P9/proton" run cmd /c exit >/dev/null 2>&1
DOC="$TMP/pfx/drive_c/users/steamuser/Documents/Assetto Corsa"
mkdir -p "$DOC/cfg"
sed -e 's/@WIDTH@/1280/' -e 's/@HEIGHT@/720/' -e 's/@REFRESH@/60/' -e 's/@FULLSCREEN@/0/' "$REPO/patches/video.ini" > "$DOC/cfg/video.ini"
cp "$REPO/patches/symbol-map-race.ini" "$DOC/cfg/race.ini"

step "Running the game once. A window may open; leave it alone, it closes by itself"
mkdir -p "$GAME/cache"
[ -f "$MAP" ] && mv -f "$MAP" "$MAP.previous"
"$P9/proton" run "$GAME/acs.exe" >/dev/null 2>&1 &
for _ in $(seq 1 300); do
    [ -s "$MAP" ] && break
    sleep 1
done
mkdir -p "$STATE"
if [ ! -s "$MAP" ]; then
    cp "$DOC/logs/custom_shaders_patch.log" "$STATE/symbol-map-csp.log" 2>/dev/null
    die "no symbol map appeared after 5 minutes. Custom Shaders Patch's log, if it wrote one, is at $STATE/symbol-map-csp.log"
fi
sleep 5

cp "$MAP" "$STATE/memory_layout.bin"
step "Symbol map saved. You can start the game from Steam now"
