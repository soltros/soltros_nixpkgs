{ lib
, stdenv
, fetchFromGitHub
, python3
, meson
, ninja
, pkg-config
, gettext
, glib
, gobject-introspection
, wrapGAppsHook4
, gtk4
, libadwaita
, libportal-gtk4
, appstream
, desktop-file-utils
, xvfb-run
}:
let
  python = python3.withPackages (ps: [ ps.pygobject3 ps.requests ps.packaging ]);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "addwater";
  version = "1.3";

  src = fetchFromGitHub {
    owner = "largestgithubuseronearth";
    repo = "addwater";
    tag = "v${finalAttrs.version}";
    hash = "sha256-ynfBP3yFw4g8ebnKKyQDdmCB7APYVgvuedcu/x5lO9w=";
  };

  nativeBuildInputs = [
    python meson ninja pkg-config gettext glib gobject-introspection
    wrapGAppsHook4 appstream desktop-file-utils
  ];
  buildInputs = [ gtk4 libadwaita libportal-gtk4 ];
  nativeInstallCheckInputs = [ xvfb-run ];

  # Upstream defaults to the development app ID. Ship the stable release.
  mesonFlags = [ "-Dprofile=default" ];

  postPatch = ''
    # Outside Flatpak the host configuration directory is XDG_CONFIG_HOME.
    substituteInPlace src/apps/firefox/firefox_paths.py \
      --replace-fail 'environ.get("HOST_XDG_CONFIG_HOME", expanduser("~/.config"))' \
      'environ.get("HOST_XDG_CONFIG_HOME", environ.get("XDG_CONFIG_HOME", expanduser("~/.config")))'
    # Portal-created autostart entries must also work after a nix run invocation.
    substituteInPlace src/preferences.py \
      --replace-fail '["addwater", "--quick-update"]' \
      '["${placeholder "out"}/bin/addwater", "--quick-update"]'
    # Allow non-strict INI parsing for profiles.ini to support duplicate options (e.g. Waterfox/Firefox profiles).
    substituteInPlace src/apps/firefox/firefox_details.py \
      --replace-fail 'cfg = ConfigParser()' 'cfg = ConfigParser(strict=False)'
  '';

  doCheck = true;
  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    export XDG_CONFIG_HOME="$TMPDIR/addwater-config"
    export XDG_CACHE_HOME="$TMPDIR/addwater-cache"
    export XDG_DATA_HOME="$TMPDIR/addwater-data"
    export GSETTINGS_BACKEND=memory
    export GTK_A11Y=none
    export GSK_RENDERER=cairo
    mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME" "$XDG_DATA_HOME"
    "$out/bin/addwater" --help > "$TMPDIR/addwater-help"
    grep -q -- --quick-update "$TMPDIR/addwater-help"
    makeWrapper ${python}/bin/python3 "$TMPDIR/addwater-smoke" \
      --prefix PYTHONPATH : "$out/share/addwater" \
      "''${gappsWrapperArgs[@]}"
    xvfb-run -a "$TMPDIR/addwater-smoke" ${./smoke.py} "$out"
    runHook postInstallCheck
  '';

  meta = {
    description = "Install and configure the Firefox GNOME Theme";
    homepage = "https://github.com/largestgithubuseronearth/addwater";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
    mainProgram = "addwater";
  };
})
