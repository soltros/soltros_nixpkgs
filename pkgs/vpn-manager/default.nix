{ lib, stdenvNoCC, python3, wrapGAppsHook4, gobject-introspection, gtk4, libadwaita, networkmanager, tailscale, iproute2, polkit }:
let
  python = python3.withPackages (ps: [ ps.pygobject3 ]);
in
stdenvNoCC.mkDerivation {
  pname = "vpn-manager";
  version = "0.1.0";
  src = ./.;
  nativeBuildInputs = [ wrapGAppsHook4 gobject-introspection ];
  buildInputs = [ gtk4 libadwaita ];
  dontBuild = true;
  doCheck = true;
  checkPhase = ''
    ${python}/bin/python -m unittest discover -s tests -v
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/vpn-manager $out/bin
    cp app.py backend.py $out/lib/vpn-manager/
    makeWrapper ${python}/bin/python $out/bin/vpn-manager \
      --add-flags $out/lib/vpn-manager/app.py \
      --unset LD_LIBRARY_PATH \
      --prefix PATH : ${lib.makeBinPath [ networkmanager tailscale iproute2 polkit ]}
    install -Dm644 io.github.soltros.VPNManager.desktop $out/share/applications/io.github.soltros.VPNManager.desktop
    install -Dm644 io.github.soltros.VPNManager.svg $out/share/icons/hicolor/scalable/apps/io.github.soltros.VPNManager.svg
    runHook postInstall
  '';
  meta = {
    description = "Simple desktop switching between Tailscale and WireGuard";
    mainProgram = "vpn-manager";
    platforms = lib.platforms.linux;
    license = lib.licenses.mit;
  };
}
