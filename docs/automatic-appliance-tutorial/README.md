# 🚀 Create OpenNebula Appliances from Docker Containers

**Turn any Docker container into a complete OpenNebula appliance in 5 minutes!**

## 📋 What You'll Do

This tutorial shows you how to use the **Docker Appliance Generator** to automatically create a complete OpenNebula appliance from any Docker container.

**What you need:**
1. A Docker image name (e.g., `nginx:alpine`, `nodered/node-red:latest`)
2. 5 minutes of your time

**What you get:**
- Complete appliance with 13+ files automatically generated
- Ready to build VM image
- Ready to deploy on OpenNebula
- Ready to submit to marketplace

---

## 📦 Prerequisites

**Required:**
- Linux system (Ubuntu 22.04+ recommended)
- Git

**Optional (for building VM images):**
- Packer
- QEMU/KVM

### Install Git

```bash
sudo apt update
sudo apt install -y git
```

---

## 🚀 Quick Start (3 Steps)

### Step 1: Clone Repository

```bash
git clone https://github.com/OpenNebula/marketplace-community.git
cd marketplace-community/tools
```

### Step 2: Create Configuration File

Create a `.env` file with your Docker container details:

```bash
nano myapp.env
```

Add your configuration (see examples below):

```bash
DOCKER_IMAGE="nginx:alpine"
APPLIANCE_NAME="nginx"
APP_NAME="NGINX Web Server"
PUBLISHER_NAME="Your Name"
PUBLISHER_EMAIL="your.email@example.com"
APP_DESCRIPTION="High-performance web server"
APP_FEATURES="Web server,Reverse proxy,Load balancing"
DEFAULT_PORTS="80:80,443:443"
WEB_INTERFACE="true"
```

### Step 3: Run Generator

```bash
./generate-docker-appliance.sh myapp.env
```

**Done!** All appliance files are now created in `../appliances/nginx/` and `../apps-code/community-apps/packer/nginx/`

---

## 📝 Configuration File Format

Your `.env` file contains variables that describe your Docker container. Here's what each variable means:

### Required Variables

These variables are **required** - the generator will fail without them:

```bash
# The Docker image to use (from Docker Hub)
DOCKER_IMAGE="nginx:alpine"

# Appliance name (lowercase, no spaces, used for file names)
APPLIANCE_NAME="nginx"

# Display name (shown in OpenNebula)
APP_NAME="NGINX Web Server"

# Your name
PUBLISHER_NAME="John Doe"

# Your email
PUBLISHER_EMAIL="john@example.com"
```

### Optional Variables

These variables are **optional** - the generator will use defaults if not specified:

```bash
# Brief description of your application
APP_DESCRIPTION="NGINX is a high-performance web server and reverse proxy"

# Comma-separated list of features
APP_FEATURES="Web server,Reverse proxy,Load balancing"

# Container name (default: appliance-name-container)
DEFAULT_CONTAINER_NAME="nginx-server"

# Port mappings in format host:container,host:container
# Default: 8080:80
DEFAULT_PORTS="80:80,443:443"

# Environment variables in format VAR1=value1,VAR2=value2
# Default: empty
DEFAULT_ENV_VARS="TZ=UTC,LOG_LEVEL=info"

# Volume mounts in format /host/path:/container/path
# Default: empty
DEFAULT_VOLUMES="/etc/nginx/conf.d:/etc/nginx/conf.d,/var/www:/usr/share/nginx/html"

# Main application port (for web interface)
# Default: 8080
APP_PORT="80"

# Does the app have a web interface?
# Default: true
WEB_INTERFACE="true"
```

### Variable Reference Table

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `DOCKER_IMAGE` | ✅ Yes | - | Docker image from Docker Hub |
| `APPLIANCE_NAME` | ✅ Yes | - | Lowercase name (no spaces) |
| `APP_NAME` | ✅ Yes | - | Display name |
| `PUBLISHER_NAME` | ✅ Yes | - | Your name |
| `PUBLISHER_EMAIL` | ✅ Yes | - | Your email |
| `APP_DESCRIPTION` | No | Generic description | Brief description |
| `APP_FEATURES` | No | Generic features | Comma-separated features |
| `DEFAULT_CONTAINER_NAME` | No | `{appliance}-container` | Container name |
| `DEFAULT_PORTS` | No | `8080:80` | Port mappings |
| `DEFAULT_ENV_VARS` | No | Empty | Environment variables |
| `DEFAULT_VOLUMES` | No | Empty | Volume mounts |
| `APP_PORT` | No | `8080` | Main application port |
| `WEB_INTERFACE` | No | `true` | Has web interface? |

---

## 📚 Complete Examples

### Example 1: NGINX Web Server

**Use case:** Simple web server

```bash
cat > nginx.env << 'EOF'
DOCKER_IMAGE="nginx:alpine"
APPLIANCE_NAME="nginx"
APP_NAME="NGINX Web Server"
PUBLISHER_NAME="Your Name"
PUBLISHER_EMAIL="your.email@example.com"
APP_DESCRIPTION="NGINX is a high-performance web server and reverse proxy"
APP_FEATURES="Web server,Reverse proxy,Load balancing"
DEFAULT_CONTAINER_NAME="nginx-server"
DEFAULT_PORTS="80:80,443:443"
DEFAULT_VOLUMES="/etc/nginx/conf.d:/etc/nginx/conf.d"
APP_PORT="80"
WEB_INTERFACE="true"
EOF

./generate-docker-appliance.sh nginx.env
```

### Example 2: Node-RED

**Use case:** IoT and automation platform

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
DEFAULT_VOLUMES="/data:/data"
APP_PORT="1880"
WEB_INTERFACE="true"
EOF

./generate-docker-appliance.sh nodered.env
```

### Example 3: PostgreSQL Database

**Use case:** Database server

```bash
cat > postgres.env << 'EOF'
DOCKER_IMAGE="postgres:15-alpine"
APPLIANCE_NAME="postgres"
APP_NAME="PostgreSQL Database"
PUBLISHER_NAME="Your Name"
PUBLISHER_EMAIL="your.email@example.com"
APP_DESCRIPTION="PostgreSQL is a powerful open-source relational database"
APP_FEATURES="SQL database,ACID compliant,Extensible"
DEFAULT_CONTAINER_NAME="postgres-db"
DEFAULT_PORTS="5432:5432"
DEFAULT_ENV_VARS="POSTGRES_PASSWORD=changeme,POSTGRES_DB=mydb"
DEFAULT_VOLUMES="/var/lib/postgresql/data:/var/lib/postgresql/data"
APP_PORT="5432"
WEB_INTERFACE="false"
EOF

./generate-docker-appliance.sh postgres.env
```

### Example 4: Redis Cache

**Use case:** In-memory data store

```bash
cat > redis.env << 'EOF'
DOCKER_IMAGE="redis:alpine"
APPLIANCE_NAME="redis"
APP_NAME="Redis Cache"
PUBLISHER_NAME="Your Name"
PUBLISHER_EMAIL="your.email@example.com"
APP_DESCRIPTION="Redis is an in-memory data structure store"
APP_FEATURES="Key-value store,Caching,Pub/Sub messaging"
DEFAULT_CONTAINER_NAME="redis-server"
DEFAULT_PORTS="6379:6379"
DEFAULT_VOLUMES="/data:/data"
APP_PORT="6379"
WEB_INTERFACE="false"
EOF

./generate-docker-appliance.sh redis.env
```

**More examples:** Check `tools/examples/` directory for additional configurations.

---

## 🎬 What Happens When You Run the Generator

When you run `./generate-docker-appliance.sh myapp.env`, the generator:

1. **Reads your .env file** - Loads all your configuration variables
2. **Validates** - Checks that required variables are set
3. **Creates directories** - Sets up the appliance directory structure
4. **Generates appliance.sh** - Creates the installation script with your Docker configuration
5. **Generates metadata files** - Creates YAML files with your app details
6. **Generates README** - Creates documentation with your app information
7. **Generates Packer files** - Creates VM build configuration
8. **Generates test files** - Creates automated tests
9. **Done!** - All 13+ files are ready

**Output example:**
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
✅ appliance.sh generated (simplified Phoenix RTOS/Node-RED structure)
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
```

---

## 📂 What Files Are Generated

The generator creates a complete appliance with this structure:

```
appliances/nginx/
├── metadata.yaml              # Build configuration
├── [uuid].yaml               # Appliance metadata (name, description, etc.)
├── README.md                 # User documentation
├── CHANGELOG.md              # Version history
├── appliance.sh              # Installation script (installs Docker, starts container)
├── tests.yaml                # Test configuration
├── context.yaml              # Test context variables
└── tests/
    └── 00-nginx_basic.rb     # Automated tests

apps-code/community-apps/packer/nginx/
├── nginx.pkr.hcl             # Main Packer build configuration
├── variables.pkr.hcl         # Build variables
├── common.pkr.hcl            # Common configuration (symlink)
├── 81-configure-ssh.sh       # SSH setup script
├── 82-configure-context.sh   # OpenNebula context setup
├── gen_context               # Context generator for testing
└── postprocess.sh            # Post-build processing
```

### Key Generated File: appliance.sh

The most important file is `appliance.sh` - it contains all the logic to:
- Install Docker
- Pull your Docker image
- Configure console access
- Start your container with the ports, volumes, and environment variables you specified

**The generated appliance.sh includes:**
- Your Docker image: `DOCKER_IMAGE="nginx:alpine"`
- Your ports: `DEFAULT_PORTS="80:80,443:443"`
- Your volumes: `DEFAULT_VOLUMES="/etc/nginx/conf.d:/etc/nginx/conf.d"`
- Your environment variables: `DEFAULT_ENV_VARS="..."`
- Container startup logic that uses these values

---

## ✅ You're Done! What's Next?

After running the generator, you have a complete appliance. Here are your options:

### Option 1: Just Use the Files (No Building Required)

If you just want to contribute the appliance definition to the marketplace:

1. **Review the generated files** - Make sure everything looks correct
2. **Add a logo** - Copy a PNG logo to `logos/nginx.png`
3. **Submit to marketplace** - Create a PR (see below)

### Option 2: Build the VM Image

If you want to build an actual VM image you can deploy:

**Prerequisites:**
```bash
# Install Packer and QEMU
sudo apt install -y qemu-kvm qemu-utils
wget https://releases.hashicorp.com/packer/1.9.4/packer_1.9.4_linux_amd64.zip
unzip packer_1.9.4_linux_amd64.zip
sudo mv packer /usr/local/bin/
```

**Build steps:**

```bash
# 1. Add to Makefile
cd apps-code/community-apps
# Edit Makefile.config and add 'nginx' to SERVICES list

# 2. Build base image (one-time, ~10 minutes)
cd ../one-apps
make context
make ubuntu2204

# 3. Build your appliance (~15-30 minutes)
cd ../community-apps
make nginx
```

**Output:** `apps-code/community-apps/export/nginx.qcow2`

You can now deploy this image to OpenNebula!

---

## 🧪 Testing Your Appliance

### Quick Test: Review Generated Files

```bash
# Check the main installation script
cat appliances/nginx/appliance.sh | grep DOCKER_IMAGE
cat appliances/nginx/appliance.sh | grep DEFAULT_PORTS

# Check the metadata
cat appliances/nginx/metadata.yaml

# Check the README
cat appliances/nginx/README.md
```

### Full Test: Deploy to OpenNebula

If you built the VM image, you can deploy and test it:

```bash
# 1. Copy image to OpenNebula
scp apps-code/community-apps/export/nginx.qcow2 root@opennebula:/var/tmp/

# 2. Create image in OpenNebula
ssh root@opennebula
oneimage create --name "nginx" --path "/var/tmp/nginx.qcow2" --datastore 1

# 3. Create and deploy VM
# (Use OpenNebula Sunstone UI or onetemplate commands)

# 4. Test the VM
ssh root@VM_IP  # Password: opennebula
docker ps       # Your container should be running
curl http://localhost:80  # Test your application
```

---

## 📤 Submitting to OpenNebula Marketplace

Want to share your appliance with the community?

```bash
# 1. Fork the repository on GitHub
# https://github.com/OpenNebula/marketplace-community

# 2. Clone your fork
git clone https://github.com/YOUR_USERNAME/marketplace-community.git
cd marketplace-community

# 3. Create a branch
git checkout -b feature/add-nginx-appliance

# 4. Add your files
git add appliances/nginx/
git add apps-code/community-apps/packer/nginx/
git add logos/nginx.png  # Don't forget the logo!

# 5. Commit and push
git commit -m "Add NGINX appliance"
git push origin feature/add-nginx-appliance

# 6. Create Pull Request on GitHub
```

---

## 🎓 Advanced: Customizing Generated Files

The generator creates working files, but you can customize them:

### Customize appliance.sh

Edit `appliances/nginx/appliance.sh` to add custom logic:

```bash
service_install() {
    # ... existing Docker installation code ...

    # Add your custom setup here
    apt-get install -y your-extra-package

    # Custom configuration
    echo "custom config" > /etc/myconfig
}
```

### Customize Metadata

Edit `appliances/nginx/metadata.yaml` to change:
- CPU/memory requirements
- Description and tags
- OpenNebula template settings

### Add More Tests

Edit `appliances/nginx/tests/00-nginx_basic.rb` to add more tests

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