# 🚀 OpenNebula Appliance Creation Tutorial

**Create a complete OpenNebula marketplace appliance from any Docker container in minutes!**

## 📋 Overview

This tutorial shows you how to use the **Docker Appliance Generator** to automatically create an OpenNebula appliance that:
- ✅ Runs any Docker container automatically on VM startup
- ✅ Has SSH access with password and key authentication
- ✅ Includes console and serial console auto-login
- ✅ Can be deployed on OpenNebula cloud platforms
- ✅ Is ready for the OpenNebula Community Marketplace

**Time required**: 15-30 minutes
**Skill level**: Beginner-friendly (no OpenNebula experience required)

---

## 🎯 What You'll Create

The generator automatically creates **13+ files** for a complete OpenNebula appliance:

1. **appliance.sh** - Installation script with Docker and container setup
2. **metadata.yaml** - Appliance metadata and configuration
3. **README.md** - Complete documentation
4. **CHANGELOG.md** - Version history
5. **Packer files** - VM image build configuration (5 files)
6. **Test files** - Automated testing framework (2 files)
7. **Context files** - OpenNebula integration

All files are generated from a simple configuration file!

---

## 📦 Prerequisites

### Required Tools
- Linux system (Ubuntu 22.04+ recommended)
- Git
- (Optional) Packer + QEMU/KVM for building VM images

### Install Dependencies

**Ubuntu/Debian**:
```bash
# Install Git
sudo apt update
sudo apt install -y git

# Optional: Install Packer and QEMU for building images
sudo apt install -y qemu-kvm qemu-utils
wget https://releases.hashicorp.com/packer/1.9.4/packer_1.9.4_linux_amd64.zip
unzip packer_1.9.4_linux_amd64.zip
sudo mv packer /usr/local/bin/
packer version
```

---

## 🛠️ Step 1: Set Up Repository

Clone the OpenNebula marketplace repository:

```bash
cd ~
git clone https://github.com/OpenNebula/marketplace-community.git
cd marketplace-community
```

---

## 📝 Step 2: Create Configuration File

Create a configuration file for your Docker container. The generator includes examples in `tools/examples/`:

### Example 1: NGINX Web Server

```bash
cd tools
cat > myapp.env << 'EOF'
DOCKER_IMAGE="nginx:alpine"
APPLIANCE_NAME="nginx"
APP_NAME="NGINX Web Server"
PUBLISHER_NAME="Your Name"
PUBLISHER_EMAIL="your.email@example.com"
APP_DESCRIPTION="NGINX is a high-performance web server and reverse proxy"
APP_FEATURES="High performance web server,Reverse proxy,Load balancing"
DEFAULT_CONTAINER_NAME="nginx-server"
DEFAULT_PORTS="80:80,443:443"
DEFAULT_ENV_VARS=""
DEFAULT_VOLUMES="/etc/nginx/conf.d:/etc/nginx/conf.d"
APP_PORT="80"
WEB_INTERFACE="true"
EOF
```

### Example 2: Node-RED

```bash
cat > nodered.env << 'EOF'
DOCKER_IMAGE="nodered/node-red:latest"
APPLIANCE_NAME="nodered"
APP_NAME="Node-RED"
PUBLISHER_NAME="Your Name"
PUBLISHER_EMAIL="your.email@example.com"
APP_DESCRIPTION="Node-RED is a flow-based programming tool for IoT"
APP_FEATURES="Visual programming,IoT integration,Flow-based development"
DEFAULT_CONTAINER_NAME="nodered-app"
DEFAULT_PORTS="1880:1880"
DEFAULT_ENV_VARS=""
DEFAULT_VOLUMES="/data:/data"
APP_PORT="1880"
WEB_INTERFACE="true"
EOF
```

### Configuration Variables Explained

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `DOCKER_IMAGE` | ✅ Yes | Docker image from Docker Hub | `nginx:alpine` |
| `APPLIANCE_NAME` | ✅ Yes | Lowercase name (no spaces) | `nginx` |
| `APP_NAME` | ✅ Yes | Display name | `NGINX Web Server` |
| `PUBLISHER_NAME` | ✅ Yes | Your name | `John Doe` |
| `PUBLISHER_EMAIL` | ✅ Yes | Your email | `john@example.com` |
| `APP_DESCRIPTION` | No | Brief description | `High-performance web server` |
| `APP_FEATURES` | No | Comma-separated features | `Web server,Proxy,Load balancing` |
| `DEFAULT_CONTAINER_NAME` | No | Container name | `nginx-server` |
| `DEFAULT_PORTS` | No | Port mappings | `80:80,443:443` |
| `DEFAULT_ENV_VARS` | No | Environment variables | `VAR1=value1,VAR2=value2` |
| `DEFAULT_VOLUMES` | No | Volume mounts | `/host/path:/container/path` |
| `APP_PORT` | No | Main application port | `80` |
| `WEB_INTERFACE` | No | Has web interface? | `true` or `false` |

---

## 🚀 Step 3: Generate Appliance Files

Run the generator script:

```bash
./generate-docker-appliance.sh myapp.env
```

**Output:**
```
🚀 Loading configuration from myapp.env
🎯 Generating complete appliance: nginx (NGINX Web Server)
📁 Creating directory structure...
✅ Directory structure created
📝 Generating metadata.yaml...
📝 Generating nginx-uuid.yaml...
✅ Metadata files generated
📝 Generating README.md...
✅ README.md generated
📝 Generating appliance.sh installation script (simplified structure)...
✅ appliance.sh generated (simplified Phoenix RTOS/Node-RED structure)
📝 Generating Packer configuration files...
✅ Packer configuration files generated
📝 Generating additional required files...
✅ Additional files generated
🎉 Appliance 'nginx' generated successfully!

📁 Files created:
  ✅ appliances/nginx/metadata.yaml
  ✅ appliances/nginx/[uuid].yaml
  ✅ appliances/nginx/README.md
  ✅ appliances/nginx/appliance.sh (with your Docker config)
  ✅ appliances/nginx/CHANGELOG.md
  ✅ appliances/nginx/tests.yaml
  ✅ appliances/nginx/context.yaml
  ✅ appliances/nginx/tests/00-nginx_basic.rb
  ✅ apps-code/community-apps/packer/nginx/*.pkr.hcl
  ✅ apps-code/community-apps/packer/nginx/81-configure-ssh.sh
  ✅ apps-code/community-apps/packer/nginx/82-configure-context.sh
  ✅ apps-code/community-apps/packer/nginx/gen_context
  ✅ apps-code/community-apps/packer/nginx/postprocess.sh

🚀 Next steps:
  1. Add nginx to apps-code/community-apps/Makefile.config SERVICES list
  2. Add logo: logos/nginx.png
  3. Build: cd apps-code/community-apps && make nginx
  4. Test the appliance
```
os-id: Ubuntu
os-release: '22.04'
os-arch: x86_64
hypervisor: KVM
opennebula_version: 7.0
opennebula_template:
  context:
    network: 'YES'
    ssh_public_key: $USER[SSH_PUBLIC_KEY]
  cpu: '2'
  memory: '2048'
  disk:
    image: $FILE[IMAGE_ID]
    image_uname: $USER[IMAGE_UNAME]
  graphics:
    listen: 0.0.0.0
    type: vnc
```

### 2.3 Create Installation Script

Create `appliance.sh` - this script runs during VM image build.

**Important**: This script follows the OpenNebula appliance structure with contextualization support.

**Note**: The `msg` function is used for logging - this is provided by the OpenNebula appliance framework.

```bash
#!/usr/bin/env bash

# My Application Appliance Installation Script
# Docker Image: your-docker-image:tag

set -o errexit -o pipefail

# List of contextualization parameters
ONE_SERVICE_PARAMS=(
    'ONEAPP_CONTAINER_NAME'     'configure'  'Docker container name'                    'O|text'
    'ONEAPP_CONTAINER_PORTS'    'configure'  'Docker container port mappings'           'O|text'
    'ONEAPP_CONTAINER_ENV'      'configure'  'Docker container environment variables'   'O|text'
    'ONEAPP_CONTAINER_VOLUMES'  'configure'  'Docker container volume mappings'         'O|text'
)

# Configuration from user input
DOCKER_IMAGE="your-docker-image:tag"
DEFAULT_CONTAINER_NAME="myapp"
DEFAULT_PORTS="80:80"
DEFAULT_ENV_VARS=""
DEFAULT_VOLUMES="/data:/data"
APP_NAME="My Application"
APPLIANCE_NAME="myapp"

### Appliance metadata ###############################################

ONE_SERVICE_NAME='My Application'
ONE_SERVICE_VERSION=   #latest
ONE_SERVICE_BUILD=$(date +%s)
ONE_SERVICE_SHORT_DESCRIPTION='My Application Docker Container Appliance'
ONE_SERVICE_DESCRIPTION='My Application running in Docker container'
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

    # Pull the Docker image
    msg info "Pulling Docker image: $DOCKER_IMAGE"
    docker pull "$DOCKER_IMAGE"

    # Configure console auto-login
    systemctl stop unattended-upgrades 2>/dev/null || true
    systemctl disable unattended-upgrades 2>/dev/null || true

    apt-get install -y mingetty

    # Configure auto-login on console
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'CONSOLE_EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin root %I $TERM
Type=idle
CONSOLE_EOF

    # Configure serial console and set root password
    mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d
    cat > /etc/systemd/system/serial-getty@ttyS0.service.d/override.conf << 'SERIAL_EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin root %I 115200,38400,9600 vt102
Type=idle
SERIAL_EOF

    echo 'root:opennebula' | chpasswd
    systemctl enable getty@tty1.service serial-getty@ttyS0.service

    # Create welcome message
    cat > /etc/profile.d/99-myapp-welcome.sh << 'WELCOME_EOF'
#!/bin/bash
case $- in
    *i*) ;;
      *) return;;
esac

echo "=================================================="
echo "  My Application Appliance"
echo "=================================================="
echo "  Docker Image: your-docker-image:tag"
echo "  Container: myapp"
echo "  Ports: 80:80"
echo ""
echo "  Commands:"
echo "    docker ps              - Show running containers"
echo "    docker logs myapp      - View container logs"
echo "    docker exec -it myapp /bin/bash - Access container"
echo ""
echo "  Web Interface: http://VM_IP:80"
echo ""
echo "  Access Methods:"
echo "    SSH: Enabled (password: 'opennebula' + context keys)"
echo "    Console: Auto-login as root (via OpenNebula console)"
echo "    Serial: Auto-login as root (via serial console)"
echo "=================================================="
WELCOME_EOF

    chmod +x /etc/profile.d/99-myapp-welcome.sh

    # Clean up
    apt-get autoremove -y
    apt-get autoclean
    find /var/log -type f -exec truncate -s 0 {} \;

    sync

    return 0
}

service_configure()
{
    msg info "Verifying Docker is running"

    if ! systemctl is-active --quiet docker; then
        msg error "Docker is not running"
        return 1
    fi

    msg info "Docker is running"
    return 0
}

service_bootstrap()
{
    msg info "Starting $APP_NAME service bootstrap"

    # Setup and start the container
    setup_myapp_container

    return $?
}

# Setup container function
setup_myapp_container()
{
    local container_name="${ONEAPP_CONTAINER_NAME:-$DEFAULT_CONTAINER_NAME}"
    local container_ports="${ONEAPP_CONTAINER_PORTS:-$DEFAULT_PORTS}"
    local container_env="${ONEAPP_CONTAINER_ENV:-$DEFAULT_ENV_VARS}"
    local container_volumes="${ONEAPP_CONTAINER_VOLUMES:-$DEFAULT_VOLUMES}"

    msg info "Setting up $APP_NAME container: $container_name"

    # Stop and remove existing container if it exists
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        msg info "Stopping existing container: $container_name"
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true
    fi

    # Parse port mappings
    local port_args=""
    if [ -n "$container_ports" ]; then
        IFS=',' read -ra PORT_ARRAY <<< "$container_ports"
        for port in "${PORT_ARRAY[@]}"; do
            port_args="$port_args -p $port"
        done
    fi

    # Parse environment variables
    local env_args=""
    if [ -n "$container_env" ]; then
        IFS=',' read -ra ENV_ARRAY <<< "$container_env"
        for env in "${ENV_ARRAY[@]}"; do
            env_args="$env_args -e $env"
        done
    fi

    # Parse volume mounts
    local volume_args=""
    if [ -n "$container_volumes" ]; then
        IFS=',' read -ra VOL_ARRAY <<< "$container_volumes"
        for vol in "${VOL_ARRAY[@]}"; do
            local host_path=$(echo "$vol" | cut -d':' -f1)
            mkdir -p "$host_path"
            volume_args="$volume_args -v $vol"
        done
    fi

    # Start the container
    msg info "Starting $APP_NAME container with:"
    msg info "  Ports: $container_ports"
    msg info "  Environment: ${container_env:-none}"
    msg info "  Volumes: $container_volumes"

    docker run -d \
        --name "$container_name" \
        --restart unless-stopped \
        $port_args \
        $env_args \
        $volume_args \
        "$DOCKER_IMAGE"

    if [ $? -eq 0 ]; then
        msg info "$APP_NAME container started successfully"
        docker ps --filter name="$container_name"
        return 0
    else
        msg error "Failed to start $APP_NAME container"
        return 1
    fi
}
```

Make it executable:
```bash
chmod +x appliance.sh
```

**Key Features of This Script:**
- ✅ OpenNebula contextualization support (ONE_SERVICE_PARAMS)
- ✅ Configurable container parameters (name, ports, env, volumes)
- ✅ Direct container startup in bootstrap phase
- ✅ Console auto-login configuration
- ✅ Welcome message with usage instructions
- ✅ Proper logging with `msg` function
- ✅ Proper cleanup and optimization

```bash
service_bootstrap()
{
    msg info "Starting My App service bootstrap"

    # Ensure Docker is running
    if ! systemctl is-active --quiet docker; then
        systemctl start docker
        sleep 3
    fi

    # Setup container
    setup_myapp_container

    return 0
}

# Container setup function
setup_myapp_container()
{
    local container_name="myapp"
    local image_name="your-docker-image:tag"

    msg info "Setting up container: $container_name"

    # Stop and remove existing container
    if docker ps -a --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
        msg info "Stopping existing container"
        docker stop "$container_name" 2>/dev/null || true
        docker rm "$container_name" 2>/dev/null || true
        sleep 2
    fi

    # Create data directory
    mkdir -p /data

    # Start container
    msg info "Starting container"
    if docker run -d \
        --name "$container_name" \
        --restart unless-stopped \
        -p 80:80 \
        -v /data:/data \
        "$image_name"; then

        msg info "✓ Container started successfully"

        # Wait and verify
        sleep 5
        if docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
            msg info "✓ Container is running"
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

**Choose Your Approach:**

| Feature | Node-RED Style | Phoenix RTOS Style |
|---------|---------------|-------------------|
| **Complexity** | More code | Less code |
| **Flexibility** | Runtime reconfiguration via context | Fixed configuration |
| **Systemd Service** | Yes (container service) | No |
| **Startup Script** | Yes (`/usr/local/bin/start-*-container.sh`) | No |
| **Context Support** | Full (ports, env, volumes configurable) | Limited |
| **Best For** | Production appliances | Simple/testing appliances |

**Recommendation**: Use **Node-RED style** for marketplace appliances - it provides better user experience with configurable parameters through OpenNebula interface.

**Key Difference**:
- **Node-RED**: Container managed by systemd service + startup script (supports reconfiguration)
- **Phoenix RTOS**: Container started directly in `service_bootstrap()` (simpler but fixed)

**Tip**: Check both `appliances/nodered/appliance.sh` and `appliances/phoenixrtos/appliance.sh` for complete working examples.

### 2.4 Create README

Create `README.md` with usage instructions:

```markdown
# My Application

## Description
Brief description of your application.

## Features
- Feature 1
- Feature 2
- Feature 3

## Requirements
- 2 vCPUs
- 2GB RAM
- 8GB disk space

## Usage

### Access the Application
After VM deployment:
- **Web Interface**: http://VM_IP:80
- **SSH Access**: `ssh root@VM_IP` (uses OpenNebula SSH key)

### Container Management
```bash
# Check container status
docker ps

# View container logs
docker logs myapp

# Restart container
systemctl restart myapp-container
```

## Configuration
Customize the container by editing `/etc/systemd/system/myapp-container.service`
```

---

## 🏗️ Step 3: Create Packer Build Configuration

### 3.1 Create Packer Directory

```bash
cd ~/marketplace-community/apps-code/community-apps
mkdir -p packer/myapp
cd packer/myapp
```

### 3.2 Create Symlink to Common Configuration

```bash
# Link to common Packer configuration
ln -s ../common.pkr.hcl common.pkr.hcl
```

### 3.3 Create Packer Variables

Create `variables.pkr.hcl`:

```hcl
variable "appliance_name" {
  type    = string
  default = "myapp"
}

variable "version" {
  type    = string
  default = "1.0.0"
}

variable "input_dir" {
  type = string
}

variable "output_dir" {
  type = string
}
```

### 3.4 Create Main Packer Template

Create `myapp.pkr.hcl`:

```hcl
source "qemu" "myapp" {
  cpus        = 2
  memory      = 2048
  accelerator = "kvm"
}

build {
  sources = ["source.qemu.myapp"]

  # Upload appliance script
  provisioner "file" {
    source      = "${var.input_dir}/appliances/myapp/appliance.sh"
    destination = "/tmp/appliance.sh"
  }

  # Run appliance script
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/appliance.sh",
      "/tmp/appliance.sh"
    ]
  }
}
```

### 3.5 Copy Configuration Scripts

```bash
# Copy standard configuration scripts from another appliance
cp ../nodered/81-configure-ssh.sh .
cp ../nodered/82-configure-context.sh .
cp ../nodered/gen_context .
```

---

## 🔨 Step 4: Build the Appliance

### 4.1 Add to Build System

Edit `Makefile.config` to add your appliance:

```bash
cd ~/marketplace-community/apps-code/community-apps
nano Makefile.config
```

Find the `SERVICES :=` line and add `myapp`:

```makefile
SERVICES := lithops rabbitmq ueransim example phoenixrtos nodered myapp
```

### 4.2 Build with Make

```bash
# Build your appliance
make myapp
```

**Build time**: 15-30 minutes

**What happens:**
1. Downloads Ubuntu 22.04 ISO (~4GB, cached for future builds)
2. Creates VM with Packer
3. Installs Ubuntu automatically
4. Runs your appliance.sh script
5. Installs OpenNebula context
6. Creates final QCOW2 image

### 4.3 Find the Built Image

```bash
# The image will be in the export directory
ls -lh export/myapp.qcow2
```

**Output**: `export/myapp.qcow2` (~2-4GB)

---

## 📤 Step 5: Deploy to OpenNebula

### 5.1 Copy Image to OpenNebula Frontend

```bash
scp export/myapp.qcow2 root@opennebula-frontend:/var/tmp/
```

### 5.2 Create OpenNebula Image

```bash
ssh root@opennebula-frontend

# Create image (replace datastore ID)
oneimage create --name "myapp" \
  --path "/var/tmp/myapp.qcow2" \
  --datastore 1

# Check status
oneimage list
```

### 5.3 Create VM Template

```bash
cat > myapp-template.txt << 'EOF'
NAME = "myapp-template"
CPU = "2"
MEMORY = "2048"
DISK = [
  IMAGE_ID = "IMAGE_ID_HERE"
]
NIC = [
  NETWORK_ID = "0"
]
CONTEXT = [
  NETWORK = "YES",
  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
]
GRAPHICS = [
  TYPE = "VNC",
  LISTEN = "0.0.0.0"
]
EOF

onetemplate create myapp-template.txt
```

### 5.4 Test the Appliance

```bash
# Instantiate VM
onetemplate instantiate TEMPLATE_ID --name "test-myapp"

# Wait for VM to be running
onevm list

# Get VM IP
onevm show VM_ID | grep IP

# Test SSH access
ssh root@VM_IP

# Verify container is running
docker ps
```

---

## ✅ Step 6: Verification Checklist

Before submitting to the marketplace, verify everything works:

- [ ] VM boots successfully
- [ ] SSH access works with OpenNebula key
- [ ] Docker service is running
- [ ] Container starts automatically
- [ ] Application is accessible (web/API)
- [ ] Container logs show no errors
- [ ] Documentation is complete and clear
- [ ] Metadata.yaml has correct information

---

## 📤 Step 7: Submit to OpenNebula Marketplace

### 7.1 Fork the Repository

1. Go to https://github.com/OpenNebula/marketplace-community
2. Click the **"Fork"** button in the top-right corner
3. Wait for GitHub to create your fork

### 7.2 Add Your Fork as Remote

```bash
cd ~/marketplace-community

# Add your fork as a remote (replace YOUR_USERNAME)
git remote add fork https://github.com/YOUR_USERNAME/marketplace-community.git

# Verify remotes
git remote -v
```

### 7.3 Create a Branch for Your Appliance

```bash
# Create and switch to a new branch
git checkout -b feature/add-myapp-appliance

# Verify you're on the new branch
git branch
```

### 7.4 Add Your Files

```bash
# Add appliance files
git add appliances/myapp/

# Add Packer build files
git add apps-code/community-apps/packer/myapp/

# Add Makefile.config (if you modified it)
git add apps-code/community-apps/Makefile.config

# Check what will be committed
git status
```

### 7.5 Commit Your Changes

```bash
git commit -m "Add My Application appliance

- Add My Application appliance with Docker support
- Ubuntu 22.04 LTS base with Docker Engine
- Auto-start container on boot
- SSH access with OpenNebula key authentication
- VNC console access
- Complete documentation and metadata
- Packer build configuration included"
```

### 7.6 Push to Your Fork

```bash
# Push your branch to your fork
git push fork feature/add-myapp-appliance
```

### 7.7 Create Pull Request

1. **Go to your fork** on GitHub: `https://github.com/YOUR_USERNAME/marketplace-community`
2. You'll see a banner: **"Compare & pull request"** - click it
3. **Fill out the PR template**:

   **Title**: `Add My Application appliance`

   **Description**:
   ```markdown
   # Appliance

   New appliance submission for **My Application**.

   ## Appliance Name

   :app: **myapp**

   ## Type of Contribution

   - [x] New Appliance
   - [ ] Update to an Existing Appliance

   ## Description of Changes

   This PR adds a new My Application appliance to the OpenNebula Community Marketplace.

   **My Application** is [brief description]. This appliance provides:

   - Feature 1
   - Feature 2
   - Feature 3
   - Docker-based deployment
   - Auto-start on boot
   - SSH and VNC access

   ### Technical Implementation

   - **Base OS**: Ubuntu 22.04 LTS
   - **Container**: Docker with your-image:tag
   - **Memory**: 2GB RAM
   - **CPU**: 2 vCPUs
   - **Disk**: 8GB
   - **Access**: SSH (OpenNebula key), VNC console

   ## Access Methods

   - **SSH**: `ssh root@VM_IP` (uses OpenNebula SSH key)
   - **Web Interface**: http://VM_IP:PORT (if applicable)
   - **VNC Console**: Available through OpenNebula Sunstone

   ## Contributor Checklist

   - [x] Appliance builds successfully
   - [x] Tested on OpenNebula
   - [x] Documentation is complete
   - [x] Metadata is accurate
   - [x] All required files included

   ## Publisher Information

   - **Publisher**: Your Name
   - **Email**: your.email@example.com

   ## Testing & Validation

   - ✅ Built successfully with `make myapp`
   - ✅ Deployed on OpenNebula
   - ✅ SSH access verified
   - ✅ Container starts automatically
   - ✅ Application accessible

   ## Files Added

   **Appliance Files:**
   - `appliances/myapp/metadata.yaml`
   - `appliances/myapp/appliance.sh`
   - `appliances/myapp/README.md`

   **Packer Build Files:**
   - `apps-code/community-apps/packer/myapp/myapp.pkr.hcl`
   - `apps-code/community-apps/packer/myapp/variables.pkr.hcl`
   - `apps-code/community-apps/packer/myapp/common.pkr.hcl` (symlink)
   - `apps-code/community-apps/packer/myapp/81-configure-ssh.sh`
   - `apps-code/community-apps/packer/myapp/82-configure-context.sh`
   - `apps-code/community-apps/packer/myapp/gen_context`
   ```

4. **Click "Create pull request"**

### 7.8 Wait for Review

- OpenNebula maintainers will review your PR
- They may request changes or ask questions
- Make any requested changes and push to the same branch
- Once approved, your appliance will be merged!

---

## 🔄 Making Changes After Submission

If you need to update your PR:

```bash
# Make your changes
nano appliances/myapp/README.md

# Commit the changes
git add appliances/myapp/README.md
git commit -m "Update documentation"

# Push to your fork (same branch)
git push fork feature/add-myapp-appliance
```

The PR will automatically update with your new commits.

---

## 🎉 Success!

You've created and submitted a complete OpenNebula appliance!

### Your Appliance Includes:
- 🖥️ Ubuntu 22.04 LTS base system
- 🐳 Docker Engine pre-installed
- 🎯 Your container auto-starting on boot
- 🔐 SSH access with OpenNebula keys
- 📊 Complete documentation
- ⚙️ Configurable through OpenNebula

---

## 📚 Additional Resources

- [OpenNebula Documentation](https://docs.opennebula.io/)
- [Packer Documentation](https://www.packer.io/docs)
- [Docker Documentation](https://docs.docker.com/)
- [OpenNebula Marketplace](https://marketplace.opennebula.io/)
- [OpenNebula Forum](https://forum.opennebula.io/)
- [GitHub Repository](https://github.com/OpenNebula/marketplace-community)

