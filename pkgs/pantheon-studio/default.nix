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
, xvfb-run
}:

stdenv.mkDerivation {
  pname = "pantheon-studio";
  version = "0.2.0";

  src = ./.;

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    vala
    xvfb-run
    wrapGAppsHook4
    glib
  ];

  buildInputs = [
    gtk4
    pantheon.granite7
    libgee
    pantheon.wingpanel
    pantheon.elementary-gsettings-schemas
  ];

  doCheck = true;

  meta = {
    description = "Customize Pantheon launcher folders, icons, panel appearance, and desktop settings";
    license = lib.licenses.gpl3Plus;
    mainProgram = "pantheon-studio";
    platforms = lib.platforms.linux;
  };
}
