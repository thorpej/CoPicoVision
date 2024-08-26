# CoPicoVision - A ColecoVision clone using a Raspberry Pi Pico and pico9918 for video
The CoPicoVision stems from another bout of nostalgia.  When I was a kid, I got
a ColecoVision one Christmas and I played the h*ll out of it.  Alas, I no longer
have it, but I wish I still did, and building a clone seems a lot more fun than
over-paying for one on eBay.

## Design philosophy
My goal is to play ColecoVision games, not to produce a faithful clone of the
circuit.  It needs to be fully-compatible with ColecoVision games, but that's
the extent of it.  As such, some shortcuts are going to be taken.

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

There are two "vintage" parts that are required for the CoPicoVision:
* A Z80 CPU in a DIP40 package.
* A TI SN76489AN sound chip.

Eventually, I'd like to replace the SN76489AN with an emulated part, (almost
certainly using a Pi Pico), but for now the real thing needs to be sourced.

Obviously, with the Z80 now being EOL'd, that poses a bit of a snag.  Luckily,
I have a stash of modern CMOS Z80s, and this design will also accept a vintage
NMOS Z80.  The CPU is clocked at 3.57MHz, so any DIP-40 Z80 should work just
fine.  Maybe one day I'll evaluate one of the FPGA Z80 cores floating around
to see if it's feasible to use one of those with an iCE40 FPGA in an updated
version of the CoPicoVision.  But for now, a genuine Z80 must be used.

## Acknowledgements
First of all, I want to say that I was inspired to take a crack at this by the
Leako project, which you can read about [here](https://www.leadedsolder.com/tag/leako).

Second, huge shout out to ChildOfCv on the AtariAge forums for their fantastic
reverse-engineered [ColecoVision schematics](https://forums.atariage.com/topic/285656-new-colecovision-schematics/).

And finally, massive thanks to Troy for his fantastic [pico9918](https://github.com/visrealm/pico9918).
It's truly what makes the CoPicoVision possible.
