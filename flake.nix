{
  description = "Script for my scanner";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      supportedSystems = [ "aarch64-linux" ];
      inherit (nixpkgs) lib;
    in
    {
      packages = lib.genAttrs supportedSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        rec {
          default = scanScript { };
          scanScript =
            {
              modelName ? "my scanner",
              scanDestination ? "/tmp",
            }:
            pkgs.writeShellApplication {
              name = "scanner";
              runtimeInputs = with pkgs; [
                exiftool
                libjpeg
                sane-backends
              ];
              text = builtins.readFile (
                pkgs.substituteAll {
                  inherit modelName scanDestination;
                  src = ./scan.sh;
                }
              );
            };
        }
      );
      nixosModules.default = self.nixosModules.scanner;
      nixosModules.scanner = import ./module.nix { flake = self; };
    };
}
