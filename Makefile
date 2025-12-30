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
	/home/staticlinkage/tools/superfamiconv palette --mode gb --no-remap --in-image $< --out-data gen/hud.palette
	/home/staticlinkage/tools/superfamiconv tiles --mode gb --bpp 2 --no-flip --in-palette gen/hud.palette --in-image $< --out-data $@
	/home/staticlinkage/tools/superfamiconv map --mode gb --bpp 2 --no-flip --map-width 32 --tile-base-offset 88 \
		--in-palette gen/hud.palette --in-image $< --in-tiles $@ --out-data src/gen/hud.tilemap

$(GENDIR)/hud.png: $(GFXDIR)/hud.aseprite
	aseprite -b $< --save-as $@

$(SRCDIR)/$(GENDIR)/sprites.2bpp: $(GENDIR)/sprites.png $(SRCDIR)/$(GENDIR)/
	rgbgfx -u -t src/gen/sprites.anim -o $@ $<

$(GENDIR)/sprites.png: $(GFXDIR)/sprites.aseprite $(GENDIR)/
	aseprite -b --sheet $@ --sheet-type vertical --data $(GENDIR)/sheet.json $<

$(SRCDIR)/$(GENDIR)/:
	mkdir $(SRCDIR)/$(GENDIR)

$(GENDIR)/:
	mkdir $(GENDIR)

$(OUTDIR)/:
	mkdir $(OUTDIR)

clean:
	rm -rf gen
	rm -rf src/gen
	rm -rf build
