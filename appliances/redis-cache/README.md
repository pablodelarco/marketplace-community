# Redis Appliance

## Overview

This appliance provides Redis running in a Docker container on Ubuntu 22.04 LTS. It's designed for easy deployment in OpenNebula cloud environments with full Docker integration and customization options.

## Features

- **Base System**: Ubuntu 22.04 LTS with latest updates
- **Docker Engine**: Pre-installed Docker CE with Docker Compose
- **Container**: redis:alpine ready to run
- **Networking**: Configurable port mappings (default: 6379:6379)
- **Storage**: Volume mounting support for persistent data
- **Configuration**: Environment variables and custom commands
- **Authentication**: Docker registry authentication support
- **Access**: SSH and VNC console access

## Quick Start

1. **Deploy the VM** from the OpenNebula marketplace
2. **Configure parameters** during instantiation:
   - Port mappings (e.g., `6379:6379`)
   - Volume mounts (e.g., `/host/data:/container/data`)
   - Environment variables (e.g., `ENV1=value1,ENV2=value2`)
3. **Access the application** via the configured ports
4. **Manage containers** using standard Docker commands

## Configuration Parameters

### Required Parameters
- **Port Mappings**: Configure which ports to expose (default: 6379:6379)

### Optional Parameters
- **Volume Mappings**: Mount host directories into the container
- **Environment Variables**: Set container environment variables
- **Custom Command**: Override the default container command
- **Registry Authentication**: Use private Docker registries

## Container Management

### Check Container Status
```bash
sudo docker ps
sudo docker logs redis-cache
```

### Restart Container
```bash
sudo docker restart redis-cache
```

### Access Container Shell
```bash
sudo docker exec -it redis-cache /bin/bash
```

## Troubleshooting

### Container Not Starting
1. Check Docker service: `sudo systemctl status docker`
2. Check container logs: `sudo docker logs redis-cache`
3. Verify image availability: `sudo docker images`

### Port Access Issues
1. Verify port mappings: `sudo docker port redis-cache`
2. Check firewall settings
3. Ensure application is listening on correct interface

## Support

- **Documentation**: [OpenNebula Documentation](https://docs.opennebula.io/)
- **Community**: [OpenNebula Community Forum](https://forum.opennebula.io/)
- **Docker Image**: [redis:alpine](https://hub.docker.com/r/redis:alpine)

## Version Information

- **Appliance Version**: 1.0.0-1
- **Base OS**: Ubuntu 22.04 LTS
- **Docker Image**: redis:alpine
- **Default Ports**: 6379:6379
