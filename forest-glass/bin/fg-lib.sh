# Forest Glass rice — shared helpers. Source this from BASH only (zsh ties
# a variable named `path` to $PATH; scripts here all use #!/usr/bin/env bash).
#
# Every tracked change goes through these functions so the rollback script
# knows the original state and the state this task applied:
#   fg_track_file  PHASE PATH         back up PATH once (or mark it as new)
#   fg_mark_file   PATH               record PATH's hash after we wrote it
#   fg_set_key     PHASE DCONF_KEY V  record original value once, then write V
#
# Backups are never overwritten: the first recorded original always wins.

set -o pipefail
[ -n "${BASH_VERSION:-}" ] || { echo "fg-lib.sh must be sourced from bash" >&2; return 1; }

FG_HOME="$HOME/.config/forest-glass"
FG_BK="$(cat "$FG_HOME/current-backup" 2>/dev/null)"
[ -n "$FG_BK" ] && [ -d "$FG_BK" ] || { echo "fg-lib: no backup dir recorded" >&2; return 1 2>/dev/null || exit 1; }
FG_MANIFEST="$FG_BK/MANIFEST.tsv"
touch "$FG_MANIFEST"

fg_id() { printf '%s' "$1" | sed 's|^/||; s|/|__|g'; }
fg_sha() { [ -e "$1" ] && sha256sum "$1" | cut -d' ' -f1 || echo MISSING; }
fg_log() { printf '\033[32m[forest-glass]\033[0m %s\n' "$*"; }

fg_in_manifest() { cut -f1,3 "$FG_MANIFEST" | grep -qxF "$(printf '%s\t%s' "$1" "$2")"; }

fg_track_file() {
  local phase="$1" target="$2" rel id
  rel="${target#"$HOME"/}"; id="$(fg_id "$rel")"
  if fg_in_manifest file "$target" || fg_in_manifest newfile "$target"; then return 0; fi
  if [ -e "$target" ]; then
    mkdir -p "$FG_BK/files/$(dirname "$rel")"
    cp -a --no-clobber "$target" "$FG_BK/files/$rel"
    fg_sha "$target" > "$FG_BK/state/$id.orig"
    printf 'file\t%s\t%s\n' "$phase" "$target" >> "$FG_MANIFEST"
    fg_log "backed up $rel"
  else
    printf 'newfile\t%s\t%s\n' "$phase" "$target" >> "$FG_MANIFEST"
    fg_log "tracking new file $rel"
  fi
}

fg_mark_file() {
  local rel="${1#"$HOME"/}"
  fg_sha "$1" > "$FG_BK/state/$(fg_id "$rel").applied"
}

# Restore one tracked file from its backup immediately (used on failed validation).
fg_revert_file() {
  local target="$1" rel="${1#"$HOME"/}"
  if [ -e "$FG_BK/files/$rel" ]; then cp -a "$FG_BK/files/$rel" "$target"; fg_log "reverted $rel"
  else rm -f -- "$target"; fg_log "removed new file $rel"; fi
}

fg_set_key() {
  local phase="$1" key="$2" value="$3" id
  id="$(fg_id "$key")"
  if ! fg_in_manifest dconf "$key"; then
    dconf read "$key" > "$FG_BK/dconf/$id.orig"   # empty file == key was unset
    printf 'dconf\t%s\t%s\n' "$phase" "$key" >> "$FG_MANIFEST"
  fi
  dconf write "$key" "$value" || { echo "fg-lib: failed to write $key" >&2; return 1; }
  dconf read "$key" > "$FG_BK/dconf/$id.applied"
  fg_log "set $key = $(head -c 120 "$FG_BK/dconf/$id.applied")"
}
