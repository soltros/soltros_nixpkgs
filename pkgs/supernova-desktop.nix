{ lib
, stdenv
, fetchFromGitHub
, electron
, makeWrapper
}:

stdenv.mkDerivation {
  pname = "supernova-desktop";
  version = "2026.07.17";

  src = fetchFromGitHub {
    owner = "soltros";
    repo = "Supernova";
    rev = "8c91a9e493bc06550eedce24ee5d3e4358527d36";
    hash = "sha256-UpEMK9OCfVTWZiJ6wY/HY238cAIuP22pCChViLbZHdE=";
  };

  sourceRoot = "source/desktop-app";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/supernova-desktop" "$out/bin"
    cp main.js preload.js security.js setup.html package.json "$out/share/supernova-desktop/"
    cp -r build "$out/share/supernova-desktop/"
    makeWrapper ${electron}/bin/electron "$out/bin/supernova-desktop" --add-flags "$out/share/supernova-desktop"
    install -Dm644 /dev/stdin "$out/share/applications/com.supernova.desktop.desktop" <<'EOF'
    [Desktop Entry]
    Type=Application
    Name=Supernova
    Comment=Desktop client for the Supernova music server
    Exec=supernova-desktop
    Icon=com.supernova.desktop
    Terminal=false
    Categories=Audio;AudioVideo;Network;
    StartupNotify=true
    EOF
    install -Dm644 build/icon.png "$out/share/icons/hicolor/512x512/apps/com.supernova.desktop.png"
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
