# devbox

Reproducible dev box for Ubuntu 24.04.

## Setup

```bash
git clone <repo> devbox && cd devbox && bash bootstrap.sh
```

Re-login after for docker group membership.

## Apply changes

```bash
home-manager switch --flake .#ubuntu
```

## Local development (macOS)

Enable nix experimental features once so `just fmt` and `just check` work without extra flags:

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

CI sets this automatically via `cachix/install-nix-action`.
