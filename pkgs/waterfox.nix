{ lib
, stdenv
, fetchurl
, makeDesktopItem
, writeText
, autoPatchelfHook
, patchelfUnstable
, wrapGAppsHook3
, alsa-lib
, curl
, dbus-glib
, gtk3
, libva
, libxtst
, pciutils
, pipewire
, adwaita-icon-theme
}:

let
  version = "6.7.3";

  sources = {
    x86_64-linux = {
      url = "https://cdn.waterfox.com/waterfox/releases/${version}/Linux_x86_64/waterfox-${version}.tar.bz2";
      hash = "sha256-2Pd9NDlHZDWLSsNlRzOJtGuArvWRVr+eD3K59hys0i8=";
    };
    aarch64-linux = {
      url = "https://cdn.waterfox.com/waterfox/releases/${version}/Linux_aarch64/waterfox-${version}.tar.bz2";
      hash = "sha256-mhW/4daAG3C3Jpmde3E/ZiqqROtJmhGQG3UoPTCqmJU=";
    };
  };

  source = sources.${stdenv.hostPlatform.system} or
    (throw "Waterfox is not available for ${stdenv.hostPlatform.system}");

  policies = writeText "waterfox-policies.json" (builtins.toJSON {
    policies.DisableAppUpdate = true;
  });

  desktopItem = makeDesktopItem {
    name = "waterfox";
    desktopName = "Waterfox";
    genericName = "Web Browser";
    comment = "Browse the Web";
    icon = "waterfox";
    exec = "waterfox %U";
    terminal = false;
    startupNotify = true;
    startupWMClass = "Waterfox";
    categories = [ "Network" "WebBrowser" ];
    mimeTypes = [
      "application/xhtml+xml"
      "text/html"
      "text/xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
  };
in
stdenv.mkDerivation {
  pname = "waterfox-bin";
  inherit version;

  src = fetchurl source;
  sourceRoot = "waterfox";

  nativeBuildInputs = [
    autoPatchelfHook
    patchelfUnstable
    wrapGAppsHook3
  ];

  buildInputs = [
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    gtk3
    libxtst
  ];

  runtimeDependencies = [
    curl
    libva.out
    pciutils
  ];

  appendRunpaths = [ "${pipewire}/lib" ];
  patchelfFlags = [ "--no-clobber-old-sections" ];

  installPhase = ''
    runHook preInstall

    install -d "$out/lib/waterfox-${version}" "$out/bin"
    cp -r . "$out/lib/waterfox-${version}"
    ln -s "$out/lib/waterfox-${version}/waterfox" "$out/bin/waterfox"

    install -d "$out/lib/waterfox-${version}/distribution"
    ln -s ${policies} "$out/lib/waterfox-${version}/distribution/policies.json"

    install -d "$out/share/applications"
    cp ${desktopItem}/share/applications/waterfox.desktop "$out/share/applications/"

    for size in 16 22 24 32 48 64 128 256; do
      icon="browser/chrome/icons/default/default''${size}.png"
      if [ -f "$icon" ]; then
        install -Dm644 "$icon" "$out/share/icons/hicolor/''${size}x''${size}/apps/waterfox.png"
      fi
    done

    runHook postInstall
  '';

  passthru = {
    applicationName = "Waterfox";
    binaryName = "waterfox";
  };

  meta = {
    description = "Customizable privacy-focused web browser based on Firefox";
    homepage = "https://www.waterfox.com/";
    changelog = "https://www.waterfox.com/docs/releases/${version}/";
    license = lib.licenses.mpl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = builtins.attrNames sources;
    mainProgram = "waterfox";
  };
}
