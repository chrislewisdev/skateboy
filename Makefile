SRCDIR = src
OUTDIR = build

SRC = $(wildcard $(SRCDIR)/*.asm)
OBJ = $(SRC:$(SRCDIR)/%.asm=$(OUTDIR)/%.o)

build/skateboy.gb: $(OBJ)
	rgblink -o $(OUTDIR)/skateboy.gb -n $(OUTDIR)/skateboy.sym $(OBJ)
	rgbfix -p0 -v $(OUTDIR)/skateboy.gb

$(OUTDIR)/%.o: $(SRCDIR)/%.asm $(OUTDIR)/
	rgbasm -i $(SRCDIR) -o $@ $<

$(OUTDIR)/:
	mkdir build