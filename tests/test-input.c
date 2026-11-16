/* Host test for amiga/inp_amiga.c, with upstream's input/escseq.c: the
 * console's keys come out as vitetris's moves. The console is a buffer
 * (fake/proto/dos.h). Copyright (c) 2026 AmiCradle Team. BSD 2-clause. */
#include <stdio.h>
#include <string.h>
#include "input.h"
#include "termin.h"
#include "keyboard.h"

int inputdevs_fd[4] = {-1, -1, -1, -1};
static const unsigned char *con;
static long con_n, con_pos, mode = -1, mode_calls;

long SetMode(long fh, long m) { mode = m; mode_calls++; return 1; }
long WaitForChar(long fh, long usec) { return con_pos < con_n; }
long Read(long fh, void *buf, long len)
{
    if (con_pos >= con_n) return 0;
    *(unsigned char *)buf = con[con_pos++];
    return 1;
}
long Input(void) { return 1; }

static int fails;
static void feed(const char *s, long n) { con = (const unsigned char *)s; con_n = n; con_pos = 0; unreadchr = 0; }
static void key(const char *what, const char *in, long n, int want_len, int want0)
{
    unsigned char k[16] = {0};
    int len;
    feed(in, n);
    len = kb_readkey(k);
    if (len != want_len || k[0] != want0) {
        printf("FAIL: %s: got %d bytes, first %d; wanted %d, %d\n", what, len, k[0], want_len, want0);
        fails++;
    }
}

int main(void)
{
    unsigned char k[16];
    set_input_mode();
    if (mode != 1) { printf("FAIL: console not raw\n"); fails++; }
    /* the console's CSI (0x9B) arrow keys */
    key("CSI A", "\x9b" "A", 2, 1, MVUP);
    key("CSI B", "\x9b" "B", 2, 1, MVDOWN);
    key("CSI C", "\x9b" "C", 2, 1, MVRIGHT);
    key("CSI D", "\x9b" "D", 2, 1, MVLEFT);
    /* the same keys as ESC [ (a terminal over a serial line) */
    key("ESC [ D", "\033[D", 3, 1, MVLEFT);
    key("Return", "\r", 1, 1, '\n');
    key("Del", "\x7f", 1, 1, BACKSPACE);
    key("space", " ", 1, 1, ' ');
    key("letter", "q", 1, 1, 'q');
    /* a lone ESC (the console's Esc key) */
    key("Esc", "\033", 1, 1, ESC);
    /* no key: nothing, and inpselect_dev says none came */
    feed("", 0);
    if (kb_readkey(k) != 0) { printf("FAIL: a key out of nothing\n"); fails++; }
    if (inpselect_dev(10) != NUM_INPUTDEVS) { printf("FAIL: inpselect_dev with no key\n"); fails++; }
    feed("x", 1);
    if (inpselect_dev(10) != 0) { printf("FAIL: inpselect_dev with a key\n"); fails++; }
    /* kb_flushinp empties the console */
    feed("abc\x9b" "A", 5);
    kb_flushinp();
    if (con_pos != con_n || unreadchr) { printf("FAIL: kb_flushinp left keys\n"); fails++; }
    restore_input_mode();
    if (mode != 0) { printf("FAIL: console not back to cooked\n"); fails++; }
    restore_input_mode();
    if (mode_calls != 2) { printf("FAIL: SetMode called %ld times\n", mode_calls); fails++; }
    if (!fails) printf("input: all checks passed\n");
    return fails != 0;
}
