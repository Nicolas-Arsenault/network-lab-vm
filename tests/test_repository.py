from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RepositoryTests(unittest.TestCase):
    def test_version_is_semver(self):
        version = (ROOT / "VERSION").read_text(encoding="utf-8").strip()
        self.assertRegex(version, r"^\d+\.\d+\.\d+$")

    def test_root_version_is_passed_to_packer(self):
        text = (ROOT / "scripts" / "build.sh").read_text(encoding="utf-8")
        self.assertIn('version=$(tr -d', text)
        self.assertIn('-var "vm_version=$version"', text)
        for arch in ("amd64", "arm64"):
            var_text = (ROOT / "packer" / f"{arch}.pkrvars.hcl").read_text(encoding="utf-8")
            self.assertNotIn("vm_version", var_text)

    def test_release_asset_names_are_stable(self):
        setup = (ROOT / "scripts" / "setup-vm.sh").read_text(encoding="utf-8")
        package = (ROOT / "scripts" / "package.sh").read_text(encoding="utf-8")
        self.assertIn('log100-network-lab-vm-$arch.ova.gz', setup)
        self.assertIn('log100-network-lab-vm-$arch.ova.gz', package)

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
        self.assertIn('headless  = false', text)
        self.assertIn('boot_wait              = "15s"', text)
        self.assertIn('boot_keygroup_interval = "200ms"', text)
        self.assertIn('["modifyvm", "{{.Name}}", "--boot1", "dvd", "--boot2", "disk", "--boot3", "none", "--boot4", "none"]', text)
        self.assertIn('"<esc><wait>"', text)
        self.assertNotIn('<tab><tab><tab><tab><tab>', text)

    def test_packer_plugin_is_pinned(self):
        text = (ROOT / "packer" / "variables.pkr.hcl").read_text(encoding="utf-8")
        self.assertIn('version = "= 1.1.5"', text)

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
