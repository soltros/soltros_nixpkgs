{
  lib,
  buildDubPackage,
  fetchFromGitHub,
  glib,
  libadwaita,
  gnupg,
  pkg-config,
}:

let
  gid = fetchFromGitHub {
    owner = "Kymorphia";
    repo = "gid";
    tag = "v0.9.9";
    hash = "sha256-F/oLXD+P/Pn504icEKXUkdfNC9pgzPU4ficX2vKa6jg=";
  };
in
buildDubPackage rec {
  pname = "hideout";
  version = "0.9.13";

  src = fetchFromGitHub {
    owner = "trikko";
    repo = "hideout";
    tag = "v${version}";
    hash = "sha256-ESpAkrl2KaKk6/crrLc/eFvSMyc3gYcTX5q1iN6EjTI=";
  };

  dubLock = ./dub-lock.json;

  postPatch = ''
    cp -r --no-preserve=mode,ownership ${gid} gid
    substituteInPlace dub.sdl \
      --replace-fail 'dependency "gid:adw1" version="~>0.9.9"' \
      'dependency "gid:adw1" path="gid"'
  '';

  nativeBuildInputs = [
    glib
    pkg-config
  ];

  buildInputs = [
    libadwaita
    gnupg
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 hideout $out/bin/hideout
    install -Dm644 hideout_icon.svg \
      $out/share/icons/hicolor/scalable/apps/it.andreafontana.hideout.svg
    install -Dm644 it.andreafontana.hideout.desktop \
      $out/share/applications/it.andreafontana.hideout.desktop
    install -Dm644 data/it.andreafontana.hideout.metainfo.xml \
      $out/share/metainfo/it.andreafontana.hideout.metainfo.xml
    install -Dm644 LICENSE $out/share/licenses/hideout/LICENSE

    runHook postInstall
  '';

  meta = {
    description = "Minimal and secure desktop application for file encryption and decryption";
    homepage = "https://github.com/trikko/hideout";
    license = lib.licenses.mit;
    mainProgram = "hideout";
    platforms = lib.platforms.linux;
  };
}
