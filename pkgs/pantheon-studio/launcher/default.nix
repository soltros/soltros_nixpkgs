{ lib, pantheon, xvfb-run, dbus, glib }:
assert lib.assertMsg (pantheon.wingpanel-applications-menu.version == "8.0.4")
  "Pantheon Studio launcher integration currently supports applications-menu 8.0.4.";
pantheon.wingpanel-applications-menu.overrideAttrs (old: {
  pname = "wingpanel-applications-menu-studio";
  nativeBuildInputs = old.nativeBuildInputs ++ [ xvfb-run dbus glib ];
  patches = (old.patches or [ ]) ++ [ ./studio-launcher.patch ];
  postPatch = (old.postPatch or "") + ''
    cp ${./test-launcher.vala} src/test-launcher.vala
    cat ${./test-meson.build} >> src/meson.build
    substituteInPlace src/meson.build --replace-fail @dbus-config@ ${dbus}/share/dbus-1/session.conf
    cat ${../src/preferences.vala} ${./StudioFolder.vala} >> src/Indicator.vala
  '';
  preCheck = (old.preCheck or "") + ''
    mkdir -p studio-schemas
    cp ../data/*.gschema.xml studio-schemas/
    glib-compile-schemas studio-schemas
  '';
  postInstall = (old.postInstall or "") + ''
    mkdir -p $out/share/pantheon-studio
    touch $out/share/pantheon-studio/launcher-integration-v1
  '';
})
