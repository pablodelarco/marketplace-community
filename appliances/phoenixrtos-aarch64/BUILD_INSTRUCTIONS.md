# Building Phoenix RTOS aarch64 Appliance

## Overview

This document provides instructions for building the Phoenix RTOS appliance for ARM64/aarch64 architecture. The build must be performed on an ARM64 machine (e.g., amp01, Raspberry Pi 4/5, AWS Graviton instance, etc.).

## Prerequisites

### Hardware Requirements
- **ARM64/aarch64 machine** with:
  - At least 4 CPU cores
  - Minimum 8GB RAM (16GB recommended)
  - 50GB free disk space
  - KVM support enabled

### Software Requirements
```bash
# Install required packages
sudo apt-get update
sudo apt-get install -y \
    qemu-system-arm \
    qemu-efi-aarch64 \
    qemu-utils \
    packer \
    make \
    git \
    genisoimage \
    ruby

# Verify architecture
uname -m  # Should output: aarch64
```

### Permissions
- **sudo access** is required for building images

## Build Process

### Step 1: Clone the Repository

```bash
git clone https://github.com/pablodelarco/marketplace-community.git
cd marketplace-community
git checkout feature/add-phoenixrtos-aarch64-appliance
```

### Step 2: Initialize Submodules

```bash
git submodule update --init --recursive
cd apps-code/one-apps
```

### Step 3: Prepare Base Ubuntu Image

The build process requires an Ubuntu 24.04 aarch64 base image:

```bash
# Download Ubuntu 24.04 ARM64 cloud image
wget https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-arm64.img

# Convert to qcow2 format
qemu-img convert -f qcow2 -O qcow2 \
    ubuntu-24.04-server-cloudimg-arm64.img \
    export/ubuntu2404.aarch64.qcow2

# Verify the image
qemu-img info export/ubuntu2404.aarch64.qcow2
```

### Step 4: Build the Phoenix RTOS aarch64 Appliance

```bash
# From the one-apps directory
cd /path/to/marketplace-community/apps-code/one-apps

# Build the aarch64 appliance
make packer-service_phoenix-rtos-one-automated.aarch64
```

This will:
1. Detect architecture from the target name (`.aarch64` suffix)
2. Use `qemu-system-aarch64` for virtualization
3. Apply the Phoenix RTOS installation script
4. Create the final image: `export/service_phoenix-rtos-one-automated.aarch64.qcow2`

### Step 5: Verify the Build

```bash
# Check the output image
ls -lh export/service_phoenix-rtos-one-automated.aarch64.qcow2

# Get image information
qemu-img info export/service_phoenix-rtos-one-automated.aarch64.qcow2

# Calculate checksums
md5sum export/service_phoenix-rtos-one-automated.aarch64.qcow2
sha256sum export/service_phoenix-rtos-one-automated.aarch64.qcow2
```

## Architecture Detection

The build system automatically detects the target architecture:

1. **Makefile Target**: `packer-service_phoenix-rtos-one-automated.aarch64`
   - The `.aarch64` suffix triggers architecture detection

2. **build.sh Script**: Checks if version contains "arch64"
   ```bash
   if [[ "$DISTRO_VER" =~ "arch64" ]]; then
       ARCH='aarch64'
   fi
   ```

3. **Packer Configuration**: Uses architecture-specific settings
   ```hcl
   qemu_binary  = "/usr/bin/qemu-system-aarch64"
   machine_type = "virt,gic-version=max"
   firmware     = "/usr/share/AAVMF/AAVMF_CODE.fd"
   ```

## Build Time Estimates

| Hardware | Estimated Build Time |
|----------|---------------------|
| Raspberry Pi 4 (4GB) | 45-60 minutes |
| Raspberry Pi 5 (8GB) | 30-45 minutes |
| AWS Graviton2 (4 vCPU) | 20-30 minutes |
| AWS Graviton3 (8 vCPU) | 15-20 minutes |
| Ampere Altra (16 cores) | 10-15 minutes |

## Testing the Image

### Quick Test with QEMU

```bash
# Test boot the image
qemu-system-aarch64 \
    -M virt,gic-version=max \
    -cpu cortex-a72 \
    -m 2048 \
    -bios /usr/share/AAVMF/AAVMF_CODE.fd \
    -drive file=export/service_phoenix-rtos-one-automated.aarch64.qcow2,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net-pci,netdev=net0 \
    -nographic

# SSH to the VM (from another terminal)
ssh -p 2222 root@localhost
```

### Test with OpenNebula

```bash
# Copy image to OpenNebula frontend
scp export/service_phoenix-rtos-one-automated.aarch64.qcow2 \
    oneadmin@opennebula-frontend:/var/tmp/

# On OpenNebula frontend, create image
oneimage create --name "Phoenix RTOS aarch64" \
    --path /var/tmp/service_phoenix-rtos-one-automated.aarch64.qcow2 \
    --type OS \
    --datastore default \
    --description "Phoenix RTOS for ARM64/aarch64"

# Create VM template
onetemplate create --name "Phoenix RTOS aarch64" \
    --cpu 2 \
    --vcpu 2 \
    --memory 2048 \
    --disk "Phoenix RTOS aarch64" \
    --nic NETWORK="default" \
    --vnc

# Instantiate VM
onetemplate instantiate "Phoenix RTOS aarch64"
```

## Troubleshooting

### Issue: QEMU aarch64 not found

```bash
# Install QEMU ARM support
sudo apt-get install qemu-system-arm qemu-efi-aarch64
```

### Issue: AAVMF firmware not found

```bash
# Install ARM UEFI firmware
sudo apt-get install qemu-efi-aarch64

# Verify installation
ls -la /usr/share/AAVMF/AAVMF_CODE.fd
```

### Issue: KVM acceleration not available

```bash
# Check KVM support
lsmod | grep kvm

# Load KVM module for ARM
sudo modprobe kvm
sudo modprobe kvm_arm  # or kvm_aarch64 depending on kernel
```

### Issue: Build fails with "No space left on device"

```bash
# Check disk space
df -h

# Clean up old builds
cd apps-code/one-apps
rm -rf build/*
rm -rf export/*.qcow2  # Keep only what you need
```

## Build on Specific ARM Platforms

### Raspberry Pi 4/5

```bash
# Enable KVM (if not already enabled)
echo 'KERNEL=="kvm", GROUP="kvm", MODE="0666"' | \
    sudo tee /etc/udev/rules.d/99-kvm.rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Increase swap if needed (for 4GB models)
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=100/CONF_SWAPSIZE=2048/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Build
make packer-service_phoenix-rtos-one-automated.aarch64
```

### AWS Graviton

```bash
# Launch Graviton instance (Ubuntu 22.04 or 24.04 ARM64)
# Instance type: t4g.xlarge or c7g.2xlarge recommended

# Install dependencies
sudo apt-get update
sudo apt-get install -y qemu-system-arm qemu-efi-aarch64 packer make git

# Build
make packer-service_phoenix-rtos-one-automated.aarch64
```

### NVIDIA Jetson

```bash
# Ensure JetPack is installed
# Install additional packages
sudo apt-get install -y qemu-system-arm qemu-efi-aarch64 packer

# Build
make packer-service_phoenix-rtos-one-automated.aarch64
```

## Next Steps After Build

1. **Calculate Checksums**:
   ```bash
   md5sum export/service_phoenix-rtos-one-automated.aarch64.qcow2 > checksums.txt
   sha256sum export/service_phoenix-rtos-one-automated.aarch64.qcow2 >> checksums.txt
   ```

2. **Get Image Size**:
   ```bash
   qemu-img info export/service_phoenix-rtos-one-automated.aarch64.qcow2 | grep "virtual size"
   ```

3. **Upload to Storage** (for marketplace):
   - Upload to S3, CloudFront, or other CDN
   - Note the public URL for the YAML metadata

4. **Update Marketplace YAML**:
   - Update `appliances/phoenixrtos-aarch64/*.yaml` with:
     - Image URL
     - Image size
     - MD5 and SHA256 checksums
     - Creation time (epoch)

5. **Test Deployment**:
   - Deploy on actual ARM hardware
   - Run test suite: `./app_readiness.rb phoenixrtos-aarch64`
   - Verify Docker and Phoenix RTOS container work

6. **Submit PR**:
   - Push changes to GitHub
   - Create pull request to OpenNebula/marketplace-community
   - Include build logs and test results

## Reference Machines

According to the engineer (aramirez), you can use:
- **amp01**: An ARM64 build machine (check with your team for access)
- Other ARM64 machines in your infrastructure

## Support

For issues or questions:
- OpenNebula Community Forum: https://forum.opennebula.io/
- GitHub Issues: https://github.com/OpenNebula/one/issues
- Marketplace Issues: Use label "Category: Marketplace"

## Additional Resources

- [OpenNebula Marketplace Documentation](https://docs.opennebula.io/stable/open_cluster_deployment/public_marketplaces/overview.html)
- [one-apps Repository](https://github.com/OpenNebula/one-apps)
- [Packer QEMU Builder](https://www.packer.io/plugins/builders/qemu)
- [Phoenix RTOS Documentation](https://phoenix-rtos.org/)

