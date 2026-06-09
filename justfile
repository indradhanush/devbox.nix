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

# Update flake inputs and apply to VM
update:
    nix flake update
    just sync

# Bootstrap a fresh VM (sync files first, then run bootstrap.sh)
bootstrap:
    rsync -av ./ ubuntu@$VM_IP:~/devbox/
    ssh ubuntu@$VM_IP 'bash ~/devbox/bootstrap.sh'

# Sync to VM, apply home-manager, pull back flake.lock
sync:
    rsync -av ./ ubuntu@$VM_IP:~/devbox/
    ssh ubuntu@$VM_IP 'source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh && cd ~/devbox && home-manager switch --flake .#ubuntu'
    scp ubuntu@$VM_IP:~/devbox/flake.lock ./flake.lock
