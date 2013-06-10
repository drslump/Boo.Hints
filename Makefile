BOOC = booc
MSPEC = mspec

all: bin
	$(BOOC) 

bin: lib
	$(BOOC) -debug -d:TRACE -lib:build -o:build/boohints.exe src/boohints.boo

lib:
	$(BOOC) @Boo.Hints.rsp

debug:
	$(BOOC) -debug -d:TRACE @Boo.Hints.rsp

cecil:
	$(BOOC) @Boo.Hints.Cecil.rsp

cecil-debug:
	$(BOOC) -debug -d:TRACE @Boo.Hints.Cecil.rsp

test: debug
	$(BOOC) -debug @Tests.rsp
	cp packages/Machine.Specifications.0.5.12/lib/net40/Machine.Specifications.dll build/
	$(MSPEC) build/Tests.dll

clean:
	$(RM) build/*
