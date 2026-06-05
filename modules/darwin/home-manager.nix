{ config, pkgs, lib, home-manager, user, fullName, email, ... }:

{
  imports = [
    ./dock
  ];

  users.users.${user} = {
    name     = "${user}";
    home     = "/Users/${user}";
    isHidden = false;
    shell    = pkgs.zsh;
  };

  homebrew = {
    # This is a module from nix-darwin
    # Homebrew is *installed* via the flake input nix-homebrew

    # These app IDs are from using the mas CLI app
    # mas = mac app store
    # https://github.com/mas-cli/mas
    #
    # $ nix shell nixpkgs#mas
    # $ mas search <app name>
    #
    enable = true;
    casks  = pkgs.callPackage ./casks.nix {};
    #masApps = {
    #  "hidden-bar"   = 1452453066;
    #  "wireguard"    = 1451685025;
    #};
  };

  home-manager = {
    useGlobalPkgs = true;
    users.${user} = { pkgs, config, lib, ... }:
      {
        home = {
          enableNixpkgsReleaseCheck = false;
          packages = pkgs.callPackage ./packages.nix {};
          stateVersion = "23.11";
        };
        programs = {} // import ../shared/home-manager.nix { inherit config pkgs lib user fullName email; };
        manual.manpages.enable = false;
      };
  };

  # Fully declarative dock using the latest from Nix Store
  local.dock = {
    enable   = true;
    username = user;
    entries  = [
      { path = "/System/Applications/Messages.app/"; }
      { path = "${pkgs.ghostty-bin}/Applications/Ghostty.app/"; }
      { path = "/System/Applications/Music.app/"; }
      { path = "/System/Applications/Photos.app/"; }
      { path = "/System/Applications/Photo Booth.app/"; }
      { path = "/System/Applications/TV.app/"; }
      { path = "/Applications/Discord.app/"; }
      { path = "/System/Applications/Home.app/"; }
      {
        path    = "${config.users.users.${user}.home}/.local/share/";
        section = "others";
        options = "--sort name --view grid --display folder";
      }
      {
        path    = "${config.users.users.${user}.home}/.local/share/downloads";
        section = "others";
        options = "--sort name --view grid --display stack";
      }
    ];
  };
}
