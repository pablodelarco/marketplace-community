# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-1] - 2025-09-18

### Added

Create new Docker appliance for OpenNebula Community Marketplace.

- Based on redis:alpine running in Docker container
- Ubuntu 22.04 LTS base operating system with Docker Engine CE pre-installed
- Docker container ready to run with configurable parameters
- Configurable port mappings (default: 6379:6379)
- Volume mounting support for persistent data
- Environment variable configuration
- Custom command execution support
- Docker registry authentication support
- VNC graphics console access
- SSH access with proper key management
- Comprehensive documentation and usage examples
- Automated testing and certification compliance
