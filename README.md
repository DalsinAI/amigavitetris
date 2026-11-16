vitetris for GFOS
=================

A port of vitetris 0.59.1, Victor Geraldsson's text-mode Tetris, from
https://github.com/vicgeralds/vitetris at commit
744b5090a6d1315cd7b818e5276ed90ba0f3df23, for GFOS: AmigaOS 3.2 with
GFOpenUp, on a 68040 or 68060. It plays in a Shell or console window:
one player, or two players side by side on one keyboard.

Status: built with the os32-gcc16-open6 stove; not yet run in a lab.


What you need
-------------

- GFOS: AmigaOS 3.2 with GFOpenUp. No GFOpenGPU: it is all text.
- A 68040 or 68060 and a console window of at least 80 x 20 characters.


Installing
----------

The release is a GFOpenUp part:

    GFOpenUpTool INSTALL Parts/vitetris

puts the vitetris drawer in SYS:Games. GFOpenUpTool REMOVE Parts/vitetris
takes it out again. Double-click vitetris (it opens its own console
window), or from a Shell:

    cd SYS:Games/vitetris
    vitetris

The options and the high scores are kept in the drawer, in vitetris.cfg
and vitetris-hiscores. vitetris -help lists its command-line options.


Playing
-------

The arrow keys move (up turns the piece), space drops it, Return starts
and pauses; Esc leaves a menu. With two players the second plays on
keys of their own (Options shows and changes them). vitetris.txt in the
drawer is upstream's own read-me.


Building
--------

    STOVE=/path/to/os32-gcc16-open6 OUT=out ./build-amiga.sh

or, in Cradle, stove_build with the os32-gcc16-open6 stove and target "."
(build-amiga.sh). It fetches vitetris at the commit vitetris.lock pins,
puts patches/ on it, builds the sources upstream's configure picks for an
ANSI terminal with two players (no network, joystick device, X or
terminal resizing) with amiga/inp_amiga.c for the keys, and writes
OUT/Parts/vitetris (the part: its Part file, Games/vitetris.info and the
Games/vitetris drawer) and OUT/unpacked/Games (the same drawer, for a lab
copy). make -C tests test runs the host tests: the Part file; that every
patch applies, with the Amiga paths and cursor codes and the source list
matching upstream's tree; and inp_amiga.c with upstream's escseq.c on a
pretend console (the console's arrow keys, Return, Del and Esc).


What was changed
----------------

- amiga/inp_amiga.c takes the place of the UNIX terminal input
  (input/inp_unixterm.c and input/select.c, termios and select()): the
  console goes to raw mode with SetMode(), WaitForChar() waits for a key
  with a timeout and Read() takes it. The console sends the arrow keys as
  CSI (0x9B) A to D; they reach upstream's escseq.c as ESC [ A to D.
- patches/0001: the options go to PROGDIR:vitetris.cfg and the high
  scores to PROGDIR:vitetris-hiscores instead of $HOME/.vitetris and
  /var/games.
- patches/0002: the console's own codes to hide and show the cursor.
- amiga/amiga_start.c: a 64 KB stack, the version string and the console
  window it opens when started from its icon.
- The icons (amiga/icons) are GlowIcons made with amicradle's
  scripts/ports/port_icons.py from three falling blocks drawn for this
  port.


Licences
--------

vitetris is under a BSD 2-clause licence (Licence.txt in the drawer).
The Amiga files here are The AmiCradle Team's, under the same licence
(LICENSE).

Designed, tested and delivered by The AmiCradle Team.
