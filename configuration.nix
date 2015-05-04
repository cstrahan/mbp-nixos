{ config, pkgs, modulesPath, ... }:
{ imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-graphical.nix>
  ];

  #services.xserver.autorun = true;
  #services.xserver.videoDrivers = [ "nvidia" ];

  environment.systemPackages = [
    pkgs.wpa_supplicant_gui
    pkgs.vim
    pkgs.cryptsetup # needed for luks
  ];

  # Some modules that may be needed for mounting anything ciphered
  # (copied from modules/system/boot/luksroot.nix)
  boot.initrd.availableKernelModules = [ "dm_mod" "dm_crypt" "cryptd" ] ++ config.boot.initrd.luks.cryptoModules;

  services.xserver.synaptics.enable = true;
  services.xserver.synaptics.twoFingerScroll = true;
  services.xserver.synaptics.buttonsMap = [ 1 3 2 ];
  services.xserver.synaptics.tapButtons = false;

  networking.enableIPv6 = false;

  # Wireless drivers
  nixpkgs.config.allowUnfree = true;
  networking.interfaceMonitor.enable = true;
  boot.extraModulePackages = [
    config.boot.kernelPackages.broadcom_sta
  ];
  # For non-WICD, use:
  networking.networkManager.enable = false;
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;
  networking.wireless.interfaces = [ "wlp3s0" ];

  # For WICD, use:
  #networking.wireless.enable = false;
  #networking.useDHCP = false;
  #networking.wicd.enable = true;

  nix.maxJobs = 4;
  nix.binaryCaches = [
    "http://cache.nixos.org/"
    "http://hydra.nixos.org/"
  ];

  isoImage.contents = [
    {
      source = ./configuration.nix;
      target = "configuration.nix";
    }
  ];
}
