BOOC = booc
NUNIT = nunit-console

all:
	$(BOOC) @Boo.Hints.rsp

debug:
	$(BOOC) -debug @Boo.Hints.rsp

cecil:
	$(BOOC) @Boo.Hints.Cecil.rsp

test: debug
	$(BOOC) -debug @Tests.rsp
	$(NUNIT) build/Tests.dll

clean:
	$(RM) build/*.dll build/*.mdb build/*.pdb