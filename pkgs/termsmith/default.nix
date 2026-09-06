{ lib
, stdenv
, meson
, ninja
, pkg-config
, vala
, wrapGAppsHook4
, gtk4
, pantheon
, glib
, libgee
}:

stdenv.mkDerivation {
  pname = "termsmith";
  version = "0.1.0";

  src = ./.;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    vala
    wrapGAppsHook4
    glib
  ];

  buildInputs = [
    gtk4
    pantheon.granite7
    libgee
  ];

  meta = {
    description = "Create and launch reusable Alacritty terminal profiles";
    license = lib.licenses.gpl3Plus;
    mainProgram = "termsmith";
    platforms = lib.platforms.linux;
  };
}
