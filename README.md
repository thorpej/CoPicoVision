# CoPicoVision - A ColecoVision clone using a Raspberry Pi Pico with pico9918 for video
The CoPicoVision stems from yet another bout of nostalgia for a time before
photorealistic video games, when all we had was blocky tile graphics and a
few bleeps and bloops and gosh darn it, we liked it!  When I was a kid, I got
a ColecoVision one Christmas and I played the h*ll out of it.  Alas, I no
longer have it, but I wish I still did, and building a clone seems a lot more
fun than over-paying for one on eBay.

Ok, fine, I have a second motive: It also serves as a test mule for using
modified variants of Troy Schrapel's excellent
[pico9918](https://github.com/visrealm/pico9918) project, something I'm
considering using in other projects, and test mules that can play Mr. Do!
and Zaxxon (yes, yes, yes, and Donkey Kong) are the best kinds of test mules.

![3D render of board image](CoPicoVision-pcb-render.png)

This work is licensed under the [Creative Commons Attribution
ShareAlike 4.0 International license](https://creativecommons.org/licenses/by-sa/4.0/).

![CC BY-SA 4.0](https://i.creativecommons.org/l/by-sa/4.0/88x31.png)

## Project Status
### Update - Dec 19, 2024
Well, I had some time to kill on a plane, so I started the process to
claw back board real estate in order to fit the additional components
needed for "Super CoPicoVision".  But of course, once the initial shrink
was done, I needed to know where the additional components would fit before
I re-routed the board.  This of course meant that I needed to actually
add these additional components to the board, meaning that I needed to do
the work to add them to the schematic.  Anyway, you can probably guess
where this is going!  I need to now fix up the BOM (when you're ordering
ICs in surface-mount packages, you need to be a little more specific about
which part number you order!)

### Update - Dec 15, 2024
I had to take a break from CoPicoVision for a little while for various
reasons, but I'm trying to get back to it.  After mulling it over and
thinking about future "Super CoPicoVision" plans, I decided to change the
audio output buffer to a TL071 opamp, taking advantage of the -5V rail I
have at my disposal.  I added an LTspice simulation of the circuit, including
passively mixing in the output of an AY-3-8910, which would be present on
this hypothetical "Super CoPicoVision".  I want to get this send off to the
fab soon and if everthing is fine, call this version "CoPicoVision 1.0".

I do plan to keep working on it, though!  I plan on experimenting with
the layout, switching to SMT components as necessary, to see if I can fit
the extra chips needed for the Super flavor within the same board footprint.

### Update - Nov 10, 2024
I finally got a chance to get set up with some powered speakers (with a
volume control) to get a better sense of how the audio section behaves.
With the AudioEngine 2+ speakers I tested with, the noise isn't really
that bad at all, and it definitely seems to be a property of the SN76489AN
(placing my finger on top of the chip while running makes an audible
different in the noise profile).

I haven't yet bodged the audio section changes in revision 0.2 onto this
revision 0.1 board.  I really should try to do that soon and re-evaluate.

### Update - Oct 12, 2024
I've updated the schematic and PCB to fix the swapped controller bug in
the rev 0.1 boards, and bumped the revision to 0.2.

I've also built up the audio section of the board and confirmed that it
works.  It's not ideal, though:
* The footprint for the resistor in the emitter-follower is wrong, so even
the relatively-small 1/2 watt resistor I spec'd doesn't quite fit.
* I should have put a current-limiting resistor between the SN76489AN and
the emitter-follower.  It works as it is, but the current setup has the
SN76489AN sourcing more current than it really ought to.  (Maybe I should
have just used a 2N7000 in a source-follower configuration instead?)
* The output is pretty noisy.  It's not _distorted_, but there's hiss and
other audio artifacts.  I remember the original ColecoVision being this
way, but always assumed it was the fault of the RF modulator.  I may bodge
in a passive low-pass filter to cut down on the noise.

### Update - Oct 11, 2024
Built up the controller section and played some Donkey Kong!  I did make
a mistake on the controller section, however.  Controller 1 and 2 are
swapped.  I will correct this in the next revision of the board, and there
is a [procedure](errata/rev0_1_controller_bodge.md) to fix the rev 0.1 boards
that I've already run off.

There also a mistake in the physical placement of the card edge connector
for the cartridge.  It's a few millimeters too close to the front of the
board, and so the cartridge bumps into one of the 2N3904s in the controller
circuit and the cartridge doesn't quite align with the silk screen outline.
That's going to be a little tricker to fix because I might have to re-route
some of the board, but I'll fix that up as well.

Guess I should build the audio section next!

### Update - Oct 10, 2024
After replacing a bad oscillator, the first test board is working!  I have
not yet installed the audio or controller circuitry yet, but I can boot up
Donkey Kong and Buck Rogers, and, due to the lack of controller circuitry
being misinterpreted as input, game play starts!

### Update - Sept 24, 2024
Boards have been back for a while now, and I finally got around to starting
to build one up.  Thought I had all of the resistors I needed in my inventory,
but alas, I did not, so need to place a Jameco order!

### Update - Sept 2, 2024
I made some small adjustments to the PCB, and sent rev 0.1 off for
fabrication!

### Update - Sept 1, 2024
I made forks of pico9918 and vrEmuTms9918 in order to make the changes
needed for CoPicoVision, and then went ahead and made all of those
changes.  Initial firmware version checked in!

### Initial - Aug 31, 2024
The initial "rev 0.1" hardware design is done and ready to send off for
fabrication.  There is some software work to do on the pico9918 side of
things, but the changes I have in mind are trivial.  My plan is to wrap
my changes in proper configuration options and feed those changes back
to Troy.

So, yah, it's early!  Watch this space!

## Design philosophy
My initial goal was to play ColecoVision games (and subsequently, also
games that require the Super Game Module), not to produce a faithful
clone of the circuit.  It needs to be fully-compatible with ColecoVision
and SGM games, but that's the extent of it.  As such, some shortcuts are
going to be taken.

First of all, I'm using Troy Schrapel's excellent pico9918 engine for the video
display.  This reduces the number of vintage parts that need to be sourced, and
gives me VGA video output.  I won't be using the pico9918 as-is, however; since
I don't need all of the outputs of a real TMS9918A (no CPUCLK or GROMCLK), I'm
using a modified pico9918 firmware that doesn't bother with those outputs and
thus allows me to use a regular Raspberry Pi Pico as a module.

Second of all, I'm not going to bother with the expansion interface; I don't
particularly care about connecting an Adam module, and if I ever do, then it
will be time to re-evaluate my life choices.

And lastly, as should be obvious through my use of a microcontroller that's
hundreds of times more powerful than the ColecoVision itself, I have no qualms
about using programmable logic to reduce the part count and generally simplify
the design.  In particular, this means GAL22V10s for address decoding and other
glue logic rather than general-purpuse 7400-series parts.  Atmel still makes
a compatible part, and there are open source tools for programming them, so the
design is still very accessible.

There are three "vintage" parts that are required for the CoPicoVision:
* A 4MHz-capable Z80 CPU in a DIP-40 package.
* A TI SN76489AN sound chip.
* A General Instrument AY-3-8910 sound chip (a Yamaha YM2149 will probably
  also work, but I don't have any to try).  This is only needed if you want
  to be able to play SGM games; regular ColecoVision games will work without
  it.

Eventually, I'd like to replace the SN76489AN and AY-3-8910s with emulated
parts, (almost certainly using a Pi Pico), but for now the real thing needs
to be sourced.

Obviously, with the Z80 now being EOL'd, that poses a bit of a snag.  Luckily,
I have a stash of modern CMOS Z80s, and this design will also accept a vintage
NMOS Z80.  The CPU is clocked at 3.57MHz, so a Z80A or better is necessary.
Maybe one day I'll evaluate one of the FPGA Z80 cores floating around
to see if it's feasible to use one of those with an iCE40 FPGA in an updated
version of the CoPicoVision.  But for now, a genuine Z80 must be used.

## Design details
I spent some time mulling over how I wanted to approach this board.  I
considered doing an all-SMT board (except for the stuff that was only
available as through-hole), but for the first version of the board I
ultimately went with mostly through-hole parts (except for the power supply)
in order to try and keep a more retro look.

This wasn't feasible for version 2, the "Super CoPicoVision"; I wanted to
keep the same basic envelope, so I had no choice to shrink the components
in order to make space for the additional logic chips and the large DIP-40
AY-3-8910.  So, I converted all of the individual resistors and ceramic
capacitors to 0805 packages, and the RAM and most logic ICs to SOIC packages
(I left the 74LS541s in the controller input section as DIP packages).

The board is 4 layers: signals (and ground fill) top and bottom, along with
an internal ground plane and power plane.  I arrived at the size of the board
through experimentation; essentially, I did a rough layout of the board into
what I thought "looked pretty good", placed mounting holes and keep-outs, and
then drew an edge-cut box around it.  Once the box was drawn, I tried to stay
within that envelope.  I'm a total novice when I comes to PCB layout and
design, and I routed the entire board by hand, but did manage to make it fit.
Some signals are routed, ahem, interestingly, but this isn't a high-speed
design so it should be just fine.

The font of the board has power and reset buttons and the 2 controller
ports.  The rear of the board has power, audio, and VGA jacks, along with
the USB connector for the Raspberry Pi Pico in case there's a need to
update the pico9918 firmware.  There's a diode in between the Pico and
the rest of the board, so it's safe to update the firmware in situ.

I've included a bill of materials with Mouser part numbers for just about
everything; the jellybean SMT resistors / capacitors (in standard 0805 case)
are left as an exercise for the reader.  Same goes for chip sockets.

### Power supply
The power supply is fairly simple, since we don't need the -12V rail that's
found on the original ColecoVision.  We do, however, require a -5V rail, which
is used as a bias voltage in the controller interface circuit as well as for
the op-amp used as an output buffer in the audio circuit.

Power comes in via a USB-C connector (with ESD protection diodes on the
control channel signals).  Power is switched using a MAX16054 on/off
supervisor chip that controls a high-side P-FET to supply power to the
rest of the system.  The MAX16054 is controlled using a single momentary
pushbutton.

The -5V rail is generated using an ICL7660A charge pump chip.

### Clock and reset generation
The clock circuit on the CoPicoVision is as simple as it gets: it's simply
a 3.579545 MHz DIP-8 oscillator can that drives the whole thing.  The CPUCLK
signal is sent directly from the oscillator to the Z80, the M1 wait-state
generator, and the SN76489AN and AY-3-8190 sound chips.  The Pi Pico that
generates the video has its own clock, so none of the complicated clock
circuitry from the original ColecoVision is necessary.

The reset circuit is also very simple.  It's based on the DS1813 reset
generator IC, which also de-bounces the reset button.  There is a small RC
network that makes the power-on-reset slightly longer than a manual reset.

### Address decoding and memory
Address decoding is performed using 2 GAL22V10 programmable logic devices.
The original ColecoVision uses 2 74LS138s for address decoding, but also
requires some extra logic to invert some of the signals used by the decoders.
By using GALs for this purpose, I save the extra logic chips.

The ColecoVision also uses a 74LS74 dual D-type flip-flop along with some
additional logic gates to add a wait-state when the Z80 performs an opcode
fetch.  It does this presumably to give some extra breathing room to slow
ROMs (of the Z80 machine cycles, M1 has the tightest timing).  There is
plenty of space in the MEMDEC GAL for this, so that's where I put it.
There is a large comment in the [MEMDEC GAL](gal-files/memdec.gal) source
file that explains how the wait-state generator works.

The BIOS ROM for the CoPicoVision is contained in a 150ns 28C64 EEPROM.
I chose this part because:
* I had a bunch of them on-hand.
* They're totally fast enough.
* They're still being made and you can buy them new from Mouser and DigiKey.

The CoPicoVision's RAM is an AS6C62256-55SCN, which is a 32KB 55ns SRAM chip.

The ColecoVision's memory address space is divided into 8 8KB "pages":

* $0000 - BIOS ROM
* $2000 - Expansion
* $4000 - Expansion
* $6000 - RAM
* $8000 - Cartridge selector 0
* $A000 - Cartridge selector 1
* $C000 - Cartridge selector 2
* $E000 - Cartridge selector 3

The ColecoVision only has 1KB of RAM at $6000, and the addresses are
incompletely decoded, so that 1KB is mirrored throughout that page.

The Super Game Module has 32KB of extended RAM, only 24KB of which is
available unless the BIOS ROM is diabled.  These features are controlled
by the following two registers:

* Writing 0b00000001 to port $53 enables extended RAM.
* Writing 0b00001101 to port $7F disables the BIOS ROM (0b00001111
  re-enables it).  Games must write one of these two values in order
  to maintain compatability with the Adam.

The CoPicoVision uses a 74HCT74 dual D-type flip-flop is used to provide
these two control registers (only 2 independently-settable bits are needed).
FF1 is connected to D0 and provides the XRAMEN signal, and FF2 is connected
to D1 and provides the ROMEN signal.  The /RESET line is connected such that
FF0 is cleared at reset and FF1 is set at reset.  These two signals are used
by the MEMDEC GAL when decoding memory addresses.  A 74HCT08 quad-AND chip
mixes the XRAM signal with RAM address lines A10-A12, forcing them to 0 when
XRAMEN is disabled and passing them through from the CPU when XRAMEN is
enabled, thus maintaining the RAM mirroring behavior of the original
ColecoVision.

When the ROM is enabled, MEMDEC sends reads from the $0000 page to
the ROM, and when disabled it sends those reads to the RAM.  Writes to
the $0000 page are always sent to RAM.  On the CoPicoVision, the $0000 page
RAM behavior is governed entirely by the ROMEN signal.  I suspect this
doesn't exactly match the original Super Game Module behavior, but I also
suspect that it doesn't matter in any practical sense.

I/O address decoding is handled by the [IODEC GAL](gal-files/iodec.gal).
In the original ColecoVision, I/O addresses were incompletely decoded using
address lines A5-A7:

* $8x writes set controller number pad scan mode
* $Ax reads read from the VDP registers
* $Ax writes write to the VDP registers
* $Cx writes set controller joystick scan mode
* $Ex reads read the controllers
* $Ex writes write to the SN76489AN sound chip

To support the SGM extensions, the IODEC GAL also needs to completely
decode the following addresses:

* $50 (AY-3-8910 address latch)
* $51 (AY-3-8910 write data)
* $52 (AY-3-8910 read data)
* $53 writes (extended memory enable register)
* $7F writes (ROM disable register)

A pair of NOR gates from a 74HCT02 are used in conjunction with the /AYSEL
output from IODEC, the A0 address line, and the Z80's /WR signal to generate
the BC1 and BDIR signals used to interface with the AY-3-8910.

### Audio
The audio section is comprised of the two sound chips, whose outputs are
passively mixed using 1K series resistors and then AC-coupled to a TL071
op-amp which serves as an output buffer.  The op-amp's output is then
AC-coupled to both outputs of a 3.5mm TRS phone jack.

### Video
Of course, the video circuit is built using a Raspberry Pi Pico running a
modified version of the pico9918 firmware.  The following changes from
the base pico9918 have been made:
* I don't need the CPUCLK and GROMCLK outputs, so these have been omitted.
This saves 2 pins and means I can use a regular Raspberry Pi Pico.
* I have inverted the interrupt output so that I can use it to drive a
TTL-level open-drain inverter to pull down the Z80's /NMI signal.

The bus interface to the Pico is a little simpler than that used on the
pico9918.  Two 74LVC245 bus transceivers are used to perform the 3V3 <--> 5V
level shift.  This works perfectly fine since I've arranged for everything
on the 5V side to use TTL logic levels, which can accept the 3V3 CMOS logic
level outputs.  One transceiver is hard-wired for the B->A direction and
level-shifts the A0, /VDPWSEL, /VDPRSEL, and /RESET input signals to the Pico.
The other transceiver level-shifts the data bus and takes care of swizzling
the bit order between the VDP and the Z80.  The IODEC GAL generates an extra
signal that's used to enable the output of the data bus transceiver, and the
direction of the transceiver is controlled by /VDPWSEL.

The VGA resistor DAC is identical to the pico9918's.

### Controller interface
The controller interface is derived more or less straight from the
ColecoVision, except the quad-NAND gate is replaced with a 74HCT part.
The controller input buffers are the same 74LS541 used on the original
because the circuit relies on Schmitt trigger inputs and the standard
CMOS replacement parts don't have them.  Eventually I may experiment with
the 74HCS541 as a replacement.

One difference is that I made both controller inputs indentical; in the
original, it seems that one controller input was drawn in a "mirror image"
and the bit order on it's buffer swapped to compensate.  That seemed
needlessly confusing to me, so I just made them both the same (I literally
copy-and-pasted, and then tweaked some net labels to make the second
instance).

The controller interface is by far the most complicated block on the system.
I have a basic understanding of how it works, but there is clearly some subtle
analog magic going on, so I decided not to push my luck.  I don't have any
of the quadrature controllers to test with at this time.

## Errata
Rev 0.1 of the CoPicoVision has the following bugs:
* Controller 1 and Controller 2 are swapped due to a silly mistake in
the selection logic.  [This procedure](errata/rev0_1_controller_bodge.md)
will correct the problem, or you can just live with it.
* The card edge connector for the cartridge is about 1.5mm too close to the
front of the board.  This was due to a measurement error.  As a result, the
cartridge does not fit within the silkscreen outline on the PCB and the front
of the cartridge may bump into the back of Q402.  You may need to bend Q402
forward a little in order to get the cartridge to seat properly.  I plan to
adjust this in the next board revision, but it may require rerouting several
signals.
* More bugs may yet be discovered; I have not yet put together the audio
section or tested with 2 controllers.

## Changes

### Rev 0.2
* Fixed the swapped controller port issue in rev 0.1.
* Changed the footprint of R501 to be vertical to make it easier to
  fit the needed 1/2 watt resistor.
* Added a 1.5K current-limiting resistor (R502) between the SN76489AN
  (U501) and the base of the emitter-follower (Q501).
* Added a 0.01uF capacitor (C504) between the base of the emitter-follower
  (Q501) and ground.  This, in conjunction with the 1.5K current-limiting
  resistor (R502), forms a passive low-pass filter with a cut-off frequency
  of ~10KHz.
* Rerouted some digital signals further away from the audio output path.
* Moved the cartridge connector towards the rear of the board by 1mm.

## Acknowledgements
First of all, I want to say that I was inspired to take a crack at this by the
Leako project, which you can read about [here](https://www.leadedsolder.com/tag/leako).

Second, huge shout out to ChildOfCv on the AtariAge forums for their fantastic
reverse-engineered [ColecoVision schematics](https://forums.atariage.com/topic/285656-new-colecovision-schematics/).

And finally, massive thanks to Troy for his fantastic [pico9918](https://github.com/visrealm/pico9918).
It's truly what makes the CoPicoVision possible.

If you have any questions about the board, you can reach out to me on
Twitter (*[@thorpej](https://twitter.com/thorpej)*) or Mastodon
(*[@thorpej@mastodon.sdf.org](https://mastodon.sdf.org/@thorpej)*).  You
can also check out my [YouTube channel](https://www.youtube.com/@thorpejsf),
which has this and other retrocomputing related content.
