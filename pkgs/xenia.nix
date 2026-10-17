{
  lib,
  llvmPackages_20,
  fetchFromGitHub,
  cmake,
  ninja,
  premake5,
  pkg-config,
  python3,
  gtk3,
  SDL2,
  alsa-lib,
  lz4,
  libx11,
  libxcb,
  vulkan-loader,
  wrapGAppsHook3,
  desktop-file-utils,
  xvfb-run,
  util-linux,
}:

llvmPackages_20.stdenv.mkDerivation (finalAttrs: {
  pname = "xenia";
  version = "95a5c3e";

  src = fetchFromGitHub {
    owner = "xenia-project";
    repo = "xenia";
    rev = "95a5c3ee250f80c3b9d139658649d9ffb6db3eec";
    forceFetchGit = true;
    fetchSubmodules = false;
    # Match upstream's Linux build: only first-level build dependencies, without
    # Windows toolchains or recursively downloading FidelityFX sample media.
    postCheckout = ''
      git -C "$out" submodule update --init --depth 1 -- \
        third_party/{xbyak,imgui,catch,premake-core,snappy,premake-export-compile-commands,discord-rpc,rapidjson,aes_128,capstone,cpptoml,cxxopts,SDL2,utfcpp,fmt,disruptorplus,premake-cmake,date,xxhash,FFmpeg,premake-androidndk,FidelityFX-CAS,FidelityFX-FSR,Vulkan-Headers,glslang,SPIRV-Tools,VulkanMemoryAllocator}
    '';
    hash = "sha256-be7ORLJMC22l2w9EzovS81lN/tW0e78vEsNw/52V84k=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    premake5
    pkg-config
    python3
    SDL2
    llvmPackages_20.bintools
    llvmPackages_20.llvm
    wrapGAppsHook3
  ];
  buildInputs = [
    gtk3
    SDL2
    alsa-lib
    lz4
    libx11
    libxcb
  ];

  postPatch = ''
    # Newer Clang toolchains emit additional warnings in bundled third-party headers.
    substituteInPlace premake5.lua \
      --replace-fail '"FatalWarnings",' ""
    # These libraries are loaded by name, outside the normal ELF dependency lookup.
    substituteInPlace src/xenia/ui/vulkan/vulkan_instance.cc \
      --replace-fail '"libvulkan.so.1"' '"${lib.getLib vulkan-loader}/lib/libvulkan.so.1"'
    substituteInPlace src/xenia/base/system_gnulinux.cc \
      --replace-fail '"libSDL2.so"' '"${lib.getLib SDL2}/lib/libSDL2.so"'
  '';

  # Nix hardening marks libc I/O results as warn_unused_result. Keep the
  # diagnostics without treating upstream's ignored results as build errors.
  env.NIX_CFLAGS_COMPILE = "-Wno-error=unused-result -Wno-deprecated-literal-operator -Wno-integer-overflow";
  env.CXXFLAGS = "-include cstdint";

  configurePhase = ''
    runHook preConfigure

    mkdir -p build
    premake5 --scripts=third_party/premake-core --file=premake5.lua --os=linux --cc=clang --test-suite-mode=combined --verbose cmake
    cat > build/version.h <<EOF
    #ifndef GENERATED_VERSION_H_
    #define GENERATED_VERSION_H_
    #define XE_BUILD_BRANCH "master"
    #define XE_BUILD_COMMIT "${finalAttrs.src.rev}"
    #define XE_BUILD_COMMIT_SHORT "${finalAttrs.version}"
    #define XE_BUILD_DATE "1970-01-01"
    #endif  // GENERATED_VERSION_H_
    EOF

    cmake -S build -B build/cmake-Release -G Ninja -DCMAKE_BUILD_TYPE=Release

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build build/cmake-Release -j$NIX_BUILD_CORES --target xenia-app
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 build/bin/Linux/Release/xenia $out/bin/xenia
    mkdir -p $out/share/applications
    cat > $out/share/applications/xenia.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=Xenia
    GenericName=Xbox 360 Emulator
    Comment=Xbox 360 Emulator Research Project
    Exec=xenia %f
    Icon=xenia
    Terminal=false
    Categories=Game;Emulator;
    MimeType=application/x-xbox360-executable;application/x-xbox360-iso;
    StartupNotify=true
    StartupWMClass=xenia
    EOF
    for size in 16 32 48 64 128 256 512 1024; do
      install -Dm644 assets/icon/$size.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/xenia.png
    done
    install -Dm644 LICENSE $out/share/licenses/xenia/LICENSE
    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    desktop-file-utils
    xvfb-run
    util-linux
  ];
  installCheckPhase = ''
    runHook preInstallCheck
    export HOME="$TMPDIR/xenia-home"
    export XDG_CACHE_HOME="$HOME/.cache"
    export GDK_BACKEND=x11
    mkdir -p "$XDG_CACHE_HOME"
    # Xenia requires both an X display and a terminal even for --help.
    xvfb-run -a timeout 30 script -q -e \
      -c "$out/bin/xenia --help" "$TMPDIR/xenia-help" < /dev/null
    grep -q 'Usage:' "$TMPDIR/xenia-help"
    desktop-file-validate "$out/share/applications/xenia.desktop"
    runHook postInstallCheck
  '';

  meta = {
    description = "Experimental Xbox 360 emulator";
    homepage = "https://github.com/xenia-project/xenia";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    mainProgram = "xenia";
  };
})
