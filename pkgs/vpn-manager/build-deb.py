#!/usr/bin/env python3
"""Build a portable Debian archive using Python 3 and dpkg-deb."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

VERSION = '0.1.0'
SOURCE = Path(__file__).resolve().parent


def build(output):
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='vpn-manager-deb-') as directory:
        root = Path(directory) / 'package'
        def write(name, content, mode=0o644):
            dest = root / name
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(content)
            dest.chmod(mode)
        def copy(name, dest):
            write(dest, (SOURCE / name).read_text())
        for name in ['app.py', 'backend.py']:
            copy(name, 'usr/share/vpn-manager/' + name)
        copy('io.github.soltros.VPNManager.desktop', 'usr/share/applications/io.github.soltros.VPNManager.desktop')
        copy('io.github.soltros.VPNManager.svg', 'usr/share/icons/hicolor/scalable/apps/io.github.soltros.VPNManager.svg')
        copy('README.md', 'usr/share/doc/vpn-manager/README.md')
        copy('LICENSE', 'usr/share/doc/vpn-manager/copyright')
        write('usr/bin/vpn-manager', '#!/bin/sh\nexec /usr/bin/python3 /usr/share/vpn-manager/app.py "$@"\n', 0o755)
        size = sum(p.stat().st_size for p in root.rglob('*') if p.is_file())
        write('DEBIAN/control', f'''Package: vpn-manager
Version: {VERSION}
Section: net
Priority: optional
Architecture: all
Maintainer: soltros
Installed-Size: {(size + 1023) // 1024}
Depends: python3 (>= 3.10), python3-gi, gir1.2-gtk-4.0 (>= 4.8), gir1.2-adw-1 (>= 1.2), network-manager (>= 1.20), iproute2, pkexec, tailscale
Recommends: policykit-1-gnome | polkit-kde-agent-1
Description: Desktop manager for Tailscale and WireGuard
 View connection status, import WireGuard configurations, and switch between
 Tailscale and NetworkManager WireGuard profiles with one connection at a time.
 Administrator operations use the desktop polkit authentication prompt.
''')
        hashes = []
        for path in sorted((root / 'usr').rglob('*')):
            if path.is_file():
                hashes.append(f'{hashlib.md5(path.read_bytes()).hexdigest()}  {path.relative_to(root)}')
        write('DEBIAN/md5sums', '\n'.join(hashes) + '\n')
        # Stable file times and root ownership without requiring a root build.
        epoch = int(os.environ.get('SOURCE_DATE_EPOCH', '1789603200'))
        for path in root.rglob('*'):
            os.utime(path, (epoch, epoch))
        target = output / f'vpn-manager_{VERSION}_all.deb'
        subprocess.run(['dpkg-deb', '--root-owner-group', '-Zxz', '--build', str(root), str(target)],
                       check=True, env=dict(os.environ, SOURCE_DATE_EPOCH=str(epoch)))
        print(target)
        return target


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', default='dist')
    build(parser.parse_args().output)
