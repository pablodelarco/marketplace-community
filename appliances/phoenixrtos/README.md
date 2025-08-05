# Phoenix RTOS Development Environment Appliance

This appliance provides a complete Phoenix RTOS development environment based on Ubuntu 24.04 LTS with Docker pre-installed and the Phoenix RTOS container image pre-loaded for immediate use.

## Features

- **Ubuntu 24.04 LTS** base system
- **Docker CE** with Phoenix RTOS container pre-loaded
- **Development tools** and utilities pre-installed
- **Ready-to-use** Phoenix RTOS development environment
- **Configurable** container parameters through OpenNebula context
- **Helper scripts** for easy container management

## Pre-loaded Container

- **Image**: `pablodelarco/phoenix-rtos-one:latest`
- **Pre-pulled** during image creation for fast startup
- **Offline availability** - no internet required for container startup

## Quick Start

### 1. Deploy the Appliance

Deploy the appliance through OpenNebula Sunstone or CLI with your desired configuration parameters.

### 2. Access the VM

```bash
ssh root@<vm-ip>
```

### 3. Start Phoenix RTOS Container

```bash
# Using the helper script
phoenix-rtos start

# Or using systemctl
systemctl start phoenix-rtos-container
```

### 4. Access Phoenix RTOS Environment

```bash
# Enter the container shell
phoenix-rtos shell

# Or directly with docker
docker exec -it phoenix-rtos-dev /bin/bash
```

## Configuration Parameters

Configure the appliance behavior through OpenNebula context variables:

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `ONEAPP_PHOENIX_CONTAINER_NAME` | Container name | `phoenix-rtos-dev` | `my-phoenix-dev` |
| `ONEAPP_PHOENIX_AUTO_START` | Auto-start on boot | `YES` | `YES`, `NO` |
| `ONEAPP_PHOENIX_WORK_DIR` | Working directory | `/opt/phoenix-rtos` | `/home/dev/phoenix` |
| `ONEAPP_PHOENIX_EXPOSE_PORTS` | Ports to expose | `22,80,443` | `8080,9000` |
| `ONEAPP_PHOENIX_MEMORY_LIMIT` | Memory limit | unlimited | `1g`, `512m` |
| `ONEAPP_PHOENIX_CPU_LIMIT` | CPU limit | unlimited | `1.5`, `2` |

## Helper Commands

The appliance includes a convenient helper script:

```bash
# Start the container
phoenix-rtos start

# Stop the container
phoenix-rtos stop

# Restart the container
phoenix-rtos restart

# Check container status
phoenix-rtos status

# Enter container shell
phoenix-rtos shell

# View container logs
phoenix-rtos logs
```

## Docker Commands

You can also use standard Docker commands:

```bash
# List containers
docker ps -a

# View container logs
docker logs phoenix-rtos-dev

# Enter container
docker exec -it phoenix-rtos-dev /bin/bash

# Stop container
docker stop phoenix-rtos-dev

# Start container
docker start phoenix-rtos-dev
```

## Development Workflow

1. **Start the container**: `phoenix-rtos start`
2. **Enter the development environment**: `phoenix-rtos shell`
3. **Work on your Phoenix RTOS projects** inside the container
4. **Access files** through the mounted working directory
5. **Use exposed ports** for web interfaces or services

## Troubleshooting

### Container won't start

```bash
# Check Docker service
systemctl status docker

# Check container logs
phoenix-rtos logs

# Check system logs
journalctl -u phoenix-rtos-container
```

### Port conflicts

If you encounter port conflicts, modify the `ONEAPP_PHOENIX_EXPOSE_PORTS` parameter and redeploy.

### Resource limits

Adjust `ONEAPP_PHOENIX_MEMORY_LIMIT` and `ONEAPP_PHOENIX_CPU_LIMIT` based on your requirements.

## File Locations

- **Configuration**: `/etc/phoenix-rtos/container.conf`
- **Working Directory**: `/opt/phoenix-rtos` (default)
- **Helper Script**: `/usr/local/bin/phoenix-rtos`
- **Service File**: `/etc/systemd/system/phoenix-rtos-container.service`
- **Docker Config**: `/etc/docker/daemon.json`

## About Phoenix RTOS

Phoenix RTOS is a scalable real-time operating system for IoT. For more information, visit: https://phoenix-rtos.org/

## Support

For issues related to:
- **Appliance**: Report in OpenNebula Community Marketplace repository
- **Phoenix RTOS**: Visit Phoenix RTOS documentation and community
- **Container**: Contact the container maintainer
