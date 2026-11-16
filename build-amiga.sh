#!/bin/sh
# Builds vitetris for GFOS (AmigaOS 3.2.3 with GFOpenUp, on the GFOpenKick
# ROM or a Kickstart) with a stove: 68040, soft float (it has no floating
# point), text in the Shell's console window. amiga/inp_amiga.c reads the
# keys in raw mode in place of the UNIX terminal input.
#   STOVE=.../stoves/os32-gcc16-open6 OUT=out ./build-amiga.sh
# vitetris is fetched at the commit vitetris.lock gives, with patches/ on
# it; nothing third-party is kept here.
# OUT gets Parts/vitetris: a GFOpenUp part (its Part file, the vitetris
# drawer for SYS:Games and its icons), installed with
#   GFOpenUpTool INSTALL Parts/vitetris
# and unpacked/Games, the same drawer for a lab copy.
# Copyright (c) 2026 AmiCradle Team. BSD 2-clause, like vitetris.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/vitetris.lock"
STOVE=${STOVE:-"$HOME/AmiCradle/kitchen/stoves/os32-gcc16-open6"}
if [ -x "$STOVE/prefix/bin/m68k-amigaos-gcc" ]; then TC="$STOVE/prefix"; else TC="$STOVE"; fi
# outside the checkout: Cradle cleans it (git clean -ffdx) before every job
WORK="${WORK:-$HOME/.cache/amigavitetris/build}"; OUT="${OUT:-$WORK/out}"
PATH="$TC/bin:$PATH"; export PATH
mkdir -p "$WORK" "$OUT"; OUT=$(cd "$OUT" && pwd)
t0=$(date +%s)

# --- vitetris at its pinned commit, with patches/ -----------------------------
SRC="$WORK/vitetris"
PSUM=$(cat "$HERE"/patches/*.patch | sha256sum | cut -c1-16)
if [ "$(cat "$SRC/.patched" 2>/dev/null)" != "$VT_COMMIT-$PSUM" ]; then
    rm -rf "$SRC"; mkdir -p "$SRC"
    git -C "$SRC" init -q
    git -C "$SRC" fetch -q --depth 1 "$VT_GIT" "$VT_COMMIT"
    git -C "$SRC" checkout -q FETCH_HEAD
    [ "$(git -C "$SRC" rev-parse HEAD)" = "$VT_COMMIT" ] || { echo "commit mismatch"; exit 1; }
    for p in "$HERE"/patches/*.patch; do
        patch -s -d "$SRC" -p1 < "$p" || { echo "patch failed: $p"; exit 1; }
    done
    echo "$VT_COMMIT-$PSUM" > "$SRC/.patched"
fi

# --- compile ----------------------------------------------------------------------
# The sources upstream's configure picks for the ANSI terminal with two
# players, no network, no joystick device, no X and no terminal resizing
# (tests/test-sources.sh checks this list against upstream's tree);
# inp_amiga.c takes the place of input/inp_unixterm.c and input/select.c.
SRCS="main.c cmdline.c cfgfile.c options.c hiscore.c lang.c timer.c focus.c
game/tetris.c game/tetris2p.c game/game.c game/wonlost.c
menu/menucore.c menu/dropdown.c menu/inputset.c menu/inputdev.c menu/gamemenu.c menu/gm_2p.c menu/gm_sock.c menu/hslist.c menu/gameover.c
menu/startup.c menu/invit.c menu/netplay.c menu/optsmenu.c menu/blockstyle.c menu/men_ansi.c
input/input.c input/keyboard.c input/joystick.c input/playerin.c input/escseq.c
draw/draw.c draw/draw_menu.c draw/draw2p.c draw/draw2p_menu.c
textgfx/block.c textgfx/win.c textgfx/print.c textgfx/ibmgfx.c textgfx/ansi.c textgfx/ansi_win.c textgfx/term.c"
CF="-noixemul -m68040 -O2 -fomit-frame-pointer -fno-tree-loop-distribute-patterns -w"
DEFS="-DTWOPLAYER=1"
O="$WORK/obj"; rm -rf "$O"; mkdir -p "$O"
OBJS=""
for f in $SRCS; do
    o="$O/$(echo "$f" | tr / _ | sed 's/\.c$/.o/')"
    m68k-amigaos-gcc $CF $DEFS -I"$SRC/src" -I"$SRC/src/input" -c "$SRC/src/$f" -o "$o"
    [ "$f" = main.c ] || OBJS="$OBJS $o"
done
m68k-amigaos-gcc $CF $DEFS -I"$SRC/src" -I"$SRC/src/input" -c "$HERE/amiga/inp_amiga.c" -o "$O/inp_amiga.o"
m68k-amigaos-gcc $CF -c "$HERE/amiga/amiga_start.c" -o "$O/amiga_start.o"
echo "compile: $(( $(date +%s) - t0 )) s"

# --- the link ---------------------------------------------------------------------
# Like upstream's Makefile, through an archive: the link takes only what is
# used, so the network menus (gm_sock.c, invit.c, netplay.c) drop out with
# no network code under them.
# shellcheck disable=SC2086
m68k-amigaos-ar rcs "$O/vitetris.a" $OBJS
m68k-amigaos-gcc -noixemul -m68040 -o "$O/vitetris.debug" "$O/main.o" "$O/inp_amiga.o" "$O/amiga_start.o" "$O/vitetris.a" > "$O/link.log" 2>&1 || { head -60 "$O/link.log"; exit 1; }

# --- the GFOpenUp part: Parts/vitetris ----------------------------------------------
P="$OUT/Parts/vitetris"; rm -rf "$P"; D="$P/Games/vitetris"; mkdir -p "$D"
m68k-amigaos-strip -o "$D/vitetris" "$O/vitetris.debug"
cp "$HERE/README.md" "$D/ReadMe"
cp "$SRC/licence.txt" "$D/Licence.txt"
cp "$SRC/README" "$D/vitetris.txt"
I="$HERE/amiga/icons"
cp "$I/vitetris.info" "$D/vitetris.info"
for f in ReadMe Licence.txt vitetris.txt; do cp "$I/ReadMe.info" "$D/$f.info"; done
cp "$I/vitetris-drawer.info" "$P/Games/vitetris.info"
sh "$HERE/scripts/write-part.sh" "$P" "$VT_VERSION"
rm -rf "$OUT/unpacked"; mkdir -p "$OUT/unpacked"; cp -R "$P/Games" "$OUT/unpacked/"
ls -l "$D/vitetris"
echo "part: $(grep -c '^copy' "$P/Part") files, $(du -sk "$P" | cut -f1) KB"
echo "total: $(( $(date +%s) - t0 )) s"
