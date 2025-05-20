#!/usr/bin/env bash
#
# ──────────────────────────────────────────────────────────────────────────────
#  Phoenix-RTOS Appliance lifecycle script
#  * install    – handled at image-build time (no runtime action)
#  * configure  – runs once at first boot inside the VM
#  * bootstrap  – not used for this appliance
# ──────────────────────────────────────────────────────────────────────────────

### ── helper banner ──────────────────────────────────────────────────────────
service_help() {
cat <<'EOF'
Phoenix-RTOS Appliance
──────────────────────
  install    – (no-op, already done in the image)
  configure  – installs Docker and launches the Phoenix-RTOS container
  bootstrap  – (not used)
EOF
}

### ── install stage (stub) ───────────────────────────────────────────────────
service_install() { echo "[Phoenix-RTOS] install stage not required."; }

### ── CONFIGURE stage (main work) ────────────────────────────────────────────
service_configure() {
  set -euo pipefail
  LOG=/root/startup.log
  exec >"$LOG" 2>&1

  progress() { echo -e "\e[1;32m$*\e[0m" >/dev/tty1 || true; }

  # make sure we are on tty1 (harmless on headless guests)
  chvt 1               2>/dev/null || true
  clear >/dev/tty1     2>/dev/null || true
  systemctl stop  getty@tty1.service 2>/dev/null || true
  systemctl mask getty@tty1.service 2>/dev/null || true

  ## ── basic network tweaks ────────────────────────────────────────────────
  progress "Updating DNS configuration…"
  sed -i 's/^#\?DNS=.*/DNS=8.8.8.8 1.1.1.1/'        /etc/systemd/resolved.conf
  sed -i 's/^#\?FallbackDNS=.*/FallbackDNS=8.8.4.4 9.9.9.9/' /etc/systemd/resolved.conf
  systemctl restart systemd-resolved
  ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf

  ## ── Docker engine ───────────────────────────────────────────────────────
  progress "Installing Docker…"
  DEBIAN_FRONTEND=noninteractive apt-get update -y
  apt-get install -y ca-certificates curl gnupg lsb-release

  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | tee /etc/apt/keyrings/docker.asc >/dev/null
  chmod a+r /etc/apt/keyrings/docker.asc
  echo \
   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
   >/etc/apt/sources.list.d/docker.list

  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io \
                     docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker

  ## ── pull + start Phoenix-RTOS container ─────────────────────────────────
  progress "Downloading Phoenix-RTOS image (this can take a few minutes)…"
  docker pull pablodelarco/phoenix-rtos-one:latest \
        | while read -r line; do echo "$line" >/dev/tty1 || true; done
  progress "Image downloaded – launching container…"
  docker run -d --name phoenix-rtos --restart=always --network host \
             pablodelarco/phoenix-rtos-one:latest

  ## ── convenience: auto-run interactively on console logins  ──────────────
  echo 'clear'                                                         >>/root/.bash_profile
  echo 'docker run --rm -it --network host pablodelarco/phoenix-rtos-one' >>/root/.bash_profile

  ## ── restore tty1 login with autologin root ─────────────────────────────
  systemctl unmask getty@tty1.service 2>/dev/null || true
  mkdir -p /etc/systemd/system/getty@tty1.service.d
  cat >/etc/systemd/system/getty@tty1.service.d/autologin.conf <<'CONF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin root --noclear %I linux
CONF
  systemctl daemon-reload
  systemctl restart getty@tty1.service

  echo 'root:root' | chpasswd
  progress "Phoenix-RTOS Appliance setup complete!"
}

### ── bootstrap (unused) ────────────────────────────────────────────────────
service_bootstrap() { echo "[Phoenix-RTOS] bootstrap stage not used."; }
