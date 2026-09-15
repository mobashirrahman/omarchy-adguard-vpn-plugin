# Omarchy AdGuard VPN plugin

An [Omarchy](https://omarchy.org/) bar widget for [AdGuard VPN](https://adguard-vpn.com/)'s
`adguardvpn-cli`. Shows connection status in the bar, with one-click
connect/disconnect and a searchable picker for choosing a specific location.

- **Left-click**: connect (to the last used location) or disconnect.
- **Right-click**: open a searchable list of every AdGuard VPN location and
  connect to the one you pick.
- Connected state uses the theme's accent color instead of the default
  urgent/red, since "connected" isn't a warning.

## Requirements

- `adguardvpn-cli` installed and logged in (`adguardvpn-cli login`).
- Passwordless sudo for one small root-owned wrapper, so bar clicks never
  block on a password prompt. `adguardvpn-cli` re-execs itself as root
  internally (`sudo -b env ... adguardvpn-cli connect ...`), so a sudoers
  rule on the plain `connect` command never matches — a tiny wrapper script
  is granted passwordless sudo instead, and nothing else is affected.

## Install

```bash
omarchy plugin add <this-repo-url> --enable
```

Then run the one-time setup once, in a terminal (you'll authenticate one
last time):

```bash
~/.config/omarchy/plugins/mobashirrahman.adguardvpn/scripts/vpn-setup-passwordless.sh
```

## Settings

| Key | Type | Default | Description |
|---|---|---|---|
| `refreshIntervalSec` | integer | `5` | How often the bar polls VPN status. |

## How it works

- `scripts/vpn-status` calls `adguardvpn-cli status` and prints Waybar-style
  JSON that the widget polls on a timer.
- `scripts/vpn-toggle` (left-click) connects or disconnects based on current
  status.
- `scripts/vpn-select-location` (right-click) parses
  `adguardvpn-cli list-locations`, opens it in Omarchy's built-in
  `omarchy-menu-select` picker, and connects to the chosen city.
- `scripts/vpn-setup-passwordless.sh` installs a root-owned wrapper at
  `/usr/local/bin/adguardvpn-bar-connect` and a matching
  `NOPASSWD` sudoers rule scoped to only that wrapper, so the two scripts
  above never block waiting for a password.

## License

MIT, see [LICENSE](LICENSE).
