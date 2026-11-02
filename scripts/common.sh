# Shared by install.sh and make-symbol-map.sh: finds Steam, the game and Proton.

APPID=244210
STEAM_ROOT=${STEAM_ROOT:-$HOME/.local/share/Steam}
STATE=$HOME/.local/share/nohesi-launcher
REPO=$(dirname "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")")

die() { echo "error: $*" >&2; exit 1; }
step() { printf '\n==> %s\n' "$*"; }

# Prints every Steam library folder, one per line.
libraries() {
    echo "$STEAM_ROOT"
    grep -E '^\s*"path"' "$STEAM_ROOT/steamapps/libraryfolders.vdf" 2>/dev/null |
        sed -E 's/^\s*"path"\s*"(.*)"\s*$/\1/'
}

# Prints the library Assetto Corsa is installed in.
find_game_library() {
    local lib
    while read -r lib; do
        if [ -f "$lib/steamapps/appmanifest_$APPID.acf" ]; then
            echo "$lib"
            return 0
        fi
    done < <(libraries)
    return 1
}

# Prints the folder of a Proton version, such as "Proton 10.0", from any library.
find_proton() {
    local lib dir
    while read -r lib; do
        for dir in "$lib/steamapps/common/$1"*; do
            if [ -x "$dir/proton" ]; then
                echo "$dir"
                return 0
            fi
        done
    done < <(libraries)
    return 1
}
