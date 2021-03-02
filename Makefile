SRCDIR = src
OUTDIR = build

BIN = $(wildcard $(SRCDIR)/**/*.bin)
INC = $(wildcard $(SRCDIR)/*.inc)
SRC = $(wildcard $(SRCDIR)/*.asm)
OBJ = $(SRC:$(SRCDIR)/%.asm=$(OUTDIR)/%.o)

$(OUTDIR)/skateboy.gb: $(OBJ)
	rgblink -o $(OUTDIR)/skateboy.gb -n $(OUTDIR)/skateboy.sym $(OBJ)
	rgbfix -p0 -v $(OUTDIR)/skateboy.gb

$(OUTDIR)/%.o: $(SRCDIR)/%.asm $(INC) $(BIN) $(OUTDIR)/
	rgbasm -i $(SRCDIR) -o $@ $<

$(OUTDIR)/:
	mkdir build
