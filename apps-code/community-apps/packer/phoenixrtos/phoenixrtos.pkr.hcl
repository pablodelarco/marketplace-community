source "null" "null" { communicator = "none" }

# Prior to setting up the appliance, the context packages need to be generated first
# These will then be installed as part of the setup process
build {
  sources = ["source.null.null"]

  provisioner "shell-local" {
    inline = [
      "mkdir -p ${var.input_dir}/context",
      "${var.input_dir}/gen_context > ${var.input_dir}/context/context.sh",
      "mkisofs -o ${var.input_dir}/${var.appliance_name}-context.iso -V CONTEXT -J -R ${var.input_dir}/context",
    ]
  }
}

# A Virtual Machine is created with qemu in order to run the setup from the ISO on the CD-ROM
# Here are the details about the VM virtual hardware
source "qemu" "phoenixrtos" {
  cpus        = 2
  memory      = 2048
  accelerator = "tcg"

  iso_url      = "../one-apps/export/ubuntu2404.qcow2"
  iso_checksum = "none"

  headless = var.headless

  disk_image       = true
  disk_cache       = "unsafe"
  disk_interface   = "virtio"
  net_device       = "virtio-net"
  format           = "qcow2"
  disk_compression = false
  skip_resize_disk = true

  output_directory = var.output_dir

  qemuargs = [["-serial", "stdio"],
    ["-cpu", "qemu64"],
    ["-cdrom", "${var.input_dir}/${var.appliance_name}-context.iso"],
    # MAC addr needs to match ETH0_MAC from context iso
    ["-netdev", "user,id=net0,hostfwd=tcp::{{ .SSHHostPort }}-:22"],
    ["-device", "virtio-net-pci,netdev=net0,mac=00:11:22:33:44:55"]
  ]
  ssh_username     = "root"
  ssh_password     = "opennebula"
  ssh_wait_timeout = "900s"
  shutdown_command = "poweroff"
  vm_name          = "${var.appliance_name}"
}

# 3) Provision: one-context + Docker + pre-pull Phoenix-RTOS
build {
  name    = "phoenixrtos"
  sources = ["source.qemu.phoenixrtos"]

  provisioner "shell" {
    inline = [
      "set -eux",

      # make sure /context exists for the common install hook
      "mkdir -p /context",

      # force IPv4
      "printf 'Acquire::ForceIPv4 \"true\";\\n' >/etc/apt/apt.conf.d/99force-ipv4",

      # drop cloud-init
      "apt-get update -y",
      "DEBIAN_FRONTEND=noninteractive apt-get purge -y cloud-init cloud-initramfs-growroot || true",

      # install one-context + its deps
      "apt-get install -y wget cloud-image-utils cloud-utils ruby ifupdown qemu-guest-agent virt-what",
      "wget -qO /tmp/one-context.deb https://github.com/OpenNebula/one-apps/releases/download/v6.10.0-3/one-context_6.10.0-3.deb",
      "dpkg -i /tmp/one-context.deb || apt-get install -fy",
      "rm -f /tmp/one-context.deb",
      "systemctl enable one-context.service",

      # Docker prereqs
      "apt-get update -y",
      "apt-get install -y ca-certificates curl gnupg",

      # add Docker’s GPG key
      "install -d -m0755 /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg",
      "chmod a+r /etc/apt/keyrings/docker.gpg",

      # configure Docker repo (no HCL interpolation in here)
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable\" | tee /etc/apt/sources.list.d/docker.list",

      # install Docker
      "apt-get update -y",
      "DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "systemctl enable --now docker",

      # bake in the container
      "docker pull pablodelarco/phoenix-rtos-one:latest"
    ]
  }

  # copy your context binaries & scripts (skip context-linux if not available)
  provisioner "file" {
    source      = "../../appliances/phoenixrtos/appliance.sh"
    destination = "/tmp/appliance.sh"
  }
  provisioner "file" {
    source      = "../one-apps/appliances/service.sh"
    destination = "/tmp/service.sh"
  }
  provisioner "file" {
    source      = "../../lib"
    destination = "/tmp/lib"
  }

  # run the numbered appliance scripts
  provisioner "shell" {
    execute_command   = "sudo -iu root {{.Vars}} bash {{.Path}}"
    scripts           = sort(concat(
      [for s in fileset(".", "*.sh")               : "${var.input_dir}/${s}"],
      [for s in fileset(".", "*.sh.${var.version}") : "${var.input_dir}/${s}"]
    ))
    expect_disconnect = true
  }

  post-processor "shell-local" {
    scripts          = ["packer/postprocess.sh"]
    execute_command  = ["bash","-c","{{.Vars}} {{.Script}}"]
    environment_vars = [
      "OUTPUT_DIR=${var.output_dir}",
      "APPLIANCE_NAME=${var.appliance_name}",
    ]
  }
}
