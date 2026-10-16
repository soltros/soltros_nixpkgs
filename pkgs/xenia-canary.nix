{
  lib,
  llvmPackages_20,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  python3,
  glslang,
  spirv-tools,
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
  pname = "xenia-canary";
  version = "583528e";

  src = fetchFromGitHub {
    owner = "xenia-canary";
    repo = "xenia-canary";
    rev = "583528e8e3d763a86a37aa848a7f4019e579362a";
    forceFetchGit = true;
    fetchSubmodules = false;
    # Match upstream's Linux build: only first-level build dependencies, without
    # Windows toolchains or recursively downloading FidelityFX sample media.
    postCheckout = ''
      git -C "$out" submodule update --init --depth 1 -- \
        third_party/{xbyak,imgui,catch,snappy,discord-rpc,rapidjson,aes_128,capstone,tomlplusplus,cxxopts,SDL2,utfcpp,fmt,disruptorplus,date,xxhash,FFmpeg,FidelityFX-CAS,FidelityFX-FSR,Vulkan-Headers,glslang,SPIRV-Tools,VulkanMemoryAllocator,zstd,zarchive,tabulate,rapidcsv,zlib-ng,pugixml,libusb,cpplint}
    '';
    hash = "sha256-m7nrcgo7qZ7CnaTcnwtnE5N1CVMOzaNkXGKrwrQQabU=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    python3
    glslang
    spirv-tools
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
    # Use the Nix linker wrapper so runtime library paths are recorded.
    substituteInPlace CMakeLists.txt \
      --replace-fail '-fuse-ld=lld' '-fuse-ld=${llvmPackages_20.bintools}/bin/ld.lld'
    # These libraries are loaded by name, outside the normal ELF dependency lookup.
    substituteInPlace src/xenia/ui/vulkan/vulkan_instance.cc \
      --replace-fail '"libvulkan.so.1"' '"${lib.getLib vulkan-loader}/lib/libvulkan.so.1"'
    substituteInPlace src/xenia/base/system_gnulinux.cc \
      --replace-fail '"libSDL2.so"' '"${lib.getLib SDL2}/lib/libSDL2.so"'
  '';

  preConfigure = ''
    # CMake is invoked directly; generate the header normally written by xb.
    mkdir -p build
    cat > build/version.h <<EOF
    #define XE_BUILD_BRANCH "canary_experimental"
    #define XE_BUILD_COMMIT "${finalAttrs.src.rev}"
    #define XE_BUILD_COMMIT_SHORT "${finalAttrs.version}"
    #define XE_BUILD_DATE "1970-01-01"
    EOF
  '';

  # Nix hardening marks libc I/O results as warn_unused_result. Keep the
  # diagnostics without treating upstream's ignored results as build errors.
  env.NIX_CFLAGS_COMPILE = "-Wno-error=unused-result";

  cmakeFlags = [
    "-DXENIA_BUILD_TESTS=OFF"
    "-DXENIA_BUILD_MISC=OFF"
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 bin/Linux/xenia_canary $out/bin/xenia-canary
    install -Dm644 ../assets/xenia_canary.desktop $out/share/applications/xenia-canary.desktop
    substituteInPlace $out/share/applications/xenia-canary.desktop \
      --replace-fail 'Exec=xenia_canary' 'Exec=xenia-canary'
    for size in 16 32 48 64 128 256 512 1024; do
      install -Dm644 ../assets/icon/$size.png \
        $out/share/icons/hicolor/''${size}x''${size}/apps/xenia_canary.png
    done
    install -Dm644 ../LICENSE $out/share/licenses/xenia-canary/LICENSE
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
      -c "$out/bin/xenia-canary --help" "$TMPDIR/xenia-help" < /dev/null
    grep -q 'Usage:' "$TMPDIR/xenia-help"
    desktop-file-validate "$out/share/applications/xenia-canary.desktop"
    runHook postInstallCheck
  '';

  meta = {
    description = "Experimental Xbox 360 emulator, Canary branch";
    homepage = "https://github.com/xenia-canary/xenia-canary";
    license = lib.licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    mainProgram = "xenia-canary";
  };
})
