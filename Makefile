SRCDIR = src
OUTDIR = build
GENDIR = gen
GFXDIR = gfx

BIN = $(wildcard $(SRCDIR)/**/*.bin)
INC = $(wildcard $(SRCDIR)/*.inc)
SRC = $(wildcard $(SRCDIR)/*.asm)
OBJ = $(SRC:$(SRCDIR)/%.asm=$(OUTDIR)/%.o)

$(OUTDIR)/skateboy.gb: $(OBJ)
	rgblink -o $(OUTDIR)/skateboy.gb -n $(OUTDIR)/skateboy.sym $(OBJ)
	rgbfix -p0 -v $(OUTDIR)/skateboy.gb

$(OUTDIR)/%.o: $(SRCDIR)/%.asm $(INC) $(BIN) $(OUTDIR)/
	rgbasm -i $(SRCDIR) -o $@ $<

$(OUTDIR)/gfx.o: $(SRCDIR)/$(GENDIR)/sprites.2bpp

$(SRCDIR)/$(GENDIR)/sprites.2bpp: $(GENDIR)/sprites.png $(SRCDIR)/$(GENDIR)/
	rgbgfx -o $@ $<

$(GENDIR)/sprites.png: $(GFXDIR)/sprites.aseprite $(GENDIR)/
	aseprite -b --sheet $@ --sheet-type vertical --data $(GENDIR)/sheet.json $<

$(SRCDIR)/$(GENDIR)/:
	mkdir $(SRCDIR)\$(GENDIR)

$(GENDIR)/:
	mkdir $(GENDIR)

$(OUTDIR)/:
	mkdir $(OUTDIR)

clean:
	rmdir /s /q gen
	rmdir /s /q "src/gen"
	rmdir /s /q build
