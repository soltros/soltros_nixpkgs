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
, json-glib
, libgee
, libsoup_3
, makeWrapper
}:

stdenv.mkDerivation {
  pname = "nixboutique";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "soltros";
    repo = "Nixboutique";
    rev = "8c1afae";
    hash = "sha256-ledoqClx03lwZttHOit3UJNKN5F5b810J32ROthqXyk=";
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    vala
    wrapGAppsHook4
    glib
    makeWrapper
  ];

  buildInputs = [
    gtk4
    json-glib
    libgee
    libsoup_3
    libsoup_3.dev
  ];

  postInstall = ''
    wrapProgram $out/bin/nixboutique \
      --set NIXBOUTIQUE_DATADIR $out/share/nixboutique
  '';

  meta = {
    description = "Modern GTK4 browser and manager for NixOS applications";
    homepage = "https://github.com/soltros/Nixboutique";
    license = lib.licenses.gpl3Plus;
    mainProgram = "nixboutique";
    platforms = lib.platforms.linux;
  };
}
