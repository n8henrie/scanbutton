flake:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  name = "scanner";
  cfg = config.services.${name};
in
{
  options.services.${name} = with lib.types; {
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

  config = lib.mkIf cfg.enable {
    hardware.sane.enable = true;

    users.users.scanner = {
      group = "scanner";
      isSystemUser = true;
    };

    systemd.services.scanner =
      let
        scanScript = flake.packages.${pkgs.system}.scanScript {
          inherit (cfg) modelName scanDestination;
        };
        scriptPath = "${scanScript}/bin/${scanScript.name}";
        conf = pkgs.substituteAll {
          inherit scriptPath;
          inherit (cfg) user;
          fujitsuConf = "${pkgs.scanbd}/etc/scanbd/scanner.d/fujitsu.conf";
          src = ./scanbd.conf;
        };
      in
      {
        description = "scanbd";
        serviceConfig = {
          Type = "simple";
          Restart = "on-failure";
          RestartSec = 10;
        };
        script = "${pkgs.scanbd}/bin/scanbd -f -c ${conf}";
        wantedBy = [ "multi-user.target" ];
      };
    services.udev.extraRules = ''
      ENV{libsane_matched}=="yes", GROUP="scanner"
    '';
  };
}
