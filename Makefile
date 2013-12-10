CECIL_VERSION = 0.9.5.4
MSPEC_VERSION = 0.5.12
MSPECBOO_VERSION = 0.1.3

BOOC = mono lib/booc.exe
MSPEC = mono --debug packages/Machine.Specifications.$(MSPEC_VERSION)/tools/mspec-clr4.exe
ILREPACK = mono packages/ILRepack.1.22.2/tools/ILRepack.exe


all: bin

bin: lib
	$(BOOC) -debug -d:TRACE -lib:build -o:build/boohints.exe src/boohints.boo

lib: deps
	$(BOOC) @Boo.Hints.rsp

deps:
	cp -f lib/Boo.Lang.* build/.

debug: deps
	$(BOOC) -debug -d:TRACE @Boo.Hints.rsp

cecil:
	@cp -f packages/Mono.Cecil.$(CECIL_VERSION)/lib/net40/*.dll build/.
	$(BOOC) @Boo.Hints.Cecil.rsp

cecil-debug:
	$(BOOC) -debug -d:TRACE @Boo.Hints.Cecil.rsp

test: debug
	@cp packages/Machine.Specifications.$(MSPEC_VERSION)/lib/net40/Machine.Specifications.dll build/
	@cp packages/Machine.Specifications.Boo.$(MSPECBOO_VERSION)/lib/net40/Machine.Specifications.Boo.dll build/

	$(BOOC) -debug @Tests.rsp

	$(MSPEC) build/Tests.dll

dist: clean bin cecil
	$(ILREPACK) /out:dist/boohints.exe /internalize /lib:build build/boohints.exe build/Boo.Hints.dll build/Boo.Hints.Cecil.dll \
		build/Boo.Lang.dll build/Boo.Lang.Compiler.dll build/Boo.Lang.Parser.dll build/Boo.Lang.Useful.dll \
		build/Mono.Cecil.dll build/Mono.Cecil.Mdb.dll build/Mono.Cecil.Pdb.dll

clean:
	$(RM) build/*
