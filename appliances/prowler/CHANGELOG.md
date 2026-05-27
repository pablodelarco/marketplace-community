# Changelog

All notable changes to the Prowler appliance will be documented in this file.

## [1.0.0-2] - 2026-05-13

### Changed
- Pivoted scope from full Prowler platform (UI + API + MCP + Postgres + Neo4j +
  Valkey + Celery via Docker Compose) to the upstream **Prowler CLI only**, per
  maintainer feedback. Result: ~250 MB image instead of ~5 GB, 1 GiB RAM instead
  of 8, no port surface exposed.
- Default user is now `prowler` (UID 1000) with NOPASSWD sudo. Root account is
  locked and SSH access is restricted to `AllowUsers prowler`.

### Added
- Bastion hardening applied at build time:
  - SSH key-only auth, `PermitRootLogin no`, `MaxAuthTries 3`
  - UFW firewall (deny incoming, allow 22/tcp only)
  - fail2ban on sshd
  - Unattended security upgrades
  - Kernel sysctl hardening (rp_filter, kptr_restrict, ptrace_scope, …)
  - auditd with CIS-aligned identity / sudoers / sshd watches
  - PAM pwquality (minlen 14, three character classes), `UMASK 027`
- Cloud-provider credentials injected at instantiation via
  `ONEAPP_PROWLER_SCAN_CREDENTIALS` (base64-encoded; no credentials baked into
  the image). Supports the full set of Prowler's officially documented
  providers: `aws`, `azure`, `gcp`, `kubernetes`, `m365`, `github`, `iac`.
- Optional **Prowler Cloud / Prowler App** integration via
  `ONEAPP_PROWLER_SCAN_TOKEN` and `ONEAPP_PROWLER_SCAN_CLOUDURL`.
  When the SaaS API key is supplied, the appliance runs `prowler ... --push-to-cloud`
  on every scan, streaming OCSF findings to `https://api.prowler.com/api/v1/ingestions`
  (or to a self-hosted Prowler App). Stays fully standalone when empty.
- Systemd `prowler-scan.timer` for recurring scans, schedule configurable via
  `ONEAPP_PROWLER_SCAN_SCHEDULE` (default: `daily`).
- Lynis installed and a baseline CIS audit captured at build time
  (`/var/log/lynis/lynis-baseline.dat`). `bastion-audit` helper re-runs the
  audit on-demand.
- Helper commands: `prowler-scan`, `prowler-status`, `bastion-audit`.

### Removed
- Docker Engine and Docker Compose
- All seven Prowler platform containers
  (`prowler-api`, `prowler-ui`, `prowler-mcp`, `postgres`, `valkey`, `neo4j`,
  `worker`, `worker-beat`)
- Auto-generated database / Django / auth secrets (no longer applicable)
- `ONEAPP_PROWLER_UI_PORT`, `ONEAPP_PROWLER_API_PORT`,
  `ONEAPP_PROWLER_DB_PASSWORD`, `ONEAPP_PROWLER_SECRET_KEY`,
  `ONEAPP_PROWLER_AUTH_SECRET`, `ONEAPP_PROWLER_VERSION` contextualization
  variables

## [1.0.0-1] - 2025-01-16

### Added
- Initial release of Prowler Security Platform appliance with full
  Docker-Compose-based deployment (UI + API + MCP + Postgres + Neo4j + Valkey
  + Celery).
