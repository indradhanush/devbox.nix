---
name: nix-programmer
description: Write idiomatic Nix and home-manager configuration in this repo (devbox). Use whenever creating, editing, or reviewing Nix (`.nix`) files — `flake.nix`, `home.nix`, package lists, shell/program integration. Covers preferring `programs.*` modules over manual wiring, `initContent` over the deprecated `initExtra`, `let`-bindings for repeated snippets, and verification with alejandra/statix/deadnix via the repo's `just` targets. Trigger on "edit home.nix", "add a package", "configure home-manager", "enable zsh/zoxide/direnv via home-manager", or any work inside a `.nix` file here.
---

# Nix Programmer (devbox)

Conventions for writing Nix and home-manager config in this repo. Nix is declarative: describe the desired end state and let the module system wire it up. Reach for a module before hand-rolling shell init or PATH edits.

The repo's `CLAUDE.md` owns the mandatory change workflow (fmt → check → sync → verify on the VM → commit). This skill covers *how to write the Nix*; that workflow covers *how to apply and verify it*. When they overlap, the repo `CLAUDE.md` wins.

## Prefer home-manager modules over manual wiring

If home-manager ships a `programs.<tool>` module, use it. It installs the package **and** wires the shell integration correctly, instead of you maintaining a package entry plus a hand-written `eval "$(tool init …)"` that silently drifts.

Good:

```nix
programs.zoxide.enable = true; # installs zoxide + injects `z`/`zi` into zsh & bash
```

Bad:

```nix
home.packages = [pkgs.zoxide];
programs.zsh.initContent = lib.mkAfter ''eval "$(zoxide init zsh)"'';
```

Same for `programs.git`, `programs.fzf`, `programs.direnv`, etc. Drop to manual `home.packages` + init only when no module exists.

## Shell init: the right hook and the right file

home-manager generates the shell rc files. Put init in the matching option, not in a stray file:

- **zsh**: `programs.zsh.initContent` — `initExtra` is **deprecated**. Wrap with `lib.mkAfter`/`lib.mkOrder` to control ordering.
- **bash**: `programs.bash.initExtra` (still current for bash).

```nix
programs.zsh.initContent = lib.mkAfter ''
  PROMPT='%m %~ %# '
'';
```

**Interactive vs non-interactive matters.** `initContent`/`initExtra` land in `.zshrc`/`.bashrc`, sourced for **interactive** shells only. A non-interactive `ssh host "cmd"` sources only `.zshenv` (zsh). So anything `cmd` needs on `PATH` must go in `home.sessionVariables` / `programs.zsh.envExtra` (.zshenv), not `initContent`. If a tool "works when I SSH in but not when I run it over SSH non-interactively", this is why.

## DRY repeated snippets with `let`

When the same store-path-interpolated line appears in more than one place (e.g. bash and zsh both source the same init script), bind it once:

```nix
{
  pkgs,
  lib,
  ...
}: let
  asdfInit = ". ${pkgs.asdf-vm}/etc/profile.d/asdf-prepare.sh";
in {
  programs.bash.initExtra = asdfInit;
  programs.zsh.initContent = lib.mkAfter asdfInit;
}
```

This kills drift between the two copies.

## Don't hand-format or hand-lint

Tooling owns style. Never reformat by hand or fight the formatter:

- `alejandra` — formatter (canonical Nix style)
- `statix` — linter (anti-patterns, simplifications)
- `deadnix` — dead / unused-binding detector

This repo wires them into `just fmt` and `just check`. Use those, not the tools directly, so flags stay consistent.

## Flakes

- `flake.lock` pins inputs. Update deliberately with `nix flake update`, not as a side effect of an unrelated change. (`just sync` pulls `flake.lock` back from the VM — re-run `just fmt && just check` afterwards.)
- `system` (`x86_64-linux`) and the hardcoded username (`ubuntu`) are load-bearing — they must match the VM. Don't change them casually; if you must, update every place they appear (see the repo `CLAUDE.md`).

## Verification before claiming done

```bash
just fmt && just check  # format + lint (alejandra/statix/deadnix) + nix flake check
just sync               # apply to the VM
```

`nix flake check` only proves the config *evaluates* — not that it *behaves*. After `just sync`, **verify the actual behavior on the VM** (SSH in, run the tool, inspect the config file) before declaring done. Report the command and outcome.

## Self-improvement (this skill rewrites itself)

This skill is meant to get better each time it is used. After you finish a Nix task with this skill:

1. **Decide if there is a lesson.** Capture one only if your *first* attempt was wrong and a later one fixed it: a deprecation you hit (like `initExtra`), an eval/build error, wrong runtime behavior, or `just check`/`just sync` rejecting your first cut. **Do not** log first-try successes, typos, or one-off flukes.
2. **Sequence it after the real work.** Implement, verify, and commit the actual Nix change *first*. The skill update is always a **separate commit, made after** the Nix change has landed.
3. **Append, don't rewrite.** Add one dated line to `## Lessons learned` below: problem → fix, and how it was caught. Keep core guidance intact — never silently rewrite a working convention.
4. **Commit it separately** to this repo:

   ```bash
   git -C /Users/dhanush/pf9/devbox add .claude/skills/nix-programmer/SKILL.md
   # then use the `commit` skill (model: haiku):
   #   docs(nix-programmer): lesson on <topic>
   ```

   One lesson per commit.
5. **Promote when it recurs.** If the same lesson shows up again or clearly generalizes, move it up into the relevant convention section and delete the line from `## Lessons learned`.

## Lessons learned

<!-- Append-only field notes (newest last). Promote into the body above when a
     lesson recurs or generalizes, then delete the line here. See Self-improvement. -->

- 2026-06-11: `programs.zsh.initExtra` is deprecated; use `programs.zsh.initContent` (wrap with `lib.mkAfter`). Caught via a home-manager eval warning during `just sync`.
