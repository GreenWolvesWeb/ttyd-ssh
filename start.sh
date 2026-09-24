#!/bin/sh
set -e
: "${TTYD_PASSWORD:?TTYD_PASSWORD is required}"

SSH_DIR=/home/dev/.ssh
mkdir -p "$SSH_DIR"

# SSH_PRIVATE_KEY: the PEM text itself (real newlines or literal \n), or base64 of it
if [ -n "$SSH_PRIVATE_KEY" ]; then
  case "$SSH_PRIVATE_KEY" in
    *"BEGIN "*) printf '%b\n' "$SSH_PRIVATE_KEY" > "$SSH_DIR/key.tmp" ;;
    *)          printf '%s' "$SSH_PRIVATE_KEY" | base64 -d > "$SSH_DIR/key.tmp" 2>/dev/null || true ;;
  esac
  chmod 600 "$SSH_DIR/key.tmp"
  # Name the file after the key type so ssh picks it up by default
  case "$(ssh-keygen -l -f "$SSH_DIR/key.tmp" 2>/dev/null)" in
    *"(ED25519)") mv "$SSH_DIR/key.tmp" "$SSH_DIR/id_ed25519" ;;
    *"(RSA)")     mv "$SSH_DIR/key.tmp" "$SSH_DIR/id_rsa" ;;
    *"(ECDSA)")   mv "$SSH_DIR/key.tmp" "$SSH_DIR/id_ecdsa" ;;
    *) rm -f "$SSH_DIR/key.tmp"; echo "WARNING: SSH_PRIVATE_KEY is not a valid private key, ignored" >&2 ;;
  esac
fi

# SSH_KNOWN_HOSTS (optional): same formats; avoids host-key prompts after every redeploy
if [ -n "$SSH_KNOWN_HOSTS" ]; then
  case "$SSH_KNOWN_HOSTS" in
    *" ssh-"*|*" ecdsa-"*) printf '%b\n' "$SSH_KNOWN_HOSTS" > "$SSH_DIR/known_hosts" ;;
    *)                     printf '%s' "$SSH_KNOWN_HOSTS" | base64 -d > "$SSH_DIR/known_hosts" 2>/dev/null \
                             || { rm -f "$SSH_DIR/known_hosts"; echo "WARNING: SSH_KNOWN_HOSTS could not be decoded, ignored" >&2; } ;;
  esac
fi

chown -R dev:dev "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Web terminal runs as the unprivileged 'dev' user; Miget sets PORT=5000
exec ttyd -p "${PORT:-5000}" -W \
  -c "${TTYD_USERNAME:-dev}:${TTYD_PASSWORD}" \
  su - dev
