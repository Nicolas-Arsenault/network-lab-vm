source "virtualbox-iso" "ubuntu" {
  vm_name         = "log100-network-lab-vm-${var.arch}"
  output_filename = "log100-network-lab-vm-${var.arch}"
  output_directory = "output-${var.arch}"

  chipset            = var.chipset
  firmware           = "efi"
  iso_interface      = "sata"
  hard_drive_interface = "sata"
  nic_type           = var.nic_type
  gfx_controller     = "vmsvga"
  guest_additions_mode = "disable"

  cpus      = 2
  memory    = 4096
  disk_size = 24576
  headless  = false
  sound     = "none"
  usb       = false

  iso_url      = var.iso_url
  iso_checksum = var.iso_checksum

  vboxmanage = [
    ["modifyvm", "{{.Name}}", "--boot1", "dvd", "--boot2", "disk", "--boot3", "none", "--boot4", "none"]
  ]

  http_directory = "${path.root}/http"

  boot_wait              = "15s"
  boot_keygroup_interval = "200ms"
  boot_command = [
    "<esc><wait>",
    "c<wait>",
    "set gfxpayload=keep<enter><wait>",
    "linux /casper/vmlinuz autoinstall quiet ds=\"nocloud-net;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\" ---<enter><wait>",
    "initrd /casper/initrd<enter><wait>",
    "boot<enter>"
  ]

  communicator = "ssh"
  ssh_username = "packer"
  ssh_password = "packer"
  ssh_timeout  = "45m"
  host_port_min = 2223
  host_port_max = 2299

  shutdown_command = "echo 'packer' | sudo -S /usr/local/sbin/log100-finalize-build"
  shutdown_timeout = "10m"

  format = "ova"
  export_opts = [
    "--manifest",
    "--vsys", "0",
    "--description", "LOG100 - Machine virtuelle pour les laboratoires de réseautique",
    "--version", var.vm_version
  ]

  vboxmanage_post = [
    ["modifyvm", "{{.Name}}", "--nat-pf1", "ssh,tcp,127.0.0.1,2222,,22"]
  ]
}

build {
  name    = "log100-network-lab-vm"
  sources = ["source.virtualbox-iso.ubuntu"]

  provisioner "shell" {
    script          = "${path.root}/scripts/provision.sh"
    execute_command = "echo 'packer' | sudo -S -E bash '{{ .Path }}'"
  }
}
