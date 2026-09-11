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
    rev = "ffeaa26";
    hash = "sha256:4a3d5b4c76fa7836627038c441bd72a9aedfe56344b1f69788d8e620ae16376e";
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
