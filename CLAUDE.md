# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a macOS configuration repository built on [nix-darwin](https://github.com/LnL7/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager). It uses Nix Flakes exclusively and follows a modular architecture. Nix must already be installed on the machine.

## Key Commands

### Building and Switching Configurations (macOS)

```bash
# Test build without switching
nix run .#build

# Build and switch to new configuration
nix run .#build-switch

# Rollback to previous generation
nix run .#rollback

# Clean up old generations (frees disk space)
nix run .#clean
```

**Important:** After making changes to any Nix configuration file, run `nix run .#build-switch`.

### Development Commands

```bash
# Update flake inputs
nix flake update

# Check flake
nix flake check

# Format Nix files
nixpkgs-fmt .

# Lint Nix code (runs in CI)
statix check
```

## Architecture

### Directory Structure
- `hosts/darwin/default.nix` - macOS (nix-darwin) system configuration
- `modules/` - Modular configuration components:
  - `shared/` - Configurations shared across machines (packages, home-manager, fonts)
  - `darwin/` - macOS-specific packages, Homebrew integration, and dock
- `overlays/` - Auto-loading Nix overlays (any .nix file here runs automatically)
- `apps/aarch64-darwin/` - Build and deployment scripts (Apple Silicon only)

### Key Patterns

1. **Module composition**: macOS modules extend the shared configuration. `modules/darwin/packages.nix` imports `modules/shared/packages.nix` and appends macOS-only packages.

2. **Auto-loading Overlays**: Drop any `.nix` file in `overlays/` and it loads automatically via the loader in `modules/shared/default.nix`.

3. **Secrets Management**: Uses `agenix` for encrypted secrets, defined in `modules/darwin/secrets.nix` (sourced from the private `secrets` flake input).

4. **Home Manager Integration**: User-level configuration lives in `modules/shared/home-manager.nix` (shell, git, editor, tmux) and `modules/darwin/home-manager.nix` (dock, macOS home-manager wiring).

### Important Configuration Files

- `flake.nix` - Main entry point defining inputs and the `darwinConfigurations` output
- `hosts/darwin/default.nix` - macOS system configuration
- `modules/shared/packages.nix` - Cross-platform CLI/package definitions
- `modules/darwin/packages.nix` - macOS-only packages
- `modules/darwin/casks.nix` - Homebrew casks (GUI apps)
- `modules/shared/home-manager.nix` - Shell, editor, and tool configurations

## Working with This Repository

### CRITICAL: Git Tracking Requirement
**IMPORTANT:** When creating ANY new file in this repository (overlays, modules, configurations, etc.), you MUST add it to git with `git add` before running `nix run .#build-switch`. Nix flakes only see files tracked by git, so untracked files will cause build failures.

### Adding Packages
1. **Cross-platform CLI packages**: Add to `modules/shared/packages.nix`
2. **macOS-only packages**: Add to `modules/darwin/packages.nix`
3. **Homebrew casks (GUI apps)**: Add to `modules/darwin/casks.nix`

### Creating Overlays
Create a new `.nix` file in `overlays/`. It will be loaded automatically.

### Modifying Shell Configuration
Edit `modules/shared/home-manager.nix` for:
- Zsh configuration and aliases
- Git settings
- Editor (`EDITOR`/`VISUAL`) and prompt (starship)
- Tmux settings
- SSH configuration

### System-specific Changes
- **macOS system settings**: `hosts/darwin/default.nix`
- **Dock**: `modules/darwin/home-manager.nix` (`local.dock`)

## Testing Changes

Always test configuration changes before applying:
1. Run `nix flake check` to validate the flake
2. Run `nix run .#build` to test the build without switching
3. Review changes before running `nix run .#build-switch`
