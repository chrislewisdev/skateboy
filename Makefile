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

$(OUTDIR)/gfx.o: $(SRCDIR)/$(GENDIR)/sprites.2bpp $(SRCDIR)/$(GENDIR)/hud.2bpp

$(SRCDIR)/$(GENDIR)/hud.2bpp: $(GENDIR)/hud.png
	rgbgfx -u -t src/gen/hud.tilemap -o $@ $<

$(GENDIR)/hud.png: $(GFXDIR)/hud.aseprite
	aseprite -b $< --save-as $@

$(SRCDIR)/$(GENDIR)/sprites.2bpp: $(GENDIR)/sprites.png $(SRCDIR)/$(GENDIR)/
	rgbgfx -u -t src/gen/sprites.anim -o $@ $<

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
