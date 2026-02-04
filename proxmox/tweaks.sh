#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit nullglob

die() { echo "ERROR: $*" >&2; exit 1; }
info() { echo "==> $*"; }

[[ $EUID -eq 0 ]] || die "Run as root"

# --- Verify PVE 9.x ---
PVE_VERSION="$(pveversion | awk -F'/' '{print $2}' | awk -F'-' '{print $1}' || true)"
[[ -n "${PVE_VERSION:-}" ]] || die "Unable to detect Proxmox VE version"
PVE_MAJOR="${PVE_VERSION%%.*}"
[[ "$PVE_MAJOR" == "9" ]] || die "This script is intended for Proxmox VE 9.x (detected: $PVE_VERSION)"

info "Proxmox VE version: $PVE_VERSION"
echo

# --- Disable legacy APT sources and use ONLY deb822 ---
info "Disabling legacy APT sources (.list and sources.list)"
if [[ -f /etc/apt/sources.list ]] && grep -qE '^\s*deb\s+' /etc/apt/sources.list; then
  cp -a /etc/apt/sources.list /etc/apt/sources.list.bak
  sed -i 's/^\s*deb\s\+/# Disabled by noninteractive PVE9 script: deb /' /etc/apt/sources.list
  info "Backed up and disabled deb lines in /etc/apt/sources.list (-> sources.list.bak)"
fi

for f in /etc/apt/sources.list.d/*.list; do
  [[ -e "$f" ]] || continue
  mv -f "$f" "$f.bak"
done
info "Renamed legacy /etc/apt/sources.list.d/*.list to *.list.bak (if any)"

# --- Migrate to deb822 sources format (Debian Trixie) ---
info "Writing deb822 Debian sources (trixie)"
cat >/etc/apt/sources.list.d/debian.sources <<'EOF'
Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://deb.debian.org/debian
Suites: trixie-updates
Components: main contrib
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF

if [[ -f /etc/apt/sources.list ]]; then
  sed -i '/proxmox/d;/bookworm/d' /etc/apt/sources.list || true
fi

# --- Delete pve-enterprise repositories if present ---
info "Removing pve-enterprise repositories (if any)"
rm -f /etc/apt/sources.list.d/pve-enterprise.sources 2>/dev/null || true
for f in /etc/apt/sources.list.d/*.sources; do
  [[ -e "$f" ]] || continue
  if grep -qE '^\s*Components:\s*.*\bpve-enterprise\b' "$f"; then
    rm -f "$f"
  fi
done

# --- Delete Ceph enterprise repositories if present ---
info "Removing Ceph enterprise repositories (if any)"
for f in /etc/apt/sources.list.d/*.sources; do
  [[ -e "$f" ]] || continue
  if grep -qE 'enterprise\.proxmox\.com/.*/ceph' "$f" || \
     (grep -qE '\bceph\b' "$f" && grep -qE '\benterprise\b' "$f"); then
    rm -f "$f"
  fi
done

# --- Ensure pve-no-subscription repository is enabled ---
info "Ensuring pve-no-subscription repository is enabled"
PVE_NS_FILE="/etc/apt/sources.list.d/proxmox.sources"
if [[ -f "$PVE_NS_FILE" ]]; then
  sed -i '/^\s*Enabled:\s*false\s*$/Id' "$PVE_NS_FILE" || true
  sed -i '/^#\s*Types:/,/^$/s/^#\s*//' "$PVE_NS_FILE" || true
else
  cat >"$PVE_NS_FILE" <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
fi

for f in /etc/apt/sources.list.d/*.sources; do
  [[ -e "$f" ]] || continue
  if grep -qE '^\s*Components:\s*.*\bpve-no-subscription\b' "$f"; then
    sed -i '/^\s*Enabled:\s*false\s*$/Id' "$f" || true
    sed -i '/^#\s*Types:/,/^$/s/^#\s*//' "$f" || true
  fi
done

# --- Ceph no-subscription (created but disabled by default) ---
info "Creating Ceph no-subscription repository (disabled by default)"
cat >/etc/apt/sources.list.d/ceph.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/ceph-squid
Suites: trixie
Components: no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF

# --- Disable pve-test repository ---
info "Disabling pve-test repository"
for f in /etc/apt/sources.list.d/*.sources; do
  [[ -e "$f" ]] || continue
  if grep -qE '^\s*Components:\s*.*\bpve-test\b' "$f"; then
    if grep -qE '^\s*Enabled:' "$f"; then
      sed -i 's/^\s*Enabled:.*/Enabled: false/I' "$f"
    else
      echo "Enabled: false" >>"$f"
    fi
  fi
done

cat >/etc/apt/sources.list.d/pve-test.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-test
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF

info "Disabling subscription nag"
mkdir -p /usr/local/bin
cat >/usr/local/bin/pve-remove-nag.sh <<'EOF'
#!/bin/sh
WEB_JS=/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
if [ -s "$WEB_JS" ] && ! grep -q NoMoreNagging "$WEB_JS"; then
  sed -i -e "/data\.status/ s/!//" -e "/data\.status/ s/active/NoMoreNagging/" "$WEB_JS"
fi

MOBILE_TPL=/usr/share/pve-yew-mobile-gui/index.html.tpl
MARKER="<!-- MANAGED BLOCK FOR MOBILE NAG -->"
if [ -f "$MOBILE_TPL" ] && ! grep -q "$MARKER" "$MOBILE_TPL"; then
  printf "%s\n" \
    "$MARKER" \
    "<script>" \
    "  function removeSubscriptionElements() {" \
    "    const dialogs = document.querySelectorAll('dialog.pwt-outer-dialog');" \
    "    dialogs.forEach(dialog => {" \
    "      const text = (dialog.textContent || '').toLowerCase();" \
    "      if (text.includes('subscription')) dialog.remove();" \
    "    });" \
    "    const cards = document.querySelectorAll('.pwt-card.pwt-p-2.pwt-d-flex.pwt-interactive.pwt-justify-content-center');" \
    "    cards.forEach(card => {" \
    "      const text = (card.textContent || '').toLowerCase();" \
    "      const hasButton = card.querySelector('button');" \
    "      if (!hasButton && text.includes('subscription')) card.remove();" \
    "    });" \
    "  }" \
    "  const observer = new MutationObserver(removeSubscriptionElements);" \
    "  observer.observe(document.body, { childList: true, subtree: true });" \
    "  removeSubscriptionElements();" \
    "  setInterval(removeSubscriptionElements, 300);" \
    "  setTimeout(() => {observer.disconnect();}, 10000);" \
    "</script>" \
    "" >> "$MOBILE_TPL"
fi
EOF
chmod 755 /usr/local/bin/pve-remove-nag.sh

cat >/etc/apt/apt.conf.d/no-nag-script <<'EOF'
DPkg::Post-Invoke { "/usr/local/bin/pve-remove-nag.sh"; };
EOF
chmod 644 /etc/apt/apt.conf.d/no-nag-script

apt --reinstall install -y proxmox-widget-toolkit >/dev/null || true

# --- Disable high availability and Corosync ---
info "Disabling HA services and Corosync"
systemctl disable -q --now pve-ha-lrm 2>/dev/null || true
systemctl disable -q --now pve-ha-crm 2>/dev/null || true
systemctl disable -q --now corosync 2>/dev/null || true

# --- Add "snippets" scope to local ---
# We need snippets for cloud-init user-data storage
info "Adding 'snippets' content type to 'local' datastore"
pvesm set local --content backup,iso,snippets 2>/dev/null || true

# --- Post-install reminder ---
cat <<'EOF'

[Support Subscriptions]
If you rely on Proxmox VE in production, consider purchasing a subscription
from the official Proxmox website to support development.

[Post-install reminder]
- Please update Proxmox VE: apt update && apt upgrade -y
- Reboot the host to apply updates.
- Clear browser cache or hard reload (Ctrl+Shift+R) before using the Web UI.
EOF

info "Completed"
