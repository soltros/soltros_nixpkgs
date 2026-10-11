{ lib, stdenvNoCC, fetchurl, buildFHSEnv, writeShellScript, alsa-lib, libpulseaudio, vulkan-loader, libGL, zlib, openssl, icu, fontconfig, freetype, SDL2, xorg, wayland, libxkbcommon }:
let
  version = "0.0.5-nexus-release.2";
  payload = stdenvNoCC.mkDerivation {
    pname = "sharpemu-files";
    inherit version;
    src = fetchurl {
      url = "https://github.com/sharpemu/sharpemu/releases/download/v${version}/sharpemu-${version}-linux-x64.tar.gz";
      hash = "sha256-0e238c8377119b67047042f1ff2f3e4c94960feaedf49a066467a72756e134f0";
    };
    sourceRoot = ".";
    dontBuild = true;
    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/sharpemu"
      cp -a . "$out/share/sharpemu/"
      chmod -R u+w "$out/share/sharpemu"
      test -f "$out/share/sharpemu/SharpEmu" || {
        echo "SharpEmu executable not found at archive root" >&2
        exit 1
      }
      chmod +x "$out/share/sharpemu/SharpEmu"
      runHook postInstall
    '';
  };
  launcher = writeShellScript "sharpemu-launch" ''
    cd "${payload}/share/sharpemu"
    exec ./SharpEmu "$@"
  '';
in
buildFHSEnv {
  name = "sharpemu";
  inherit version;
  targetPkgs = pkgs: with pkgs; [
    alsa-lib libpulseaudio vulkan-loader libGL zlib openssl icu
    fontconfig freetype SDL2 xorg.libX11 xorg.libXcursor xorg.libXi
    xorg.libXrandr xorg.libXext xorg.libXrender xorg.libxcb
    wayland libxkbcommon
  ];
  runScript = "${launcher}";
  extraInstallCommands = ''
    mkdir -p "$out/share/applications"
    cat > "$out/share/applications/sharpemu.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=SharpEmu
Comment=Experimental PlayStation 5 emulator
Exec=sharpemu
Terminal=false
Categories=Game;Emulator;
EOF
  '';
  meta = with lib; {
    description = "Experimental PlayStation 5 emulator";
    homepage = "https://github.com/sharpemu/sharpemu";
    license = licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
    mainProgram = "sharpemu";
  };
}
