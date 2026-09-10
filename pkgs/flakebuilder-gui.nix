{ lib
, stdenv
, fetchFromGitHub
, meson
, ninja
, pkg-config
, vala
, wrapGAppsHook4
, glib
, gtk4
, pantheon
}:

stdenv.mkDerivation {
  pname = "flakebuilder-gui";
  version = "unstable-2026-09-10";
  src = fetchFromGitHub {
    owner = "soltros";
    repo = "Flakebuilder";
    rev = "d5978cf";
    hash = "sha256-ORVpCdQ1QakMCbjNeyrrM4+KVwMxd3FrvKaDjKGNGTw=";
    sparseCheckout = [ "gui" ];
  };
  sourceRoot = "source/gui";
  nativeBuildInputs = [ meson ninja pkg-config vala wrapGAppsHook4 glib ];
  buildInputs = [ gtk4 pantheon.granite7 ];
  meta = {
    description = "Pantheon-style GTK frontend for Flakebuilder";
    homepage = "https://github.com/soltros/Flakebuilder";
    license = lib.licenses.gpl3Only;
    mainProgram = "flakebuilder-gui";
    platforms = lib.platforms.linux;
  };
}
