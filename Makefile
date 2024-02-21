ROCKSPECS:=$(wildcard *.rockspec)
ROCKPACKS:=$(ROCKSPECS:.rockspec=.all.rock)
LUAROCKS:=$(ROCKSPECS:.rockspec=)

NAMES=$(shell ls *.rockspec)
VERS=$(shell ls *.rockspec)

all: clean build pack

clean:
	@echo == clean all rock packs
	rm -rf $(notdir $(ROCKPACKS))
	@echo == remove installed rocks
	@-for i in $(notdir $(LUAROCKS)); do \
	  j=`echo $$i | sed -e 's/\(^[a-z-]*\).*/\1/g' | sed -e '$$ s/.$$//'`; \
	  luarocks remove $$j > /dev/null 2>&1; \
	done
	@echo == all pack and install cleaned

build: $(LUAROCKS)
  @echo == build finished

$(LUAROCKS): $(ROCKSPECS)
	@echo == build $@
	luarocks make --pack-binary-rock $@.rockspec

pack: $(ROCKPACKS)
  @echo == pack finished

%.all.rock: %.rockspec
	@n=`echo $* | sed -e 's/\(^[a-z-]*\).*/\1/g' | sed -e '$$ s/.$$//'` ; \
   v=`echo $* | sed 's/[a-z]//g' | sed 's/^\-*//g'` ; \
	  echo $$n; \
		echo $$v; \
      luarocks pack $$n $$v;
  @echo == success pack $*
