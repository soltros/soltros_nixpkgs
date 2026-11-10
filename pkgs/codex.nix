{ lib, stdenv, fetchurl, autoPatchelfHook, alsa-lib }:
let
  version = "0.167.0";
  targets = {
    x86_64-linux = { target = "x86_64-unknown-linux-musl"; hash = "sha256-O7916D3mtYrtKPLPbjOtQj7DH9RwChRXuUvlV+pafG4="; };
    aarch64-linux = { target = "aarch64-unknown-linux-musl"; hash = "sha256-DeJh7PHn8wKKeVLwP8ogk/dJJ304WQt4uzL4VndWu7c="; };
  };
  platform = targets.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation {
  pname = "codex";
  inherit version;
  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-${platform.target}.tar.gz";
    inherit (platform) hash;
  };
  sourceRoot = ".";
  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib alsa-lib ];
  dontConfigure = true;
  dontBuild = true;
  # Preserve upstream's static executables and package-relative runtime layout.
  dontStrip = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -a bin codex-package.json codex-path codex-resources "$out/"
    runHook postInstall
  '';
  preFixup = ''
    addAutoPatchelfSearchPath "$out/codex-resources/voice/lib"
  '';
  doInstallCheck = stdenv.buildPlatform.canExecute stdenv.hostPlatform;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/codex" --version | grep -F "${version}"
    runHook postInstallCheck
  '';
  meta = {
    description = "OpenAI Codex CLI, official prebuilt binary bundle";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames targets;
    mainProgram = "codex";
  };
}
