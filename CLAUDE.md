# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Reproducible dev box configuration for an Ubuntu 24.04 VM. Nix + home-manager manages dev tools (`go`, `make`). Docker is managed separately via the official apt repo because its daemon requires systemd integration unavailable to home-manager on non-NixOS.

## Architecture

- `flake.nix` — declares nixpkgs + home-manager inputs; exports a single `homeConfigurations.ubuntu` output
- `home.nix` — the actual package list; edit this to add/remove Nix-managed tools
- `bootstrap.sh` — idempotent one-shot setup script; runs all four steps in order: install Nix → apply home-manager → install Docker → add user to docker group

The flake targets `x86_64-linux` and hardcodes username `ubuntu`. Both must match the VM.

## Verification (mandatory)

Every change to `home.nix` or `flake.nix` must be tested on the VM before the change is considered done.

Set `VM_IP` in `.env` (see `.env.example`), then:

```bash
just sync
```

This syncs local changes, applies home-manager on the VM, and pulls `flake.lock` back.

## Before committing

```bash
just fmt    # auto-format all files
just check  # run all CI checks locally
```

On macOS, if `nix` is not in your shell PATH, source the profile first:
```bash
source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
```

## Common commands

Apply a changed `home.nix` (after the initial bootstrap):
```bash
home-manager switch --flake .#ubuntu
```

Update all flake inputs and re-pin `flake.lock`:
```bash
nix flake update
home-manager switch --flake .#ubuntu
```

Re-run bootstrap on a new VM (idempotent — safe to run again):
```bash
bash bootstrap.sh
```

## Adding packages

Edit `home.nix`. Search for a package name:
```bash
nix search nixpkgs <name>
```

Then apply:
```bash
home-manager switch --flake .#ubuntu
```

## Changing the VM username

Two places must stay in sync: `home.username` / `home.homeDirectory` in `home.nix`, and the `homeConfigurations` key in `flake.nix`.
