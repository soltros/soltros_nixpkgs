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
    rev = "0117412";
    hash = "sha256:050f45419c190c050fcf8daf5ff274c93c9b9d091b507f86b19dcc7e737bd2cb";
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
