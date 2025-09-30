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

## 🎯 What the Generator Creates

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
cat > nginx.env << 'EOF'
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
./generate-docker-appliance.sh nginx.env
```

**Output:**
```
🚀 Loading configuration from nginx.env
🎯 Generating complete appliance: nginx (NGINX Web Server)
📁 Creating directory structure...
✅ Directory structure created
📝 Generating metadata.yaml...
✅ Metadata files generated
📝 Generating README.md...
✅ README.md generated
📝 Generating appliance.sh installation script (simplified structure)...
✅ appliance.sh generated
📝 Generating Packer configuration files...
✅ Packer configuration files generated
🎉 Appliance 'nginx' generated successfully!

📁 Files created:
  ✅ appliances/nginx/metadata.yaml
  ✅ appliances/nginx/[uuid].yaml
  ✅ appliances/nginx/README.md
  ✅ appliances/nginx/appliance.sh
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

---

## 📂 Step 4: Review Generated Files

The generator creates all necessary files. Let's review the key ones:

### Generated appliance.sh Structure

The generated `appliance.sh` uses the simplified Phoenix RTOS/Node-RED pattern:

```bash
#!/usr/bin/env bash
set -o errexit -o pipefail

# Contextualization parameters
ONE_SERVICE_PARAMS=(
    'ONEAPP_CONTAINER_NAME'     'configure'  'Docker container name'
    'ONEAPP_CONTAINER_PORTS'    'configure'  'Docker container port mappings'
    'ONEAPP_CONTAINER_ENV'      'configure'  'Docker container environment variables'
    'ONEAPP_CONTAINER_VOLUMES'  'configure'  'Docker container volume mappings'
)

# Configuration (from your .env file)
DOCKER_IMAGE="nginx:alpine"
DEFAULT_CONTAINER_NAME="nginx-server"
DEFAULT_PORTS="80:80,443:443"
# ... etc

service_install() {
    # Installs Docker
    # Pulls your Docker image
    # Configures console auto-login
    # Sets root password to 'opennebula'
    # Creates welcome message
}

service_configure() {
    # Verifies Docker is running
}

service_bootstrap() {
    # Calls setup_nginx_container()
}

setup_nginx_container() {
    # Parses OpenNebula context variables
    # Starts Docker container with your configuration
}
```

**Key Features:**
- ✅ Direct container startup (no systemd service)
- ✅ Uses `msg` function for logging
- ✅ Console and serial console auto-login
- ✅ SSH with password ('opennebula') and context keys
- ✅ Configurable via OpenNebula context variables

### Generated Directory Structure

```
appliances/nginx/
├── metadata.yaml              # Build configuration
├── [uuid].yaml               # Appliance metadata
├── README.md                 # Documentation
├── CHANGELOG.md              # Version history
├── appliance.sh              # Installation script
├── tests.yaml                # Test configuration
├── context.yaml              # Test context
└── tests/
    └── 00-nginx_basic.rb     # Basic tests

apps-code/community-apps/packer/nginx/
├── nginx.pkr.hcl             # Main Packer config
├── variables.pkr.hcl         # Variables
├── common.pkr.hcl            # Common config (symlink)
├── 81-configure-ssh.sh       # SSH configuration
├── 82-configure-context.sh   # Context configuration
├── gen_context               # Context generator
└── postprocess.sh            # Post-processing
```

---

## 🏗️ Step 5: Add to Build System (Optional)

To build the VM image, add your appliance to the build system:

### 5.1 Add to Makefile

Edit `apps-code/community-apps/Makefile.config` and add your appliance to the `SERVICES` list:

```makefile
SERVICES = \
    ...
    nginx \
    ...
```

### 5.2 Add Logo

Add a logo for your appliance:

```bash
# Download or create a logo (PNG format, recommended size: 256x256)
cp your-logo.png logos/nginx.png
```

---

## 🔨 Step 6: Build VM Image (Optional)

If you want to build the actual VM image:

### 6.1 Build Base Image

First, build the Ubuntu base image (one-time setup):

```bash
cd apps-code/one-apps
make context
make ubuntu2204
```

This creates `apps-code/one-apps/export/ubuntu2204.qcow2`.

### 6.2 Build Your Appliance

```bash
cd ../community-apps
make nginx
```

**Build time**: 15-30 minutes

**Output**: `apps-code/community-apps/export/nginx.qcow2`

---

## 🧪 Step 7: Test the Appliance

### Option A: Test Without Building (Quick)

Review the generated files to ensure they match your requirements:

```bash
# Check appliance.sh
cat ../appliances/nginx/appliance.sh

# Check metadata
cat ../appliances/nginx/metadata.yaml

# Check README
cat ../appliances/nginx/README.md
```

### Option B: Test Built Image (Complete)

If you built the VM image, test it in OpenNebula:

#### 1. Copy Image to OpenNebula Frontend

```bash
scp apps-code/community-apps/export/nginx.qcow2 root@opennebula-frontend:/var/tmp/
```

#### 2. Create OpenNebula Image

```bash
# SSH to OpenNebula frontend
ssh root@opennebula-frontend

# Create image (replace datastore ID)
oneimage create --name "nginx" --path "/var/tmp/nginx.qcow2" --datastore 1
```

#### 3. Create VM Template

```bash
cat > nginx-template.txt << 'EOF'
NAME = "nginx-template"
CPU = "2"
MEMORY = "2048"
DISK = [
  IMAGE_ID = "IMAGE_ID_FROM_STEP_2"
]
NIC = [
  NETWORK_ID = "0"
]
CONTEXT = [
  NETWORK = "YES",
  SSH_PUBLIC_KEY = "$USER[SSH_PUBLIC_KEY]",
  SET_HOSTNAME = "$USER[SET_HOSTNAME]"
]
GRAPHICS = [
  TYPE = "VNC",
  LISTEN = "0.0.0.0"
]
EOF

onetemplate create nginx-template.txt
```

#### 4. Deploy and Test

```bash
# Instantiate VM
onetemplate instantiate TEMPLATE_ID --name "test-nginx-vm"

# Wait for VM to be running
onevm show VM_ID

# Get VM IP
onevm show VM_ID | grep IP

# Test SSH access
ssh root@VM_IP
# Password: opennebula

# Once connected, verify:
docker ps                    # Container should be running
docker logs nginx-server     # Check container logs
curl http://localhost:80     # Test NGINX
```

---

## 📤 Step 8: Submit to Marketplace (Optional)

To share your appliance with the OpenNebula community:

### 8.1 Fork Repository

```bash
# Fork on GitHub: https://github.com/OpenNebula/marketplace-community
# Clone your fork
git clone https://github.com/YOUR_USERNAME/marketplace-community.git
cd marketplace-community
```

### 8.2 Create Branch

```bash
git checkout -b feature/add-nginx-appliance
```

### 8.3 Commit Files

```bash
git add appliances/nginx/
git add apps-code/community-apps/packer/nginx/
git add logos/nginx.png
git commit -m "Add NGINX appliance"
```

### 8.4 Push and Create PR

```bash
git push origin feature/add-nginx-appliance
```

Then create a Pull Request on GitHub.

---

## 🎓 Advanced: Customizing Generated Files

After generation, you can customize the files:

### Modify appliance.sh

```bash
# Edit the installation script
nano appliances/nginx/appliance.sh

# Add custom setup steps in service_install()
# Modify container startup in setup_nginx_container()
```

### Modify Metadata

```bash
# Edit appliance metadata
nano appliances/nginx/metadata.yaml

# Update description, tags, requirements, etc.
```

### Add Custom Tests

```bash
# Add more tests
nano appliances/nginx/tests/00-nginx_basic.rb

# Add test methods following Ruby minitest format
```

---

## 📚 More Examples

Check `tools/examples/` for more configuration examples:

- **nginx.env** - NGINX web server
- **nodered.env** - Node-RED IoT platform
- **postgres.env** - PostgreSQL database
- **redis.env** - Redis cache

---

## 🐛 Troubleshooting

### Generator Issues

**Problem**: "Required variable not set"  
**Solution**: Ensure all required variables are in your .env file

**Problem**: "APPLIANCE_NAME must be lowercase"  
**Solution**: Use only lowercase letters and numbers, no spaces

### Build Issues

**Problem**: "ubuntu2204.qcow2 not found"  
**Solution**: Build base image first: `cd apps-code/one-apps && make ubuntu2204`

**Problem**: Packer build fails  
**Solution**: Check you have KVM enabled: `lsmod | grep kvm`

### Deployment Issues

**Problem**: Container not starting  
**Solution**: Check Docker logs: `docker logs CONTAINER_NAME`

**Problem**: SSH fails  
**Solution**: Recreate VM template (OpenNebula context resolution issue)

---

## ✅ Summary

You've learned how to:
- ✅ Use the Docker Appliance Generator
- ✅ Create configuration files for any Docker container
- ✅ Generate complete appliance files automatically
- ✅ Build VM images (optional)
- ✅ Test and deploy appliances
- ✅ Submit to OpenNebula marketplace

**Next Steps:**
- Try generating appliances for other Docker containers
- Customize generated files for your needs
- Share your appliances with the community

---

## 📖 Additional Resources

- [OpenNebula Documentation](https://docs.opennebula.io/)
- [Docker Hub](https://hub.docker.com/)
- [Packer Documentation](https://www.packer.io/docs)
- [OpenNebula Marketplace](https://marketplace.opennebula.io/)

---

**Questions or Issues?**  
Open an issue on the [marketplace-community repository](https://github.com/OpenNebula/marketplace-community/issues)

