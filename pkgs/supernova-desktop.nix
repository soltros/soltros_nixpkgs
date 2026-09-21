{ lib
, flutter
, fetchFromGitHub
, gtk3
, libsecret
, pkg-config
}:

flutter.buildFlutterApplication (finalAttrs: {
  pname = "supernova-desktop";
  version = "0-unstable-2026-09-21";

  src = fetchFromGitHub {
    owner = "soltros";
    repo = "Supernova";
    rev = "16b87577e7944c2457e8ae3de2600ab9bb7518ba";
    hash = lib.fakeHash;
  };

  sourceRoot = "${finalAttrs.src.name}/desktop-app";
  autoPubspecLock = finalAttrs.src + "/desktop-app/pubspec.lock";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ gtk3 libsecret ];

  postInstall = ''
    install -Dm644 packaging/com.soltros.Supernova.desktop       $out/share/applications/com.soltros.Supernova.desktop
    install -Dm644 assets/icon.png       $out/share/icons/hicolor/512x512/apps/com.soltros.Supernova.png
  '';

  meta = {
    description = "Native Flutter desktop client for the Supernova music server";
    homepage = "https://github.com/soltros/Supernova";
    license = lib.licenses.gpl3Only;
    mainProgram = "supernova-desktop";
    platforms = lib.platforms.linux;
  };
})
