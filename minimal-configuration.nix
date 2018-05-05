# Installation:
#
#   $ mount /dev/disk/by-label/nixos /mnt
#   $ mkdir -p /mnt/boot/efi
#   $ nixos-generate-config --root /mnt
#   $ cp -v min-conf/* /mnt/etc/nixos
#   $ mkdir -p /mnt/etc/nixos/passwords -m 700
#   $ mkpasswd -m sha-512 > /mnt/etc/nixos/passwords/cstrahan
#   $ chmod 700 /mnt/etc/nixos/passwords/cstrahan
#   $ mount /dev/disk/by-label/EFI /mnt/boot/efi
#   $ nixos-install
{ config, lib, pkgs, ... }:

# Per-machine settings.
let
  meta = import ./meta.nix;
  isMBP = (builtins.substring 0 10 meta.productName) == "MacBookPro";
  isWork = meta.productName == "MacBookPro11,5";
  isNvidia = meta.productName != "MacBookPro11,5";

in

{
  imports = [
    ./hardware-configuration.nix
  ];

  system.stateVersion = "18.03";

  #boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/boot/efi";
  boot.loader.timeout = 8;
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true; # don't depend on NVRAM
    device = "nodev"; # EFI only
  };

  boot.supportedFilesystems = [ "exfat" "btrfs" ];
  boot.kernelModules = [ "msr" "coretemp" ] ++ lib.optional isMBP "applesmc";
  boot.blacklistedKernelModules =
    # make my desktop use the `wl` module for WiFi.
    lib.optionals (!isMBP) [ "b43" "bcma" "bcma-pci-bridge" ];

  # Select internationalisation properties.
  time.timeZone = null;
  i18n.consoleUseXkbConfig = true;

  networking.hostName = meta.hostname;

  networking.networkmanager.enable = lib.mkForce true;
  networking.networkmanager.insertNameservers = [ "8.8.8.8" "8.8.4.4" ];
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];
  networking.wireless.enable = lib.mkForce false;
  networking.firewall.enable = false;

  hardware = {
    enableRedistributableFirmware = true;
    opengl.enable = true;
    pulseaudio.enable = true;
    pulseaudio.support32Bit = true;
    pulseaudio.daemon.config = { flat-volumes = "no"; };
    bluetooth.enable = true;
  };

  programs.ssh.startAgent = false;
  programs.gnupg = {
    agent.enable = true;
    agent.enableSSHSupport = true;
    agent.enableExtraSocket = false;
    agent.enableBrowserSocket = false;
    dirmngr.enable = true;
  };

  services.logind.extraConfig =
    lib.optionalString isMBP ''
      HandlePowerKey=suspend
    '';

  environment.variables = {
    BROWSER = "firefox";
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
  };

  environment.etc."fuse.conf".text = ''
    user_allow_other
  '';

  # Enable the backlight on rMBP
  # Disable USB-based wakeup
  # see: https://wiki.archlinux.org/index.php/MacBookPro11,x
  systemd.services.mbp-fixes = {
    description = "Fixes for MacBook Pro";
    wantedBy = [ "multi-user.target" "post-resume.target" ];
    after = [ "multi-user.target" "post-resume.target" ];
    script = ''
      if [[ "$(cat /sys/class/dmi/id/product_name)" == "MacBookPro11,3" ]]; then
        if [[ "$(${pkgs.pciutils}/bin/setpci  -H1 -s 00:01.00 BRIDGE_CONTROL)" != "0000" ]]; then
          ${pkgs.pciutils}/bin/setpci -v -H1 -s 00:01.00 BRIDGE_CONTROL=0
        fi
        echo 5 > /sys/class/leds/smc::kbd_backlight/brightness

        if ${pkgs.gnugrep}/bin/grep -q '\bXHC1\b.*\benabled\b' /proc/acpi/wakeup; then
          echo XHC1 > /proc/acpi/wakeup
        fi
      fi
    '';
    serviceConfig.Type = "oneshot";
  };

  services.xserver = {
    enable = true;
    autorun = false;
    videoDrivers = lib.optional isNvidia "nvidia" ++
                   lib.optional (!isNvidia) "radeon";
    xkbOptions = "ctrl:nocaps";

    autoRepeatDelay = 200;
    autoRepeatInterval = 33; # 30hz

    synaptics.enable = lib.mkForce false;
    libinput.enable = true;
    libinput.tapping = false;
    libinput.tappingDragLock = false;

    windowManager.default = "none";
    displayManager.sddm.enable = true;
    desktopManager.xterm.enable = true;
    desktopManager.default = "plasma5";
    desktopManager.plasma5 = {
      enable = true;
      enableQt4Support = false;
    };
  };

  environment.systemPackages = [
    pkgs.firefox

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
    pkgs.silver-searcher
  ];

  environment.shells = [ "/run/current-system/sw/bin/zsh" ];

  users = {
    mutableUsers = false;
    extraGroups.docker.gid = lib.mkForce config.ids.gids.docker;
    extraUsers = [
      {
        uid             = 2000;
        name            = "cstrahan";
        group           = "users";
        extraGroups     = [ "wheel" "networkmanager" "docker" "fuse" "vboxusers" ];
        isNormalUser    = true;
        passwordFile    = "/etc/nixos/passwords/cstrahan";
        useDefaultShell = false;
        shell           = "/run/current-system/sw/bin/zsh";
      }
    ];
  };

  nix = {
    package = pkgs.nixUnstable;
    useSandbox = true;
    binaryCaches = [ "https://cache.nixos.org" ];
    trustedBinaryCaches = [ "https://cache.nixos.org" ];
    requireSignedBinaryCaches = true;
    distributedBuilds = true;
  };

  fonts = {
    fontconfig.enable = true;
    enableFontDir = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      pragmatapro
    ];
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (self: super: {
      pragmatapro = self.callPackage ./pragmatapro.nix { };
    })
  ];
}
