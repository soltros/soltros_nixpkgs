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
  pname = "pantheon-studio";
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

  doCheck = true;

  meta = {
    description = "Customize Pantheon application names, icons, and visibility";
    license = lib.licenses.gpl3Plus;
    mainProgram = "pantheon-studio";
    platforms = lib.platforms.linux;
  };
}
