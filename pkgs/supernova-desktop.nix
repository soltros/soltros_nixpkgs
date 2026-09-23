{ lib
, flutter
, fetchFromGitHub
, gtk3
, libsecret
, makeWrapper
, mpv
, pkg-config
}:

flutter.buildFlutterApplication (finalAttrs: {
  pname = "supernova-desktop";
  version = "0-unstable-2026-09-22";

  src = fetchFromGitHub {
    owner = "soltros";
    repo = "Supernova";
    rev = "8c91a9e493bc06550eedce24ee5d3e4358527d36";
    hash = lib.fakeHash;
  };

  sourceRoot = "${finalAttrs.src.name}/desktop-app";
  autoPubspecLock = finalAttrs.src + "/desktop-app/pubspec.lock";

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ gtk3 libsecret mpv ];

  preBuild = ''
    flutter create --platforms=linux --project-name supernova_desktop --org com.soltros .
  '';

  postInstall = ''
    install -Dm644 packaging/com.soltros.Supernova.desktop       $out/share/applications/com.soltros.Supernova.desktop
    install -Dm644 assets/icon.png       $out/share/icons/hicolor/512x512/apps/com.soltros.Supernova.png

  '';

  postFixup = ''
    # media_kit loads libmpv dynamically at runtime. On NixOS there is no
    # global /usr/lib fallback, so make libmpv visible to the application.
    if [ -x "$out/bin/supernova_desktop" ]; then
      wrapProgram "$out/bin/supernova_desktop" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ mpv ]}"
    fi

    # Flutter derives the executable name from the Dart project name. Expose
    # the stable hyphenated command advertised by meta.mainProgram.
    if [ ! -e "$out/bin/supernova-desktop" ]; then
      ln -s "$out/bin/supernova_desktop" "$out/bin/supernova-desktop"
    fi
  '';

  meta = {
    description = "Native Flutter desktop client for the Supernova music server";
    homepage = "https://github.com/soltros/Supernova";
    license = lib.licenses.gpl3Only;
    mainProgram = "supernova-desktop";
    platforms = lib.platforms.linux;
  };
})
