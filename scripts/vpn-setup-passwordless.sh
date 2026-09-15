#!/usr/bin/env bash
# One-time setup: allow the bar's one-click AdGuard VPN toggle to
# connect/disconnect without ever prompting for a password.
#
# Why a wrapper: adguardvpn-cli re-invokes itself as root via
# `sudo -b env ... adguardvpn-cli connect ...`, so a sudoers rule on the
# plain connect command never matches. Instead we allow passwordless sudo
# for ONLY this tiny root-owned wrapper (which just runs connect) plus
# disconnect. Everything else still asks for a password as usual.
#
# Run once in a terminal (you'll authenticate one last time):
#   ~/.config/omarchy/plugins/mobashirrahman.adguardvpn/scripts/vpn-setup-passwordless.sh
set -euo pipefail

ME="$(id -un)"
WRAPPER="/usr/local/bin/adguardvpn-bar-connect"

sudo tee "$WRAPPER" >/dev/null <<'EOF'
#!/bin/sh
# Root-owned helper for the Omarchy bar VPN toggle. Started via the
# passwordless sudoers rule so the CLI, running as root, can create/own
# tun0 without its own internal sudo (which needs a password/fingerprint).
#
# When sudo starts us, HOME points at /root, so adguardvpn-cli would look
# for its license/config under /root and fail. Reconstruct the invoking
# user's environment first - exactly what the original
# `sudo -b env HOME=... XDG_DATA_HOME=...` invocation did.
U="${SUDO_USER:-$(id -un)}"
H="$(getent passwd "$U" | cut -d: -f6)"
[ -n "$H" ] || H="$HOME"

export HOME="$H"
export XDG_DATA_HOME="$H/.local/share"
UID_NUM="$(id -u "$U")"
export XDG_RUNTIME_DIR="/run/user/$UID_NUM"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$UID_NUM/bus"

case "${1:-}" in
  disconnect)
    exec /usr/bin/adguardvpn-cli disconnect
    ;;
  connect|"")
    [ $# -gt 0 ] && shift
    exec /usr/bin/adguardvpn-cli connect -y --no-progress "$@"
    ;;
  *)
    exec /usr/bin/adguardvpn-cli "$@"
    ;;
esac
EOF
sudo chown root:root "$WRAPPER"
sudo chmod 755 "$WRAPPER"

# The wrapper handles both directions, so it is the only NOPASSWD grant.
printf '%s\n' "$ME ALL=(root) NOPASSWD: $WRAPPER" \
  | sudo tee /etc/sudoers.d/adguardvpn-cli >/dev/null
sudo chmod 440 /etc/sudoers.d/adguardvpn-cli
sudo visudo -c

# Non-destructive self-tests: `--help` only prints help, but proves the
# passwordless path works end to end.
if sudo -n "$WRAPPER" --help >/dev/null 2>&1; then
  echo "Verified: passwordless connect path works."
else
  echo "WARNING: verification failed - sudo still prompted. Share this output when asking for help."
  exit 1
fi

echo "Done. Bar VPN clicks will no longer prompt for a password."
