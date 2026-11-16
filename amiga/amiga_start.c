/* The Amiga port's stack, version string and console window.
 * Copyright (c) 2026 AmiCradle Team. BSD 2-clause, like vitetris. */

unsigned long __stack = 64 * 1024;
static const char version[] __attribute__((used)) =
    "$VER: vitetris 0.59.1 (16.11.2026)";

/* Started from its Workbench icon, vitetris plays in this console window:
 * 80 columns and 25 lines of the default font with room to spare. */
char *__stdiowin = "CON:20/30/720/480/vitetris/CLOSE/WAIT";
