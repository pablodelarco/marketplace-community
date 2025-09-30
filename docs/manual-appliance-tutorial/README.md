# ✍️ Manual OpenNebula Appliance Creation Tutorial

**Learn how to manually create OpenNebula marketplace appliances from Docker containers**

This tutorial teaches you how to create each file manually, giving you complete control and deep understanding of the appliance structure.

**Time required**: 30-45 minutes  
**Skill level**: Intermediate (requires understanding of bash scripting and YAML)

---

## 📋 Overview

You will manually create **13+ files** for a complete OpenNebula appliance:

1. **appliance.sh** - Installation script (main logic)
2. **metadata.yaml** - Build configuration
3. **[UUID].yaml** - Appliance metadata
4. **README.md** - User documentation
5. **CHANGELOG.md** - Version history
6. **tests.yaml** - Test configuration
7. **context.yaml** - Test context variables
8. **tests/00-[name]_basic.rb** - Test script
9. **Packer files** (5 files) - VM build configuration

---

## 📦 Prerequisites

- Linux system (Ubuntu 22.04+ recommended)
- Git
- Text editor (nano, vim, or VS Code)
- Basic knowledge of:
  - Bash scripting
  - YAML syntax
  - Docker containers
  - (Optional) Packer and QEMU/KVM for building images

---

## 🚀 Step 1: Set Up Directory Structure

First, clone the repository and create your appliance directory:

```bash
# Clone repository
cd ~
git clone https://github.com/OpenNebula/marketplace-community.git
cd marketplace-community

# Create appliance directory (use lowercase, no spaces)
mkdir -p appliances/myapp
cd appliances/myapp
```

**Naming convention**: Use lowercase letters, numbers, and hyphens only (e.g., `nginx`, `node-red`, `postgres`).

---

## 📝 Step 2: Create metadata.yaml

This file configures how the VM image is built.

```bash
nano metadata.yaml
```

**Template:**

```yaml
---
name: 'MyApp'
version: '1.0.0'
publisher: 'Your Name'
description: |-
  MyApp is a description of your application.
  
  This appliance runs MyApp in a Docker container with automatic startup.
  
  **Access Methods:**
  - SSH: root@<vm-ip> (password: opennebula)
  - Console: Auto-login as root

short_description: 'MyApp - Brief description'
tags:
  - 'docker'
  - 'myapp'
format: 'qcow2'
os-id: 'Ubuntu'
os-release: '22.04'
os-arch: 'x86_64'
hypervisor: 'KVM'
opennebula_version: '6.0'
opennebula_template:
  context:
    network: 'YES'
    ssh_public_key: '$USER[SSH_PUBLIC_KEY]'
  cpu: '2'
  memory: '2048'
  graphics:
    listen: '0.0.0.0'
    type: 'VNC'
logo: 'myapp.png'
images:
  - name: 'myapp'
    url: ''
    type: 'OS'
    dev_prefix: 'vd'
    driver: 'qcow2'
    size: 8192
```

**Customize**: name, version, publisher, description, tags

---

## 🔧 Step 3: Create appliance.sh

This is the main installation script. Use the **exact structure** from Phoenix RTOS/Node-RED appliances.

```bash
nano appliance.sh
```

**Template (based on Phoenix RTOS/Node-RED structure):**

```bash
#!/usr/bin/env bash

# MyApp Appliance Installation Script
# Docker Image: your-docker-image:tag

set -o errexit -o pipefail

# List of contextualization parameters
ONE_SERVICE_PARAMS=(
    'ONEAPP_CONTAINER_NAME'     'configure'  'Docker container name'                    'O|text'
    'ONEAPP_CONTAINER_PORTS'    'configure'  'Docker container port mappings'           'O|text'
    'ONEAPP_CONTAINER_ENV'      'configure'  'Docker container environment variables'   'O|text'
    'ONEAPP_CONTAINER_VOLUMES'  'configure'  'Docker container volume mappings'         'O|text'
)

# Configuration from user input - CUSTOMIZE THESE
DOCKER_IMAGE="your-docker-image:tag"
DEFAULT_CONTAINER_NAME="myapp-container"
DEFAULT_PORTS="8080:8080"
DEFAULT_ENV_VARS=""
DEFAULT_VOLUMES="/data:/data"
APP_NAME="MyApp"
APPLIANCE_NAME="myapp"

### Appliance metadata ###############################################

ONE_SERVICE_NAME='MyApp'
ONE_SERVICE_VERSION=   #latest
ONE_SERVICE_BUILD=$(date +%s)
ONE_SERVICE_SHORT_DESCRIPTION='MyApp Docker Container Appliance'
ONE_SERVICE_DESCRIPTION='MyApp running in Docker container'
ONE_SERVICE_RECONFIGURABLE=true

### Appliance functions ##############################################

service_cleanup()
{
    :
}

service_install()
{
    export DEBIAN_FRONTEND=noninteractive

# Update system
apt-get update
apt-get upgrade -y

# Install Docker
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Pre-create the data directory
mkdir -p /data
chown 1000:1000 /data

# Pull Docker image during installation
msg info "Pulling ${APP_NAME} Docker image"
docker pull $DOCKER_IMAGE

# Verify the image was pulled
msg info "Verifying ${APP_NAME} image was pulled:"
docker images $DOCKER_IMAGE

# Configure console auto-login
systemctl stop unattended-upgrades 2>/dev/null || true
systemctl disable unattended-upgrades 2>/dev/null || true
apt-get install -y mingetty
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin root %I $TERM
Type=idle
EOF

# Configure serial console and set root password
mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d
cat > /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin root %I 115200,38400,9600 vt102
Type=idle
EOF
echo 'root:opennebula' | chpasswd
systemctl enable getty@tty1.service serial-getty@ttyS0.service

# Create welcome message
cat > /etc/profile.d/99-myapp-welcome.sh << 'EOF'
#!/bin/bash
case $- in *i*) ;; *) return;; esac
echo "=================================================="
echo "  MyApp Appliance - Container: myapp-container"
echo "  Commands: docker ps | docker logs myapp-container"
echo "=================================================="
EOF
chmod +x /etc/profile.d/99-myapp-welcome.sh

# Clean up
apt-get autoremove -y
apt-get autoclean
find /var/log -type f -exec truncate -s 0 {} \;

sync
}

service_configure()
{
    msg info "Starting ${APP_NAME} service configuration"

    # Ensure Docker is running
    if ! systemctl is-active --quiet docker; then
        msg info "Starting Docker service..."
        systemctl enable docker
        systemctl start docker
        sleep 3
    fi

    # Verify Docker is working
    if docker info >/dev/null 2>&1; then
        msg info "✓ Docker is running and accessible"
    else
        msg error "✗ Docker is not working properly"
        return 1
    fi

    msg info "${APP_NAME} configuration completed"
    return 0
}

service_bootstrap()
{
    msg info "Starting ${APP_NAME} service bootstrap"

    # Ensure Docker is running
    if ! systemctl is-active --quiet docker; then
        msg info "Starting Docker service..."
        systemctl start docker
        sleep 3
    fi

    # Setup container
    msg info "Setting up ${APP_NAME} container"
    setup_myapp_container

    msg info "${APP_NAME} bootstrap completed"
    return 0
}

# Container setup function
setup_myapp_container()
{
    local container_name="${DEFAULT_CONTAINER_NAME}"
    local image_name="${DOCKER_IMAGE}"

    msg info "Setting up ${APP_NAME} container: $container_name"

    # Stop and remove any existing container
    if docker ps -a --filter "name=$container_name" --format "table {{.Names}}" | grep -q "$container_name"; then
        msg info "Stopping and removing existing ${APP_NAME} container"
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true
        sleep 2
    fi

    # Create data directory
    mkdir -p /data

    # Start container
    msg info "Starting ${APP_NAME} container"
    if docker run -d \
        --name "$container_name" \
        --restart unless-stopped \
        -p 8080:8080 \
        -v /data:/data \
        --label oneapp.managed=true \
        --label oneapp.service=${APPLIANCE_NAME} \
        "$image_name"; then

        msg info "✓ ${APP_NAME} container created and started successfully"

        # Wait and verify container is running
        sleep 5
        if docker ps --filter "name=$container_name" --format "table {{.Names}}" | grep -q "$container_name"; then
            msg info "✓ ${APP_NAME} container is running"

            # Show container status
            local status=$(docker ps --filter "name=$container_name" --format "{{.Status}}")
            msg info "  Status: $status"
        else
            msg error "✗ ${APP_NAME} container stopped unexpectedly"
            msg info "Container logs:"
            docker logs "$container_name" 2>&1 | tail -10 | while read line; do
                msg info "  $line"
            done
            return 1
        fi
    else
        msg error "✗ Failed to start ${APP_NAME} container"
        return 1
    fi
}
```

**Key points (matching Phoenix RTOS/Node-RED):**
- Uses `msg info/error/warn` for logging (provided by OpenNebula framework)
- No systemd service - direct container startup in `service_bootstrap()`
- Console auto-login with getty configuration
- Root password set to 'opennebula'
- Welcome message in `/etc/profile.d/`
- Separate `setup_myapp_container()` function
- Uses `--restart unless-stopped` for container

---

## 📄 Step 4: Create UUID.yaml

Generate a UUID and create the metadata file:

```bash
# Generate UUID
UUID=$(uuidgen)
echo "Generated UUID: $UUID"

# Create file
nano ${UUID}.yaml
```

**Template:**

```yaml
---
name: 'MyApp'
version: '1.0.0'
publisher: 'Your Name'
description: 'MyApp description'
short_description: 'MyApp - Brief description'
tags:
  - 'docker'
  - 'myapp'
format: 'qcow2'
creation_time: 1234567890
os-id: 'Ubuntu'
os-release: '22.04'
os-arch: 'x86_64'
hypervisor: 'KVM'
```

---

## 📖 Step 5: Create README.md

```bash
nano README.md
```

**Template:**

```markdown
# MyApp Appliance

## Description

MyApp is [description of your application].

This appliance provides a ready-to-use MyApp installation running in a Docker container.

## Features

- Automatic Docker container startup
- SSH access with password authentication
- Console auto-login
- Configurable via OpenNebula context

## Access

- **SSH**: `ssh root@<vm-ip>` (password: `opennebula`)
- **Console**: Auto-login as root
- **Application**: http://<vm-ip>:8080

## Configuration

You can configure the container via OpenNebula context variables:

- `ONEAPP_CONTAINER_NAME`: Container name (default: myapp-container)
- `ONEAPP_CONTAINER_PORTS`: Port mappings (default: 8080:8080)
- `ONEAPP_CONTAINER_ENV`: Environment variables
- `ONEAPP_CONTAINER_VOLUMES`: Volume mappings

## Container Management

```bash
# View logs
docker logs myapp-container

# Restart container
docker restart myapp-container

# Stop container
docker stop myapp-container
```

## Requirements

- CPU: 2 cores
- Memory: 2 GB RAM
- Disk: 8 GB

## Support

For issues and questions, visit: [your-support-url]
```

---

## 📝 Step 6: Create CHANGELOG.md

```bash
nano CHANGELOG.md
```

**Template:**

```markdown
# Changelog

## [1.0.0] - 2024-01-01

### Added
- Initial release
- Docker-based MyApp deployment
- SSH and console access
- OpenNebula context integration
```

---

## 🧪 Step 7: Create Test Files

### tests.yaml

```bash
nano tests.yaml
```

```yaml
---
tests:
  - name: 'basic'
    description: 'Basic functionality test'
    script: 'tests/00-myapp_basic.rb'
```

### context.yaml

```bash
nano context.yaml
```

```yaml
---
context:
  ONEAPP_CONTAINER_NAME: 'test-myapp'
  ONEAPP_CONTAINER_PORTS: '8080:8080'
```

### Test script

```bash
mkdir -p tests
nano tests/00-myapp_basic.rb
```

```ruby
require 'minitest/autorun'

class TestMyApp < Minitest::Test
  def test_docker_installed
    assert system('which docker'), 'Docker should be installed'
  end
  
  def test_container_running
    assert system('docker ps | grep myapp'), 'Container should be running'
  end
end
```

---

## 🏗️ Step 8: Create Packer Files

Create Packer configuration for building the VM image:

```bash
cd ../../apps-code/community-apps/packer
mkdir -p myapp
cd myapp
```

### myapp.pkr.hcl

```hcl
source "qemu" "myapp" {
  source_path = "../../one-apps/export/ubuntu2204.qcow2"
  output_directory = "../../export"
  vm_name = "myapp.qcow2"
  
  cpus = 2
  memory = 2048
  disk_size = "8G"
  
  headless = true
  accelerator = "kvm"
}

build {
  sources = ["source.qemu.myapp"]
  
  provisioner "shell" {
    script = "../../../appliances/myapp/appliance.sh"
    environment_vars = [
      "ONE_SERVICE_SETUP_INSTALL=YES",
      "ONE_SERVICE_SETUP_CONFIGURE=YES"
    ]
  }
}
```

---

## ✅ Step 9: Verify Your Files

Check that you have all required files:

```bash
cd ~/marketplace-community/appliances/myapp
ls -la
```

**You should have:**
- appliance.sh
- metadata.yaml
- [UUID].yaml
- README.md
- CHANGELOG.md
- tests.yaml
- context.yaml
- tests/00-myapp_basic.rb

---

## 🔨 Step 10: Build the VM Image (Optional)

If you want to build the actual VM image:

```bash
# Build base image (one-time)
cd ~/marketplace-community/apps-code/one-apps
make context
make ubuntu2204

# Build your appliance
cd ../community-apps
# Add 'myapp' to Makefile.config SERVICES list
make myapp
```

**Output**: `apps-code/community-apps/export/myapp.qcow2`

---

## 📤 Step 11: Submit to Marketplace

```bash
# Fork repository on GitHub
# Clone your fork
git clone https://github.com/YOUR_USERNAME/marketplace-community.git
cd marketplace-community

# Create branch
git checkout -b feature/add-myapp-appliance

# Add files
git add appliances/myapp/
git add apps-code/community-apps/packer/myapp/
git add logos/myapp.png  # Don't forget the logo!

# Commit and push
git commit -m "Add MyApp appliance"
git push origin feature/add-myapp-appliance

# Create Pull Request on GitHub
```

---

## 📚 Reference: Existing Appliances

Study existing appliances for examples:

```bash
# View example appliance
cat appliances/example/appliance.sh
cat appliances/example/metadata.yaml

# View Node-RED appliance (if available)
cat appliances/nodered/appliance.sh
```

---

## 🐛 Troubleshooting

**Problem**: appliance.sh fails during build  
**Solution**: Test the script manually on an Ubuntu 22.04 VM

**Problem**: Docker container doesn't start  
**Solution**: Check Docker logs: `docker logs container-name`

**Problem**: SSH access fails  
**Solution**: Verify password authentication is enabled in sshd_config

---

## 💡 Tips

1. **Start simple**: Get basic functionality working first
2. **Test locally**: Test appliance.sh on a VM before building
3. **Study examples**: Look at existing appliances in the repository
4. **Use logging**: Add `msg info` statements for debugging
5. **Version control**: Commit changes frequently

---

## 📖 Additional Resources

- [OpenNebula Documentation](https://docs.opennebula.io/)
- [Docker Documentation](https://docs.docker.com/)
- [Packer Documentation](https://www.packer.io/docs)
- [OpenNebula Marketplace](https://marketplace.opennebula.io/)

---

## ✅ Summary

You've learned how to:
- ✅ Create appliance directory structure
- ✅ Write metadata.yaml configuration
- ✅ Create appliance.sh installation script
- ✅ Write documentation files
- ✅ Create test files
- ✅ Configure Packer for VM builds
- ✅ Submit to OpenNebula marketplace

**Next Steps:**
- Build and test your appliance
- Customize for your specific needs
- Share with the OpenNebula community
