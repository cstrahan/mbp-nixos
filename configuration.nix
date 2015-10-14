{ config, lib, pkgs, modulesPath, ... }:
{ imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical.nix>
    #<nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-base.nix>
  ];

  boot.kernelPackages = pkgs.linuxPackages_4_2;
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];

  i18n.consoleUseXkbConfig = true;

  environment.systemPackages = [
    pkgs.wpa_supplicant_gui
    pkgs.vim
    pkgs.gparted
    pkgs.vim
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
  ];

  powerManagement.enable = true;
  services.dbus.enable = true;
  services.upower.enable = true;
  services.xserver = {
    enable = true;
    autorun = lib.mkForce false;
    xkbOptions = "ctrl:nocaps";
    synaptics = {
      enable = true;
      twoFingerScroll = true;
      buttonsMap = [ 1 3 2 ];
      tapButtons = false;
      accelFactor = "0.0055";
      minSpeed = "0.95";
      maxSpeed = "1.15";
      palmDetect = true;
    };
    displayManager.sessionCommands = ''
      ${pkgs.xorg.xset}/bin/xset r rate 220 50
      if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
        eval "$(${pkgs.dbus.tools}/bin/dbus-launch --sh-syntax --exit-with-session)"
        export DBUS_SESSION_BUS_ADDRESS
      fi
    '';
  };

  nix.maxJobs = 4;
  nix.requireSignedBinaryCaches = true;
  nix.binaryCaches = [ "http://hydra.nixos.org" ];
  nix.binaryCachePublicKeys = [ "hydra.nixos.org-1:CNHJZBh9K4tP3EKF6FkkgeVYsS3ohTl+oS0Qa8bezVs=" ];

  networking.enableIPv6 = true;
  networking.interfaceMonitor.enable = true;
  networking.networkmanager.enable = lib.mkForce true;
  networking.wireless.enable = lib.mkForce false;
  networking.usePredictableInterfaceNames = true;

  isoImage.contents = [ ];

  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = super: let self = super.pkgs; in rec {
      linux_4_2 = super.linux_4_2.override {
        extraConfig = "BRCMFMAC_PCIE y";
      };
    };
  };

  # Additional packages to include in the store.
  system.extraDependencies = [ ];

}
