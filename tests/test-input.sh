#!/bin/sh
# Host test: amiga/inp_amiga.c with upstream's input/escseq.c at the commit
# vitetris.lock pins: the console's keys (CSI arrows, Return, Del, Esc) come
# out as vitetris's moves. Needs git, cc and the network (GitHub).
# Copyright (c) 2026 AmiCradle Team. BSD 2-clause, like vitetris.
set -eu
HERE=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$HERE/../vitetris.lock"
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
git -C "$T" init -q
git -C "$T" fetch -q --depth 1 "$VT_GIT" "$VT_COMMIT"
git -C "$T" checkout -q FETCH_HEAD
I="$T/src/input"
cc -w -DTWOPLAYER=1 -I"$HERE/fake" -I"$I" -I"$T/src" -o "$T/test-input" \
    "$HERE/test-input.c" "$HERE/../amiga/inp_amiga.c" "$I/escseq.c"
"$T/test-input"
