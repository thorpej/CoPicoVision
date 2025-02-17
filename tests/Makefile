TARGETS=	CoPicoVision-memtest.rom
Z80ASM_FLAGS=
Z80ASM=		z80asm $(Z80ASM_FLAGS)

all: $(TARGETS)

clean:
	-rm -f $(TARGETS) *.lst *.bin

# Don't bother with dependencies on the targets.  These build REALLY
# fast and this makes it so we don't have to chase all the nested
# includes.
.PHONY: CoPicoVision-memtest.bin
CoPicoVision-memtest.bin:
	$(Z80ASM) -o $(@) CoPicoVision-memtest.s

CoPicoVision-memtest.rom: CoPicoVision-memtest.bin
	dd if=$(<) of=$(@) obs=8192 conv=osync
