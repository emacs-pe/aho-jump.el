EMACS      = emacs
EMACSFLAGS =
EMACSBATCH = $(EMACS) --batch -Q $(EMACSFLAGS)

SRCS := aho-jump.el
OBJS  = $(SRCS:.el=.elc)

compile: $(OBJS)

%.elc: %.el
	$(EMACSBATCH) -f batch-byte-compile $<

test:
	$(EMACSBATCH) -L . -l aho-jump-test.el -f ert-run-tests-batch-and-exit

clean:
	$(RM) $(OBJS)
