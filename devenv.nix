{ pkgs, lib, config, inputs, ... }:

{
  packages = [
    pkgs.git
  ];

  # Zig 0.16-dev is managed via zigup, not nixpkgs (nixpkgs has 0.15.2)
  languages = {
    nix.enable = true;
  };

  claude.code.enable = true;

  # Override Nix's Apple SDK paths so Zig can find macOS frameworks
  env.DEVELOPER_DIR = if pkgs.stdenv.isDarwin then "/Applications/Xcode.app/Contents/Developer" else "";
  env.SDKROOT = if pkgs.stdenv.isDarwin then "/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk" else "";

  tasks."axios:build" = {
    exec = "zig build";
  };

  tasks."axios:run" = {
    exec = "zig build run";
    after = [ "axios:build" ];
  };

  tasks."axios:test" = {
    exec = "zig build test";
  };

  tasks."axios:release" = {
    exec = "zig build -Doptimize=ReleaseSafe";
  };

  tasks."axios:clean" = {
    exec = "rm -rf zig-out .zig-cache";
  };

  tasks."axios:site" = {
    exec = "python3 -m http.server 8080 -d site";
  };

  enterShell = ''
    echo "Axios — Zig $(zig version) + raylib"
    echo ""
    echo "Tasks:"
    echo "  devenv tasks run axios:build    - Build the game"
    echo "  devenv tasks run axios:run      - Build and run"
    echo "  devenv tasks run axios:test     - Run tests"
    echo "  devenv tasks run axios:release  - Build optimized release"
    echo "  devenv tasks run axios:clean    - Remove build artifacts"
    echo "  devenv tasks run axios:site     - Preview website at localhost:8080"
    echo ""
    echo "Steam: zig build -Dsteam=true (requires SDK in vendor/steamworks/sdk/)"
  '';

  enterTest = ''
    echo "Running Axios test suite..."
    zig build test
  '';

  # See full reference at https://devenv.sh/reference/options/
}
