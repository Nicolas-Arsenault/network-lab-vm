from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RepositoryTests(unittest.TestCase):
    def test_version_is_semver(self):
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        self.assertRegex(version, r"^\d+\.\d+\.\d+$")

    def test_root_version_is_passed_to_packer(self):
        text = (ROOT / "scripts" / "build.sh").read_text(encoding="utf-8")
        self.assertIn("version=$(tr -d", text)
        self.assertIn('-var "vm_version=$version"', text)
        for arch in ("amd64", "arm64"):
            var_text = (ROOT / "packer" / f"{arch}.pkrvars.hcl").read_text(
                encoding="utf-8"
            )
            self.assertNotIn("vm_version", var_text)

    def test_release_asset_names_are_stable(self):
        setup = (ROOT / "scripts" / "setup-vm.sh").read_text(encoding="utf-8")
        package = (ROOT / "scripts" / "package.sh").read_text(encoding="utf-8")
        self.assertIn("log100-network-lab-vm-$arch.ova.gz", setup)
        self.assertIn("log100-network-lab-vm-$arch.ova.gz", package)

    def test_ssh_is_localhost_only(self):
        packer = (ROOT / "packer" / "ubuntu.pkr.hcl").read_text(encoding="utf-8")
        posix = (ROOT / "scripts" / "setup-vm.sh").read_text(encoding="utf-8")
        powershell = (ROOT / "scripts" / "setup-vm.ps1").read_text(encoding="utf-8")
        self.assertIn("127.0.0.1,2222,,22", packer)
        self.assertIn("127.0.0.1,$ssh_port,,22", posix)
        self.assertIn("127.0.0.1,$SshPort,,22", powershell)

    def test_packer_validation_message_is_full_sentence(self):
        text = (ROOT / "packer" / "variables.pkr.hcl").read_text(encoding="utf-8")
        self.assertIn("L'architecture doit être amd64 ou arm64.", text)

    def test_packer_boot_is_robust_for_virtualbox(self):
        text = (ROOT / "packer" / "ubuntu.pkr.hcl").read_text(encoding="utf-8")
        self.assertIn("headless  = false", text)
        self.assertIn('boot_wait              = "20s"', text)
        self.assertIn('boot_keygroup_interval = "200ms"', text)
        self.assertRegex(text, r'iso_interface\s*=\s*"sata"')
        self.assertRegex(text, r'hard_drive_interface\s*=\s*"sata"')
        self.assertRegex(text, r"sata_port_count\s*=\s*2")
        self.assertIn('http_network_protocol = "tcp4"', text)
        self.assertIn(
            '["modifyvm", "{{.Name}}", "--boot1", "dvd", "--boot2", "disk", "--boot3", "none", "--boot4", "none"]',
            text,
        )
        self.assertIn('["modifyvm", "{{.Name}}", "--firmware", "efi"]', text)
        self.assertIn('"c<wait2>"', text)
        self.assertIn("linux /casper/vmlinuz autoinstall", text)
        self.assertIn("/casper/initrd", text)
        self.assertNotIn("<tab>", text)

    def test_virtualbox_guest_type_matches_architecture(self):
        packer = (ROOT / "packer" / "ubuntu.pkr.hcl").read_text(encoding="utf-8")
        amd64 = (ROOT / "packer" / "amd64.pkrvars.hcl").read_text(encoding="utf-8")
        arm64 = (ROOT / "packer" / "arm64.pkrvars.hcl").read_text(encoding="utf-8")
        self.assertIn("guest_os_type    = var.guest_os_type", packer)
        self.assertIn('guest_os_type = "Ubuntu_64"', amd64)
        self.assertIn('guest_os_type = "Ubuntu_arm64"', arm64)
        self.assertIn('chipset       = "armv8virtual"', arm64)

    def test_packer_plugin_is_pinned(self):
        text = (ROOT / "packer" / "variables.pkr.hcl").read_text(encoding="utf-8")
        self.assertIn('version = "= 1.1.5"', text)

    def test_autoinstall_disables_installer_refresh(self):
        text = (ROOT / "packer" / "http" / "user-data").read_text(encoding="utf-8")
        self.assertIn("refresh-installer:", text)
        self.assertIn("update: false", text)

    def test_rootless_network_packages_are_explicit(self):
        text = (ROOT / "packer" / "scripts" / "provision.sh").read_text(
            encoding="utf-8"
        )
        for package in (
            "podman",
            "netavark",
            "aardvark-dns",
            "iptables",
            "nftables",
            "passt",
            "uidmap",
            "fuse-overlayfs",
            "slirp4netns",
        ):
            self.assertIn(package, text)
        self.assertNotIn("podman pull", text)
        self.assertIn("apt-mark manual podman netavark aardvark-dns passt", text)
        self.assertIn("iptables nftables", text)
        self.assertIn("test -x /usr/lib/podman/netavark", text)
        self.assertIn("test -x /usr/lib/podman/aardvark-dns", text)
        self.assertIn("command -v iptables", text)
        self.assertIn("command -v nft", text)
        self.assertIn("command -v pasta", text)
        self.assertIn("command -v slirp4netns", text)
        self.assertIn("command -v fuse-overlayfs", text)
        self.assertIn("/usr/lib/podman/netavark --version", text)
        self.assertIn("iptables --version", text)
        self.assertIn("nft --version", text)

    def test_ssh_uses_classic_service_mode(self):
        text = (ROOT / "packer" / "scripts" / "provision.sh").read_text(
            encoding="utf-8"
        )
        self.assertIn("PasswordAuthentication yes", text)
        self.assertIn("PubkeyAuthentication yes", text)
        self.assertIn("systemctl disable ssh.socket", text)
        self.assertIn("/etc/systemd/system-generators/sshd-socket-generator", text)
        self.assertIn("systemctl enable ssh.service", text)
        self.assertIn("systemctl is-enabled --quiet ssh.service", text)
        self.assertIn("systemctl is-enabled --quiet ssh.socket", text)
        self.assertIn("Before=ssh.service", text)
        self.assertNotIn("Before=ssh.service ssh.socket", text)

    def test_setup_scripts_can_select_explicit_release(self):
        posix = (ROOT / "scripts" / "setup-vm.sh").read_text(encoding="utf-8")
        powershell = (ROOT / "scripts" / "setup-vm.ps1").read_text(encoding="utf-8")
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        student = (ROOT / "docs" / "student-setup.md").read_text(encoding="utf-8")
        self.assertIn("--version", posix)
        self.assertIn("releases/download/$release_tag", posix)
        self.assertIn("releases/latest/download", posix)
        self.assertIn('[string]$Version = "latest"', powershell)
        self.assertIn("releases/download/$ReleaseTag", powershell)
        self.assertIn("releases/latest/download", powershell)
        self.assertIn("./setup-vm.sh --version v0.1.1", readme)
        self.assertIn("-Version v0.1.1", readme)
        self.assertIn("./setup-vm.sh --version v0.1.1", student)
        self.assertIn("-Version v0.1.1", student)

    def test_prerelease_mode_is_amd64_only(self):
        release = (ROOT / "scripts" / "release.sh").read_text(encoding="utf-8")
        build_doc = (ROOT / "docs" / "build.md").read_text(encoding="utf-8")
        self.assertIn("--prerelease", release)
        self.assertIn("architectures=(amd64)", release)
        self.assertIn("architectures=(amd64 arm64)", release)
        self.assertIn("--latest=false", release)
        self.assertIn("release_args+=(--prerelease --latest=false)", release)
        self.assertIn("./scripts/release.sh --prerelease", build_doc)

    def test_release_notes_are_versioned_and_configurable(self):
        release = (ROOT / "scripts" / "release.sh").read_text(encoding="utf-8")
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        build_doc = (ROOT / "docs" / "build.md").read_text(encoding="utf-8")
        notes = ROOT / "release-notes" / "v0.1.1.md"
        self.assertTrue(notes.is_file())
        self.assertIn('notes_file="$root/release-notes/$tag.md"', release)
        self.assertIn("--notes", release)
        self.assertIn('--notes-file "$notes_file"', release)
        self.assertNotIn("mktemp", release)
        self.assertIn("release-notes/v0.1.1.md", readme)
        self.assertIn("release-notes/v<version>.md", build_doc)
        self.assertFalse((ROOT / "CHANGELOG.md").exists())

    def test_arm64_release_requires_explicit_validation(self):
        release = (ROOT / "scripts" / "release.sh").read_text(encoding="utf-8")
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        support = (ROOT / "docs" / "support.md").read_text(encoding="utf-8")
        self.assertIn("LOG100_ARM64_VALIDATED", release)
        self.assertIn('[[ "$prerelease" == false', release)
        self.assertIn("ne doit pas encore être annoncée", readme)
        self.assertIn("ne doit pas encore être présentée", support)

    def test_autoinstall_uses_minimal_server_source(self):
        text = (ROOT / "packer" / "http" / "user-data").read_text(encoding="utf-8")
        self.assertIn("id: ubuntu-server-minimal", text)
        self.assertIn("search_drivers: false", text)

    def test_virtual_disk_supports_trim(self):
        text = (ROOT / "packer" / "ubuntu.pkr.hcl").read_text(encoding="utf-8")
        self.assertIn("hard_drive_discard       = true", text)
        self.assertIn("hard_drive_nonrotational = true", text)

    def test_guest_baseline_packages_are_explicit(self):
        text = (ROOT / "packer" / "scripts" / "provision.sh").read_text(encoding="utf-8")
        self.assertIn("apt-get install -y --no-install-recommends", text)
        for package in (
            "ca-certificates",
            "curl",
            "git",
            "openssh-server",
            "podman",
            "netavark",
            "aardvark-dns",
            "passt",
            "slirp4netns",
            "fuse-overlayfs",
            "uidmap",
            "iptables",
            "nftables",
            "iproute2",
            "iputils-ping",
            "procps",
            "psmisc",
            "lsof",
            "socat",
            "dnsutils",
            "traceroute",
            "tcpdump",
            "tshark",
            "jq",
            "zip",
            "unzip",
            "tar",
            "gzip",
            "xz-utils",
            "zstd",
            "nano",
            "vim-tiny",
            "less",
        ):
            self.assertRegex(text, rf"(?m)^  {package.replace('-', r'\-')} \\?$|^  {package.replace('-', r'\-')}$")

    def test_additional_student_tooling_is_explicit(self):
        text = (ROOT / "packer" / "scripts" / "provision.sh").read_text(encoding="utf-8")
        for package in (
            "python3",
            "python3-pip",
            "python3-requests",
            "python3-venv",
            "python3-yaml",
            "netcat-openbsd",
            "dbus-user-session",
            "catatonit",
        ):
            self.assertIn(package, text)
        self.assertIn("wireshark-common/install-setuid boolean false", text)
        self.assertIn("command -v tshark", text)
        self.assertIn("tshark --version", text)
        self.assertIn("vi --version", text)

    def test_cleanup_reclaims_guest_disk_space(self):
        cleanup = (ROOT / "packer" / "scripts" / "cleanup.sh").read_text(encoding="utf-8")
        packer = (ROOT / "packer" / "ubuntu.pkr.hcl").read_text(encoding="utf-8")
        provision = (ROOT / "packer" / "scripts" / "provision.sh").read_text(encoding="utf-8")
        self.assertIn("apt-get autoremove --purge -y", cleanup)
        self.assertIn("/var/log/installer", cleanup)
        self.assertIn("cloud-init clean --logs --seed", cleanup)
        self.assertIn("fstrim -av", cleanup)
        self.assertIn("log100-zero-fill", cleanup)
        self.assertIn('script          = "${path.root}/scripts/cleanup.sh"', packer)
        self.assertIn("/usr/local/sbin/log100-cleanup-build --final", provision)
        self.assertIn("truncate -s 0 /etc/machine-id", provision)

    def test_package_reports_oversize_rebuild_requirement(self):
        text = (ROOT / "scripts" / "package.sh").read_text(encoding="utf-8")
        self.assertIn("taille de l'OVA source", text)
        self.assertIn("package.sh ne peut pas compacter un disque déjà exporté", text)
        self.assertIn("./scripts/build.sh $arch", text)

    def test_no_unicode_dashes(self):
        ignored = {".git"}
        bad = []
        for path in ROOT.rglob("*"):
            if not path.is_file() or any(part in ignored for part in path.parts):
                continue
            if path.suffix in {".gz", ".ova", ".iso", ".vdi", ".vmdk"}:
                continue
            try:
                text = path.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if "\u2013" in text or "\u2014" in text:
                bad.append(str(path.relative_to(ROOT)))
        self.assertEqual([], bad)


if __name__ == "__main__":
    unittest.main()
