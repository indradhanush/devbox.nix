# Run all CI checks
check:
    nix flake check
    nix run nixpkgs#alejandra -- --check .
    nix run nixpkgs#statix -- check .
    nix run nixpkgs#deadnix -- --fail .
    nix run nixpkgs#shfmt -- -i 2 -d bootstrap.sh
    nix run nixpkgs#shellcheck -- bootstrap.sh

# Auto-format all files
fmt:
    nix run nixpkgs#alejandra -- .
    nix run nixpkgs#shfmt -- -i 2 -w bootstrap.sh
