{ lib
, rustPlatform
, pkg-config
, wrapGAppsHook3
, dbus
, gtk3
, libappindicator-gtk3
, libxkbcommon
, wayland
, xorg
}:

let
  src = builtins.fetchGit {
    url = "https://github.com/soltros/Cabinet-Desktop.git";
    rev = "a3599ae986b4eaa2e6effc6cde8edd78c126a451";
  };
in
rustPlatform.buildRustPackage {
  pname = "cabinet-desktop";
  version = "0.1.0-dev-20260921";

  inherit src;

  cargoLock = {
    lockFile = "${src}/Cargo.lock";
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    dbus
    gtk3
    libappindicator-gtk3
    libxkbcommon
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
  ];

  postInstall = ''
    install -Dm644 /dev/stdin "$out/share/applications/cabinet-desktop.desktop" <<'EOF'
    [Desktop Entry]
    Type=Application
    Name=Cabinet
    Comment=Desktop client for the Cabinet self-hosted file locker
    Exec=cabinet-desktop
    Icon=cabinet-desktop
    Terminal=false
    Categories=Utility;Network;
    StartupNotify=true
    EOF

    install -Dm644 /dev/stdin "$out/share/icons/hicolor/scalable/apps/cabinet-desktop.svg" <<'EOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128">
      <rect width="128" height="128" rx="28" fill="#2563eb"/>
      <rect x="28" y="25" width="72" height="78" rx="10" fill="white"/>
      <rect x="37" y="37" width="54" height="23" rx="5" fill="#dbeafe"/>
      <rect x="37" y="69" width="54" height="23" rx="5" fill="#dbeafe"/>
      <rect x="58" y="45" width="12" height="5" rx="2.5" fill="#2563eb"/>
      <rect x="58" y="77" width="12" height="5" rx="2.5" fill="#2563eb"/>
    </svg>
    EOF
  '';

  meta = {
    description = "Native Rust desktop client for Cabinet";
    homepage = "https://github.com/soltros/Cabinet-Desktop";
    license = lib.licenses.gpl3Only;
    mainProgram = "cabinet-desktop";
    platforms = lib.platforms.linux;
  };
}
