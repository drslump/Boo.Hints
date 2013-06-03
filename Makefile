BOOC = booc
MSPEC = mspec

all:
	$(BOOC) @Boo.Hints.rsp

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