{ config, pkgs, sf-mono-liga-src, llm-agents, ... }:

{

  nixpkgs = {
    overlays = [
      # SFMono-Nerd-Font-Ligaturized: pre-patched .otf files, just copied in.
      (final: prev: {
        sf-mono-liga-bin = prev.stdenvNoCC.mkDerivation {
          pname = "sf-mono-liga-bin";
          version = "dev";
          src = sf-mono-liga-src;
          dontConfigure = true;
          installPhase = ''
            mkdir -p $out/share/fonts/opentype
            cp -R $src/*.otf $out/share/fonts/opentype/
          '';
        };
      })
      # Track current pi releases via numtide/llm-agents.nix (daily updates).
      # nixpkgs.pi-coding-agent lags; keep the attr name so packages.nix is stable.
      (final: prev: {
        pi-coding-agent =
          llm-agents.packages.${prev.stdenv.hostPlatform.system}.pi.overrideAttrs (old: {
            # Bun creates a linker-signed Mach-O, then Nix's fixup phase modifies
            # it. Re-sign it before the version check or macOS kills it (SIGKILL).
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
              prev.darwin.autoSignDarwinBinariesHook
            ];
          });
      })
      # vfkit source build dies at link on this Darwin/SDK (ld Trace/BPT trap).
      # Install the upstream-signed release binary as-is; re-codesign needs
      # codesign_allocate which isn't available under stdenvNoCC.
      (final: prev: {
        vfkit =
          let
            version = "0.6.3";
            src = prev.fetchurl {
              url = "https://github.com/crc-org/vfkit/releases/download/v${version}/vfkit";
              hash = "sha256-GdBpXUDZluw4UpoitzzaqE/2e6FfS0SScpLn/ohc7g4=";
            };
          in
          prev.stdenvNoCC.mkDerivation {
            pname = "vfkit";
            inherit version;
            dontUnpack = true;
            installPhase = ''
              mkdir -p $out/bin
              install -m755 ${src} $out/bin/vfkit
            '';
            meta = prev.vfkit.meta // {
              sourceProvenance = [ prev.lib.sourceTypes.binaryNativeCode ];
            };
          };
      })
      # watchexec source link dies with the same ld Trace/BPT trap as vfkit.
      # Ship the upstream aarch64-darwin release tarball instead.
      (final: prev: {
        watchexec =
          let
            version = "2.5.1";
            src = prev.fetchzip {
              url = "https://github.com/watchexec/watchexec/releases/download/v${version}/watchexec-${version}-aarch64-apple-darwin.tar.xz";
              hash = "sha256-6o4DGZZqEB8VZAGvh3pK7dS73fZq0vyer8+qSPw9L3c=";
            };
          in
          prev.stdenvNoCC.mkDerivation {
            pname = "watchexec";
            inherit version src;
            dontConfigure = true;
            dontBuild = true;
            installPhase = ''
              mkdir -p $out/bin $out/share/man/man1
              install -m755 watchexec $out/bin/watchexec
              install -m644 watchexec.1 $out/share/man/man1/watchexec.1
            '';
            meta = prev.watchexec.meta // {
              sourceProvenance = [ prev.lib.sourceTypes.binaryNativeCode ];
            };
          };
      })
      # starship: same ld Trace/BPT trap on Darwin source builds.
      # Upstream ships a flat aarch64-apple-darwin tarball (just the binary).
      (final: prev: {
        starship =
          let
            version = "1.26.0";
            src = prev.fetchzip {
              url = "https://github.com/starship/starship/releases/download/v${version}/starship-aarch64-apple-darwin.tar.gz";
              hash = "sha256-dJMbKSPoqn6GmCS0PHgnhx1aW4OFBnRG7r+pdYXZMBk=";
              stripRoot = false;
            };
          in
          prev.stdenvNoCC.mkDerivation {
            pname = "starship";
            inherit version src;
            dontConfigure = true;
            dontBuild = true;
            installPhase = ''
              mkdir -p $out/bin
              install -m755 starship $out/bin/starship
            '';
            meta = prev.starship.meta // {
              sourceProvenance = [ prev.lib.sourceTypes.binaryNativeCode ];
            };
          };
      })
    ];
    config = {
      allowUnfree = true;
      #cudaSupport = true;
      #cudaCapabilities = ["8.0"];
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };
  };
}
