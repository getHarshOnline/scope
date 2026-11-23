# LaTeX build system for the paper. Selects the repository's own master.
# Copied from MONAD's paper/Makefile (https://github.com/getHarshOnline/MONAD), which keeps the canonical copy.

REPOSITORY_NAME := $(notdir $(abspath ..))
ROOT_TEX := $(wildcard *.tex)
REPOSITORY_MASTER := $(wildcard $(REPOSITORY_NAME).tex)
MASTER ?= $(if $(REPOSITORY_MASTER),$(REPOSITORY_MASTER),$(if $(word 2,$(ROOT_TEX)),,$(firstword $(ROOT_TEX))))

ifeq ($(strip $(MASTER)),)
$(error Cannot select a paper master: declare MASTER=<file>.tex when the repository name does not identify one of multiple root .tex files)
endif

NAME := $(basename $(MASTER))

.PHONY: all quick clean validate figures

# Discard stale output. Accept only the diagnostics for a citation-free master.
all: figures
	rm -f "$(NAME).bbl" "$(NAME).blg"
	pdflatex -interaction=nonstopmode $(MASTER)
	@status=0; bibtex "$(NAME)" || status=$$?; \
	if [ "$$status" -ne 0 ]; then \
		log="$(NAME).blg"; \
		if [ "$$status" -eq 2 ] && grep -Fq 'I found no \citation commands' "$$log" && \
		   { grep -Fxq '(There was 1 error message)' "$$log" || \
		     { grep -Fq 'I found no \bibdata command' "$$log" && \
		       grep -Fq 'I found no \bibstyle command' "$$log" && \
		       grep -Fxq '(There were 3 error messages)' "$$log"; }; }; then \
			rm -f "$(NAME).bbl"; \
			echo "No citations requested for $(MASTER)"; \
		else \
			exit "$$status"; \
		fi; \
	fi; \
	if grep -Fq "Warning--I didn't find a database entry for" "$(NAME).blg"; then \
		echo "Unresolved bibliography entries for $(MASTER)" >&2; \
		exit 1; \
	fi
	pdflatex -interaction=nonstopmode $(MASTER)
	pdflatex -interaction=nonstopmode $(MASTER)

quick:
	pdflatex -interaction=nonstopmode $(MASTER)

# Rebuild each source figure so changes in nested inputs reach the master.
figures:
	@set -e; stage=; \
	trap 'if [ -n "$$stage" ]; then rm -rf "$$stage"; fi' EXIT; \
	trap 'exit 130' INT; trap 'exit 143' TERM; \
	for f in figures/tikz/*.tex; do \
		[ -f "$$f" ] || continue; \
		name=$$(basename "$$f" .tex); \
		out="figures/pdf/$$name.pdf"; \
		if [ -z "$$stage" ]; then \
			mkdir -p figures/pdf; \
			stage=$$(mktemp -d figures/pdf/.build.XXXXXX); \
		fi; \
		echo "Building $$f → $$out"; \
		pdflatex -halt-on-error -interaction=nonstopmode -output-directory="$$stage" "$$f"; \
		if [ ! -s "$$stage/$$name.pdf" ]; then \
			echo "Figure produced no PDF: $$f" >&2; \
			exit 1; \
		fi; \
		for extension in aux log; do \
			if [ -f "$$stage/$$name.$$extension" ]; then \
				mv -f "$$stage/$$name.$$extension" "figures/pdf/$$name.$$extension"; \
			fi; \
		done; \
		mv -f "$$stage/$$name.pdf" "$$out"; \
	done

clean:
	rm -f $(NAME).pdf $(NAME).aux $(NAME).bbl $(NAME).blg $(NAME).log \
		$(NAME).out $(NAME).toc $(NAME).fls $(NAME).fdb_latexmk \
		figures/pdf/*.aux figures/pdf/*.log

validate:
	./validate.sh
