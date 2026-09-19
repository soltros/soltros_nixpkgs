{ lib
, stdenv
, fetchFromGitHub
, glib
}:

stdenv.mkDerivation rec {
  pname = "quick-settings-tray";
  version = "1";
  uuid = "quick-settings-tray@soltros";

  src = fetchFromGitHub {
    owner = "soltros";
    repo = "quick-settings-tray";
    rev = "42992bb4d665469961295419aba769cc3b100981";
    hash = "sha256-L92FbfXQFfATaBSGcSVAqAIgs79IjNQlSmktM7phVcM=";
  };

  nativeBuildInputs = [
    glib
  ];

  buildPhase = ''
    runHook preBuild
    if [ -d schemas ]; then
      glib-compile-schemas --strict schemas
    fi
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/gnome-shell/extensions/${uuid}
    cp -r * $out/share/gnome-shell/extensions/${uuid}/
    mkdir -p $out/share/gsettings-schemas/${pname}-${version}/glib-2.0/schemas
    if [ -d schemas ]; then
      cp -r schemas/* $out/share/gsettings-schemas/${pname}-${version}/glib-2.0/schemas/
      glib-compile-schemas $out/share/gsettings-schemas/${pname}-${version}/glib-2.0/schemas/
    fi
    runHook postInstall
  '';

  passthru = {
    extensionUuid = uuid;
    extensionPortalSlug = pname;
  };

  meta = with lib; {
    description = "AppIndicator and KStatusNotifierItem icons in a contained System Tray section of Quick Settings";
    homepage = "https://github.com/soltros/quick-settings-tray";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
