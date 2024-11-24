# Notes about the Colecovision Super Game Module by Opcode Games.

There is a pretty good write-up of what the Super Game Module is
[here](https://www.colecovision.dk/sem.htm?refreshed).  These here
are notes about how a future "CoPicoVision-SGM" that includes all
of the SGM functionality might work.

The base ColecoVision has 1K of RAM located at $6000 which is only
partially-decoded (A0-A9 are connected to the 2114s, A13-A15 are
connected to the 74LS138 that does memory address decoding).  The
CoPicoVision mimics this behavior -- only A0-A9 are connected to
the 6C6264 SRAM; the upper 7KB are unused.

The SGM allows for up to 32KB of RAM.  When enabled, $2000 - $7FFF
map to RAM.

The base ColecoVision also maps the ROM into $0000 - $2000.  The SGM
also allows for the ROM to be disabled and this bottom 8KB to be mapped
to RAM, which gives a total of 32KB (the bottom half of the address space
before the cartridge area).

We could easily implement this on the CoPicoVision with a few small
changes:
* Define an XRAMEN signal that, when asserted, enables the extended RAM.
* Define a ROMDIS signal that, when asserted, disables reading the ROM.
* Replace the 6C6264 with a 6C62256, giving us 32KB of RAM total.
* Addition of a mux for RAM address lines A10 - A14.
* Changes to the address decoding logic.

More thoughts to come...
