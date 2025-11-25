# darwin.nix

{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = [
    pkgs.alacritty
    pkgs.ansible
    pkgs.ast-grep
    pkgs.cargo
    pkgs.eksctl
    pkgs.fd
    pkgs.fish
    pkgs.fzf
    pkgs.git
    pkgs.gnupg
    pkgs.go
    pkgs.hugo
    pkgs.kubernetes-helm
    pkgs.keepassxc
    pkgs.lazygit
    pkgs.lazydocker
    pkgs.lua
    pkgs.lua52Packages.luarocks
    pkgs.minikube
    pkgs.neovim
    pkgs.nodejs_22
    pkgs.obsidian
    pkgs.python3
    pkgs.python312Packages.pip
    pkgs.python312Packages.requests
    pkgs.reaper
    pkgs.rectangle
    pkgs.ripgrep
    pkgs.starship
    pkgs.stow
    pkgs.terraform
    pkgs.tmux
    pkgs.vscode
    pkgs.wget
    pkgs.yazi
    pkgs.yq-go
    pkgs.zsh-autosuggestions
  ];

  homebrew = {
    enable = true;
    casks = [
      "anki"
      "bitwarden"
      "cheatsheet"
      "firefox"
      "devtoys"
      "discord"
      "docker"
      "espanso"
      "ghostty"
      "hiddenbar"
      "libreoffice"
      "maccy"
      "mysqlworkbench"
      "raycast"
      "skype"
      "steam"
      "telegram"
      "thunderbird@esr"
      "transmission"
      "vlc"
      "whatsapp"
    ];
    masApps = {
      "hp_smart" = 1474276998;
      "ms_office" = 1450038993;
    };
    onActivation.cleanup = "zap";
    onActivation.autoUpdate = true;
    onActivation.upgrade = true;
  };

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.hack
  ];

  # home-manager.backupFileExtension = "backup";
  # nix.configureBuildUsers = true;
  # nix.useDaemon = true;

  # Auto upgrade nix package and the daemon service.
  # services.nix-daemon.enable = true;
  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  system.defaults = {
    dock.autohide = true;
    dock.mru-spaces = false;
    dock.show-recents = false;
    dock.persistent-apps = [
      "${pkgs.alacritty}/Applications/Alacritty.app"
      "/Applications/Firefox.app"
      "${pkgs.obsidian}/Applications/Obsidian.app"
      "/Applications/Thunderbird.app"
    ];
    finder.AppleShowAllExtensions = true;
    finder.FXPreferredViewStyle = "Nlsv";
    finder.CreateDesktop = false;
    finder.ShowPathbar = true;
    finder.ShowStatusBar = true;
    screencapture.location = "~/Pictures/screenshots";
    screensaver.askForPasswordDelay = 10;
  };

  # security.pam.enableSudoTouchIdAuth = true;

  users.users.basin = {
    name = "basin";
    home = "/Users/basin";
  };
}
