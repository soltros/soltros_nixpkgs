{ lib, runCommand, python3, dpkg }:
runCommand "vpn-manager-deb-0.1.0" {
  nativeBuildInputs = [ python3 dpkg ];
  meta = {
    description = "Debian package for VPN Manager";
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
  };
} ''
  python ${./.}/build-deb.py --output $out
  dpkg-deb --info $out/*.deb
''
