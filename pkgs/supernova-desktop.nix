{ lib
, buildNpmPackage
, fetchFromGitHub
, electron_44
, makeWrapper
}:

buildNpmPackage rec {
  pname = "supernova-desktop";
  version = "2026.07.17-unstable-2026-09-22";

  src = fetchFromGitHub {
    owner = "soltros";
    repo = "Supernova";
    rev = "8c91a9e493bc06550eedce24ee5d3e4358527d36";
    hash = "sha256-UpEMK9OCfVTWZiJ6wY/HY238cAIuP22pCChViLbZHdE=";
  };

  sourceRoot = "${src.name}/desktop-app";

  npmDepsHash = lib.fakeHash;

  env.ELECTRON_SKIP_BINARY_DOWNLOAD = true;

  nativeBuildInputs = [ makeWrapper ];

  buildPhase = ''
    runHook preBuild

    npx electron-builder --linux --dir \
      -c.electronDist="${electron_44.dist}" \
      -c.electronVersion=${electron_44.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/lib/supernova-desktop"
    cp -r dist/*-unpacked/resources/app.asar* "$out/share/lib/supernova-desktop/"

    install -Dm644 build/icon.png \
      "$out/share/icons/hicolor/512x512/apps/com.supernova.desktop.png"

    install -Dm644 /dev/stdin "$out/share/applications/com.supernova.desktop.desktop" <<'EOF'
    [Desktop Entry]
    Type=Application
    Name=Supernova
    Comment=Official desktop client for the Supernova music server
    Exec=supernova-desktop
    Icon=com.supernova.desktop
    Terminal=false
    Categories=Audio;AudioVideo;Player;
    StartupNotify=true
    EOF

    makeWrapper "${lib.getExe electron_44}" "$out/bin/supernova-desktop" \
      --add-flags "$out/share/lib/supernova-desktop/app.asar" \
      --inherit-argv0

    runHook postInstall
  '';

  meta = {
    description = "Official Electron desktop client for the Supernova music server";
    homepage = "https://github.com/soltros/Supernova";
    license = lib.licenses.gpl3Only;
    mainProgram = "supernova-desktop";
    platforms = lib.platforms.linux;
  };
}
