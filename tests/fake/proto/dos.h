/* Host test stand-in for <proto/dos.h>: the console is a buffer of bytes
 * (test-input.c fills it), so inp_amiga.c can be run on the host. */
#ifndef FAKE_PROTO_DOS_H
#define FAKE_PROTO_DOS_H
typedef long BPTR;
typedef long LONG;
LONG SetMode(BPTR fh, LONG mode);
LONG WaitForChar(BPTR fh, LONG usec);
LONG Read(BPTR fh, void *buf, LONG len);
BPTR Input(void);
#endif
