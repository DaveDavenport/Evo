VALA_SOURCES=\
		test.vala\
		DNA.Point.vala\
		DNA.Polygon.vala\
		DNA.Brush.vala\
		DNA.Strain.vala\
		DNA.Render.vala\
		PPM.vala

VALAC=valac
VALAC_FLAGS=--pkg=libxml-2.0 --pkg=gdk-pixbuf-2.0 -X "-O3" -X "--fast-math" -g
PROGRAM=evo

$(PROGRAM): $(VALA_SOURCES) Makefile
	$(VALAC) $(VALAC_FLAGS) $(VALA_SOURCES) -o $@
