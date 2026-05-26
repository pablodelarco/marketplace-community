# Prowler CLI Appliance

[Prowler](https://github.com/prowler-cloud/prowler) is the most widely used open-source
cloud security platform. This appliance ships the upstream **Prowler CLI** on a
bastion-hardened Ubuntu 24.04 base, intended for automated multi-cloud security and
compliance scanning.

It is deliberately CLI-only: no web UI, no API, no database, no Docker. Reports are
written to disk and can be retrieved over SSH or rsync.

## What is included

- Ubuntu 24.04 LTS (server, minimal package set)
- Prowler CLI installed via `pipx` for the non-root `prowler` user
- `prowler-scan` and `prowler-status` helper commands
- Systemd `prowler-scan.timer` for periodic scans
- Bastion hardening applied at build time (see below)

## Bastion hardening (applied by default)

| Control                 | Setting                                                                 |
|-------------------------|-------------------------------------------------------------------------|
| Default user            | `prowler` (UID 1000), default password `opennebula`, NOPASSWD sudo      |
| Root account            | Password locked; `PermitRootLogin no`                                   |
| SSH                     | `AllowUsers prowler`, `MaxAuthTries 3`, key + password auth, no X11 fwd |
| VNC console             | Auto-login as `prowler` (no prompt)                                     |
| Change credentials      | `passwd` after first login                                              |
| Firewall                | UFW: deny incoming, allow `22/tcp` only                                 |
| Brute-force protection  | `fail2ban` watching `sshd` (3 retries / 10 min / 1 h ban)               |

## Contextualization

Cloud-provider credentials and scan options are injected at VM instantiation through
OpenNebula's contextualization (no credentials are baked into the image).

| Variable                              | Required | Default | Description                                                                                          |
|---------------------------------------|----------|---------|------------------------------------------------------------------------------------------------------|
| `ONEAPP_PROWLER_SCAN_PROVIDER`             | yes      | `aws`   | One of `aws`, `azure`, `gcp`, `kubernetes`, `m365`                                                   |
| `ONEAPP_PROWLER_SCAN_CREDENTIALS`      | no       |         | Base64-encoded credential file for the selected provider (see formats below)                         |
| `ONEAPP_PROWLER_SCAN_REGION`               | no       |         | Default region (`aws`/`gcp`)                                                                         |
| `ONEAPP_PROWLER_SCAN_COMPLIANCE`           | no       |         | Comma-separated compliance frameworks (e.g. `cis_2.0_aws,ens_rd2022_aws`)                            |
| `ONEAPP_PROWLER_SCAN_TOKEN`        | no       |         | Prowler Cloud / Prowler App API key. When set, the appliance pushes every scan's findings to the SaaS dashboard (see below) |
| `ONEAPP_PROWLER_SCAN_CLOUDURL`   | no       | `https://api.prowler.com` | Override only for **self-hosted Prowler App** users                                       |
| `ONEAPP_PROWLER_SCAN_ONBOOT`         | no       | `YES`   | Run an initial scan after first boot if credentials are present                                      |
| `ONEAPP_PROWLER_SCAN_SCHEDULE`             | no       | `daily` | Systemd `OnCalendar=` expression for the recurring scan timer (empty = manual only)                  |
| `ONEAPP_PROWLER_SCAN_SSHKEY`   | no       |         | Extra SSH public key authorized for the `prowler` user (in addition to `$USER[SSH_PUBLIC_KEY]`)      |

### Credential formats

`ONEAPP_PROWLER_SCAN_CREDENTIALS` is the base64 encoding of a provider-specific file:

| Provider     | File format                                                                 |
|--------------|-----------------------------------------------------------------------------|
| `aws`        | INI file matching `~/.aws/credentials`                                      |
| `azure`      | Shell env file exporting `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_CLIENT_SECRET`, `AZURE_SUBSCRIPTION_ID` |
| `gcp`        | Service account JSON (the contents of the downloaded key file)              |
| `kubernetes` | Kubeconfig YAML                                                             |
| `m365`       | Shell env file exporting `M365_CLIENT_ID`, `M365_TENANT_ID`, `M365_CLIENT_SECRET` |
| `github`     | Shell env file exporting `GITHUB_PERSONAL_ACCESS_TOKEN` (or `GITHUB_OAUTH_APP_TOKEN`, or `GITHUB_APP_ID` + `GITHUB_APP_KEY`) |
| `iac`        | Optional: tar archive of Terraform / CloudFormation / Kubernetes manifests, extracted to `~prowler/iac`. May also be left empty and the files SCP'd in post-boot. |

Encode locally before instantiation:

```bash
base64 -w0 ~/.aws/credentials              # then paste into the user input
```

## Prowler Cloud / Prowler App integration

Cloud-provider credentials let the appliance *scan*. A separate
**Prowler Cloud API key** lets it *publish* findings to the
[Prowler App / Prowler Cloud](https://docs.prowler.com/projects/prowler-open-source/en/latest/tutorials/prowler-app-import-findings/)
dashboard so they're aggregated alongside scans from other sources.

1. In the Prowler Cloud / Prowler App UI, generate an API key (`pk_…`)
   under *Settings → API Keys*.
2. Create the provider (cloud account) in the dashboard so the appliance
   has somewhere to publish to.
3. Paste the API key into `ONEAPP_PROWLER_SCAN_TOKEN` at VM
   instantiation. (Optional: set `ONEAPP_PROWLER_SCAN_CLOUDURL` if
   you self-host Prowler App.)

The wrapper appends `--push-to-cloud` to every `prowler` invocation when
the key is present. OCSF findings are POSTed to
`${PROWLER_CLOUD_API_BASE_URL}/api/v1/ingestions`. When the key is empty
the appliance runs fully standalone — reports are written only to
`/var/lib/prowler/reports/`.

## Quick start

1. Instantiate the appliance from the OpenNebula marketplace.
2. Pick a provider and paste the base64-encoded credential blob.
3. Wait ~1 minute for boot.
4. SSH in as the `prowler` user:
   ```bash
   ssh prowler@<VM_IP>
   ```
5. The first scan runs automatically when `SCAN_ON_BOOT=YES`. Inspect with:
   ```bash
   prowler-status
   ```

## Running scans

```bash

# On-demand scan (writes to /var/lib/prowler/reports/<date>/)
sudo prowler-scan

# Different provider on the same host
sudo prowler-scan azure

# Show the most recent scan summary
prowler-status

# Inspect the recurring scan timer
systemctl status prowler-scan.timer
systemctl list-timers prowler-scan.timer
```

Reports are written to `/var/lib/prowler/reports/<YYYY-MM-DD>/` in HTML, CSV, JSON, and
OCSF/ASFF formats. Retrieve them with `rsync` or `scp`:

```bash
rsync -av prowler@<VM_IP>:/var/lib/prowler/reports/ ./reports/
```

## System requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| vCPU     | 1       | 2           |
| RAM      | 1 GiB   | 2 GiB       |
| Disk     | 8 GiB   | 16 GiB      |

## Customization

`prowler` has NOPASSWD sudo. To run as a different user, reduce the sudo scope, or
add other tools (jq, awscli, …), simply SSH in and modify the image.

## Documentation

- [Prowler CLI documentation](https://docs.prowler.com/projects/prowler-open-source/en/latest/)
- [Prowler GitHub](https://github.com/prowler-cloud/prowler)
- [OpenNebula contextualization reference](https://docs.opennebula.io/stable/management_and_operations/references/template.html#context-section)

## License

Prowler is licensed under the Apache License 2.0.
