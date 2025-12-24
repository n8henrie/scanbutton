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
        {
          default = self.outputs.packages.scanScript;
          scanScript = pkgs.callPackage ./. { };
        }
      );
      nixosModules = {
        default = self.nixosModules.scanner;
        scanner = import ./module.nix self;
      };
    };
}
