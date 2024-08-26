#GALASM=	galasm
GALASM=		galette

GALASM_FLAGS=	-f -p

JEDECS=		iodec.jed memdec.jed

.SUFFIXES:
.SUFFIXES: .gal .jed

.gal.jed:
	$(GALASM) $(GALASM_FLAGS) $<

all: $(JEDECS)

clean:
	-rm -f *.jed *.chp *.fus *.pin
