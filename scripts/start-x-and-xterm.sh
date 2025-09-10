#!/usr/bin/env bash
# start-x-and-x-term.sh
# Opens 1 white X11 xterm + (N-1) mintty terminals, all in the SAME directory.
# Also: starts a shared ssh-agent; first xterm runs ssh-add + git push (if repo).
# Defaults: /cygdrive/c/design/sds1104xu/pelengator/  4  55  25

set -euo pipefail
err(){ echo "Error: $*" >&2; exit 1; }

# --- Defaults (overridable by args) ---
DEF_DIR="/cygdrive/c/design/sds1104xu/pelengator/"
DEF_NUM=4
DEF_COLS=55
DEF_ROWS=25

START_DIR="${1-${DEF_DIR}}"
NUM_TERMS="${2-${DEF_NUM}}"
COLS="${3-${DEF_COLS}}"
ROWS="${4-${DEF_ROWS}}"

# Git/SSH defaults
SSH_KEY_PATH="${SSH_KEY_PATH:-$HOME/.ssh/ssh-keys-ed25519-forjustaneutral}"

# Tiling defaults (grid cols = ceil(sqrt(N)))
sqrt_ceil(){ awk -v n="$1" 'BEGIN{ printf("%d", int(sqrt(n)+0.999999)) }'; }
DEFAULT_TILE_COLS="$(sqrt_ceil "${NUM_TERMS}")"

TILE_COLS="${5-${DEFAULT_TILE_COLS}}"
TILE_W_PX="${6-800}"
TILE_H_PX="${7-600}"
X0="${8-60}"     # top-left X
Y0="${9-60}"     # top-left Y
GAP_X="${10-10}" # horizontal gap
GAP_Y="${11-40}" # vertical gap

# --- Validate ---
[[ -d "${START_DIR}" ]] || err "START_DIR not found: ${START_DIR}"
case "${NUM_TERMS}" in ''|*[!0-9]* ) err "NUM_TERMS must be integer";; esac
case "${COLS}" in ''|*[!0-9]* ) err "COLS must be integer";; esac
case "${ROWS}" in ''|*[!0-9]* ) err "ROWS must be integer";; esac
case "${TILE_COLS}" in ''|*[!0-9]* ) err "TILE_COLS must be integer";; esac

command -v /usr/bin/startxwin >/dev/null || err "startxwin not found (install xorg-server xinit)"
command -v /usr/bin/mintty   >/dev/null || err "mintty not found"
command -v /usr/bin/xterm    >/dev/null || err "xterm not found"
command -v /usr/bin/ssh-agent >/dev/null || err "ssh-agent not found"
command -v /usr/bin/ssh-add    >/dev/null || err "ssh-add not found"
command -v /usr/bin/git        >/dev/null || err "git not found"

# --- Start XWin if needed ---
if ! pgrep -x XWin >/dev/null 2>&1; then
  echo "[INFO] Starting XWin..."
  /usr/bin/startxwin -- -multiwindow -clipboard -nowgl >/dev/null 2>&1 &
  sleep 2
fi

# --- Environment that keeps Cygwin login shells in our directory ---
export DISPLAY=:0.0
export CHERE_INVOKING=1

# --- Start (or reuse) a shared ssh-agent in this parent shell ---
if [[ -z "${SSH_AUTH_SOCK:-}" ]] || ! ps -p "${SSH_AGENT_PID:-0}" >/dev/null 2>&1; then
  echo "[INFO] Starting ssh-agent for this session..."
  eval "$(/usr/bin/ssh-agent -s)"
fi
export SSH_AUTH_SOCK SSH_AGENT_PID

# --- Create a robust wrapper that forces cwd and optionally runs git flow, then execs a login shell ---
WRAP="$(/usr/bin/mktemp /tmp/cygterm-wrap.XXXXXX.sh)"
cat > "$WRAP" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
# Args: TARGET_DIR, WINDOW_TAG, RUN_GIT("yes"|"no"), SSH_KEY_PATH
TARGET_DIR="$1"; shift
WINDOW_TAG="$1"; shift || true
RUN_GIT="${1:-no}"; shift || true
SSH_KEY_PATH="${1:-$HOME/.ssh/id_ed25519}"

# Keep login shells in current dir and share agent
export DISPLAY=${DISPLAY:-:0.0}
export CHERE_INVOKING=1

cd "$TARGET_DIR" || { echo "cd failed: $TARGET_DIR" >&2; exec /usr/bin/bash -l; }

echo "[$WINDOW_TAG] DISPLAY=$DISPLAY ; pwd=$(pwd)"

if [[ "$RUN_GIT" == "yes" ]] && [[ -d ".git" ]]; then
  echo "[$WINDOW_TAG] Git repo detected. Running git pre-push steps..."
  git config --list --global || true
  # Add key to the already-running agent (prompts for passphrase here if needed)
  if [[ -f "$SSH_KEY_PATH" ]]; then
    /usr/bin/ssh-add "$SSH_KEY_PATH" || true
  else
    echo "[$WINDOW_TAG] WARNING: SSH key not found at $SSH_KEY_PATH" >&2
  fi
  # Attempt git status; any failure leaves you at the shell to inspect
  /usr/bin/git status || true
fi

# Exec a *login* bash so your normal environment is loaded
exec /usr/bin/bash -l
EOF
chmod +x "$WRAP"

# --- Tiling helper ---
tile_pos(){ # arg: index -> echoes "x y"
  local idx="$1"
  local row=$(( idx / TILE_COLS ))
  local col=$(( idx % TILE_COLS ))
  local x=$(( X0 + col * (TILE_W_PX + GAP_X) ))
  local y=$(( Y0 + row * (TILE_H_PX + GAP_Y) ))
  echo "${x} ${y}"
}

# --- 1) One white X11 xterm in tile #0 (RUN_GIT=yes here) ---
read X_POS0 Y_POS0 < <(tile_pos 0)
/usr/bin/xterm \
  -geometry "${COLS}x${ROWS}+${X_POS0}+${Y_POS0}" \
  -bg white -fg black \
  -fa 'Monospace' -fs 11 \
  -title "X11 xterm (1 of ${NUM_TERMS})" \
  -e "$WRAP" "${START_DIR}" "xterm" "yes" "${SSH_KEY_PATH}" &
sleep 0.2

# --- 2) Remaining (NUM_TERMS-1) mintty terminals (black), RUN_GIT=no ---
for (( i=1; i<NUM_TERMS; i++ )); do
  read PX PY < <(tile_pos "${i}")
  TITLE="Cygwin $((i+1))/${NUM_TERMS}"

  /usr/bin/mintty \
    --position "${PX},${PY}" \
    -o Columns="${COLS}" -o Rows="${ROWS}" \
    -o BackgroundColour=0,0,0 -o ForegroundColour=255,255,255 \
    -i /Cygwin-Terminal.ico \
    -t "${TITLE}" \
    "$WRAP" "${START_DIR}" "${TITLE}" "no" "${SSH_KEY_PATH}" &
  sleep 0.1
done

wait
# Optionally: rm -f "$WRAP"

