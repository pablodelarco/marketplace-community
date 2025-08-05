#!/usr/bin/env bash

# Phoenix RTOS Docker-based Appliance Implementation
# This appliance provides a pre-configured Phoenix RTOS development environment
# with the Phoenix RTOS container pre-loaded for immediate use.

### Phoenix RTOS Configuration ###################################################

# Configuration variables
PHOENIX_CONTAINER_IMAGE="pablodelarco/phoenix-rtos-one:latest"
PHOENIX_WORK_DIR="/opt/phoenix-rtos"
PHOENIX_CONFIG_DIR="/etc/phoenix-rtos"
ONE_SERVICE_SETUP_DIR="/opt/one-appliance" ### Install location. Required by bash helpers

### CONTEXT SECTION ##########################################################

# List of contextualization parameters
# This is how you interact with the appliance using OpenNebula.
# These variables are defined in the CONTEXT section of the VM Template as custom variables
ONE_SERVICE_PARAMS=(
    'ONEAPP_PHOENIX_CONTAINER_NAME'     'configure'  'Phoenix RTOS container name'                    'O|text'
    'ONEAPP_PHOENIX_AUTO_START'         'configure'  'Auto-start container on boot'                   'O|boolean'
    'ONEAPP_PHOENIX_WORK_DIR'           'configure'  'Phoenix RTOS working directory'                 'O|text'
    'ONEAPP_PHOENIX_EXPOSE_PORTS'       'configure'  'Ports to expose (comma-separated)'              'O|text'
    'ONEAPP_PHOENIX_MEMORY_LIMIT'       'configure'  'Container memory limit (e.g., 1g)'              'O|text'
    'ONEAPP_PHOENIX_CPU_LIMIT'          'configure'  'Container CPU limit (e.g., 1.5)'                'O|text'
)

# Default values for when the variable doesn't exist on the VM Template
ONEAPP_PHOENIX_CONTAINER_NAME="${ONEAPP_PHOENIX_CONTAINER_NAME:-phoenix-rtos-dev}"
ONEAPP_PHOENIX_AUTO_START="${ONEAPP_PHOENIX_AUTO_START:-YES}"
ONEAPP_PHOENIX_WORK_DIR="${ONEAPP_PHOENIX_WORK_DIR:-/opt/phoenix-rtos}"
ONEAPP_PHOENIX_EXPOSE_PORTS="${ONEAPP_PHOENIX_EXPOSE_PORTS:-22,80,443}"
ONEAPP_PHOENIX_MEMORY_LIMIT="${ONEAPP_PHOENIX_MEMORY_LIMIT:-}"
ONEAPP_PHOENIX_CPU_LIMIT="${ONEAPP_PHOENIX_CPU_LIMIT:-}"

### Appliance metadata ###############################################

# Appliance metadata
ONE_SERVICE_NAME='Phoenix RTOS Development Environment - KVM'
ONE_SERVICE_BUILD=$(date +%s)
ONE_SERVICE_SHORT_DESCRIPTION='Phoenix RTOS development environment with pre-loaded Docker container'
ONE_SERVICE_RECONFIGURABLE=false

### APPLIANCE FUNCTIONS ##########################################################

#
# service_install
#
# This function is executed during the installation phase of the appliance.
# It's responsible for installing packages, setting up directories, and preparing
# the system for the Phoenix RTOS development environment.
#
service_install()
{
    msg info "Phoenix RTOS Development Environment Installation"

    # Create necessary directories
    mkdir -p "$ONE_SERVICE_SETUP_DIR"
    mkdir -p "$PHOENIX_WORK_DIR"
    mkdir -p "$PHOENIX_CONFIG_DIR"

    # Verify Docker installation (should be done by Packer)
    verify_docker_installation

    # Verify Phoenix RTOS container is available
    verify_phoenix_container

    # Install additional development tools
    install_development_tools

    # Create helper scripts
    create_helper_scripts

    msg info "INSTALLATION FINISHED"
    return 0
}

#
# service_configure
#
# This function is executed during the configuration phase of the appliance.
# It's responsible for configuring the Phoenix RTOS development environment
# based on the context variables provided by the user.
#
service_configure()
{
    msg info "Configuring Phoenix RTOS Development Environment"

    # Configure Docker daemon
    configure_docker_daemon

    # Create container configuration
    create_container_config

    # Set up systemd service for container management
    setup_container_service

    # Configure firewall if needed
    configure_firewall

    # Save configuration report
    create_service_report

    msg info "CONFIGURATION FINISHED"
    return 0
}

#
# service_bootstrap
#
# This function is executed during the bootstrap phase of the appliance.
# It's responsible for starting services and finalizing the setup.
#
service_bootstrap()
{
    msg info "Starting Phoenix RTOS Development Environment"

    # Start Docker service
    systemctl start docker
    systemctl enable docker

    # Start Phoenix RTOS container if auto-start is enabled
    if [ "${ONEAPP_PHOENIX_AUTO_START}" = "YES" ]; then
        start_phoenix_container
    fi

    # Enable container management service
    systemctl enable phoenix-rtos-container

    msg info "BOOTSTRAP FINISHED"
    return 0
}

### HELPER FUNCTIONS ##########################################################

#
# Helper functions for Phoenix RTOS appliance implementation
#

verify_docker_installation()
{
    msg info "Verifying Docker installation"
    
    if ! command -v docker >/dev/null 2>&1; then
        msg error "Docker is not installed. This should have been installed by Packer."
        exit 1
    fi
    
    if ! systemctl is-enabled docker >/dev/null 2>&1; then
        msg info "Enabling Docker service"
        systemctl enable docker
    fi
    
    if ! systemctl is-active docker >/dev/null 2>&1; then
        msg info "Starting Docker service"
        systemctl start docker
    fi
    
    # Wait for Docker to be ready
    local timeout=30
    local count=0
    while ! docker info >/dev/null 2>&1; do
        if [ $count -ge $timeout ]; then
            msg error "Docker failed to start within $timeout seconds"
            exit 1
        fi
        msg info "Waiting for Docker to start... ($count/$timeout)"
        sleep 1
        count=$((count + 1))
    done
    
    msg info "Docker is running and ready"
}

verify_phoenix_container()
{
    msg info "Verifying Phoenix RTOS container availability"
    
    if ! docker images --format "table {{.Repository}}:{{.Tag}}" | grep -q "$PHOENIX_CONTAINER_IMAGE"; then
        msg error "Phoenix RTOS container image not found: $PHOENIX_CONTAINER_IMAGE"
        msg error "This should have been pre-loaded by Packer during image creation"
        exit 1
    fi
    
    msg info "Phoenix RTOS container image is available: $PHOENIX_CONTAINER_IMAGE"
}

install_development_tools()
{
    msg info "Installing additional development tools"
    
    # Update package list
    apt-get update
    
    # Install useful development tools
    apt-get install -y \
        git \
        vim \
        nano \
        curl \
        wget \
        htop \
        tree \
        jq \
        unzip \
        build-essential \
        python3 \
        python3-pip \
        screen \
        tmux
    
    msg info "Development tools installed successfully"
}

create_helper_scripts()
{
    msg info "Creating Phoenix RTOS helper scripts"
    
    # Create main helper script
    cat > /usr/local/bin/phoenix-rtos <<'EOF'
#!/bin/bash
# Phoenix RTOS Helper Script

CONTAINER_NAME="phoenix-rtos-dev"
CONTAINER_IMAGE="pablodelarco/phoenix-rtos-one:latest"
WORK_DIR="/opt/phoenix-rtos"

case "$1" in
    start)
        echo "Starting Phoenix RTOS container..."
        systemctl start phoenix-rtos-container
        ;;
    stop)
        echo "Stopping Phoenix RTOS container..."
        systemctl stop phoenix-rtos-container
        ;;
    restart)
        echo "Restarting Phoenix RTOS container..."
        systemctl restart phoenix-rtos-container
        ;;
    status)
        echo "Phoenix RTOS container status:"
        systemctl status phoenix-rtos-container
        ;;
    shell)
        echo "Entering Phoenix RTOS container shell..."
        docker exec -it "$CONTAINER_NAME" /bin/bash
        ;;
    logs)
        echo "Phoenix RTOS container logs:"
        docker logs "$CONTAINER_NAME"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|shell|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the Phoenix RTOS container"
        echo "  stop    - Stop the Phoenix RTOS container"
        echo "  restart - Restart the Phoenix RTOS container"
        echo "  status  - Show container status"
        echo "  shell   - Enter container shell"
        echo "  logs    - Show container logs"
        exit 1
        ;;
esac
EOF
    
    chmod +x /usr/local/bin/phoenix-rtos
    
    msg info "Helper scripts created successfully"
}

configure_docker_daemon()
{
    msg info "Configuring Docker daemon"
    
    # Create Docker daemon configuration
    mkdir -p /etc/docker
    
    cat > /etc/docker/daemon.json <<EOF
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
    
    # Restart Docker to apply configuration
    systemctl restart docker
    
    msg info "Docker daemon configured successfully"
}

create_container_config()
{
    msg info "Creating Phoenix RTOS container configuration"
    
    # Create container configuration file
    cat > "$PHOENIX_CONFIG_DIR/container.conf" <<EOF
# Phoenix RTOS Container Configuration
CONTAINER_NAME=$ONEAPP_PHOENIX_CONTAINER_NAME
CONTAINER_IMAGE=$PHOENIX_CONTAINER_IMAGE
WORK_DIR=$ONEAPP_PHOENIX_WORK_DIR
EXPOSE_PORTS=$ONEAPP_PHOENIX_EXPOSE_PORTS
MEMORY_LIMIT=$ONEAPP_PHOENIX_MEMORY_LIMIT
CPU_LIMIT=$ONEAPP_PHOENIX_CPU_LIMIT
AUTO_START=$ONEAPP_PHOENIX_AUTO_START
EOF
    
    msg info "Container configuration created"
}

setup_container_service()
{
    msg info "Setting up Phoenix RTOS container systemd service"
    
    # Build port mapping arguments
    local port_args=""
    if [ -n "$ONEAPP_PHOENIX_EXPOSE_PORTS" ]; then
        IFS=',' read -ra PORTS <<< "$ONEAPP_PHOENIX_EXPOSE_PORTS"
        for port in "${PORTS[@]}"; do
            port=$(echo "$port" | tr -d ' ')
            if [ -n "$port" ]; then
                port_args="$port_args -p $port:$port"
            fi
        done
    fi
    
    # Build resource limit arguments
    local resource_args=""
    if [ -n "$ONEAPP_PHOENIX_MEMORY_LIMIT" ]; then
        resource_args="$resource_args --memory=$ONEAPP_PHOENIX_MEMORY_LIMIT"
    fi
    if [ -n "$ONEAPP_PHOENIX_CPU_LIMIT" ]; then
        resource_args="$resource_args --cpus=$ONEAPP_PHOENIX_CPU_LIMIT"
    fi
    
    # Create systemd service file
    cat > /etc/systemd/system/phoenix-rtos-container.service <<EOF
[Unit]
Description=Phoenix RTOS Development Container
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=-/usr/bin/docker stop $ONEAPP_PHOENIX_CONTAINER_NAME
ExecStartPre=-/usr/bin/docker rm $ONEAPP_PHOENIX_CONTAINER_NAME
ExecStart=/usr/bin/docker run -d \\
    --name $ONEAPP_PHOENIX_CONTAINER_NAME \\
    --hostname phoenix-rtos \\
    -v $ONEAPP_PHOENIX_WORK_DIR:/workspace \\
    $port_args \\
    $resource_args \\
    --restart unless-stopped \\
    $PHOENIX_CONTAINER_IMAGE
ExecStop=/usr/bin/docker stop $ONEAPP_PHOENIX_CONTAINER_NAME
ExecStopPost=/usr/bin/docker rm $ONEAPP_PHOENIX_CONTAINER_NAME

[Install]
WantedBy=multi-user.target
EOF
    
    # Reload systemd
    systemctl daemon-reload
    
    msg info "Phoenix RTOS container service created"
}

configure_firewall()
{
    msg info "Configuring firewall for Phoenix RTOS"
    
    # Configure UFW if available
    if command -v ufw >/dev/null 2>&1; then
        # Allow SSH
        ufw allow ssh
        
        # Allow configured ports
        if [ -n "$ONEAPP_PHOENIX_EXPOSE_PORTS" ]; then
            IFS=',' read -ra PORTS <<< "$ONEAPP_PHOENIX_EXPOSE_PORTS"
            for port in "${PORTS[@]}"; do
                port=$(echo "$port" | tr -d ' ')
                if [ -n "$port" ] && [ "$port" != "22" ]; then
                    ufw allow "$port"
                fi
            done
        fi
        
        msg info "Firewall configured for Phoenix RTOS"
    fi
}

start_phoenix_container()
{
    msg info "Starting Phoenix RTOS container"
    
    if systemctl start phoenix-rtos-container; then
        msg info "Phoenix RTOS container started successfully"
        
        # Wait for container to be ready
        local timeout=30
        local count=0
        while ! docker exec "$ONEAPP_PHOENIX_CONTAINER_NAME" echo "Container ready" >/dev/null 2>&1; do
            if [ $count -ge $timeout ]; then
                msg warning "Container may not be fully ready after $timeout seconds"
                break
            fi
            sleep 1
            count=$((count + 1))
        done
        
        msg info "Phoenix RTOS container is ready"
    else
        msg error "Failed to start Phoenix RTOS container"
        exit 1
    fi
}

create_service_report()
{
    msg info "Creating service configuration report"
    
    cat > "$ONE_SERVICE_REPORT" <<EOF
[Phoenix RTOS Development Environment]
Container Name: $ONEAPP_PHOENIX_CONTAINER_NAME
Container Image: $PHOENIX_CONTAINER_IMAGE
Working Directory: $ONEAPP_PHOENIX_WORK_DIR
Auto Start: $ONEAPP_PHOENIX_AUTO_START

[Exposed Ports]
Ports: $ONEAPP_PHOENIX_EXPOSE_PORTS

[Resource Limits]
Memory Limit: ${ONEAPP_PHOENIX_MEMORY_LIMIT:-unlimited}
CPU Limit: ${ONEAPP_PHOENIX_CPU_LIMIT:-unlimited}

[Helper Commands]
Start container: phoenix-rtos start
Stop container: phoenix-rtos stop
Container shell: phoenix-rtos shell
Container logs: phoenix-rtos logs
Container status: phoenix-rtos status

[Docker Commands]
List containers: docker ps -a
Container logs: docker logs $ONEAPP_PHOENIX_CONTAINER_NAME
Enter container: docker exec -it $ONEAPP_PHOENIX_CONTAINER_NAME /bin/bash
EOF
    
    chmod 600 "$ONE_SERVICE_REPORT"
    
    msg info "Service report created: $ONE_SERVICE_REPORT"
}
