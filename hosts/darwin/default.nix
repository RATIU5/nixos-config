{ agenix, config, pkgs, lib, user, ... }:
{
  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
    ../../modules/darwin/secrets.nix
    agenix.darwinModules.default
  ];
  # Setup user, packages, programs
  nix = {
    enable = false;
    package = pkgs.nix;
    settings = {
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };
    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
  # Load configuration that is shared across systems
  environment.systemPackages = with pkgs; [
    agenix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ] ++ (import ../../modules/shared/packages.nix { inherit pkgs; });

  # Application firewall on (allows established/signed; blocks unsolicited incoming).
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
  };

  system = {
    # Turn off NIX_PATH warnings now that we're using flakes
    checks.verifyNixPath = false;
    primaryUser = user;
    stateVersion = 4;
    defaults = {
      LaunchServices = {
        LSQuarantine = false;
      };
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;
        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;

        # 24-hour clock
        AppleICUForce24HourTime = true;

        # Text input: turn off all the "helpful" auto-corrections
        NSAutomaticSpellingCorrectionEnabled = false;  # correct spelling
        NSAutomaticCapitalizationEnabled     = false;  # capitalize words
        NSAutomaticInlinePredictionEnabled   = false;  # predictive text
        NSAutomaticPeriodSubstitutionEnabled = false;  # period on double-space
        NSAutomaticQuoteSubstitutionEnabled  = false;  # smart quotes
        NSAutomaticDashSubstitutionEnabled   = false;  # smart dashes

        # Kill UI animations
        NSAutomaticWindowAnimationsEnabled = false;  # open/close window anim
        NSWindowResizeTime = 0.001;                  # near-instant resize

        # Power-user UI
        AppleInterfaceStyle = "Dark";
        AppleKeyboardUIMode = 3;            # Tab moves focus between ALL controls
        AppleShowScrollBars = "Always";
        _HIHideMenuBar = true;              # auto-hide the menu bar
        NSTableViewDefaultSizeMode = 1;     # compact list rows
        NSNavPanelExpandedStateForSaveMode = true;   # expanded save dialog
        PMPrintingExpandedStateForPrint = true;      # expanded print dialog
        NSDocumentSaveNewDocumentsToCloud = false;   # save to disk, not iCloud
      };
      dock = {
        orientation = "right";
        autohide = true;
        autohide-delay = 0.25;            # wait 0.25s before the dock appears
        autohide-time-modifier = 0.0;     # then snap in with no slide animation
        launchanim = false;
        expose-animation-duration = 0.0;  # Mission Control animation
        static-only = true;     # only show open apps
        show-recents = false;
        mru-spaces = false;
        mouse-over-hilite-stack = true;
        tilesize = 48;
        # No pinned ("stuck") apps or folders.
        persistent-apps = [ ];
        persistent-others = [ ];
        # Disable all four hot corners (1 = no-op).
        wvous-tl-corner = 1;
        wvous-tr-corner = 1;
        wvous-bl-corner = 1;
        wvous-br-corner = 1;
      };
      finder = {
        _FXShowPosixPathInTitle = false;
        AppleShowAllExtensions = true;  # show all file extensions
        AppleShowAllFiles = true;       # show dotfiles
        ShowPathbar = true;
        ShowStatusBar = true;
        _FXSortFoldersFirst = true;     # folders before files
        QuitMenuItem = true;            # allow quitting Finder (⌘Q)
        FXEnableExtensionChangeWarning = false;
        FXDefaultSearchScope = "SCcf";  # search current folder by default
        FXPreferredViewStyle = "Nlsv";  # default to List view
        CreateDesktop = false;          # hide all desktop icons
        ShowHardDrivesOnDesktop = false;
        ShowExternalHardDrivesOnDesktop = false;
        ShowMountedServersOnDesktop = false;
        ShowRemovableMediaOnDesktop = false;
      };
      WindowManager = {
        GloballyEnabled = false;                  # Stage Manager off
        EnableStandardClickToShowDesktop = false; # clicking wallpaper won't hide windows
      };
      screencapture = {
        location = "/Users/${user}/Pictures/Screenshots";
        type = "png";
        disable-shadow = true;
      };
      screensaver = {
        askForPassword = true;
        askForPasswordDelay = 0;  # require password immediately on wake
      };
      loginwindow = {
        GuestEnabled = false;
      };
      universalaccess = {
        reduceMotion = true;        # minimize accessibility animations
        reduceTransparency = true;  # drop blur/transparency effects
      };
      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
      # Disable system keyboard shortcuts via the symbolic-hotkeys store.
      # NOTE: nix-darwin rewrites the WHOLE AppleSymbolicHotKeys dict on every
      # build-switch, so any shortcut tweaks made in System Settings are reset
      # on the next rebuild. macOS 15 window-*tiling* shortcuts use undocumented
      # IDs and are not reliably covered here — toggle those in Settings if needed.
      CustomUserPreferences = {
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            # Spotlight
            "64"  = { enabled = false; };  # Show Spotlight search
            "65"  = { enabled = false; };  # Show Finder search window
            # Screenshots
            "28"  = { enabled = false; };  # Save screen to file
            "29"  = { enabled = false; };  # Copy screen to clipboard
            "30"  = { enabled = false; };  # Save selected area to file
            "31"  = { enabled = false; };  # Copy selected area to clipboard
            "184" = { enabled = false; };  # Screenshot/recording options (shift-cmd-5)
            # Mission Control
            "32"  = { enabled = false; };  # Mission Control
            "34"  = { enabled = false; };  # Mission Control (variant)
            "36"  = { enabled = false; };  # Application windows
            "37"  = { enabled = false; };  # Application windows (variant)
            "79"  = { enabled = false; };  # Move left a space
            "80"  = { enabled = false; };  # Move left a space (variant)
            "81"  = { enabled = false; };  # Move right a space
            "82"  = { enabled = false; };  # Move right a space (variant)
          };
        };
      };
    };
    keyboard = {
      enableKeyMapping = true;
      remapCapsLockToControl = true;
    };
  };
}
