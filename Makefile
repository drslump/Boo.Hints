BOOC = booc
MSPEC = mspec
NUGET = nuget

all:
	$(BOOC) @Boo.Hints.rsp

deps:
	$(NUGET) install Mono.Cecil -Version 0.9.5.4
	$(NUGET) install Machine.Specifications -Version 0.5.12
	$(NUGET) install Machine.Specifications.Boo -Version 0.1.2

debug:
	$(BOOC) -debug -d:TRACE @Boo.Hints.rsp

cecil:
	$(BOOC) @Boo.Hints.Cecil.rsp

cecil-debug:
	$(BOOC) -debug -d:TRACE @Boo.Hints.Cecil.rsp

test: debug
	$(BOOC) -debug @Tests.rsp
	$(NUNIT) build/Tests.dll

clean:
	$(RM) build/*.dll build/*.mdb build/*.pdb
	$(RM) -r packages/*