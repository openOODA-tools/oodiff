Name:           oodiff
Version:        0.3.1
Release:        1%{?dist}
Summary:        Capability-bounded file and directory diff engine
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/oodiff
Source0:        oodiff-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
oodiff is a drop-in diff replacement written in pure openOODA, featuring
byte-for-byte GNU diff parity, negative-trust capability security, and a
first-class MCP stdio surface for AI agents.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/oodiff
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/oodiff-uninstall

%files
/usr/bin/oodiff
/usr/bin/oodiff-uninstall

%changelog
* Tue Oct 06 2026 openOODA-tools <ops@openooda.org> - 0.3.1-1
- Align AGENTS.md, companion uninstaller, oote theme integration, and packaging
* Tue Oct 06 2026 openOODA-tools <ops@openooda.org> - 0.3.0-1
- Bundled clean uninstaller (oodiff-uninstall), hardened defenses, universal installers, and green CI/CD
* Mon Oct 05 2026 openOODA-tools <ops@openooda.org> - 0.2.2-1
- GNU diff parity, UTF-8 folding, DJB2 hashing, /dev/null support, MCP stdio server
