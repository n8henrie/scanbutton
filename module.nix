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
  options.services.${name} =
    let
      inherit (lib) mkEnableOption mkOption;
    in
    with lib.types;
    {
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

    users.users.${cfg.user} = {
      group = cfg.user;
      isSystemUser = true;
    };

    systemd.services.scanner =
      let
        exe = lib.getExe flake.outputs.packages.${pkgs.stdenv.hostPlatform.system}.scanScript;
        script = pkgs.writeShellScriptBin "run" ''
          "${exe}" "${cfg.modelName}" "${cfg.scanDestination}"
        '';
        conf = pkgs.replaceVars ./scanbd.conf {
          inherit (cfg) user;
          scriptPath = lib.getExe script;
          fujitsuConf = "${pkgs.scanbd}/etc/scanbd/scanner.d/fujitsu.conf";
        };
      in
      {
        description = "scanbd";
        serviceConfig = {
          Restart = "on-failure";
          RestartSec = 10;
          Type = "simple";
        };
        script = "${lib.getExe' pkgs.scanbd "scanbd"} -f -c ${conf}";
        wantedBy = [ "multi-user.target" ];
      };
    services.udev.extraRules = ''
      ENV{libsane_matched}=="yes", GROUP="${cfg.user}"
    '';
  };
}
