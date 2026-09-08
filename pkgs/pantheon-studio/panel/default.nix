{ lib, pantheon }:
assert lib.assertMsg (pantheon.wingpanel.version == "8.0.4")
  "Pantheon Studio panel integration currently supports Wingpanel 8.0.4.";
pantheon.wingpanel.overrideAttrs (old: {
  pname = "wingpanel-studio";
  patches = (old.patches or [ ]) ++ [ ./studio-panel.patch ];
  postPatch = (old.postPatch or "") + ''
    cat ${../src/preferences.vala} ${./StudioPanel.vala} >> src/Application.vala
  '';
})
