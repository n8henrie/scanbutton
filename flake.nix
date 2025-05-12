{
  description = "Script for my scanner";
  inputs.nixpkgs.url = "nixpkgs/nixos-22.11";

  outputs = {
    self,
    nixpkgs,
  }: let
    version = builtins.substring 0 8 self.lastModifiedDate;
    supportedSystems = ["aarch64-linux"];
    lib = nixpkgs.lib;
  in {
    packages = lib.genAttrs supportedSystems (system: let
      pkgs = import nixpkgs {inherit system;};
    in rec {
      default = scanScript {};
      scanScript = {
        modelName ? "my scanner",
        scanDestination ? "/tmp",
      }:
        pkgs.writeShellApplication {
          name = "scanner-${version}";
          runtimeInputs = with pkgs; [
            exiftool
            libjpeg
            sane-backends
          ];
          text = builtins.readFile (pkgs.substituteAll {
            inherit modelName scanDestination;
            src = ./scan.sh;
          });
        };
    });
    nixosModules.default = self.nixosModules.scanner;
    nixosModules.scanner = {
      config,
      pkgs,
      ...
    }: let
      name = "scanner";
      cfg = config.services.${name};
    in
      with lib; {
        options.services.${name} = with types; {
          enable = mkEnableOption "Enable the scanner";
          user = mkOption {
            type = str;
            description = "user for running scanner";
            default = "scanner";
          };
          modelName = mkOption {
            type = str;
            description = "Scanner model name";
            default = "my scanner";
          };
          scanDestination = mkOption {
            type = str;
            description = "Destination for the scan output files.";
            default = "/tmp";
          };
        };

        config = mkIf cfg.enable {
          hardware.sane.enable = true;

          users.users.scanner = {
            group = "scanner";
            isSystemUser = true;
          };

          systemd.services.scanner = let
            scanScript = self.packages.${pkgs.system}.scanScript {
              inherit (cfg) modelName scanDestination;
            };
            scriptPath = "${scanScript}/bin/${scanScript.name}";
            conf = pkgs.substituteAll {
              inherit scriptPath;
              inherit (cfg) user;
              fujitsuConf = "${pkgs.scanbd}/etc/scanbd/scanner.d/fujitsu.conf";
              src = ./scanbd.conf;
            };
          in {
            description = "scanbd";
            serviceConfig = {
              Type = "simple";
              Restart = "on-failure";
              RestartSec = 10;
            };
            script = "${pkgs.scanbd}/bin/scanbd -f -c ${conf}";
            wantedBy = ["multi-user.target"];
          };
          services.udev.extraRules = ''
            ENV{libsane_matched}=="yes", GROUP="scanner"
          '';
        };
      };
  };
}
