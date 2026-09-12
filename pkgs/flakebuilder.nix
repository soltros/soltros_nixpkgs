{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "flakebuilder";
  version = "unstable-2026-09-10";

  src = fetchFromGitHub {
    owner = "soltros";
    repo = "Flakebuilder";
    rev = "9254fc1";
    hash = "sha256-ypTMVSAKbreBddw/IOHXMOa1+gj+2NQveElINLfXCVQ=";
  };

  vendorHash = "sha256-uwBJAqN4sIepiiJf9lCDumLqfKJEowQO2tOiSWD3Fig=";

  ldflags = [ "-s" "-w" ];
  subPackages = [ "." ];

  postInstall = ''
    mv $out/bin/Flakebuilder $out/bin/flakebuilder
  '';

  meta = {
    description = "Build a single NixOS flake from selectable configuration bits";
    homepage = "https://github.com/soltros/Flakebuilder";
    license = lib.licenses.gpl3Only;
    mainProgram = "flakebuilder";
    platforms = lib.platforms.linux;
  };
}
