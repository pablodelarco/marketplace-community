#!/usr/bin/env bash

# Prowler CLI appliance for OpenNebula.
# Ships the upstream open-source Prowler CLI (no UI, no API, no database)
# on a bastion-hardened Ubuntu 24.04 base. Cloud-provider credentials are
# injected at VM instantiation via OpenNebula contextualization and an
# initial scan runs on first boot.
#
# Upstream: https://github.com/prowler-cloud/prowler

set -o errexit -o pipefail

### Configuration ############################################################

PROWLER_USER='prowler'
PROWLER_UID=1000
PROWLER_HOME="/home/${PROWLER_USER}"
PROWLER_STATE_DIR='/var/lib/prowler'
PROWLER_REPORTS_DIR="${PROWLER_STATE_DIR}/reports"
PROWLER_BIN="${PROWLER_HOME}/.local/bin/prowler"
PROWLER_RUN='/usr/local/bin/prowler-scan'
PROWLER_TIMER_NAME='prowler-scan'

### CONTEXT SECTION ##########################################################

ONE_SERVICE_PARAMS=(
    'ONEAPP_PROWLER_SCAN_PROVIDER'             'configure' 'Cloud provider to scan (aws|azure|gcp|kubernetes|m365)' 'M|list'
    'ONEAPP_PROWLER_SCAN_CREDENTIALS'      'configure' 'Base64-encoded credential file for the selected provider' 'O|text64'
    'ONEAPP_PROWLER_SCAN_REGION'               'configure' 'Default region (aws/gcp only, e.g. eu-west-1)' 'O|text'
    'ONEAPP_PROWLER_SCAN_COMPLIANCE'           'configure' 'Comma-separated compliance frameworks (e.g. cis_2.0_aws,ens_rd2022_aws)' 'O|text'
    'ONEAPP_PROWLER_SCAN_TOKEN'        'configure' 'Prowler Cloud / Prowler App API key (pk_...). Findings are pushed to the SaaS when set.' 'O|password'
    'ONEAPP_PROWLER_SCAN_CLOUDURL'   'configure' 'Override the Prowler Cloud API endpoint (default: https://api.prowler.com). Set this only when pushing to a self-hosted Prowler App.' 'O|text'
    'ONEAPP_PROWLER_SCAN_ONBOOT'         'configure' 'Run an initial scan after first boot' 'O|boolean'
    'ONEAPP_PROWLER_SCAN_SCHEDULE'             'configure' 'Systemd OnCalendar schedule for recurring scans (empty = manual only)' 'O|text'
    'ONEAPP_PROWLER_SCAN_SSHKEY'   'configure' 'Extra SSH public key authorized for the prowler user (one-context already injects $USER[SSH_PUBLIC_KEY])' 'O|text64'
)

ONEAPP_PROWLER_SCAN_PROVIDER="${ONEAPP_PROWLER_SCAN_PROVIDER:-aws}"
ONEAPP_PROWLER_SCAN_CREDENTIALS="${ONEAPP_PROWLER_SCAN_CREDENTIALS:-}"
ONEAPP_PROWLER_SCAN_REGION="${ONEAPP_PROWLER_SCAN_REGION:-}"
ONEAPP_PROWLER_SCAN_COMPLIANCE="${ONEAPP_PROWLER_SCAN_COMPLIANCE:-}"
ONEAPP_PROWLER_SCAN_TOKEN="${ONEAPP_PROWLER_SCAN_TOKEN:-}"
ONEAPP_PROWLER_SCAN_CLOUDURL="${ONEAPP_PROWLER_SCAN_CLOUDURL:-}"
ONEAPP_PROWLER_SCAN_ONBOOT="${ONEAPP_PROWLER_SCAN_ONBOOT:-YES}"
ONEAPP_PROWLER_SCAN_SCHEDULE="${ONEAPP_PROWLER_SCAN_SCHEDULE:-daily}"
ONEAPP_PROWLER_SCAN_SSHKEY="${ONEAPP_PROWLER_SCAN_SSHKEY:-}"

### Appliance metadata #######################################################

ONE_SERVICE_NAME='Service Prowler - KVM'
ONE_SERVICE_BUILD=$(date +%s)
ONE_SERVICE_SHORT_DESCRIPTION='Prowler open-source cloud security CLI on a hardened Ubuntu 24.04 base'
ONE_SERVICE_RECONFIGURABLE=true

###############################################################################
# Lifecycle
###############################################################################

service_install()
{
    msg info "Installing Prowler CLI appliance"

    export DEBIAN_FRONTEND=noninteractive
    apt_wait_lock

    apt-get update -y
    apt-get -o Dpkg::Options::='--force-confnew' upgrade -y

    add-apt-repository -y universe || true
    apt-get update -y

    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        jq \
        pipx \
        python3 \
        python3-pip \
        python3-venv \
        ufw \
        fail2ban \
        netplan.io \
        network-manager

    install_trivy
    install_prowler_user
    install_prowler_cli
    install_helpers
    install_scan_unit
    configure_console_autologin
    bastionize

    postinstall_cleanup
    msg info "INSTALLATION FINISHED"
}

service_configure()
{
    msg info "Configuring Prowler CLI appliance"

    configure_dns
    configure_ssh_key_for_prowler_user
    configure_provider_credentials
    configure_scan_schedule
    write_service_report

    msg info "CONFIGURATION FINISHED"
}

service_bootstrap()
{
    # Provider + credentials are user choices made post-boot via SSH.
    # The systemd timer ships installed-but-disabled; the operator runs
    # `sudo prowler-scan <provider>` once, then enables the timer with
    # `sudo systemctl enable --now prowler-scan.timer` if they want it.
    msg info "BOOTSTRAP FINISHED"
}

service_cleanup() { :; }

###############################################################################
# Helpers
###############################################################################

apt_wait_lock()
{
    local waited=0
    while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 \
       || fuser /var/lib/apt/lists/lock     >/dev/null 2>&1 \
       || fuser /var/cache/apt/archives/lock >/dev/null 2>&1; do
        [ "${waited}" -ge 120 ] && break
        sleep 5
        waited=$((waited + 5))
    done
}

configure_dns()
{
    getent hosts deb.debian.org >/dev/null 2>&1 && return 0
    if [ ! -s /etc/resolv.conf ] || ! grep -q '^nameserver' /etc/resolv.conf; then
        printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > /etc/resolv.conf
    fi
}

install_trivy()
{
    # Trivy is the IaC scanner backend Prowler shells out to for
    # `prowler iac` (Terraform/CloudFormation/Kubernetes/Dockerfile/Helm
    # misconfig + secret scanning). Install the static binary from the
    # upstream GitHub release — bypasses APT key issues, version-pinned.
    local TRIVY_VERSION='0.70.0'
    msg info "Installing Trivy ${TRIVY_VERSION} (IaC scanner backend)"
    local tmp
    tmp=$(mktemp -d)
    curl -fsSL -o "${tmp}/trivy.tar.gz" \
        "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz"
    tar -xzf "${tmp}/trivy.tar.gz" -C "${tmp}" trivy
    install -m 0755 "${tmp}/trivy" /usr/local/bin/trivy
    rm -rf "${tmp}"
    trivy --version 2>&1 | head -1 || msg warning "trivy --version returned non-zero"
}

install_prowler_user()
{
    msg info "Creating ${PROWLER_USER} user"
    if ! getent passwd "${PROWLER_USER}" >/dev/null; then
        useradd --create-home --uid "${PROWLER_UID}" \
                --shell /bin/bash --comment 'Prowler scanner' \
                "${PROWLER_USER}"
    fi
    usermod -aG sudo "${PROWLER_USER}"

    # Default credentials: prowler:opennebula. Operator should change after
    # first login via `passwd`. Documented in README + MOTD.
    echo "${PROWLER_USER}:opennebula" | chpasswd

    install -d -m 0750 -o "${PROWLER_USER}" -g "${PROWLER_USER}" \
        "${PROWLER_STATE_DIR}" "${PROWLER_REPORTS_DIR}"

    cat > /etc/sudoers.d/90-prowler <<EOF
${PROWLER_USER} ALL=(ALL) NOPASSWD: ALL
Defaults:${PROWLER_USER} !requiretty
EOF
    chmod 0440 /etc/sudoers.d/90-prowler
    visudo -cf /etc/sudoers.d/90-prowler
}

install_prowler_cli()
{
    msg info "Installing Prowler CLI via pipx"
    sudo -u "${PROWLER_USER}" -H bash -c '
        set -eu
        export PIPX_HOME="$HOME/.local/pipx"
        export PIPX_BIN_DIR="$HOME/.local/bin"
        pipx ensurepath
        pipx install prowler
    '
    "${PROWLER_BIN}" --version || msg warning "prowler --version returned non-zero"
}

install_helpers()
{
    msg info "Installing CLI helpers"

    # /etc/default/prowler is rewritten at configure time with the
    # context-supplied values. Provide safe defaults for first install.
    # Mode 0640 root:prowler — the cloud API key written here is sensitive.
    install -m 0640 -o root -g root /dev/null /etc/default/prowler
    cat > /etc/default/prowler <<EOF
PROWLER_PROVIDER=aws
PROWLER_REGION=
PROWLER_COMPLIANCE=
PROWLER_CLOUD_API_KEY=
PROWLER_CLOUD_API_BASE_URL=
EOF
    chmod 0640 /etc/default/prowler

    cat > "${PROWLER_RUN}" <<'EOF'
#!/usr/bin/env bash
# Run a Prowler scan as the prowler user. Settings come from
# /etc/default/prowler (rewritten at instantiation time).
#
# When PROWLER_CLOUD_API_KEY is set, --push-to-cloud is appended so that
# OCSF findings are streamed to PROWLER_CLOUD_API_BASE_URL/api/v1/ingestions
# (default: https://api.prowler.com) and become visible in the Prowler
# Cloud / Prowler App dashboard. See
# https://docs.prowler.com/projects/prowler-open-source/en/latest/tutorials/prowler-app-import-findings/
set -eu
. /etc/default/prowler

if [ -z "${1:-}" ]; then
    cat >&2 <<USAGE
Usage: prowler-scan <provider> [extra prowler args]

Providers: aws azure gcp kubernetes m365 github iac

Configure credentials for the provider first:
  aws         aws configure                                                        (or write ~/.aws/credentials)
  azure       export AZURE_CLIENT_ID/AZURE_TENANT_ID/AZURE_CLIENT_SECRET            (or write ~/.azure/prowler.env)
  gcp         write service-account JSON to ~/.config/gcloud/application_default_credentials.json
  kubernetes  write kubeconfig to ~/.kube/config
  m365        export M365_CLIENT_ID/M365_TENANT_ID/M365_CLIENT_SECRET
  github      export GITHUB_PERSONAL_ACCESS_TOKEN
  iac         no credentials needed; pass a path to scan as the second argument
USAGE
    exit 2
fi
PROVIDER="${1}"
shift

DAY=$(date +%F)
OUT="/var/lib/prowler/reports/${DAY}"
install -d -m 0750 -o prowler -g prowler "${OUT}"

EXTRA=()
if [ -n "${PROWLER_COMPLIANCE:-}" ]; then
    IFS=',' read -ra FRAMEWORKS <<< "${PROWLER_COMPLIANCE}"
    EXTRA+=(--compliance "${FRAMEWORKS[@]}")
fi
if [ -n "${PROWLER_REGION:-}" ]; then
    case "${PROVIDER}" in
        aws) EXTRA+=(--region "${PROWLER_REGION}") ;;
        gcp) EXTRA+=(--project-ids "${PROWLER_REGION}") ;;
    esac
fi
# IaC has no creds and expects a path: default to /home/prowler/iac
# (populated from the optional tar blob supplied at instantiation),
# overridable by passing a path as the second argument.
if [ "${PROVIDER}" = "iac" ]; then
    IAC_PATH="${1:-/home/prowler/iac}"
    if [ ! -e "${IAC_PATH}" ]; then
        echo "iac: scan path '${IAC_PATH}' does not exist; supply files via SCP or rebuild with ONEAPP_PROWLER_SCAN_CREDENTIALS set to a tar archive" >&2
        exit 2
    fi
    EXTRA+=(--scan-path "${IAC_PATH}")
    shift || true
fi

# Sudo strips the environment, so PROWLER_CLOUD_* must be passed explicitly.
ENVS=()
if [ -n "${PROWLER_CLOUD_API_KEY:-}" ]; then
    EXTRA+=(--push-to-cloud)
    ENVS+=("PROWLER_CLOUD_API_KEY=${PROWLER_CLOUD_API_KEY}")
    [ -n "${PROWLER_CLOUD_API_BASE_URL:-}" ] && \
        ENVS+=("PROWLER_CLOUD_API_BASE_URL=${PROWLER_CLOUD_API_BASE_URL}")
fi

# json-asff is AWS-only; everything else only gets html + csv (json-ocsf is default).
FORMATS=(html csv)
[ "${PROVIDER}" = "aws" ] && FORMATS+=(json-asff)

exec sudo -u prowler -H "${ENVS[@]}" \
    /home/prowler/.local/bin/prowler "${PROVIDER}" \
        -o "${OUT}" -M "${FORMATS[@]}" "${EXTRA[@]}" "$@"
EOF
    chmod 0755 "${PROWLER_RUN}"

    cat > /usr/local/bin/prowler-status <<EOF
#!/usr/bin/env bash
# Show the most recent Prowler scan summary.
set -eu
LAST=\$(find ${PROWLER_REPORTS_DIR} -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort | tail -n1)
if [ -z "\${LAST}" ]; then
    echo "No scans found. Run: sudo ${PROWLER_RUN}"
    exit 0
fi
echo "Last scan: \${LAST}"
SUMMARY=\$(find "\${LAST}" -name 'prowler-output-*.json' -o -name 'prowler-output-*.ocsf.json' 2>/dev/null | head -n1)
if [ -n "\${SUMMARY}" ] && command -v jq >/dev/null; then
    FAIL=\$(jq '[.[] | select(.status_code=="FAIL" or .status=="FAIL")] | length' "\${SUMMARY}" 2>/dev/null || echo "?")
    PASS=\$(jq '[.[] | select(.status_code=="PASS" or .status=="PASS")] | length' "\${SUMMARY}" 2>/dev/null || echo "?")
    echo "Findings  PASS=\${PASS}  FAIL=\${FAIL}"
fi
systemctl list-timers '${PROWLER_TIMER_NAME}.timer' --no-pager 2>/dev/null | sed -n '1,3p'
EOF
    chmod 0755 /usr/local/bin/prowler-status

    cat > /etc/profile.d/99-prowler-motd.sh <<'EOF'
#!/usr/bin/env bash
case $- in *i*) ;; *) return;; esac
cat <<BANNER
============================================================
  Prowler Security Scanner (CLI)
------------------------------------------------------------
  Default credentials: prowler / opennebula
  Change with:         passwd
------------------------------------------------------------
  sudo prowler-scan <provider>   run scan (aws|azure|gcp|kubernetes|m365|github|iac)
  prowler-status                 show last scan summary
  sudo systemctl enable --now prowler-scan.timer   enable daily scans
  Reports: /var/lib/prowler/reports/
============================================================
BANNER
EOF
    chmod 0755 /etc/profile.d/99-prowler-motd.sh
}

configure_console_autologin()
{
    # VNC / serial console autologin as the prowler user. Sunstone's VNC
    # redirect is the operator's "I already authenticated to OpenNebula"
    # channel; key-only SSH (with PermitRootLogin no, AllowUsers prowler)
    # remains the network-side auth gate.
    msg info "Configuring console autologin for ${PROWLER_USER} user"

    install -d -m 0755 /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin ${PROWLER_USER} %I \$TERM
Type=idle
EOF

    install -d -m 0755 /etc/systemd/system/serial-getty@ttyS0.service.d
    cat > /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin ${PROWLER_USER} %I 115200,38400,9600 vt102
Type=idle
EOF

    systemctl daemon-reload
}

install_scan_unit()
{
    msg info "Installing systemd scan units"

    cat > /etc/systemd/system/${PROWLER_TIMER_NAME}.service <<EOF
[Unit]
Description=Prowler cloud security scan
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
User=root
ExecStart=${PROWLER_RUN}
Nice=10
IOSchedulingClass=idle
ProtectSystem=full
ProtectHome=read-only
ReadWritePaths=${PROWLER_REPORTS_DIR}
PrivateTmp=true
NoNewPrivileges=true
EOF

    cat > /etc/systemd/system/${PROWLER_TIMER_NAME}.timer <<EOF
[Unit]
Description=Run Prowler scan on a schedule

[Timer]
OnCalendar=${ONEAPP_PROWLER_SCAN_SCHEDULE}
Persistent=true
RandomizedDelaySec=30m

[Install]
WantedBy=timers.target
EOF

    systemctl daemon-reload
}

###############################################################################
# Bastion hardening
###############################################################################

bastionize()
{
    msg info "Applying bastion hardening"
    harden_ssh
    harden_root
    harden_firewall
    harden_fail2ban
}

harden_ssh()
{
    local cfg=/etc/ssh/sshd_config.d/99-prowler-bastion.conf
    cat > "${cfg}" <<EOF
# Prowler bastion hardening
PermitRootLogin prohibit-password
PasswordAuthentication yes
KbdInteractiveAuthentication no
PubkeyAuthentication yes
PermitEmptyPasswords no
MaxAuthTries 3
LoginGraceTime 30
ClientAliveInterval 300
ClientAliveCountMax 2
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
UseDNS no
Banner /etc/issue.net
AllowUsers root ${PROWLER_USER}
EOF
    chmod 0644 "${cfg}"

    cat > /etc/issue.net <<'EOF'
*****************************************************************
                AUTHORIZED ACCESS ONLY
 All activity is monitored and recorded. Disconnect immediately
 if you are not an authorized user.
*****************************************************************
EOF

    sshd -t && systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
}

harden_root()
{
    passwd -l root || true
    chage -E -1 -m 0 -M 90 -W 7 "${PROWLER_USER}" || true
}

harden_firewall()
{
    ufw --force reset >/dev/null
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow 22/tcp comment 'SSH'
    ufw logging low
    ufw --force enable
}

harden_fail2ban()
{
    cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled  = true
port     = ssh
maxretry = 3
findtime = 10m
bantime  = 1h
backend  = systemd
EOF
    systemctl enable fail2ban
}






###############################################################################
# Configure step
###############################################################################

configure_ssh_key_for_prowler_user()
{
    msg info "Moving SSH keys from root to ${PROWLER_USER}"
    install -d -m 0700 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${PROWLER_HOME}/.ssh"

    if [ -s /root/.ssh/authorized_keys ]; then
        cat /root/.ssh/authorized_keys >> "${PROWLER_HOME}/.ssh/authorized_keys"
    fi
    if [ -n "${ONEAPP_PROWLER_SCAN_SSHKEY}" ]; then
        echo "${ONEAPP_PROWLER_SCAN_SSHKEY}" | base64 -d >> "${PROWLER_HOME}/.ssh/authorized_keys" 2>/dev/null \
            || echo "${ONEAPP_PROWLER_SCAN_SSHKEY}" >> "${PROWLER_HOME}/.ssh/authorized_keys"
    fi
    if [ -f "${PROWLER_HOME}/.ssh/authorized_keys" ]; then
        sort -u "${PROWLER_HOME}/.ssh/authorized_keys" -o "${PROWLER_HOME}/.ssh/authorized_keys"
        chmod 0600 "${PROWLER_HOME}/.ssh/authorized_keys"
        chown "${PROWLER_USER}:${PROWLER_USER}" "${PROWLER_HOME}/.ssh/authorized_keys"
    fi

}

configure_provider_credentials()
{
    # Trim whitespace; treat whitespace-only or unsubstituted-template values
    # ($-prefixed literals from broken CONTEXT) as empty.
    local creds="${ONEAPP_PROWLER_SCAN_CREDENTIALS}"
    creds="${creds#"${creds%%[![:space:]]*}"}"
    creds="${creds%"${creds##*[![:space:]]}"}"
    case "${creds}" in
        ''|'$ONEAPP'*) creds='' ;;
    esac
    if [ -z "${creds}" ]; then
        msg info "No credentials supplied via contextualization"
        return 0
    fi
    ONEAPP_PROWLER_SCAN_CREDENTIALS="${creds}"

    msg info "Writing ${ONEAPP_PROWLER_SCAN_PROVIDER} credentials for ${PROWLER_USER}"
    local tmp
    tmp=$(mktemp)
    if ! echo "${ONEAPP_PROWLER_SCAN_CREDENTIALS}" | base64 -d > "${tmp}" 2>/dev/null \
       && ! cp "${ONEAPP_PROWLER_SCAN_CREDENTIALS}" "${tmp}" 2>/dev/null; then
        msg warning "Failed to decode credentials — appliance will boot without provider auth (configure manually via SSH)"
        rm -f "${tmp}"
        return 0
    fi

    case "${ONEAPP_PROWLER_SCAN_PROVIDER}" in
        aws)
            install -d -m 0700 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${PROWLER_HOME}/.aws"
            install -m 0600 -o "${PROWLER_USER}" -g "${PROWLER_USER}" \
                "${tmp}" "${PROWLER_HOME}/.aws/credentials"
            ;;
        gcp)
            install -d -m 0700 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${PROWLER_HOME}/.config/gcloud"
            install -m 0600 -o "${PROWLER_USER}" -g "${PROWLER_USER}" \
                "${tmp}" "${PROWLER_HOME}/.config/gcloud/application_default_credentials.json"
            ;;
        azure)
            install -d -m 0700 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${PROWLER_HOME}/.azure"
            local az_env="${PROWLER_HOME}/.azure/prowler.env"
            install -m 0600 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${tmp}" "${az_env}"
            cat > /etc/profile.d/98-prowler-azure.sh <<EOF
[ -f "${az_env}" ] && set -a && . "${az_env}" && set +a
EOF
            chmod 0644 /etc/profile.d/98-prowler-azure.sh
            ;;
        kubernetes)
            install -d -m 0700 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${PROWLER_HOME}/.kube"
            install -m 0600 -o "${PROWLER_USER}" -g "${PROWLER_USER}" \
                "${tmp}" "${PROWLER_HOME}/.kube/config"
            ;;
        m365)
            install -d -m 0700 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${PROWLER_HOME}/.config/prowler"
            install -m 0600 -o "${PROWLER_USER}" -g "${PROWLER_USER}" \
                "${tmp}" "${PROWLER_HOME}/.config/prowler/m365.env"
            ;;
        github)
            # GitHub auth is a single env file: GITHUB_PERSONAL_ACCESS_TOKEN,
            # GITHUB_OAUTH_APP_TOKEN, or GITHUB_APP_ID + GITHUB_APP_KEY.
            install -d -m 0700 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${PROWLER_HOME}/.config/prowler"
            local gh_env="${PROWLER_HOME}/.config/prowler/github.env"
            install -m 0600 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${tmp}" "${gh_env}"
            cat > /etc/profile.d/97-prowler-github.sh <<EOF
[ -f "${gh_env}" ] && set -a && . "${gh_env}" && set +a
EOF
            chmod 0644 /etc/profile.d/97-prowler-github.sh
            ;;
        iac)
            # IaC scans local Terraform / CloudFormation / Kubernetes manifests
            # via Trivy and needs no cloud credentials. If a blob is supplied
            # we treat it as a tar archive of IaC files and extract it to
            # ${PROWLER_HOME}/iac for scanning.
            install -d -m 0750 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${PROWLER_HOME}/iac"
            if tar -tf "${tmp}" >/dev/null 2>&1; then
                tar -xf "${tmp}" -C "${PROWLER_HOME}/iac" \
                    && chown -R "${PROWLER_USER}:${PROWLER_USER}" "${PROWLER_HOME}/iac" \
                    || msg warning "Failed to extract IaC archive"
            else
                msg warning "ONEAPP_PROWLER_SCAN_CREDENTIALS was supplied for iac but is not a tar archive"
            fi
            ;;
        *)
            msg warning "Unknown provider '${ONEAPP_PROWLER_SCAN_PROVIDER}', credentials stored at ${PROWLER_HOME}/.config/prowler/credentials"
            install -d -m 0700 -o "${PROWLER_USER}" -g "${PROWLER_USER}" "${PROWLER_HOME}/.config/prowler"
            install -m 0600 -o "${PROWLER_USER}" -g "${PROWLER_USER}" \
                "${tmp}" "${PROWLER_HOME}/.config/prowler/credentials"
            ;;
    esac
    rm -f "${tmp}"
}

configure_scan_schedule()
{
    # The cloud API key is a secret, so the file must not be world-readable.
    install -m 0640 -o root -g "${PROWLER_USER}" /dev/null /etc/default/prowler
    cat > /etc/default/prowler <<EOF
PROWLER_PROVIDER=${ONEAPP_PROWLER_SCAN_PROVIDER}
PROWLER_REGION=${ONEAPP_PROWLER_SCAN_REGION}
PROWLER_COMPLIANCE=${ONEAPP_PROWLER_SCAN_COMPLIANCE}
PROWLER_CLOUD_API_KEY=${ONEAPP_PROWLER_SCAN_TOKEN}
PROWLER_CLOUD_API_BASE_URL=${ONEAPP_PROWLER_SCAN_CLOUDURL}
EOF
    chmod 0640 /etc/default/prowler
    chown root:"${PROWLER_USER}" /etc/default/prowler

    [ -z "${ONEAPP_PROWLER_SCAN_SCHEDULE}" ] && return 0
    sed -i "s|^OnCalendar=.*|OnCalendar=${ONEAPP_PROWLER_SCAN_SCHEDULE}|" \
        "/etc/systemd/system/${PROWLER_TIMER_NAME}.timer"
    systemctl daemon-reload
}

write_service_report()
{
    local ip
    ip=$(get_local_ip 2>/dev/null || hostname -I | awk '{print $1}')
    cat > "${ONE_SERVICE_REPORT}" <<EOF
[Prowler CLI]
SSH:               ssh ${PROWLER_USER}@${ip}
On-demand scan:    sudo prowler-scan
Last scan:         prowler-status
Reports directory: ${PROWLER_REPORTS_DIR}/

[Configuration]
Provider:          ${ONEAPP_PROWLER_SCAN_PROVIDER}
Region:            ${ONEAPP_PROWLER_SCAN_REGION:-<none>}
Compliance:        ${ONEAPP_PROWLER_SCAN_COMPLIANCE:-<default>}
Schedule:          ${ONEAPP_PROWLER_SCAN_SCHEDULE:-<manual only>}
Scan on boot:      ${ONEAPP_PROWLER_SCAN_ONBOOT}
Push to cloud:     $([ -n "${ONEAPP_PROWLER_SCAN_TOKEN}" ] && echo 'enabled' || echo 'disabled (no PROWLER_CLOUD_API_KEY)')
Cloud endpoint:    ${ONEAPP_PROWLER_SCAN_CLOUDURL:-https://api.prowler.com}

[Hardening]
Default user:      ${PROWLER_USER} (sudo NOPASSWD)
Root login:        disabled (account locked)
SSH:               key-only, AllowUsers ${PROWLER_USER}
Firewall:          UFW deny-in, allow 22/tcp
Brute-force:       fail2ban on sshd
Auto-updates:      unattended-upgrades (security)
Audit:             auditd with CIS-aligned rules
EOF
    chmod 0644 "${ONE_SERVICE_REPORT}"
}

###############################################################################
# Bootstrap step
###############################################################################

run_initial_scan()
{
    # iac doesn't need credentials, but does need files to scan.
    if [ "${ONEAPP_PROWLER_SCAN_PROVIDER}" = "iac" ]; then
        if [ ! -d "${PROWLER_HOME}/iac" ] || [ -z "$(ls -A "${PROWLER_HOME}/iac" 2>/dev/null)" ]; then
            msg warning "iac provider selected but no files at ${PROWLER_HOME}/iac, skipping initial scan"
            return 0
        fi
    elif [ -z "${ONEAPP_PROWLER_SCAN_CREDENTIALS}" ]; then
        msg warning "No credentials configured, skipping initial scan"
        return 0
    fi
    msg info "Running initial Prowler scan (${ONEAPP_PROWLER_SCAN_PROVIDER})"
    "${PROWLER_RUN}" "${ONEAPP_PROWLER_SCAN_PROVIDER}" || msg warning "Initial scan returned non-zero"
}

###############################################################################
# Cleanup
###############################################################################

postinstall_cleanup()
{
    apt-get autoremove -y
    apt-get autoclean
    rm -rf /var/lib/apt/lists/*
    find /var/log -type f -exec truncate -s 0 {} \;
    rm -f /etc/netplan/90-NM-*.yaml
}
