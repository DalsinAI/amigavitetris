/* vitetris keyboard input on an AmigaOS console (the Shell window that
 * started it), in place of inp_unixterm.c and select.c: the console goes
 * to raw mode (SetMode), WaitForChar() waits for a key with a timeout and
 * Read() takes it. The console sends the arrow keys as CSI (0x9B) A..D,
 * which reach escseq.c as ESC [ A..D, the same as on a UNIX terminal.
 * Copyright (c) 2026 AmiCradle Team. BSD 2-clause, like vitetris. */
#include <string.h>
#include <stdlib.h>	/* atexit */
#include <proto/dos.h>
#include "termin.h"
#include "keyboard.h"
#include "escseq.h"
#include "input.h"

#define CSI 0x9B

char unreadchr = '\0';
static int raw_on;

void set_input_mode()
{
	if (!raw_on && SetMode(Input(), 1))
		raw_on = 1;
	atexit(free_escape_sequences);
}

void restore_input_mode()
{
	if (raw_on) {
		SetMode(Input(), 0);
		raw_on = 0;
	}
}

/* 1 when a key is waiting, within msec milliseconds */
int waitinput_stdin(unsigned msec)
{
	if (unreadchr)
		return 1;
	return WaitForChar(Input(), 1000L * msec) ? 1 : 0;
}

int readchr()
{
	unsigned char c;
	int ret;
	if (unreadchr) {
		ret = (unsigned char) unreadchr;
		unreadchr = '\0';
		return ret;
	}
	if (!WaitForChar(Input(), 0))
		return 0;
	if (Read(Input(), &c, 1) != 1)
		return 0;
	if (c == CSI) {		/* ESC [ for escseq.c */
		unreadchr = '[';
		return ESC;
	}
	return c;
}

void init_keybd()
{
	inputdevs_fd[0] = 0;
}

int kb_readkey(unsigned char *dest)
{
	int c = readchr();
	if (!c)
		return 0;
	if (c == ESC)
		switch (c = readescseq((char *) dest+1)) {
		case -1:
			return 0;
		case 0:
			dest[0] = ESC;
			return strlen((char *) dest);
		}
	else if (c == DEL)
		c = BACKSPACE;
	else if (c == '\r')
		c = '\n';
	*dest = c;
	return 1;
}

int kb_toascii(const unsigned char *key)
{
	return ESC+1;
}

void kb_flushinp()
{
	while (readchr())
		;
}

const char *kb_keyname(unsigned char *key, int n)
{
	if (n < 2)
		return NULL;
	memmove(key+3, key+1, n);
	memcpy(key, "ESC", 3);
	return (const char *) key;
}

/* the keyboard (0) when a key comes within tm milliseconds, else none */
int inpselect_dev(int tm)
{
	return waitinput_stdin(tm > 0 ? tm : 0) ? 0 : NUM_INPUTDEVS;
}
