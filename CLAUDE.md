# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Reproducible dev box configuration for an Ubuntu 24.04 VM. Nix + home-manager manages dev tools (`go`, `make`). Docker is managed separately via the official apt repo because its daemon requires systemd integration unavailable to home-manager on non-NixOS.

## Architecture

- `flake.nix` — declares nixpkgs + home-manager inputs; exports a single `homeConfigurations.ubuntu` output
- `home.nix` — the actual package list; edit this to add/remove Nix-managed tools
- `bootstrap.sh` — idempotent one-shot setup script; runs all four steps in order: install Nix → apply home-manager → install Docker → add user to docker group

The flake targets `x86_64-linux` and hardcodes username `ubuntu`. Both must match the VM.

## Change workflow (mandatory)

For every change to any file in this repo (`home.nix`, `flake.nix`, `bootstrap.sh`, etc.):

1. Make the change
2. Run `just fmt && just check` to catch formatting/lint issues early
3. Run `just sync` — syncs to the VM, applies home-manager, pulls back `flake.lock`
4. If `just sync` fails, fix the issue and go back to step 3
5. **Verify the behavior on the VM** — SSH in and confirm the specific change took effect (e.g. check `/etc/shells`, run the installed tool, inspect config files). Do not assume sync success means the change is correct.
6. Only commit once `just sync` succeeds **and** the behavior is verified

```bash
just fmt && just check   # format and lint
just sync                # apply to VM — must succeed before committing
just fmt && just check   # re-run after sync pulls back flake.lock
ssh ubuntu@$VM_IP        # verify behavior on the VM
# then commit
```

Set `VM_IP` in `.envrc` (see `.envrc.example`) before running `just sync`.

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
