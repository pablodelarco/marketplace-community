# 🚀 Quick Start: Create an OpenNebula Appliance

**The fastest way to create an OpenNebula appliance from a Docker container**

---

## ⚡ 5-Minute Setup

### 1. Install Tools

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y qemu-kvm qemu-utils git

# Install Packer
wget https://releases.hashicorp.com/packer/1.9.4/packer_1.9.4_linux_amd64.zip
unzip packer_1.9.4_linux_amd64.zip
sudo mv packer /usr/local/bin/
```

### 2. Clone Repository

```bash
git clone https://github.com/OpenNebula/marketplace-community.git
cd marketplace-community
```

### 3. Create Appliance Files

```bash
# Create appliance directory
mkdir -p appliances/myapp
cd appliances/myapp

# Create metadata.yaml (see template below)
nano metadata.yaml

# Create appliance.sh (see template below)
nano appliance.sh
chmod +x appliance.sh

# Create README.md
nano README.md
```

---

## 📋 File Templates

### metadata.yaml Template

```yaml
---
name: My App
version: 1.0.0-1
publisher: Your Name
publisher_email: your@email.com
description: |-
  Your app description here.
  
  **Features:**
  - Feature 1
  - Feature 2

short_description: One-line description
tags:
  - docker
  - ubuntu
format: qcow2
creation_time: 1234567890
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
```

### appliance.sh Template

**Note**: Use the full template from Node-RED or Phoenix RTOS as reference. Here's the essential structure:

```bash
#!/usr/bin/env bash
set -o errexit -o pipefail

# Contextualization parameters
ONE_SERVICE_PARAMS=(
    'ONEAPP_CONTAINER_NAME'     'configure'  'Docker container name'           'O|text'
    'ONEAPP_CONTAINER_PORTS'    'configure'  'Docker container port mappings'  'O|text'
    'ONEAPP_CONTAINER_ENV'      'configure'  'Environment variables'           'O|text'
    'ONEAPP_CONTAINER_VOLUMES'  'configure'  'Volume mappings'                 'O|text'
)

# Configuration
DOCKER_IMAGE="your-image:tag"
DEFAULT_CONTAINER_NAME="myapp"
DEFAULT_PORTS="80:80"
APPLIANCE_NAME="myapp"

# Metadata
ONE_SERVICE_NAME='My App'
ONE_SERVICE_RECONFIGURABLE=true

service_install()
{
    export DEBIAN_FRONTEND=noninteractive

    # Update and install Docker
    apt-get update && apt-get upgrade -y
    apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io

    systemctl enable docker
    systemctl start docker

    # Pull image
    docker pull "$DOCKER_IMAGE"

    # Create container startup script (see full tutorial for complete script)
    cat > /usr/local/bin/start-myapp-container.sh << 'SCRIPT'
#!/bin/bash
# Load context, parse ports/env/volumes, start container
# (See CREATE_APPLIANCE_TUTORIAL.md for full script)
SCRIPT

    chmod +x /usr/local/bin/start-myapp-container.sh

    # Create systemd service
    cat > /etc/systemd/system/myapp-container.service << 'EOF'
[Unit]
Description=My App Container
After=docker.service one-context.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/start-myapp-container.sh
ExecStop=/usr/bin/docker stop myapp
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
EOF

    systemctl enable myapp-container.service

    # Configure console auto-login
    apt-get install -y mingetty
    mkdir -p /etc/systemd/system/getty@tty1.service.d
    cat > /etc/systemd/system/getty@tty1.service.d/override.conf << 'EOF'
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noissue --autologin root %I $TERM
EOF

    echo 'root:opennebula' | chpasswd

    # Create welcome message
    cat > /etc/profile.d/99-myapp-welcome.sh << 'EOF'
echo "My App Appliance - http://VM_IP:80"
echo "Commands: docker ps, docker logs myapp"
EOF

    # Cleanup
    apt-get autoremove -y
    apt-get autoclean

    return 0
}

service_configure()
{
    # Handle context variables
    return 0
}

service_bootstrap()
{
    systemctl start myapp-container.service
    return 0
}
```

**Two Approaches:**

1. **Node-RED style** (RECOMMENDED): Container startup script + systemd service
   - ✅ Supports runtime reconfiguration via OpenNebula context
   - ✅ Users can change ports, env vars, volumes through UI
   - ✅ Better for production marketplace appliances

2. **Phoenix RTOS style**: Direct container setup in `service_bootstrap()`
   - ✅ Simpler code, less files
   - ❌ No runtime reconfiguration
   - ✅ Good for simple/testing appliances

**For complete examples**:
- Node-RED: `appliances/nodered/appliance.sh` (recommended pattern)
- Phoenix RTOS: `appliances/phoenixrtos/appliance.sh` (simpler pattern)
- Full tutorial: `docs/CREATE_APPLIANCE_TUTORIAL.md`

---

## 🏗️ Build the Image

### Install Build Tools

**Ubuntu/Debian**:
```bash
sudo apt update
sudo apt install -y qemu-kvm qemu-utils

# Install Packer
wget https://releases.hashicorp.com/packer/1.9.4/packer_1.9.4_linux_amd64.zip
unzip packer_1.9.4_linux_amd64.zip
sudo mv packer /usr/local/bin/
packer version
```

**CentOS/RHEL**:
```bash
sudo yum install -y qemu-kvm qemu-img
# Then install Packer as above
```

### Create Packer Configuration

```bash
cd ~/marketplace-community/apps-code/community-apps
mkdir -p packer/myapp
cd packer/myapp

# Create symlink to common config
ln -s ../common.pkr.hcl common.pkr.hcl

# Copy configuration scripts from existing appliance
cp ../nodered/81-configure-ssh.sh .
cp ../nodered/82-configure-context.sh .
cp ../nodered/gen_context .
```

Create `variables.pkr.hcl` and `myapp.pkr.hcl` (see full tutorial)

### Add to Build System

```bash
cd ~/marketplace-community/apps-code/community-apps
nano Makefile.config
```

Add `myapp` to the `SERVICES :=` line:
```makefile
# Before:
SERVICES := lithops rabbitmq ueransim example phoenixrtos nodered

# After (add myapp):
SERVICES := lithops rabbitmq ueransim example phoenixrtos nodered myapp
```

Save the file (Ctrl+X, Y, Enter).

### Build with Make

```bash
# Build your appliance (takes 15-30 minutes)
make myapp
```

**What happens during build:**
1. 📥 Downloads Ubuntu 22.04 LTS ISO (~4GB, cached for future builds)
2. 🖥️ Creates virtual machine with 2GB RAM, 8GB disk
3. 💿 Installs Ubuntu automatically
4. 🐳 Installs Docker and your container
5. ⚙️ Configures SSH, console access, and OpenNebula integration
6. 📦 Creates final .qcow2 image file

**Build time**: 15-30 minutes (depending on internet speed)

### Verify Build Success

```bash
# Check the built image
ls -la export/myapp.qcow2

# Should show a file ~2-4GB in size
```

**Output**: `export/myapp.qcow2`

---

## 📤 Deploy to OpenNebula

### 1. Copy Image

```bash
scp export/myapp.qcow2 root@opennebula-frontend:/var/tmp/
```

### 2. Create Image

```bash
ssh root@opennebula-frontend
oneimage create --name "myapp" --path "/var/tmp/myapp.qcow2" --datastore 1
```

### 3. Create Template

```bash
cat > template.txt << 'EOF'
NAME = "myapp"
CPU = "2"
MEMORY = "2048"
DISK = [ IMAGE_ID = "IMAGE_ID" ]
NIC = [ NETWORK_ID = "0" ]
CONTEXT = [
  NETWORK = "YES",
  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]"
]
EOF

onetemplate create template.txt
```

### 4. Deploy VM

```bash
onetemplate instantiate TEMPLATE_ID --name "test-myapp"
```

---

## ✅ Test

```bash
# Get VM IP
onevm show VM_ID | grep IP

# SSH to VM
ssh root@VM_IP

# Check container
docker ps
docker logs myapp
```

---

## 🎯 Common Use Cases

### Web Application (Port 80)

```bash
# In appliance.sh
docker run -d --name myapp --restart unless-stopped -p 80:80 nginx:alpine
```

### Database (Port 5432)

```bash
# In appliance.sh
docker run -d --name postgres --restart unless-stopped \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=secret \
  -v /data:/var/lib/postgresql/data \
  postgres:15
```

### API Service (Port 8080)

```bash
# In appliance.sh
docker run -d --name api --restart unless-stopped \
  -p 8080:8080 \
  -e API_KEY=your-key \
  your-api-image:latest
```

---

## 🔧 Troubleshooting

### Build Fails

```bash
# Check build logs
make myapp

# Clean and rebuild
make clean
make myapp

# Check if appliance is in SERVICES list
grep SERVICES Makefile.config
```

### Container Not Starting

```bash
# SSH to VM
ssh root@VM_IP

# Check service status
systemctl status myapp.service

# Check Docker logs
docker logs myapp

# Check Docker service
systemctl status docker
```

### SSH Access Fails

```bash
# Recreate VM template (OpenNebula context issue)
onetemplate delete TEMPLATE_ID
onetemplate create template.txt

# Verify SSH key in OpenNebula user settings
oneuser show
```

---

## 📤 Submit to Marketplace

### 1. Fork Repository

Go to https://github.com/OpenNebula/marketplace-community and click **Fork**

### 2. Add Fork as Remote

```bash
git remote add fork https://github.com/YOUR_USERNAME/marketplace-community.git
```

### 3. Create Branch

```bash
git checkout -b feature/add-myapp-appliance
```

### 4. Add and Commit Files

```bash
git add appliances/myapp/
git add apps-code/community-apps/packer/myapp/
git add apps-code/community-apps/Makefile.config
git commit -m "Add My App appliance"
```

### 5. Push to Fork

```bash
git push fork feature/add-myapp-appliance
```

### 6. Create Pull Request

1. Go to your fork on GitHub
2. Click **"Compare & pull request"**
3. Fill out the PR template with:
   - Appliance name and description
   - Features and technical details
   - Testing verification
   - Files added
4. Click **"Create pull request"**

---

## 📚 Next Steps

- Read full tutorial: [CREATE_APPLIANCE_TUTORIAL.md](CREATE_APPLIANCE_TUTORIAL.md)
- Check existing appliances: `marketplace-community/appliances/`
- Join community: [OpenNebula Forum](https://forum.opennebula.io/)

---

## 💡 Tips

1. **Test locally first**: Use QEMU to test the image before deploying
2. **Keep it simple**: Start with basic Docker run, add complexity later
3. **Document everything**: Good README helps users
4. **Use tags**: Proper tags help discoverability
5. **Version properly**: Follow semantic versioning (1.0.0-1)
6. **Check existing appliances**: Look at Node-RED or Phoenix RTOS as examples

---

## 🎉 Done!

You now have a working OpenNebula appliance. Share it with the community! 🚀

