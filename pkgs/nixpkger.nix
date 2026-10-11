{ lib, stdenvNoCC, python3, makeWrapper }:

stdenvNoCC.mkDerivation {
  pname = "nixpkger";
  version = "unstable-2026-10-10";

  # A fixed commit allows the update scanner to detect upstream changes.
  src = builtins.fetchGit {
    url = "https://github.com/soltros/nixpkger.git";
    rev = "fa3f74fb49fb38c82a878076036e3cf752e842d0";
  };

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/nixpkger" "$out/bin"
    cp -r nixpkger_core "$out/libexec/nixpkger/"
    cp main.py nixpkger "$out/libexec/nixpkger/"
    makeWrapper "${python3}/bin/python3" "$out/bin/nixpkger" \
      --add-flags "$out/libexec/nixpkger/nixpkger" \
      --prefix PYTHONPATH : "$out/libexec/nixpkger"
    runHook postInstall
  '';

  meta = {
    description = "CLI manager for NixOS package modules and flakes";
    homepage = "https://github.com/soltros/nixpkger";
    license = lib.licenses.gpl3Only;
    mainProgram = "nixpkger";
    platforms = lib.platforms.linux;
  };
}
