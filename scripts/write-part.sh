#!/bin/sh
# Writes the Part file GFOpenUpTool INSTALL reads (gfopenup src/openuptool.c):
# one "copy" line per file under the part drawer, each to SYS:<its path>.
#   write-part.sh <part drawer> <version>
# Copyright (c) 2026 AmiCradle Team. BSD 2-clause, like vitetris.
set -eu
P=$1; V=$2
{
    echo "part vitetris $V"
    echo "; vitetris: text-mode Tetris for one or two players, in a console window"
    echo "needs 68040"
    (cd "$P" && find Games -type f ! -name Part | LC_ALL=C sort) | while read -r f; do
        echo "copy \"$f\" \"SYS:$f\""
    done
} > "$P/Part"
