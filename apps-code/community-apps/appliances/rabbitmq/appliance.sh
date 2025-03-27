#!/usr/bin/env bash

# This script contains an example implementation logic for your appliances.
# For this example the goal will be to have a "database as a service" appliance

### RabbitMQ ##########################################################

# For organization purposes is good to define here variables that will be used by your bash logic
RABBITMQ_CONFIG_FILE=/etc/rabbitmq/rabbitmq.conf
RABBITMQ_ADVANCED_CONFIG_FILE=/etc/rabbitmq/advanced.config
PASSWORD_LENGTH=16
ONE_SERVICE_SETUP_DIR="/opt/one-appliance" ### Install location. Required by bash helpers

### CONTEXT SECTION ##########################################################

# List of contextualization parameters
# This is how you interact with the appliance using OpenNebula.
# These variables are defined in the CONTEXT section of the VM Template as custom variables
# https://docs.opennebula.io/6.8/management_and_operations/references/template.html#context-section
ONE_SERVICE_PARAMS=(
    'ONEAPP_RABBITMQ_DEFAULT_USER'     'configure' 'User to create when RabbitMQ creates a new database'               ''
    'ONEAPP_RABBITMQ_DEFAULT_PASS'     'configure' 'Password for the default user'               ''
    'ONEAPP_RABBITMQ_LOG_LEVEL'        'configure' 'Controls the granularity of logging'               ''
)
# Default values for when the variable doesn't exist on the VM Template
ONEAPP_RABBITMQ_DEFAULT_USER="${ONEAPP_RABBITMQ_DEFAULT_USER:-guest}"
ONEAPP_RABBITMQ_DEFAULT_PASS="${ONEAPP_RABBITMQ_DEFAULT_PASS:-$(gen_password ${PASSWORD_LENGTH})}"
ONEAPP_RABBITMQ_LOG_LEVEL="${ONEAPP_RABBITMQ_LOG_LEVEL:-info}"

# You can make this parameters a required step of the VM instantiation wizard by using the USER_INPUTS feature
# https://docs.opennebula.io/6.8/management_and_operations/vm_management/vm_templates.html?#user-inputs

###############################################################################
###############################################################################
###############################################################################

# The following functions will be called by the appliance service manager at
# the  different stages of the appliance life cycles. They must exist
# https://github.com/OpenNebula/one-apps/wiki/apps_intro#appliance-life-cycle

#
# Mandatory Functions
#

service_install()
{
    echo "Updating package list"
    sudo apt-get update -y || { echo "Failed to update package list"; exit 1; }

    echo "Installing dependencies"
    sudo apt-get install -y curl gnupg apt-transport-https || { echo "Failed to install dependencies"; exit 1; }

    echo "Adding RabbitMQ and Erlang signing keys"
    curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" | sudo gpg --dearmor | sudo tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null
    curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg > /dev/null
    curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key | sudo gpg --dearmor | sudo tee /usr/share/keyrings/rabbitmq.9F4587F226208342.gpg > /dev/null

    echo "Adding RabbitMQ and Erlang repositories"
    sudo tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Provides modern Erlang/OTP releases
##
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main

deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main

## Provides RabbitMQ
##
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main

deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
EOF

    echo "Updating package list again"
    sudo apt-get update -y || { echo "Failed to update package list after adding repositories"; exit 1; }

    echo "Installing Erlang packages"
    sudo apt-get install -y erlang-base \
                        erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
                        erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
                        erlang-runtime-tools erlang-snmp erlang-ssl \
                        erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl || { echo "Failed to install Erlang packages"; exit 1; }

    echo "Installing RabbitMQ server"
    sudo apt-get install rabbitmq-server -y --fix-missing || { echo "Failed to install RabbitMQ server"; exit 1; }

    echo "Enabling and starting RabbitMQ service"
    sudo systemctl enable rabbitmq-server
    sudo systemctl start rabbitmq-server || { echo "Failed to start RabbitMQ service"; exit 1; }

    # cleanup
    postinstall_cleanup

    echo "INSTALLATION FINISHED"
    return 0
}

service_configure()
{
    msg info "Stopping services"
    systemctl stop rabbitmq-server

    setup_rabbitmq

    msg info "Credentials and config values are saved in: ${ONE_SERVICE_REPORT}"

    cat > "$ONE_SERVICE_REPORT" <<EOF
[RabbitMQ user credentials]
username = ${ONEAPP_RABBITMQ_DEFAULT_USER}
password = ${ONEAPP_RABBITMQ_DEFAULT_PASS}
EOF

    chmod 600 "$ONE_SERVICE_REPORT"

    msg info "Enable services"
    systemctl enable rabbitmq-server

    msg info "CONFIGURATION FINISHED"

    return 0
}

service_bootstrap()
{
    msg info "BOOTSTRAP FINISHED"

    return 0
}


# This one is not really mandatory, however it is a handled function
service_cleanup()
{
    :
}


###############################################################################
###############################################################################
###############################################################################

# Then for modularity purposes you can define your own functions as long as their name
# doesn't clash with the previous functions

#
# functions
#

setup_rabbitmq()
{

sudo tee /etc/rabbitmq/rabbitmq-env.conf > /dev/null <<EOL

## Set log file locations
NODENAME=rabbit@$(hostname -f)
RABBITMQ_CONFIG_FILE="$RABBITMQ_CONFIG_FILE"
RABBITMQ_ADVANCED_CONFIG_FILE="$RABBITMQ_ADVANCED_CONFIG_FILE"
RABBITMQ_CONF_ENV_FILE=/path/to/a/custom/location/rabbitmq-env.conf
RABBITMQ_LOGS=/var/log/rabbitmq/rabbitmq.log
RABBITMQ_SASL_LOGS=/var/log/rabbitmq/rabbitmq-sasl.log

EOL

sudo tee "$RABBITMQ_CONFIG_FILE" > /dev/null <<EOL

## Networking
# listeners.tcp.default = 5672

## Users & Security
default_user = "$ONEAPP_RABBITMQ_DEFAULT_USER"
default_pass = "$ONEAPP_RABBITMQ_DEFAULT_PASS"
# default_user_tags.administrator = true
loopback_users.guest = true

## Log level for file logging
log.file.level = "$ONEAPP_RABBITMQ_LOG_LEVEL"

EOL


}

is_rabbitmq_up()
{
    if systemctl is-active --quiet rabbitmq-server; then
        return 0
    else
        return 1
    fi
}



postinstall_cleanup()
{
    msg info "Delete cache and stored packages"
    apt-get autoclean
    apt-get autoremove
    rm -rf /var/lib/apt/lists/*
}
