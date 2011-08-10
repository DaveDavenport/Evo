VALA_SOURCES=\
		test.vala\
		DNA.Point.vala\
		DNA.Polygon.vala\
		DNA.Brush.vala\
		DNA.Strain.vala\
		DNA.Render.vala\
		PPM.vala

VALAC=valac
VALAC_FLAGS=--pkg=libxml-2.0 --pkg=gdk-pixbuf-2.0 -X "-O4" -X "--fast-math" -X "-funsafe-math-optimizations" -X "-funsafe-math-optimizations" -X "-funroll-loops" -X "-fprefetch-loop-arrays"  -g --save-temps
# -X "-march=amdfam10"
PROGRAM=evo

$(PROGRAM): $(VALA_SOURCES) Makefile
	$(VALAC) $(VALAC_FLAGS) $(VALA_SOURCES) -o $@

.PHONY: source
source: $(VALA_SOURCES) Makefile
	$(VALAC) $(VALAC_FLAGS) $(VALA_SOURCES) -o $@ -C
