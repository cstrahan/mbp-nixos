# This is mostly taken from <nixpkgs/nixos/release.nix>

{ nixpkgs ? { outPath = <nixpkgs>; revCount = 56789; shortRev = "gfedcba"; }
, stableBranch ? false
, supportedSystems ? [ "x86_64-linux" "i686-linux" ]
}:

let

  version = builtins.readFile "${nixpkgs}/.version";

  versionSuffix =
    (if stableBranch then "." else "pre") + "${toString nixpkgs.revCount}.${nixpkgs.shortRev}";

  forAllSystems = pkgs.lib.genAttrs supportedSystems;

  scrubDrv = drv: let res = { inherit (drv) drvPath outPath type name system meta; outputName = "out"; out = res; }; in res;

  pkgs = import nixpkgs { system = "x86_64-linux"; };

  lib = pkgs.lib;

  versionModule =
    { system.nixosVersionSuffix = versionSuffix;
      system.nixosRevision = nixpkgs.rev or nixpkgs.shortRev;
    };

  makeIso =
    { module, type, description ? type, maintainers ? ["cstrahan"], system }:

    with import nixpkgs { inherit system; };

    let

      config = (import "${nixpkgs}/nixos/lib/eval-config.nix" {
        inherit system;
        modules = [ module versionModule { isoImage.isoBaseName = "nixos-${type}"; } ];
      }).config;

      iso = config.system.build.isoImage;

    in
      # Declare the ISO as a build product so that it shows up in Hydra.
      scrubDrv (runCommand "nixos-iso-${config.system.nixosVersion}"
        { meta = {
            description = "NixOS installation CD (${description}) - ISO image for ${system}";
            maintainers = map (x: lib.getAttr x lib.maintainers) maintainers;
          };
          inherit iso;
          passthru = { inherit config; };
        }
        ''
          mkdir -p $out/nix-support
          echo "file iso" $iso/iso/*.iso* >> $out/nix-support/hydra-build-products
        ''); # */

in rec {

  iso_mbp = forAllSystems (system: makeIso {
    module =
      { config, pkgs, modulesPath, ... }:
      { imports = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical.nix"
        ];

        #services.xserver.autorun = true;
        #services.xserver.videoDrivers = [ "nvidia" ];

        environment.systemPackages = [
          pkgs.wpa_supplicant_gui
          pkgs.vim
        ];

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

        nixpkgs.config.packageOverrides = pkgs:
          rec {
            vim =
              with pkgs;
              with pkgs.xorg;
              let ruby = ruby_2_1_2; in
              stdenv.mkDerivation rec {
                name = "vim-${version}";

                version = "7.4.481";

                dontStrip = 1;

                src = fetchhg {
                  url = "https://vim.googlecode.com/hg/";
                  rev = "v7-4-481";
                  sha256 = "1fhcgdx8d6qxgi7a3xnicxvvs9k19raa6y4dyvlzam2clz43nz1s";
                };

                buildInputs = [
                  pkgconfig gettext glib
                  libX11 libXext libSM libXpm libXt libXaw libXau libXmu libICE
                  gtk ncurses
                  cscope
                  python ruby luajit perl tcl
                ];

                configureFlags = [
                    "--enable-cscope"
                    "--enable-fail-if-missing"
                    "--with-features=huge"
                    "--enable-gui=none"
                    "--enable-multibyte"
                    "--enable-nls"
                    "--enable-luainterp=yes"
                    "--enable-pythoninterp=yes"
                    "--enable-perlinterp=yes"
                    "--enable-rubyinterp=yes"
                    "--enable-tclinterp=yes"
                    "--with-luajit"
                    "--with-lua-prefix=${luajit}"
                    "--with-python-config-dir=${python}/lib"
                    "--with-ruby-command=${ruby}/bin/ruby"
                    "--with-tclsh=${tcl}/bin/tclsh"
                    "--with-tlib=ncurses"
                    "--with-compiledby=Nix"
                ];

                meta = with stdenv.lib; {
                  description = "The most popular clone of the VI editor";
                  homepage    = http://www.vim.org;
                  maintainers = with maintainers; [ cstrahan ];
                  platforms   = platforms.unix;
                };
              };
          };
      };
    type = "mbp";
    inherit system;
  });

}
