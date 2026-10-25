{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, wrapGAppsHook3
, alsa-lib
, at-spi2-atk
, at-spi2-core
, cairo
, cups
, dbus
, expat
, gdk-pixbuf
, glib
, gtk3
, libX11
, libXcomposite
, libXdamage
, libXext
, libXfixes
, libXrandr
, libxcb
, libdrm
, mesa
, nspr
, nss
, pango
, systemd
, libxkbcommon
, vulkan-loader
, libGL
, libusb1
, openssl
, tpm2-tss
, qt6
, bubblewrap
}:

let
  # Use versioned upstream pool URLs so later releases do not invalidate pinned hashes.
  sources = {
    x86_64-linux = {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_26.1021.22027_amd64.deb";
      sha256 = "sha256-6wgxxzTxVPk/jrzw4X0RjaDep9wXN9xhoecURDdb8ZA=";
    };
    aarch64-linux = {
      url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_26.1021.22027_arm64.deb";
      sha256 = "sha256-aN4exEBmhx5Bd7ocp5Pr7muiODl/E8eU5FsUlBwSYfs=";
    };
  };
  srcInfo = sources.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "chatgpt";
  version = "26.1021.22027";

  src = fetchurl {
    inherit (srcInfo) url sha256;
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libdrm
    mesa
    nspr
    nss
    pango
    systemd
    libxkbcommon
    vulkan-loader
    libGL
    libusb1
    openssl
    tpm2-tss
    qt6.qtbase
  ];

  dontWrapQtApps = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x $src .
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share
    cp -r usr/lib/chatgpt $out/lib
    cp -r usr/share/* $out/share/

    # Remove non-glibc node prebuilds and unused Qt5 shim.
    find $out/lib -name "*musl*" -exec rm -rf {} +
    find $out/lib -path "*/prebuilds/android-*" -prune -exec rm -rf {} +
    rm -f $out/lib/libqt5_shim.so

    # Ensure desktop file points to the right binary
    substituteInPlace $out/share/applications/chatgpt.desktop \
      --replace-fail "Exec=chatgpt %U" "Exec=$out/bin/chatgpt %U"

    # Symlink binary wrapper with ozone / wayland flags support
    makeWrapper $out/lib/ChatGPT $out/bin/chatgpt \
      --prefix PATH : "${lib.makeBinPath [ bubblewrap ]}" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath buildInputs}:$out/lib" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "ChatGPT desktop app for Linux by OpenAI";
    homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "chatgpt";
  };
}
