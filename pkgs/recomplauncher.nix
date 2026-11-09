{ lib
, appimageTools
, bash
, coreutils
, dbus
, e2fsprogs
, expat
, fontconfig
, fetchurl
, fribidi
, freetype
, glib
, harfbuzz
, libdrm
, libglvnd
, libgpg-error
, mesa
, stdenv
, wayland
, xorg
, zlib
}:

let
  pname = "recomplauncher";
  version = "0.90.0-beta.22";

  src = fetchurl {
    url = "https://github.com/elripalda/RecompLauncher/releases/download/v${version}/RecompLauncher_${version}_amd64.AppImage";
    hash = "sha256-330vcv1ed8H3grkX/b+7KJxktaxNSNYKQxLlWmN9ZIc=";
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: [
    coreutils
    bash
    dbus
    e2fsprogs
    expat
    fontconfig
    fribidi
    freetype
    glib
    harfbuzz
    libdrm
    libglvnd
    libgpg-error
    mesa
    stdenv.cc.cc.lib
    wayland
    zlib
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
    xorg.libxcb
  ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/usr/share/applications/RecompLauncher.desktop \
      "$out/share/applications/recomplauncher.desktop"
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/128x128/apps/recomplauncher.png \
      "$out/share/icons/hicolor/128x128/apps/recomplauncher.png"
  '';

  meta = {
    description = "Discover, install, update, and play PC recomps";
    homepage = "https://github.com/elripalda/RecompLauncher";
    changelog = "https://github.com/elripalda/RecompLauncher/releases/tag/v${version}";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "recomplauncher";
  };
}
