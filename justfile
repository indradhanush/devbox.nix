nix_flags := "--extra-experimental-features 'nix-command flakes'"

# Run all CI checks
check:
    nix {{nix_flags}} flake check
    nix {{nix_flags}} run nixpkgs#alejandra -- --check .
    nix {{nix_flags}} run nixpkgs#statix -- check .
    nix {{nix_flags}} run nixpkgs#deadnix -- --fail .
    nix {{nix_flags}} run nixpkgs#shfmt -- -i 2 -d bootstrap.sh
    nix {{nix_flags}} run nixpkgs#shellcheck -- bootstrap.sh

# Auto-format all files
fmt:
    nix {{nix_flags}} run nixpkgs#alejandra -- .
    nix {{nix_flags}} run nixpkgs#shfmt -- -i 2 -w bootstrap.sh
