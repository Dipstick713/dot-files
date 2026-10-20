#!/usr/bin/env bash
# Copy the Forest Glass tooling into ~/.dotfiles/forest-glass/ and refresh the
# exported rice settings. Idempotent; only ever writes inside that folder.
# Does not commit — review with `git -C ~/.dotfiles diff` and commit yourself.
set -euo pipefail
FG_HOME="$HOME/.config/forest-glass"
DEST="$HOME/.dotfiles/forest-glass"
[ -d "$HOME/.dotfiles/.git" ] || { echo "~/.dotfiles is not a git repo" >&2; exit 1; }
mkdir -p "$DEST/bin" "$DEST/src" "$DEST/dconf"
# Mirror bin/ and src/ (removing files deleted from the tooling), plus README.
rsync -a --delete "$FG_HOME/bin/" "$DEST/bin/"
rsync -a --delete "$FG_HOME/src/" "$DEST/src/"
install -m 644 "$FG_HOME/README.md" "$DEST/README.md"

# Current values of every dconf key the rice manages (from the backup manifest),
# in `dconf load` format. Reference/restore aid; the apply scripts set these too.
BK="$(cat "$FG_HOME/current-backup")"
python3 -I - "$BK/MANIFEST.tsv" "$DEST/dconf/rice-settings.ini" <<'PY'
import subprocess, sys, collections
manifest, out = sys.argv[1:3]
groups = collections.OrderedDict()
for line in open(manifest):
    kind, _phase, key = line.rstrip('\n').split('\t')
    if kind != 'dconf':
        continue
    val = subprocess.run(['dconf', 'read', key], capture_output=True, text=True).stdout.strip()
    if not val:
        continue
    d, k = key.rsplit('/', 1)
    groups.setdefault(d, {})[k] = val
with open(out, 'w') as f:
    f.write('# Forest Glass rice settings. Restore with:\n#   dconf load / < rice-settings.ini\n\n')
    for d, kv in sorted(groups.items()):
        f.write(f'[{d.lstrip("/")}]\n')
        for k, v in sorted(kv.items()):
            f.write(f'{k}={v}\n')
        f.write('\n')
PY
echo "[forest-glass] synced to $DEST"
git -C "$HOME/.dotfiles" status --short -- forest-glass
