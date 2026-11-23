#!/usr/bin/env bash
# Validation script for the paper build.
# Copied from MONAD's paper/validate.sh (https://github.com/getHarshOnline/MONAD), which keeps the canonical copy.
set -euo pipefail

if [ -z "${MASTER:-}" ]; then
  repository_name=$(basename "$(cd .. && pwd)")
  if [ -f "${repository_name}.tex" ]; then
    MASTER="${repository_name}.tex"
  else
    shopt -s nullglob
    root_tex=(*.tex)
    shopt -u nullglob
    if [ "${#root_tex[@]}" -ne 1 ]; then
      echo "Cannot select a paper master: set MASTER=<file>.tex when the repository name does not identify one of multiple root .tex files."
      exit 1
    fi
    MASTER="${root_tex[0]}"
  fi
fi

if [ ! -f "$MASTER" ]; then
  echo "Paper master not found: $MASTER"
  exit 1
fi

NAME="${MASTER%.tex}"
LOG="${NAME}.log"

if [ ! -f "$LOG" ]; then
  echo "No build log found. Run 'make all' first."
  exit 1
fi

errors=0

echo "=== Checking $NAME ==="

# Undefined references
undef_refs=$(grep -c "LaTeX Warning: Reference.*undefined" "$LOG" 2>/dev/null || true)
if [ "$undef_refs" -gt 0 ]; then
  echo "FAIL: $undef_refs undefined reference(s)"
  grep "LaTeX Warning: Reference.*undefined" "$LOG"
  errors=$((errors + 1))
else
  echo "OK: 0 undefined references"
fi

# Undefined citations
undef_cites=$(grep -c "LaTeX Warning: Citation.*undefined" "$LOG" 2>/dev/null || true)
if [ "$undef_cites" -gt 0 ]; then
  echo "FAIL: $undef_cites undefined citation(s)"
  grep "LaTeX Warning: Citation.*undefined" "$LOG"
  errors=$((errors + 1))
else
  echo "OK: 0 undefined citations"
fi

# LaTeX errors
latex_errors=$(grep -c "^!" "$LOG" 2>/dev/null || true)
if [ "$latex_errors" -gt 0 ]; then
  echo "FAIL: $latex_errors LaTeX error(s)"
  grep "^!" "$LOG"
  errors=$((errors + 1))
else
  echo "OK: 0 LaTeX errors"
fi

# Overfull boxes (warning, not failure)
overfull=$(grep -c "Overfull" "$LOG" 2>/dev/null || true)
echo "INFO: $overfull overfull box warning(s)"

# Typography rules for this stack. The sources use no em dash and no
# section sign. The byte escapes keep this script clean under its own
# rules.
EM_DASH=$'\xe2\x80\x94'
SECTION_SIGN=$'\xc2\xa7'
src_hits=$(grep -rEn --include='*.tex' --include='*.bib' \
  "(${EM_DASH}|${SECTION_SIGN})" . 2>/dev/null || true)
if [ -n "$src_hits" ]; then
  count=$(printf '%s\n' "$src_hits" | wc -l | tr -d ' ')
  echo "FAIL: $count source line(s) with an em dash or a section sign"
  printf '%s\n' "$src_hits"
  errors=$((errors + 1))
else
  echo "OK: sources carry no em dash and no section sign"
fi

# Rendered output check. The typeset pages show no section sign and no
# end-of-proof mark.
if command -v pdftotext >/dev/null 2>&1 && [ -f "${NAME}.pdf" ]; then
  BLACK_SQUARE=$'\xe2\x96\xa0'
  WHITE_SQUARE=$'\xe2\x96\xa1'
  END_OF_PROOF=$'\xe2\x88\x8e'
  pdf_hits=$(pdftotext "${NAME}.pdf" - 2>/dev/null | grep -cE \
    "(${SECTION_SIGN}|${BLACK_SQUARE}|${WHITE_SQUARE}|${END_OF_PROOF})" || true)
  if [ "$pdf_hits" -gt 0 ]; then
    echo "FAIL: $pdf_hits rendered line(s) with a section sign or a proof mark"
    errors=$((errors + 1))
  else
    echo "OK: rendered pages carry no section sign and no proof mark"
  fi
else
  echo "INFO: pdftotext or ${NAME}.pdf not found; rendered output check skipped"
fi

# Advisory lint. chktex reports TeX idiom warnings. Some warnings are
# false positives on correct mathematics, so the count is informative
# and does not fail the build.
if command -v chktex >/dev/null 2>&1; then
  lint=$(chktex -q "$MASTER" sections/*.tex shared/*/*.tex 2>/dev/null \
    | grep -c '^Warning' || true)
  echo "INFO: $lint chktex warning(s); review with: chktex -q $MASTER sections/*.tex"
else
  echo "INFO: chktex not found; TeX lint skipped"
fi

if [ "$errors" -gt 0 ]; then
  echo "VALIDATION FAILED ($errors issue(s))"
  exit 1
else
  echo "VALIDATION PASSED"
fi
