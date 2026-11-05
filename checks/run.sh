#!/bin/sh
# checks/run.sh -- the theatre's promises, checked in sh and awk.
#   T1  every page and picture keeps the theatre's CSP (default-src 'none'; style-src 'self'; img-src 'self' data:):
#       no script, no <style>, no style= or on...= attribute, nothing loaded from another host
#   T2  every local link and source on a page resolves to a file in public/
#   T3  the front page lists every show folder, and every listed show has a folder
#   sh checks/run.sh              the checks
#   sh checks/run.sh --prove-red  one planted fault per check, in a scratch copy; each must go red
# Copyright 2026 INPUTLOOP; GPL-3.0-or-later OR LGPL-3.0-or-later.  Mentat (for Corwin, claude-opus-5-5)
set -u
HERE=$(cd "$(dirname "$0")/.." && pwd); PUB=${PUB:-$HERE/public}
fail=0; ok() { [ -n "${QUIET:-}" ] || echo "  ok    $1"; }; bad() { fail=$((fail + 1)); echo "  FAIL  $1"; }
BADRE='<script|<style|[[:space:]]style=|[[:space:]]on[a-z]+=|(src|srcset|href)="https?://[^"]*\.(js|css|svg|png|jpg|woff2?)"|<link[^>]*href="https?:'
echo "T1 the CSP"
for f in $(find "$PUB" -type f \( -name '*.html' -o -name '*.svg' \) | sort); do
  if grep -q -i -E "$BADRE" "$f"; then bad "${f#$PUB/} breaks the CSP: $(grep -o -i -E "$BADRE" "$f" | head -1)"; else ok "${f#$PUB/}"; fi
done
echo "T2 local links"
for f in $(find "$PUB" -type f -name '*.html' | sort); do
  d=$(dirname "$f")
  for l in $(grep -o -E '(href|src)="[^"#?]+' "$f" | sed 's/^[a-z]*="//' | grep -v -E '^(https?:|mailto:)'); do
    case $l in /*) t=$PUB$l ;; *) t=$d/$l ;; esac
    case $t in */) t=${t}index.html ;; esac
    [ -e "$t" ] || bad "${f#$PUB/}: $l does not resolve"
  done
done
[ "$fail" -eq 0 ] && ok "every local link resolves"
echo "T3 the front page and the show folders"
for s in $(find "$PUB" -mindepth 2 -maxdepth 2 -name index.html | sed "s|$PUB/||; s|/index.html||" | sort); do
  grep -q "href=\"/$s/\"" "$PUB/index.html" && ok "$s is listed" || bad "show folder $s is not on the front page"
done
for s in $(grep -o 'class="show" href="/[^"]*/"' "$PUB/index.html" | sed 's|.*href="/||; s|/"||'); do
  [ -f "$PUB/$s/index.html" ] || bad "the front page lists $s, which has no folder"
done
if [ "${1:-}" = --prove-red ]; then
  [ "$fail" -eq 0 ] || { echo "PROVE-RED: the control is not green"; exit 1; }
  red=0 not=0
  plant() {  # $1 what, $2 command run inside the scratch copy's public/
    w=$(mktemp -d) || exit 2; cp -R "$PUB" "$w/public"
    (cd "$w/public" && eval "$2")
    if PUB=$w/public QUIET=1 sh "$0" > "$w/out" 2>&1; then echo "  GREEN $1"; not=$((not + 1))
    else echo "  red   $1: $(grep -m1 FAIL "$w/out" | sed 's/^ *FAIL *//')"; red=$((red + 1)); fi
    rm -rf "$w"
  }
  echo "prove-red"
  plant "an inline style" "sed -i 's/<main class=\"stage\">/<main style=\"x\" class=\"stage\">/' index.html"
  plant "a script from another host" "sed -i 's|</body>|<script src=\"https://example.org/x.js\"></script></body>|' 404.html"
  plant "a broken local link" "sed -i 's|href=\"/site.css\"|href=\"/sites.css\"|' 404.html"
  plant "a show folder not listed" "cp -R to-the-two-readers new-show"
  plant "a listed show with no folder" "mv to-the-two-readers gone"
  echo "prove-red: $red red, $not not"
  [ "$not" -eq 0 ] && echo "PROVE-RED OK"; [ "$not" -eq 0 ]; exit $?
fi
echo "checks: $fail failed"; [ "$fail" -eq 0 ]
