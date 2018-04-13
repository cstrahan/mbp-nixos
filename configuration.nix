{ config, lib, pkgs, modulesPath, ... }:
{ imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical-kde.nix>
  ];

  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.supportedFilesystems = [ "exfat" ];

  i18n.consoleUseXkbConfig = true;

  environment.extraOutputsToInstall = [ ];
  environment.systemPackages = [
    pkgs.gparted
    pkgs.vim
    pkgs.neovim
    pkgs.bvi
    pkgs.glxinfo
    pkgs.xsel
    pkgs.xclip
    pkgs.mkpasswd
    pkgs.zsh
    pkgs.networkmanagerapplet
    pkgs.git
    pkgs.curl
    pkgs.wget
    pkgs.tmux
    pkgs.termite
    pkgs.tree
  ];

  fonts = {
    fontconfig.enable = true;
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      pragmatapro
    ];
  };

  powerManagement.enable = true;
  services.dbus.enable = true;
  services.upower.enable = true;
  services.xserver = {
    enable = true;
    autorun = lib.mkForce false;
    xkbOptions = "ctrl:nocaps";

    autoRepeatDelay = 200;
    autoRepeatInterval = 33; # 30hz

    synaptics.enable = lib.mkForce false;
    libinput.enable = true;
    libinput.tapping = false;
    libinput.tappingDragLock = false;
  };

  nix.useSandbox = true;
  nix.maxJobs = 4;
  nix.requireSignedBinaryCaches = true;

  networking.enableIPv6 = true;
  networking.networkmanager.enable = lib.mkForce true;
  networking.networkmanager.insertNameservers = [ "8.8.8.8" "8.8.4.4" ];
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
  networking.wireless.enable = lib.mkForce false;
  networking.firewall.enable = false;

  isoImage.contents = [ ];

  boot.postBootCommands = ''
    mkdir -p /root/.config/termite
    cp -T ${./config/termite} /root/.config/termite/config
    chmod u+w /root/.config/termite/config

    cp -T ${./config/kcminputrc} /root/.config/kcminputrc
    chmod u+w /root/.config/kcminputrc
  '';

  system.activationScripts.installerCustom = ''
    mkdir -p /root/Desktop
    ln -sfT ${pkgs.termite}/share/applications/termite.desktop /root/Desktop/termite.desktop
  '';

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = super: let self = super.pkgs; in rec {
      pragmatapro = self.callPackage ./pragmatapro.nix { };
    };
  };

  # Additional packages to include in the store.
  system.extraDependencies = [ ];
}
