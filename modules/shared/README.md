## Shared
Much of the macOS configuration is actually found here.

This configuration is imported by the darwin module. Some configuration examples include `git`, `zsh`, `vim`, and `tmux`.

## Layout
```
.
├── config             # Config files not written in Nix
├── cachix             # Defines cachix, a global cache for builds
├── default.nix        # Defines how we import overlays
├── home-manager.nix   # The goods; most all shared config lives here
├── packages.nix       # List of packages to share

```
