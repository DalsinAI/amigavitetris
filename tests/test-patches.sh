#!/bin/sh
# Host test: every patch in patches/ applies to vitetris at the commit
# vitetris.lock pins; on AmigaOS the options and high scores go to PROGDIR:
# and the console's own cursor codes are sent; the build's source list
# matches upstream's tree (what its configure builds for the ANSI terminal,
# less the network, joystick device, X and resizing code). Needs git and
# the network (GitHub). Copyright (c) 2026 AmiCradle Team. BSD 2-clause.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../vitetris.lock"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
git -C "$T" init -q
git -C "$T" fetch -q --depth 1 "$VT_GIT" "$VT_COMMIT"
git -C "$T" checkout -q FETCH_HEAD
for p in "$HERE"/../patches/*.patch; do
    patch -s -d "$T" -p1 --dry-run < "$p" >/dev/null || { echo "FAIL: $p does not apply"; exit 1; }
    patch -s -d "$T" -p1 < "$p"
done
S="$T/src"
grep -q '"PROGDIR:vitetris.cfg"' "$S/config2.h" || { echo "FAIL: options not in PROGDIR:"; exit 1; }
grep -q '"PROGDIR:vitetris-hiscores"' "$S/config2.h" || { echo "FAIL: high scores not in PROGDIR:"; exit 1; }
grep -q '\\033\[0 p' "$S/textgfx/ansi.c" || { echo "FAIL: no console cursor-off code"; exit 1; }
# The AmigaOS build takes no HOME or passwd file: preprocess as the stove would.
cc -E -D__amigaos__ -DTWOPLAYER=1 -I"$S" "$S/cfgfile.c" 2>/dev/null | grep -q 'getpwuid' && { echo "FAIL: cfgfile.c still asks the passwd file on AmigaOS"; exit 1; }
# Upstream's own Unix build is unchanged.
cc -E -DTWOPLAYER=1 -I"$S" "$S/cfgfile.c" 2>/dev/null | grep -q 'getpwuid' || { echo "FAIL: cfgfile.c lost its UNIX code"; exit 1; }
SRCS=$(sed -n '/^SRCS="/,/"$/p' "$HERE/../build-amiga.sh" | tr -d '"' | sed 's/^SRCS=//')
for f in $SRCS; do
    [ -f "$S/$f" ] || { echo "FAIL: no src/$f upstream"; exit 1; }
done
# what upstream's ANSI build has that this one leaves out, and why
LEFT="input/inp_unixterm.c input/select.c"   # amiga/inp_amiga.c instead
for d in game menu draw textgfx input; do
    for f in $(cd "$S" && ls $d/*.c); do
        echo "$SRCS" | tr ' ' '\n' | grep -qxF "$f" && continue
        case " $LEFT " in *" $f "*) continue ;; esac
        case "$f" in
        input/inp_allegro.c|input/inp_con.c|input/inp_curses.c|input/joylinux.c) continue ;;  # other front ends, Linux joystick
        textgfx/allegro*.c|textgfx/curses*.c|menu/men_allegro.c|menu/men_curses.c) continue ;;  # other front ends
        textgfx/resize.c) continue ;;                                                          # terminal resizing (SIGWINCH)
        esac
        echo "FAIL: src/$f neither built nor left out on purpose"; exit 1
    done
done
echo "patches: all apply, PROGDIR: paths, console cursor, sources match"
