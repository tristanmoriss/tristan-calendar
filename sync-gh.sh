#!/bin/bash
set -e
REPO="tristan-calendar"
SRC="/Users/tristanmorissette/.hermes/profiles/calendar/workspace"
DIR="$SRC/gh-pages"
mkdir -p "$DIR"
cp "$SRC/events.json" "$DIR/events.json" 2>/dev/null || true
cd "$DIR"
if [ ! -d .git ]; then git init -q; git branch -m main; git remote add origin "https://github.com/tristanmoriss/$REPO.git" 2>/dev/null || true; fi
git config user.name >/dev/null 2>&1 || git config user.name tristanmorissette
git config user.email >/dev/null 2>&1 || git config user.email tristancareers9@gmail.com
if git fetch -q origin main 2>/dev/null; then
  if git show origin/main:events.json > /tmp/repo_events.json 2>/dev/null; then
    python3 - "$SRC/events.json" /tmp/repo_events.json <<'PY'
import json,sys
a=json.load(open(sys.argv[1])); b=json.load(open(sys.argv[2]))
la=a["events"] if isinstance(a,dict) else a; lb=b["events"] if isinstance(b,dict) else b
key=lambda e:(e["date"],e.get("time",""),e["title"])
seen={key(e) for e in la}
m=la+[e for e in lb if key(e) not in seen]
m.sort(key=lambda e:(e["date"],e.get("time","")))
json.dump({"events":m},open(sys.argv[1],"w"),indent=1)
print(f"union-merged: {len(la)}+{len(lb)} -> {len(m)}")
PY
    cp "$SRC/events.json" "$DIR/events.json"
  fi
fi
git pull --rebase -q origin main 2>/dev/null || true
git add -A; git commit -qm "calendar sync $(date '+%m-%d %H:%M')" || echo "no changes"
git push -q -u origin main 2>&1 | tail -1 || true
export PATH="$PATH:/Users/tristanmorissette/.hermes/tools/bin"
gh api -X POST repos/tristanmoriss/$REPO/pages/builds >/dev/null 2>&1 || true
echo "synced tristanmoriss/$REPO"
