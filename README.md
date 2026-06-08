# devbox

Reproducible dev box configuration for an Ubuntu 24.04 VM using Nix + home-manager.

## What it installs

| Tool | Manager |
|---|---|
| go, make, git, gh, asdf | Nix (home-manager) |
| docker | apt (official Docker CE repo) |

## Setup

On a fresh Ubuntu 24.04 VM:

```bash
git clone <repo> devbox && cd devbox && bash bootstrap.sh
```

Re-login after bootstrap for docker group membership to take effect.

## Applying changes

After editing `home.nix`:

```bash
home-manager switch --flake .#ubuntu
```

## Adding packages

Search:

```bash
nix search nixpkgs <name>
```

Add to `home.packages` in `home.nix`, then apply.

## Updating

```bash
nix flake update
home-manager switch --flake .#ubuntu
```
