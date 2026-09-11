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
, makeWrapper
}:

stdenv.mkDerivation {
  pname = "nixboutique";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "soltros";
    repo = "Nixboutique";
    rev = "a9ca90a";
    hash = "sha256:c5039be3d09711d3d1dcc8cca6a67b2cf4000853157981686c1320ee3ba48918";
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
