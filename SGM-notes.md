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
map to RAM, which astute readers will note is 24KB.

The base ColecoVision also maps the ROM into $0000 - $2000.  The SGM
also allows for the ROM to be disabled and this bottom 8KB to be mapped
to RAM, which gives a total of 32KB (the bottom half of the address space
before the cartridge area).

We could easily implement this on the CoPicoVision with a few small
changes:
* Define an XRAMEN signal that, when asserted, enables the extended RAM.
  This signal should default to de-asserted at reset.
* Define a ROMEN signal that, when asserted, enables reading the ROM.
  This signal should default to asserted at reset.
* Replace the 6C6264 with a 6C62256, giving us 32KB of RAM total.
* Changes to the address decoding logic.

Now would the address lines to the 6C2256 be connected and how would the
decoding work?  The CoPicoVision asserts /RAMSEL when A13 and A14 are high
and A15 is low.  Since A13 and A14 are a fixed value when XRAMEN is not
asserted, we don't need to mux those -- they can simply be connected
directly to the RAM chip, and only the lower 1KB of the upper 8KB of the
chip will be used.  A0-A9 can also be connected directly, as they are in
the standard configuration.  We just need to deal with A10-A12.  When
XRAMEN is disabled, we want A10-A12 to be fixed low so that we get the
mirroring behavior of the original circuit.  But when XRAMEN is enabled,
we want A10-A12 to be passed through from the Z80.  This is super easy
to do with just a 74HCT08 quad-AND chip:

       A10 --+
             +-- AND -> RA10
    XRAMEN --+

       A11 --+
             +-- AND -> RA11
    XRAMEN --+

       A12 --+
             +-- AND -> RA12
    XRAMEN --+

Thinking about the ROM and the RAM trapped "beneath" it... it seems like
it would be handy to write to that RAM even when the ROM is enabled.  This
would enable game code to copy the ROM if desired, or let game code otherwise
initialize that RAM before disabling the ROM.  This is pretty easy to do; we
can add the /RD signal as an input to the MEMDEC GAL.

So, how do we want to generate the XRAMEN and ROMEN signals?  In the SGM,
extended RAM is enabled by writing 0b00000001 to port $53.  Because of
the need to maintain Adam compatibility, the SGM has this to say about
disabling the ROM:
* Write 0b00001111 to port $7F to enable the ROM.
* Write 0b00001101 to port $7F to disable the ROM.

Obviously the ROM needs to default to "enabled" at reset.

Also, we're not an Adam, so we don't particularly need all of the bits
in those registers.  I am pretty sure the registers themselves are also
write-only, so there's not even any real need to fully emulate them.

This sounds like a perfect situation for a 74HCT74: dual D-type
positive-edge-triggered flip-flops with Clear and Preset.  Each flip-flop
is completely independent, with its own /CLR and /PRE inputs.  So we
can use them as follows:
* FF1's D input is connected to D0, Q output connected to XRAMEN,
/PRE input connected to Vcc, and /CLR input connected to /RESET.
* FF2's D input is connected to D1, Q output connected to ROMEN,
/PRE input connected to /RESET, and /CLR input connected to Vcc.

Each FF would get a clock input from the IODEC address decoder, call them
/FF1SEL and /FF2SEL for now.

The base CoPicoVision MEMDEC GAL has the following connections:

    CLK M1 /MREQ   /RFSH      A13       A14      A15      NC     NC NC  NC     GND
    NC  NC  M1WAIT /CRTESEL  /CRTCSEL  /CRTASEL /CRT8SEL /RAMSEL NC NC /ROMSEL VCC

We know we need to add /RD, XRAMEN, and ROMEN as inputs.  Unfortunately,
there aren't enough available outputs to use the MEMDEC GAL for A10-A12,
so we'll have to add a 74HCT08 to the board.

So, with that in mind, here's what the new GAL equations for /ROMSEL and
/RAMSEL could look like:

    CLK M1 /MREQ   /RFSH      A13       A14      A15     /RD     XRAMEN ROMEN  NC     GND
    NC  NC  M1WAIT /CRTESEL  /CRTCSEL  /CRTASEL /CRT8SEL /RAMSEL NC     NC    /ROMSEL VCC

    ROMSEL   = /A15 * /A14 * /A13 * MREQ * /RFSH *  RD *  ROMEN ; ROM reads, ROM enabled
    RAMSEL   = /A15 * /A14 * /A13 * MREQ * /RFSH *  RD * /ROMEN ; ROM reads, ROM disabled
             + /A15 * /A14 * /A13 * MREQ * /RFSH * /RD          ; ROM writes
             + /A15 * /A14 *  A13 * MREQ * /RFSH * XRAMEN       ; XRAM $2000
             + /A15 *  A14 * /A13 * MREQ * /RFSH * XRAMEN       ; XRAM $4000
             + /A15 *  A14 *  A13 * MREQ * /RFSH                ; base RAM

Now let's take a look at what we need to change in the I/O address
decoding.  The base CoPicoVision IODEC GAL looks like this:

    /IORQ /WR A5 A6  A7     NC      NC      NC     NC       NC       NC     GND
     NC    NC NC NC /CRSEL /C1WSEL /C2WSEL /VDPEN /VDPWSEL /VDPRSEL /SNWSEL VCC

    C2WSEL  = A7 * /A6 * /A5 * IORQ *  WR		; $80 writes
    VDPRSEL = A7 * /A6 *  A5 * IORQ * /WR		; $A0 reads
    VDPWSEL = A7 * /A6 *  A5 * IORQ *  WR		; $A0 writes
    VDPEN   = A7 * /A6 *  A5 * IORQ			; enable VDP transceiver
    C1WSEL  = A7 *  A6 * /A5 * IORQ *  WR		; $C0 writes
    CRSEL   = A7 *  A6 *  A5 * IORQ * /WR		; $E0 reads
    SNWSEL  = A7 *  A6 *  A5 * IORQ *  WR		; $E0 writes

Because we need to decode $53 and $7F, we're going to need to get all
8 of I/O port address bits connected to the GAL.

We need to generate a positive-edge clock pulse for the extended memory
FF's when they are written.  Looking at the Z80 I/O cycle timing diagram,
we can see that D0-D7 will be valid until the end of T3, and the /WR signal
is de-asserted before the end of T3, so that will do exactly what we need
in order to generate those.  We're also going to decode at least part of
the AY-3-8910 address space, since we have all of the address lines coming
in here as it is (see below for details):

So, with that, it looks like:

    /IORQ /WR     A0       A1       A2     A3      A4      A5     A6       A7       NC     GND
     NC   /AYSEL /FF1WSEL /FF2WSEL /CRSEL /C1WSEL /C2WSEL /VDPEN /VDPWSEL /VDPRSEL /SNWSEL VCC

    AYSEL   = /A7 * A6 * /A5 * A4 * /A3 * /A2 * /A1 * /A0 * IORQ ; $50
            + /A7 * A6 * /A5 * A4 * /A3 * /A2 * /A1 *  A0 * IORQ ; $51
            + /A7 * A6 * /A5 * A4 * /A3 * /A2 *  A1 * /A0 * IORQ ; $52

    FF1WSEL = /A7 * A6 * /A5 * A4 * /A3 * /A2 *  A1 *  A0 * IORQ *  WR ; $53 writes
    FF2WSEL = /A7 * A6 *  A5 * A4 *  A3 *  A2 *  A1 *  A0 * IORQ *  WR ; $7F writes

    C2WSEL  = A7 * /A6 * /A5 * IORQ *  WR		; $80 writes
    VDPRSEL = A7 * /A6 *  A5 * IORQ * /WR		; $A0 reads
    VDPWSEL = A7 * /A6 *  A5 * IORQ *  WR		; $A0 writes
    VDPEN   = A7 * /A6 *  A5 * IORQ			; enable VDP transceiver
    C1WSEL  = A7 *  A6 * /A5 * IORQ *  WR		; $C0 writes
    CRSEL   = A7 *  A6 *  A5 * IORQ * /WR		; $E0 reads
    SNWSEL  = A7 *  A6 *  A5 * IORQ *  WR		; $E0 writes

...which leaves one available output on the IODEC GAL.

OK!  On to the AY-3-8910 PSG!  Looks like the following I/O ports are
used for the PSG:
* $50 (w) -- address latch
* $51 (w) -- write data
* $52 (r) -- read data

This is very similar to what is used on the MSX:
* $A0 (w) -- address latch
* $A1 (w) -- write data
* $A2 (r) -- read data

The AY-3-8910 uses the goofy bus protocol from the General Instrument
CP1600, and so we have to generate the BDIR, BC1, and BC2 signals from
the I/O port accesses.  The AY-3-8910 manual further states that the BC2
signal can be tied to Vcc and that only 4 of the CP1600 bus states are
actually used:
* BDIR=0 BC1=0 -- inactive
* BDIR=0 BC1=1 -- read from PSG
* BDIR=1 BC1=0 -- write to PSG
* BDIR=1 BC1=1 -- latch address

We don't have enough outputs left on the IODEC GAL (DRAT, that's what I get
for trying to cheap out on an extra chip for VDPEN), so I'll add an AYDEC
GAL that implements the following logic:
* BDIR <- write-$x0 OR write-$x1
* BC1  <- write-$x0 OR read-$x2

...and the GAL equations:

    /AYSEL /WR A0 A1 NC NC NC NC NC NC  NC   GND
     NC     NC NC NC NC NC NC NC NC BC1 BDIR VCC
    
    BDIR = /AYSEL * /A1 * /A0 *  WR ; write-$x0
         + /AYSEL * /A1 *  A0 *  WR ; write-%x1
    
    BC1  = /AYSEL * /A1 * /A0 *  WR ; write-$x0
         + /AYSEL *  A1 * /A0 * /WR ;  read-$x2

More thoughts to come...
