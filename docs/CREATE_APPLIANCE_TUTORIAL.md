# Creating OpenNebula Appliances from Docker Containers

**A complete guide to creating OpenNebula marketplace appliances**

---

## 📖 Introduction

This guide teaches you how to create OpenNebula appliances that run Docker containers. An OpenNebula appliance is a pre-configured VM image that can be deployed on OpenNebula cloud platforms and shared through the OpenNebula Community Marketplace.

**What you'll create:**
- A VM image (QCOW2 format) with Ubuntu 22.04 + Docker
- Automatic Docker container startup on VM boot
- SSH access with password and key authentication
- Console and serial console auto-login
- OpenNebula context integration for runtime configuration

**Two approaches available:**
1. **Automatic** - Use a generator script (5 minutes, recommended)
2. **Manual** - Create all files manually (30-45 minutes, full control)

---

## 🤖 Approach 1: Automatic (Recommended)

**Best for:** Quick appliance creation, beginners, standard Docker containers

### Prerequisites

- Linux system (Ubuntu 22.04+ recommended)
- Git

```bash
sudo apt update
sudo apt install -y git
```

### Step 1: Clone Repository

```bash
git clone https://github.com/OpenNebula/marketplace-community.git
cd marketplace-community
```

### Step 2: Create Configuration File

Create a `.env` file with your Docker container details:

```bash
cd docs/automatic-appliance-tutorial

cat > myapp.env << 'ENVEOF'
# Required variables
DOCKER_IMAGE="your-docker-image:tag"
APPLIANCE_NAME="myapp"
APP_NAME="MyApp"
PUBLISHER_NAME="Your Name"
PUBLISHER_EMAIL="your.email@example.com"

# Optional variables
APP_DESCRIPTION="MyApp description"
APP_FEATURES="Feature 1,Feature 2,Feature 3"
DEFAULT_CONTAINER_NAME="myapp-container"
DEFAULT_PORTS="8080:8080"
DEFAULT_ENV_VARS=""
DEFAULT_VOLUMES="/data:/data"
APP_PORT="8080"
WEB_INTERFACE="true"
ENVEOF
```

**Configuration variables:**

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DOCKER_IMAGE` | Yes | Docker image name | `nginx:alpine` |
| `APPLIANCE_NAME` | Yes | Lowercase name (no spaces) | `nginx` |
| `APP_NAME` | Yes | Display name | `NGINX Web Server` |
| `PUBLISHER_NAME` | Yes | Your name | `John Doe` |
| `PUBLISHER_EMAIL` | Yes | Your email | `john@example.com` |
| `DEFAULT_PORTS` | No | Port mappings | `80:80,443:443` |
| `DEFAULT_ENV_VARS` | No | Environment variables | `KEY=value,KEY2=value2` |
| `DEFAULT_VOLUMES` | No | Volume mappings | `/data:/data` |
| `WEB_INTERFACE` | No | Has web UI? | `true` or `false` |

### Step 3: Run Generator

```bash
./generate-docker-appliance.sh myapp.env
```

**Output:**
```
🚀 Loading configuration from myapp.env
🎯 Generating complete appliance: myapp (MyApp)
📁 Creating directory structure...
✅ Directory structure created
📝 Generating metadata.yaml...
✅ Metadata files generated
📝 Generating README.md...
✅ README.md generated
📝 Generating appliance.sh installation script...
✅ appliance.sh generated
📝 Generating Packer configuration files...
✅ Packer configuration files generated
🎉 Appliance 'myapp' generated successfully!
```

**Files created:**
- `../../appliances/myapp/appliance.sh` - Installation script
- `../../appliances/myapp/metadata.yaml` - Build configuration
- `../../appliances/myapp/README.md` - Documentation
- `../../appliances/myapp/CHANGELOG.md` - Version history
- `../../appliances/myapp/tests.yaml` - Test configuration
- `../../apps-code/community-apps/packer/myapp/*.pkr.hcl` - Packer files

### Step 4: Review Generated Files

```bash
cd ../../appliances/myapp
ls -la
```

The generator creates a complete appliance using the proven Phoenix RTOS/Node-RED structure.

### Examples

See `docs/automatic-appliance-tutorial/examples/` for complete examples:
- **nginx.env** - NGINX web server
- **nodered.env** - Node-RED IoT platform
- **postgres.env** - PostgreSQL database
- **redis.env** - Redis cache

---

## ✍️ Approach 2: Manual

**Best for:** Custom appliances, advanced users, special requirements

### Prerequisites

- Linux system (Ubuntu 22.04+ recommended)
- Git
- Text editor
- Basic knowledge of bash scripting and YAML

### Step 1: Create Directory Structure

```bash
git clone https://github.com/OpenNebula/marketplace-community.git
cd marketplace-community

# Create appliance directory (lowercase, no spaces)
mkdir -p appliances/myapp
cd appliances/myapp
```

### Step 2: Create metadata.yaml

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
  MyApp description.
  
  This appliance runs MyApp in a Docker container.
  
  **Access:**
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

### Step 3: Create appliance.sh

This is the main installation script. Use the **exact structure** from Phoenix RTOS/Node-RED:

```bash
nano appliance.sh
```

**Template:**

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

# Configuration - CUSTOMIZE THESE
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

# Pre-create data directory
mkdir -p /data
chown 1000:1000 /data

# Pull Docker image
msg info "Pulling ${APP_NAME} Docker image"
docker pull $DOCKER_IMAGE

# Verify image
msg info "Verifying ${APP_NAME} image:"
docker images $DOCKER_IMAGE

# Configure console auto-login
systemctl stop unattended-upgrades 2>/dev/null || true
systemctl disable unattended-upgrades 2>/dev/null || true
apt-get install -y mingetty
mkdir -p /etc/systemd/system/getty@tty1.service.d
cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'CONSOLE_EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin root %I $TERM
Type=idle
CONSOLE_EOF

# Configure serial console
mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d
cat > /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf << 'SERIAL_EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin root %I 115200,38400,9600 vt102
Type=idle
SERIAL_EOF

# Set root password
echo 'root:opennebula' | chpasswd
systemctl enable getty@tty1.service serial-getty@ttyS0.service

# Create welcome message
cat > /etc/profile.d/99-myapp-welcome.sh << 'WELCOME_EOF'
#!/bin/bash
case $- in *i*) ;; *) return;; esac
echo "=================================================="
echo "  MyApp Appliance - Container: myapp-container"
echo "  Commands: docker ps | docker logs myapp-container"
echo "=================================================="
WELCOME_EOF
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

    # Verify Docker
    if docker info >/dev/null 2>&1; then
        msg info "✓ Docker is running"
    else
        msg error "✗ Docker is not working"
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

    # Stop and remove existing container
    if docker ps -a --filter "name=$container_name" --format "table {{.Names}}" | grep -q "$container_name"; then
        msg info "Stopping existing container"
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

        msg info "✓ Container started successfully"

        # Verify container is running
        sleep 5
        if docker ps --filter "name=$container_name" --format "table {{.Names}}" | grep -q "$container_name"; then
            msg info "✓ Container is running"
            local status=$(docker ps --filter "name=$container_name" --format "{{.Status}}")
            msg info "  Status: $status"
        else
            msg error "✗ Container stopped unexpectedly"
            docker logs "$container_name" 2>&1 | tail -10
            return 1
        fi
    else
        msg error "✗ Failed to start container"
        return 1
    fi
}
```

**Key points:**
- Uses `msg info/error` for logging (provided by OpenNebula framework)
- No systemd service - direct container startup
- Console auto-login (getty@tty1 + serial-getty@ttyS0)
- Root password: `opennebula`
- Separate `setup_myapp_container()` function

### Step 4: Create Additional Files

**UUID.yaml:**
```bash
UUID=$(uuidgen)
nano ${UUID}.yaml
```

**README.md:**
```bash
nano README.md
```

**CHANGELOG.md:**
```bash
nano CHANGELOG.md
```

For complete templates, see: `docs/manual-appliance-tutorial/README.md`

---

## 🔨 Building VM Images (Optional)

Both approaches create appliance files. To build actual VM images:

### Prerequisites

```bash
# Install Packer and QEMU
sudo apt install -y qemu-kvm qemu-utils
wget https://releases.hashicorp.com/packer/1.9.4/packer_1.9.4_linux_amd64.zip
unzip packer_1.9.4_linux_amd64.zip
sudo mv packer /usr/local/bin/
```

### Build Steps

```bash
# 1. Build base image (one-time, ~10 minutes)
cd apps-code/one-apps
make context
make ubuntu2204

# 2. Add your appliance to Makefile
cd ../community-apps
# Edit Makefile.config and add 'myapp' to SERVICES list

# 3. Build your appliance (~15-30 minutes)
make myapp
```

**Output:** `apps-code/community-apps/export/myapp.qcow2`

---

## 🚀 Deploying to OpenNebula

After building the QCOW2 image (either automatic or manual approach), you need to deploy it to OpenNebula.

### Step 1: Copy Image to OpenNebula Frontend

```bash
# From your build machine, copy the QCOW2 image to OpenNebula
scp apps-code/community-apps/export/myapp.qcow2 root@opennebula-frontend:/var/tmp/
```

**Note:** Replace `opennebula-frontend` with your OpenNebula frontend hostname or IP.

### Step 2: Create OpenNebula Image

SSH to your OpenNebula frontend and create the image:

```bash
ssh root@opennebula-frontend

# Create the image in a datastore (replace datastore ID as needed)
oneimage create --name "MyApp" \
  --path "/var/tmp/myapp.qcow2" \
  --type OS \
  --datastore 1 \
  --description "MyApp Docker Container Appliance"

# Check image status
oneimage list
oneimage show <IMAGE_ID>
```

**Wait for the image to be in READY state** (this may take a few minutes depending on image size).

### Step 3: Create VM Template

Create a VM template for easy deployment:

```bash
cat > myapp-template.txt << 'EOF'
NAME = "MyApp Template"
CPU = "2"
MEMORY = "2048"

DISK = [
  IMAGE_ID = "<IMAGE_ID_FROM_STEP_2>"
]

NIC = [
  NETWORK = "default",
  NETWORK_UNAME = "oneadmin"
]

CONTEXT = [
  NETWORK = "YES",
  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]",
  SET_HOSTNAME = "$NAME"
]

# Optional: Add context variables for container configuration
CONTEXT = [
  NETWORK = "YES",
  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]",
  SET_HOSTNAME = "$NAME",
  ONEAPP_CONTAINER_NAME = "myapp-container",
  ONEAPP_CONTAINER_PORTS = "8080:8080",
  ONEAPP_CONTAINER_ENV = "",
  ONEAPP_CONTAINER_VOLUMES = "/data:/data"
]

GRAPHICS = [
  TYPE = "VNC",
  LISTEN = "0.0.0.0"
]

# Optional: Add user inputs for runtime configuration
USER_INPUTS = [
  ONEAPP_CONTAINER_NAME = "O|text|Container name",
  ONEAPP_CONTAINER_PORTS = "O|text|Port mappings (format: host:container,host:container)",
  ONEAPP_CONTAINER_ENV = "O|text|Environment variables (format: KEY=value,KEY=value)",
  ONEAPP_CONTAINER_VOLUMES = "O|text|Volume mappings (format: host:container,host:container)"
]
EOF

# Create the template
onetemplate create myapp-template.txt

# Verify template was created
onetemplate list
```

**Replace `<IMAGE_ID_FROM_STEP_2>`** with the actual image ID from Step 2.

### Step 4: Instantiate VM

Deploy a VM from the template:

```bash
# Instantiate VM
onetemplate instantiate <TEMPLATE_ID> --name "myapp-test-vm"

# Monitor VM status
onevm list
onevm show <VM_ID>

# Wait for VM to be in RUNNING state
watch onevm list
```

### Step 5: Get VM IP Address

```bash
# Get VM IP address
onevm show <VM_ID> | grep IP
# Or
onevm show <VM_ID> --json | jq -r '.VM.TEMPLATE.NIC[0].IP'
```

### Step 6: Test the Appliance

**Test SSH access:**
```bash
# SSH with password
ssh root@<VM_IP>
# Password: opennebula

# Or with your SSH key (if configured in context)
ssh -i ~/.ssh/id_rsa root@<VM_IP>
```

**Verify Docker container is running:**
```bash
# Once connected to the VM
docker ps

# Check container logs
docker logs myapp-container

# Check container status
docker inspect myapp-container
```

**Test the application:**
```bash
# If your app has a web interface
curl http://<VM_IP>:8080

# Or open in browser
# http://<VM_IP>:8080
```

**Test console access (via OpenNebula Sunstone):**
1. Open OpenNebula Sunstone web interface
2. Go to Instances → VMs
3. Click on your VM
4. Click "VNC" button
5. You should see auto-login to root with welcome message

---

## 📤 Submitting to OpenNebula Marketplace

Once your appliance is tested and working, submit it to the community marketplace.

### Step 1: Fork the Repository

1. Go to https://github.com/OpenNebula/marketplace-community
2. Click the **"Fork"** button in the top right
3. This creates a copy in your GitHub account

### Step 2: Clone Your Fork

```bash
# Clone your forked repository
git clone https://github.com/YOUR_USERNAME/marketplace-community.git
cd marketplace-community

# Add upstream remote (to sync with main repo later)
git remote add upstream https://github.com/OpenNebula/marketplace-community.git

# Verify remotes
git remote -v
```

### Step 3: Create a Feature Branch

```bash
# Create and switch to a new branch
git checkout -b feature/add-myapp-appliance

# Verify you're on the new branch
git branch
```

**Branch naming convention:** `feature/add-<appliance-name>-appliance`

### Step 4: Add Your Appliance Files

```bash
# Add appliance files
git add appliances/myapp/

# Add Packer configuration files
git add apps-code/community-apps/packer/myapp/

# Add logo (256x256 PNG recommended)
# Make sure you have a logo file ready
cp /path/to/your/logo.png logos/myapp.png
git add logos/myapp.png
```

**Required files checklist:**
- ✅ `appliances/myapp/appliance.sh`
- ✅ `appliances/myapp/metadata.yaml`
- ✅ `appliances/myapp/<UUID>.yaml`
- ✅ `appliances/myapp/README.md`
- ✅ `appliances/myapp/CHANGELOG.md`
- ✅ `appliances/myapp/tests.yaml`
- ✅ `appliances/myapp/context.yaml`
- ✅ `appliances/myapp/tests/00-myapp_basic.rb`
- ✅ `apps-code/community-apps/packer/myapp/*.pkr.hcl`
- ✅ `logos/myapp.png`

### Step 5: Commit Your Changes

```bash
# Check what files will be committed
git status

# Commit with a descriptive message
git commit -m "Add MyApp appliance

- Docker-based MyApp deployment
- Automatic container startup
- SSH and console access
- OpenNebula context integration
- Tested on Ubuntu 22.04"
```

**Good commit message format:**
- First line: Brief summary (50 chars or less)
- Blank line
- Detailed description with bullet points

### Step 6: Push to Your Fork

```bash
# Push your branch to your fork
git push origin feature/add-myapp-appliance
```

### Step 7: Create Pull Request (PR)

**Option A: Using the GitHub banner (easiest)**

1. Go to your fork on GitHub: `https://github.com/YOUR_USERNAME/marketplace-community`
2. After pushing, you should see a yellow/green banner at the top: **"Compare & pull request"**
3. Click the **"Compare & pull request"** button

**Option B: Manual PR creation**

1. Go to your fork: `https://github.com/YOUR_USERNAME/marketplace-community`
2. Click the **"Pull requests"** tab
3. Click the green **"New pull request"** button
4. You'll see the "Comparing changes" page
5. Make sure the branches are set correctly:
   - **base repository:** `OpenNebula/marketplace-community` (left side)
   - **base branch:** `master` (left side)
   - **head repository:** `YOUR_USERNAME/marketplace-community` (right side)
   - **compare branch:** `feature/add-myapp-appliance` (right side)
6. Click **"Create pull request"**

**What you should see:**
- Green text: "Able to merge" ✅
- List of your commits
- Files changed (should show your appliance files)

If you see conflicts or errors, you may need to sync with upstream first.

### Step 8: Fill Pull Request Details

**Title:**
```
Add MyApp appliance
```

**Description template:**
```markdown
## Description

This PR adds a new appliance for MyApp, a [brief description of what MyApp does].

## Appliance Details

- **Name:** MyApp
- **Version:** 1.0.0
- **Docker Image:** your-docker-image:tag
- **Base OS:** Ubuntu 22.04
- **Publisher:** Your Name

## Features

- Automatic Docker container startup
- SSH access with password and key authentication
- Console and serial console auto-login
- OpenNebula context integration
- Configurable via context variables:
  - Container name
  - Port mappings
  - Environment variables
  - Volume mappings

## Testing

- ✅ Built successfully with Packer
- ✅ Deployed to OpenNebula
- ✅ Container starts automatically
- ✅ SSH access works (password + keys)
- ✅ Console auto-login works
- ✅ Application accessible on configured ports

## Files Added

- `appliances/myapp/` - Appliance definition files
- `apps-code/community-apps/packer/myapp/` - Packer build configuration
- `logos/myapp.png` - Appliance logo

## Checklist

- [x] Appliance builds successfully
- [x] Appliance tested on OpenNebula
- [x] Documentation included (README.md)
- [x] Logo added (256x256 PNG)
- [x] Follows Phoenix RTOS/Node-RED structure
- [x] No sensitive information in files
```

### Step 9: Submit and Wait for Review

1. Click **"Create pull request"**
2. Wait for OpenNebula maintainers to review
3. Address any feedback or requested changes
4. Once approved, your appliance will be merged!

### Step 10: Update Your PR (if needed)

If maintainers request changes:

```bash
# Make the requested changes to your files
nano appliances/myapp/appliance.sh

# Commit the changes
git add appliances/myapp/appliance.sh
git commit -m "Address review feedback: fix container startup logic"

# Push to your branch (PR will update automatically)
git push origin feature/add-myapp-appliance
```

The PR will automatically update with your new commits.

---

## 🐛 Troubleshooting

**Problem:** Generator fails  
**Solution:** Check all required variables are set in .env file

**Problem:** appliance.sh fails during build  
**Solution:** Test script manually on Ubuntu 22.04 VM

**Problem:** Container doesn't start  
**Solution:** Check Docker logs: `docker logs container-name`

**Problem:** SSH fails  
**Solution:** Recreate VM template (OpenNebula context issue)

---

## 📖 Additional Resources

- [OpenNebula Documentation](https://docs.opennebula.io/)
- [Docker Hub](https://hub.docker.com/)
- [Packer Documentation](https://www.packer.io/docs)
- [OpenNebula Marketplace](https://marketplace.opennebula.io/)

---

## 💡 Tips

- **Start with automatic approach** - Even if you need customization, generate first then edit
- **Study examples** - Check `docs/automatic-appliance-tutorial/examples/` for working configs
- **Test locally** - Test appliance.sh on a VM before building
- **Use logging** - Add `msg info` statements for debugging
- **Follow the pattern** - Use the Phoenix RTOS/Node-RED structure (proven in production)
