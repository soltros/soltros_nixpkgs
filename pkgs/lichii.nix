{ lib, appimageTools, fetchurl, stdenv }:

let
  pname = "lichii";
  version = "125";
  sources = {
    x86_64-linux = {
      arch = "x86_64";
      hash = "sha256-3xVDMoxEiwfMmHHnDO5EkfUXS0TJg6PjLWIjZA4/lzw=";
    };
    aarch64-linux = {
      arch = "aarch64";
      hash = "sha256-8MUUs0wsTuM87MATL0yuJ5m5JVBdIjUPXRhLaQKgdu8=";
    };
  };
  source = sources.${stdenv.hostPlatform.system}
    or (throw "Lichii supports only x86_64-linux and aarch64-linux");
  src = fetchurl {
    url = "https://github.com/zortos293/Lichii/releases/download/build-${version}/lichii-linux-${source.arch}-pgo.AppImage";
    inherit (source) hash;
  };
  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  # Qt and FFmpeg are bundled; provide the host libraries and GPU/audio backends
  # deliberately excluded from the upstream AppImage (including dlopen users).
  extraPkgs = pkgs: with pkgs; [
    alsa-lib
    e2fsprogs
    expat
    fontconfig
    freetype
    fribidi
    gmp
    graphite2
    harfbuzz
    libcap
    libdecor
    libdrm
    libglvnd
    libgpg-error
    libpulseaudio
    libusb1
    libxkbcommon
    pipewire
    stdenv.cc.cc.lib
    udev
    vulkan-loader
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXScrnSaver
    xorg.libXtst
    xorg.libxcb
    zlib
  ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/io.github.zortos293.lichii.desktop \
      "$out/share/applications/io.github.zortos293.lichii.desktop"
    install -Dm444 ${appimageContents}/io.github.zortos293.lichii.png \
      "$out/share/icons/hicolor/256x256/apps/io.github.zortos293.lichii.png"
  '';

  meta = {
    description = "Experimental Nintendo Switch and Switch 2 emulator";
    homepage = "https://github.com/zortos293/Lichii";
    changelog = "https://github.com/zortos293/Lichii/releases/tag/build-${version}";
    license = lib.licenses.gpl3Plus;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames sources;
    mainProgram = "lichii";
  };
}
