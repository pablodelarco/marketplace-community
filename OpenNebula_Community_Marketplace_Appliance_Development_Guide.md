# OpenNebula Community Marketplace Appliance Development Guide

**Version 2.0**  
**Date: January 2025**

This comprehensive guide explains how to create, develop, and add custom appliances to the OpenNebula Community Marketplace. It provides step-by-step instructions for both bash and Ruby-based implementations.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Repository Structure Overview](#repository-structure-overview)
3. [Getting Started](#getting-started)
4. [Creating Your First Appliance](#creating-your-first-appliance)
5. [Implementation Approaches](#implementation-approaches)
6. [Building and Testing](#building-and-testing)
7. [Marketplace Integration](#marketplace-integration)
8. [Testing Framework](#testing-framework)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting appliance development, ensure you have:

- **OpenNebula Environment**: A working OpenNebula installation (version 6.10+ recommended)
- **Development Tools**: 
  - Git
  - Packer (for image building)
  - Docker (optional, for containerized builds)
  - Ruby (for testing framework)
  - Make and build tools
- **System Requirements**:
  - Linux development environment
  - At least 8GB RAM for building images
  - 20GB+ free disk space
- **Access**: Fork access to the `marketplace-community` repository

## Repository Structure Overview

The marketplace-community repository follows this structure:

```
marketplace-community/
├── appliances/           # Appliance definitions and logic
│   ├── example/         # Template appliance (use as base)
│   ├── your-app/        # Your appliance directory
│   └── ...
├── apps-code/           # Build system and Packer configurations
│   └── community-apps/
│       ├── Makefile.config  # Build configuration
│       └── packer/          # Packer build scripts
├── lib/                 # Shared libraries and helpers
│   ├── helpers.rb       # Ruby helper functions
│   ├── common.sh        # Bash helper functions
│   └── community/       # Testing framework
├── logos/               # Application logos
└── README.md
```

## Getting Started

### Step 1: Fork and Clone the Repository

```bash
# Fork the repository on GitHub first, then clone your fork
git clone https://github.com/YOUR-USERNAME/marketplace-community.git
cd marketplace-community

# Add upstream remote for updates
git remote add upstream https://github.com/OpenNebula/marketplace-community.git
```

### Step 2: Set Up Development Environment

```bash
# Install required packages (Ubuntu/Debian)
sudo apt update
sudo apt install -y build-essential git wget curl uuid-runtime \
    packer qemu-kvm libvirt-daemon-system ruby ruby-dev

# Install Ruby gems for testing
gem install rspec yaml
```

### Step 3: Understand the Example Appliance

Study the example appliance to understand the structure:

```bash
# Examine the example appliance structure
ls -la appliances/example/
cat appliances/example/UUID.yaml
cat appliances/example/appliance.sh
```

## Creating Your First Appliance

### Step 1: Create Appliance Directory Structure

```bash
# Generate a unique UUID for your appliance
NEW_UUID=$(uuidgen)
echo "Generated UUID: $NEW_UUID"

# Create appliance directory (replace 'myapp' with your application name)
cp -r appliances/example appliances/myapp

# Rename the UUID file
cd appliances/myapp
mv UUID.yaml ${NEW_UUID}.yaml
```

### Step 2: Create Packer Build Configuration

```bash
# Copy packer configuration
cp -r apps-code/community-apps/packer/example apps-code/community-apps/packer/myapp

# Rename the main packer file
cd apps-code/community-apps/packer/myapp
mv example.pkr.hcl myapp.pkr.hcl

# Update references in the packer files
sed -i 's/example/myapp/g' myapp.pkr.hcl
sed -i 's/example/myapp/g' variables.pkr.hcl
```

### Step 3: Add to Build System

```bash
# Edit the Makefile configuration to include your appliance
cd apps-code/community-apps
# Add 'myapp' to the SERVICES line in Makefile.config
```

### Step 4: Add Application Logo

```bash
# Add your application logo to the logos directory
cp /path/to/your/logo.png logos/myapp.png
```

## Implementation Approaches

You can implement your appliance logic using either **Bash** (traditional) or **Ruby** (modern) approaches.

### Approach 1: Bash Implementation (Traditional)

This is the most common approach used in existing appliances.

**File Structure:**
```
appliances/myapp/
├── UUID.yaml           # Appliance metadata
├── appliance.sh        # Main implementation logic
├── tests.yaml          # Test configuration
└── tests/              # Test files
    └── 00-myapp_basic.rb
```

**Key Components:**

1. **appliance.sh**: Contains the main logic with required functions:
   - `service_install()`: Install packages and dependencies
   - `service_configure()`: Configure the application
   - `service_bootstrap()`: Start services and final setup
   - `service_cleanup()`: Cleanup on failure (optional)

2. **Context Variables**: Define user-configurable parameters:
```bash
ONE_SERVICE_PARAMS=(
    'ONEAPP_MYAPP_PARAM1'    'configure'  'Description'  'default_value'
    'ONEAPP_MYAPP_PARAM2'    'configure'  'Description'  'default_value'
)
```

### Approach 2: Ruby Implementation (Modern)

This approach uses Ruby for more structured and maintainable code.

**File Structure:**
```
appliances/myapp/
├── UUID.yaml           # Appliance metadata  
├── main.rb             # Main implementation logic
├── config.rb           # Configuration and parameters
├── tests.yaml          # Test configuration
└── tests/              # Test files
    └── 00-myapp_basic.rb
```

**Key Components:**

1. **config.rb**: Define configuration parameters and constants
2. **main.rb**: Implement the Service module with required methods
3. **Modified Packer Configuration**: Updated to use Ruby service framework

## Building and Testing

### Building Your Appliance

```bash
# From the apps-code/community-apps directory
cd apps-code/community-apps

# Build your specific appliance
sudo make myapp

# The resulting image will be in export/myapp.qcow2
```

### Local Testing with OpenNebula

```bash
# Copy the built image to OpenNebula frontend
sudo cp export/myapp.qcow2 /var/tmp/

# Create OpenNebula image
oneimage create -d <datastore_id> --name "MyApp" --type OS \
    --prefix vd --format qcow2 --path /var/tmp/myapp.qcow2

# Verify image creation
oneimage list
```

### Running Automated Tests

```bash
# From the lib/community directory
cd lib/community

# Run tests for your appliance
./app_readiness.rb myapp
```

## Marketplace Integration

### Step 1: Configure Appliance Metadata

Edit your `UUID.yaml` file with proper metadata:

```yaml
---
name: MyApp
version: 1.0.0
one-apps_version: 7.0.0-0
publisher: Your Organization
publisher_email: your-email@domain.com
description: |-
  Detailed description of your appliance.
  
  Features:
  - Feature 1
  - Feature 2
  
short_description: Brief description for marketplace listing
tags:
- myapp
- ubuntu
- service
format: qcow2
creation_time: 1704067200  # Use: date +%s
os-id: Ubuntu
os-release: 24.04 LTS
os-arch: x86_64
hypervisor: KVM
opennebula_version: 6.10, 7.0
opennebula_template:
  context:
    network: 'YES'
    oneapp_myapp_param1: "$ONEAPP_MYAPP_PARAM1"
    oneapp_myapp_param2: "$ONEAPP_MYAPP_PARAM2"
    ssh_public_key: "$USER[SSH_PUBLIC_KEY]"
  cpu: '1'
  graphics:
    listen: 0.0.0.0
    type: vnc
  inputs_order: >-
    ONEAPP_MYAPP_PARAM1, ONEAPP_MYAPP_PARAM2
  memory: '1024'
  os:
    arch: x86_64
  user_inputs:
    oneapp_myapp_param1: M|text|Parameter 1 description| |default_value
    oneapp_myapp_param2: O|password|Parameter 2 description| |
logo: myapp.png
images:
- name: myapp
  url: >-
    https://marketplace.opennebula.io/appliance/myapp.qcow2
  type: OS
  dev_prefix: vd
  driver: qcow2
  size: 5242880000
  checksum:
    md5: your_md5_checksum
    sha256: your_sha256_checksum
```

### Step 2: User Input Configuration

Configure user inputs for the Sunstone interface:

- **M|type|description|validation|default**: Mandatory field
- **O|type|description|validation|default**: Optional field

**Supported types:**
- `text`: Text input
- `password`: Password input (hidden)
- `number`: Numeric input
- `boolean`: Checkbox
- `list`: Dropdown list

## Testing Framework

### Creating Test Files

Create comprehensive tests in `appliances/myapp/tests/00-myapp_basic.rb`:

```ruby
require_relative '../../../lib/community/app_handler'

describe 'MyApp Appliance Certification' do
    include_context('vm_handler')

    it 'myapp is installed' do
        cmd = 'which myapp'
        @info[:vm].ssh(cmd).expect_success
    end

    it 'myapp service is running' do
        cmd = 'systemctl is-active myapp'
        start_time = Time.now
        timeout = 60

        loop do
            result = @info[:vm].ssh(cmd)
            break if result.success?

            if Time.now - start_time > timeout
                raise "MyApp service did not become active within #{timeout} seconds"
            end

            sleep 1
        end
    end

    it 'checks oneapps motd' do
        cmd = 'cat /etc/motd'
        timeout_seconds = 60
        retry_interval_seconds = 5

        begin
            Timeout.timeout(timeout_seconds) do
                loop do
                    execution = @info[:vm].ssh(cmd)

                    if execution.exitstatus == 0 && execution.stdout.include?('All set and ready to serve')
                        expect(execution.exitstatus).to eq(0)
                        expect(execution.stdout).to include('All set and ready to serve')
                        break
                    else
                        sleep(retry_interval_seconds)
                    end
                end
            end
        rescue Timeout::Error
            fail "Timeout after #{timeout_seconds} seconds: MOTD did not contain 'All set and ready to serve'"
        end
    end
end
```

### Test Configuration

Create `appliances/myapp/tests.yaml`:

```yaml
---
- '00-myapp_basic.rb'
```

## Best Practices

### Security
- Never hardcode passwords or sensitive data
- Use OpenNebula context variables for configuration
- Implement proper input validation
- Follow principle of least privilege

### Performance
- Minimize image size by cleaning up after installation
- Use efficient package managers
- Implement proper service dependencies
- Optimize startup time

### Maintainability
- Use clear, descriptive variable names
- Add comprehensive comments
- Implement proper error handling
- Follow consistent coding style

### Documentation
- Provide clear descriptions in metadata
- Document all configuration parameters
- Include usage examples
- Maintain changelog

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Packer logs: `PACKER_LOG=1 make myapp`
   - Verify base image availability
   - Check disk space and permissions

2. **Service Not Starting**
   - Check systemd logs: `journalctl -u myapp`
   - Verify service file syntax
   - Check dependencies and prerequisites

3. **Context Variables Not Working**
   - Verify variable names match exactly
   - Check context script execution
   - Validate YAML syntax in template

4. **Test Failures**
   - Check VM network connectivity
   - Verify SSH access
   - Review test timeout values
   - Check service startup time

### Debug Mode

Enable debug mode for detailed logging:

```bash
# Set debug environment variables
export PACKER_LOG=1
export VERBOSE=1

# Build with debug output
make myapp
```

### Getting Help

- **Documentation**: [OpenNebula Documentation](https://docs.opennebula.io/)
- **Community**: [OpenNebula Forum](https://forum.opennebula.io/)
- **Issues**: [GitHub Issues](https://github.com/OpenNebula/one/issues)
- **Examples**: Study existing appliances in the repository

## Detailed Implementation Examples

### Example 1: Bash Implementation (Database Service)

Here's a complete example of a MariaDB appliance using bash:

**appliances/mariadb/appliance.sh:**
```bash
#!/usr/bin/env bash

# MariaDB Service Appliance Implementation

### Configuration Variables ###
MARIADB_CREDENTIALS=/root/.my.cnf
MARIADB_CONFIG=/etc/my.cnf.d/mariadb.cnf
PASSWORD_LENGTH=16
ONE_SERVICE_SETUP_DIR="/opt/one-appliance"

### Context Parameters ###
ONE_SERVICE_PARAMS=(
    'ONEAPP_DB_NAME'            'configure' 'Database name'                     'mariadb'
    'ONEAPP_DB_USER'            'configure' 'Database service user'             'mariadb'
    'ONEAPP_DB_PASSWORD'        'configure' 'Database service password'         ''
    'ONEAPP_DB_ROOT_PASSWORD'   'configure' 'Database password for root'        ''
)

# Set defaults
ONEAPP_DB_NAME="${ONEAPP_DB_NAME:-mariadb}"
ONEAPP_DB_USER="${ONEAPP_DB_USER:-mariadb}"
ONEAPP_DB_PASSWORD="${ONEAPP_DB_PASSWORD:-$(gen_password ${PASSWORD_LENGTH})}"
ONEAPP_DB_ROOT_PASSWORD="${ONEAPP_DB_ROOT_PASSWORD:-$(gen_password ${PASSWORD_LENGTH})}"

### Required Functions ###

service_install() {
    msg info "Installing MariaDB packages"

    # Update package manager
    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        apt-get install -y mariadb-server mariadb-client expect
    elif command -v yum >/dev/null 2>&1; then
        yum install -y mariadb mariadb-server expect
    else
        msg error "Unsupported package manager"
        exit 1
    fi

    msg info "INSTALLATION FINISHED"
    return 0
}

service_configure() {
    msg info "Configuring MariaDB"

    # Stop service for configuration
    systemctl stop mariadb

    # Configure MariaDB
    setup_mariadb

    # Save credentials
    cat > "$ONE_SERVICE_REPORT" <<EOF
[DB connection info]
host     = localhost
database = ${ONEAPP_DB_NAME}

[DB root credentials]
username = root
password = ${ONEAPP_DB_ROOT_PASSWORD}

[DB user credentials]
username = ${ONEAPP_DB_USER}
password = ${ONEAPP_DB_PASSWORD}
EOF

    chmod 600 "$ONE_SERVICE_REPORT"

    # Enable service
    systemctl enable mariadb

    msg info "CONFIGURATION FINISHED"
    return 0
}

service_bootstrap() {
    msg info "Starting MariaDB service"
    systemctl start mariadb

    msg info "BOOTSTRAP FINISHED"
    return 0
}

service_cleanup() {
    msg info "Cleaning up MariaDB installation"
    systemctl stop mariadb || true
    return 0
}

### Helper Functions ###

setup_mariadb() {
    msg info "Setting up MariaDB database"

    # Start MariaDB
    systemctl start mariadb

    # Secure installation
    mysql_secure_installation_automated

    # Create database and user
    mysql -u root -p"${ONEAPP_DB_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS ${ONEAPP_DB_NAME};
GRANT ALL PRIVILEGES ON ${ONEAPP_DB_NAME}.* TO '${ONEAPP_DB_USER}'@'localhost' IDENTIFIED BY '${ONEAPP_DB_PASSWORD}';
FLUSH PRIVILEGES;
EOF
}

mysql_secure_installation_automated() {
    msg info "Running automated MySQL secure installation"

    expect -f - <<EOF
set timeout 10
spawn mysql_secure_installation

expect "Enter current password for root (enter for none):"
send "\r"

expect "Set root password?"
send "Y\r"

expect "New password:"
send "${ONEAPP_DB_ROOT_PASSWORD}\r"

expect "Re-enter new password:"
send "${ONEAPP_DB_ROOT_PASSWORD}\r"

expect "Remove anonymous users?"
send "Y\r"

expect "Disallow root login remotely?"
send "Y\r"

expect "Remove test database and access to it?"
send "Y\r"

expect "Reload privilege tables now?"
send "Y\r"

expect eof
EOF
}
```

### Example 2: Ruby Implementation (Web Service)

Here's a complete example using Ruby for a Nginx web service:

**appliances/nginx/config.rb:**
```ruby
# frozen_string_literal: true

begin
   require '/etc/one-appliance/lib/helpers'
rescue LoadError
   require_relative '../lib/helpers'
end

# Configuration file paths
NGINX_CONF = "/etc/nginx/nginx.conf"
NGINX_SITE_CONF = "/etc/nginx/sites-available/default"

# Internal variables (not exposed to user)
ONEAPP_NGINX_VERSION = env :ONEAPP_NGINX_VERSION, '1.18'

# User-configurable parameters
ONEAPP_NGINX_PORT = env :ONEAPP_NGINX_PORT, '80'
ONEAPP_NGINX_SERVER_NAME = env :ONEAPP_NGINX_SERVER_NAME, 'localhost'
ONEAPP_NGINX_DOCUMENT_ROOT = env :ONEAPP_NGINX_DOCUMENT_ROOT, '/var/www/html'
ONEAPP_NGINX_SSL_ENABLED = env :ONEAPP_NGINX_SSL_ENABLED, 'NO'
ONEAPP_NGINX_SSL_CERT = env :ONEAPP_NGINX_SSL_CERT, ''
ONEAPP_NGINX_SSL_KEY = env :ONEAPP_NGINX_SSL_KEY, ''
```

**appliances/nginx/main.rb:**
```ruby
# frozen_string_literal: true

begin
   require '/etc/one-appliance/lib/helpers'
rescue LoadError
   require_relative '../lib/helpers'
end

require_relative 'config'

# Base module for OpenNebula services
module Service
    # Nginx appliance implementation
    module Nginx
        extend self

        DEPENDS_ON = []

        def install
            msg :info, 'Nginx::install'
            install_nginx
            msg :info, 'Installation completed successfully'
        end

        def configure
            msg :info, 'Nginx::configure'
            configure_nginx
            setup_ssl if ONEAPP_NGINX_SSL_ENABLED.upcase == 'YES'
            msg :info, 'Configuration completed successfully'
        end

        def bootstrap
            msg :info, 'Nginx::bootstrap'
            start_nginx
            msg :info, 'Bootstrap completed successfully'
        end

        private

        def install_nginx
            msg :info, 'Installing Nginx packages'
            puts bash <<~SCRIPT
                apt-get update
                apt-get install -y nginx
            SCRIPT
        end

        def configure_nginx
            msg :info, 'Configuring Nginx'

            # Create document root
            puts bash "mkdir -p #{ONEAPP_NGINX_DOCUMENT_ROOT}"

            # Configure main site
            site_config = generate_site_config
            File.write(NGINX_SITE_CONF, site_config)

            # Create a simple index page
            create_index_page
        end

        def generate_site_config
            config = <<~CONFIG
                server {
                    listen #{ONEAPP_NGINX_PORT};
                    server_name #{ONEAPP_NGINX_SERVER_NAME};
                    root #{ONEAPP_NGINX_DOCUMENT_ROOT};
                    index index.html index.htm;

                    location / {
                        try_files $uri $uri/ =404;
                    }
            CONFIG

            if ONEAPP_NGINX_SSL_ENABLED.upcase == 'YES'
                config += <<~SSL_CONFIG

                    listen 443 ssl;
                    ssl_certificate #{ONEAPP_NGINX_SSL_CERT};
                    ssl_certificate_key #{ONEAPP_NGINX_SSL_KEY};
                SSL_CONFIG
            end

            config += "\n}\n"
            config
        end

        def create_index_page
            index_content = <<~HTML
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Welcome to Nginx</title>
                </head>
                <body>
                    <h1>Welcome to Nginx on OpenNebula!</h1>
                    <p>This server is running on #{ONEAPP_NGINX_SERVER_NAME}</p>
                    <p>Document root: #{ONEAPP_NGINX_DOCUMENT_ROOT}</p>
                </body>
                </html>
            HTML

            File.write("#{ONEAPP_NGINX_DOCUMENT_ROOT}/index.html", index_content)
        end

        def setup_ssl
            msg :info, 'Setting up SSL configuration'

            unless File.exist?(ONEAPP_NGINX_SSL_CERT) && File.exist?(ONEAPP_NGINX_SSL_KEY)
                msg :warn, 'SSL certificates not found, generating self-signed certificates'
                generate_self_signed_cert
            end
        end

        def generate_self_signed_cert
            puts bash <<~SCRIPT
                openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                    -keyout #{ONEAPP_NGINX_SSL_KEY} \
                    -out #{ONEAPP_NGINX_SSL_CERT} \
                    -subj "/C=US/ST=State/L=City/O=Organization/CN=#{ONEAPP_NGINX_SERVER_NAME}"
            SCRIPT
        end

        def start_nginx
            msg :info, 'Starting and enabling Nginx'
            puts bash <<~SCRIPT
                systemctl restart nginx
                systemctl enable nginx
            SCRIPT
        end
    end
end
```

### Packer Configuration for Ruby Implementation

When using Ruby, you need to modify the Packer configuration:

**apps-code/community-apps/packer/nginx/nginx.pkr.hcl:**
```hcl
# Replace the bash-specific provisioners with Ruby ones:

provisioner "file" {
  sources = ["../../lib/helpers.rb"]
  destination = "/etc/one-appliance/lib/"
}

# Contains the appliance service management tool (Ruby version)
provisioner "file" {
  source = "../one-apps/appliances/service.rb"
  destination = "/etc/one-appliance/service"
}

# Pull your Ruby appliance logic
provisioner "file" {
  sources = ["../../appliances/nginx"]
  destination = "/etc/one-appliance/service.d/"
}
```

## Advanced Topics

### Multi-Service Appliances

For complex appliances that require multiple services:

```bash
# In your appliance.sh, define service dependencies
service_install() {
    install_database
    install_webserver
    install_application
}

service_configure() {
    configure_database
    configure_webserver
    configure_application
}

service_bootstrap() {
    start_database
    start_webserver
    start_application
}
```

### Reconfigurable Appliances

Enable runtime reconfiguration:

```bash
# Add to your appliance metadata
ONE_SERVICE_RECONFIGURABLE=true

# Implement reconfiguration logic
service_reconfigure() {
    msg info "Reconfiguring service with new parameters"

    # Stop services
    systemctl stop myapp

    # Apply new configuration
    update_configuration

    # Restart services
    systemctl start myapp
}
```

### Container-Based Appliances

For containerized applications, you can pre-load Docker images during the Packer build process and manage them through your appliance logic.

#### Example: Docker-Based Appliance Structure

**Packer Configuration (apps-code/community-apps/packer/myapp/myapp.pkr.hcl):**
```hcl
# Install Docker and pre-pull container images
provisioner "shell" {
  inline = [
    # Install Docker
    "apt-get update -y",
    "apt-get install -y ca-certificates curl gnupg",
    "install -d -m0755 /etc/apt/keyrings",
    "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
    "chmod a+r /etc/apt/keyrings/docker.gpg",
    "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable\" | tee /etc/apt/sources.list.d/docker.list",
    "apt-get update -y",
    "DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io",
    "systemctl enable --now docker",

    # Pre-pull your container image
    "docker pull myapp:latest"
  ]
}
```

**Appliance Logic (appliances/myapp/appliance.sh):**
```bash
service_install() {
    # Verify Docker installation
    verify_docker_installation

    # Verify container image is available
    verify_container_image

    # Install additional tools
    install_development_tools
}

service_configure() {
    # Configure Docker daemon
    configure_docker_daemon

    # Create container configuration
    create_container_config

    # Set up systemd service for container management
    setup_container_service
}

service_bootstrap() {
    # Start Docker service
    systemctl start docker

    # Start application container
    start_application_container
}

verify_docker_installation() {
    if ! command -v docker >/dev/null 2>&1; then
        msg error "Docker is not installed"
        exit 1
    fi

    if ! systemctl is-active docker >/dev/null 2>&1; then
        systemctl start docker
    fi
}

verify_container_image() {
    if ! docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "myapp:latest"; then
        msg error "Container image not found: myapp:latest"
        exit 1
    fi
}

setup_container_service() {
    cat > /etc/systemd/system/myapp-container.service <<EOF
[Unit]
Description=MyApp Container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/bin/docker stop myapp
ExecStartPre=-/usr/bin/docker rm myapp
ExecStart=/usr/bin/docker run -d \\
    --name myapp \\
    -p 80:80 \\
    --restart unless-stopped \\
    myapp:latest
ExecStop=/usr/bin/docker stop myapp

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable myapp-container
}

start_application_container() {
    systemctl start myapp-container
}
```

#### Benefits of Pre-loading Containers

1. **Fast Startup**: No need to download images on first boot
2. **Offline Operation**: Works without internet connectivity
3. **Consistent Deployment**: Same image version across all instances
4. **Reduced Network Usage**: Images downloaded once during build

### Example 3: Complete Docker-Based Appliance (Phoenix RTOS)

Here's a complete example of a Docker-based appliance that pre-loads a Phoenix RTOS development environment:

**Directory Structure:**
```
appliances/phoenixrtos/
├── 4971b27e-4844-49fd-a3b3-5ba8b99ba57c.yaml  # Appliance metadata
├── appliance.sh                                # Main logic
├── metadata.yaml                               # Testing metadata
├── tests.yaml                                  # Test configuration
├── tests/
│   └── 00-phoenixrtos_basic.rb                # Test file
└── README.md                                   # Documentation

apps-code/community-apps/packer/phoenixrtos/
├── phoenixrtos.pkr.hcl                        # Main Packer config
├── variables.pkr.hcl                          # Variables
├── common.pkr.hcl                             # Common config
└── cloud-init.yml                             # Cloud-init config
```

**Key Features:**
- Pre-loads `pablodelarco/phoenix-rtos-one:latest` container
- Provides helper script for container management
- Configurable through OpenNebula context variables
- Systemd service for container lifecycle management
- Development tools pre-installed

**Context Variables:**
- `ONEAPP_PHOENIX_CONTAINER_NAME`: Container name
- `ONEAPP_PHOENIX_AUTO_START`: Auto-start on boot
- `ONEAPP_PHOENIX_WORK_DIR`: Working directory
- `ONEAPP_PHOENIX_EXPOSE_PORTS`: Ports to expose
- `ONEAPP_PHOENIX_MEMORY_LIMIT`: Memory limit
- `ONEAPP_PHOENIX_CPU_LIMIT`: CPU limit

**Helper Script Usage:**
```bash
phoenix-rtos start    # Start container
phoenix-rtos stop     # Stop container
phoenix-rtos shell    # Enter container
phoenix-rtos logs     # View logs
phoenix-rtos status   # Check status
```

This example demonstrates how to create a production-ready Docker-based appliance with proper configuration management, testing, and user-friendly interfaces.

### High Availability Setup

For HA appliances:

```bash
# Define cluster parameters
ONE_SERVICE_PARAMS=(
    'ONEAPP_CLUSTER_ENABLED'    'configure' 'Enable cluster mode'           'NO'
    'ONEAPP_CLUSTER_NODES'      'configure' 'Cluster node IPs'              ''
    'ONEAPP_CLUSTER_VIP'        'configure' 'Virtual IP for cluster'        ''
)

service_configure() {
    if [ "${ONEAPP_CLUSTER_ENABLED}" = "YES" ]; then
        setup_cluster_configuration
    else
        setup_standalone_configuration
    fi
}
```

---

This comprehensive guide provides everything needed to develop professional OpenNebula Community Marketplace appliances. For additional examples and advanced patterns, study the existing appliances in the repository and adapt them to your specific requirements.
