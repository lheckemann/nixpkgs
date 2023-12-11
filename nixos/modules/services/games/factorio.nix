{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.factorio;
  name = "Factorio";
  stateDir = "/var/lib/${cfg.stateDirName}";
  mkSavePath = name: "${stateDir}/saves/${name}.zip";
  configFile = pkgs.writeText "factorio.conf" ''
    use-system-read-write-data-directories=true
    [path]
    read-data=${cfg.package}/share/factorio/data
    write-data=${stateDir}
  '';
  serverSettings = {
    name = cfg.game-name;
    description = cfg.description;
    visibility = {
      public = cfg.public;
      lan = cfg.lan;
    };
    username = cfg.username;
    password = cfg.password;
    token = cfg.token;
    game_password = cfg.game-password;
    require_user_verification = cfg.requireUserVerification;
    max_upload_in_kilobytes_per_second = 0;
    minimum_latency_in_ticks = 0;
    ignore_player_limit_for_returning_players = false;
    allow_commands = "admins-only";
    autosave_interval = cfg.autosave-interval;
    autosave_slots = 5;
    afk_autokick_interval = 0;
    auto_pause = true;
    only_admins_can_pause_the_game = true;
    autosave_only_on_server = true;
    non_blocking_saving = cfg.nonBlockingSaving;
  } // cfg.extraSettings;
  serverSettingsString = builtins.toJSON (filterAttrsRecursive (n: v: v != null) serverSettings);
  serverSettingsFile = pkgs.writeText "server-settings.json" serverSettingsString;
  serverAdminsFile = pkgs.writeText "server-adminlist.json" (builtins.toJSON cfg.admins);
  modDir = pkgs.factorio-utils.mkModDirDrv cfg.mods cfg.mods-dat;
in
{
  options = {
    services.factorio = {
      enable = mkEnableOption (lib.mdDoc name);
      port = mkOption {
        type = types.port;
        default = 34197;
        description = lib.mdDoc ''
          The port to which the service should bind.
        '';
      };

      bind = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = lib.mdDoc ''
          The address to which the service should bind.
        '';
      };

      admins = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "username" ];
        description = lib.mdDoc ''
          List of player names which will be admin.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether to automatically open the specified UDP port in the firewall.
        '';
      };
      saveName = mkOption {
        type = types.str;
        default = "default";
        description = lib.mdDoc ''
          The name of the savegame that will be used by the server.

          When not present in /var/lib/''${config.services.factorio.stateDirName}/saves,
          a new map with default settings will be generated before starting the service.
        '';
      };
      loadLatestSave = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Load the latest savegame on startup. This overrides saveName, in that the latest
          save will always be used even if a saved game of the given name exists. It still
          controls the 'canonical' name of the savegame.

          Set this to true to have the server automatically reload a recent autosave after
          a crash or desync.
        '';
      };
      # TODO Add more individual settings as nixos-options?
      # TODO XXX The server tries to copy a newly created config file over the old one
      #   on shutdown, but fails, because it's in the nix store. When is this needed?
      #   Can an admin set options in-game and expect to have them persisted?
      configFile = mkOption {
        type = types.path;
        default = configFile;
        defaultText = literalExpression "configFile";
        description = lib.mdDoc ''
          The server's configuration file.

          The default file generated by this module contains lines essential to
          the server's operation. Use its contents as a basis for any
          customizations.
        '';
      };
      extraSettingsFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = lib.mdDoc ''
          File, which is dynamically applied to server-settings.json before
          startup.

          This option should be used for credentials.

          For example a settings file could contain:
          ```json
          {
            "game-password": "hunter1"
          }
          ```
        '';
      };
      stateDirName = mkOption {
        type = types.str;
        default = "factorio";
        description = lib.mdDoc ''
          Name of the directory under /var/lib holding the server's data.

          The configuration and map will be stored here.
        '';
      };
      mods = mkOption {
        type = types.listOf types.package;
        default = [];
        description = lib.mdDoc ''
          Mods the server should install and activate.

          The derivations in this list must "build" the mod by simply copying
          the .zip, named correctly, into the output directory. Eventually,
          there will be a way to pull in the most up-to-date list of
          derivations via nixos-channel. Until then, this is for experts only.
        '';
      };
      mods-dat = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = lib.mdDoc ''
          Mods settings can be changed by specifying a dat file, in the [mod
          settings file
          format](https://wiki.factorio.com/Mod_settings_file_format).
        '';
      };
      game-name = mkOption {
        type = types.nullOr types.str;
        default = "Factorio Game";
        description = lib.mdDoc ''
          Name of the game as it will appear in the game listing.
        '';
      };
      description = mkOption {
        type = types.nullOr types.str;
        default = "";
        description = lib.mdDoc ''
          Description of the game that will appear in the listing.
        '';
      };
      extraSettings = mkOption {
        type = types.attrs;
        default = {};
        example = { admins = [ "username" ];};
        description = lib.mdDoc ''
          Extra game configuration that will go into server-settings.json
        '';
      };
      public = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Game will be published on the official Factorio matching server.
        '';
      };
      lan = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Game will be broadcast on LAN.
        '';
      };
      username = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          Your factorio.com login credentials. Required for games with visibility public.

          This option is insecure. Use extraSettingsFile instead.
        '';
      };
      package = mkPackageOption pkgs "factorio-headless" {
        example = "factorio-headless-experimental";
      };
      password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          Your factorio.com login credentials. Required for games with visibility public.

          This option is insecure. Use extraSettingsFile instead.
        '';
      };
      token = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          Authentication token. May be used instead of 'password' above.
        '';
      };
      game-password = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = lib.mdDoc ''
          Game password.

          This option is insecure. Use extraSettingsFile instead.
        '';
      };
      requireUserVerification = mkOption {
        type = types.bool;
        default = true;
        description = lib.mdDoc ''
          When set to true, the server will only allow clients that have a valid factorio.com account.
        '';
      };
      autosave-interval = mkOption {
        type = types.nullOr types.int;
        default = null;
        example = 10;
        description = lib.mdDoc ''
          Autosave interval in minutes.
        '';
      };
      nonBlockingSaving = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Highly experimental feature, enable only at your own risk of losing your saves.
          On UNIX systems, server will fork itself to create an autosave.
          Autosaving on connected Windows clients will be disabled regardless of autosave_only_on_server option.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.factorio = {
      description   = "Factorio headless server";
      wantedBy      = [ "multi-user.target" ];
      after         = [ "network.target" ];

      preStart =
        (toString [
          "test -e ${stateDir}/saves/${cfg.saveName}.zip"
          "||"
          "${cfg.package}/bin/factorio"
          "--config=${cfg.configFile}"
          "--create=${mkSavePath cfg.saveName}"
          (optionalString (cfg.mods != []) "--mod-directory=${modDir}")
        ])
        + (optionalString (cfg.extraSettingsFile != null) ("\necho ${lib.strings.escapeShellArg serverSettingsString}"
          + " \"$(cat ${cfg.extraSettingsFile})\" | ${lib.getExe pkgs.jq} -s add"
          + " > ${stateDir}/server-settings.json"));

      serviceConfig = {
        Restart = "always";
        KillSignal = "SIGINT";
        DynamicUser = true;
        StateDirectory = cfg.stateDirName;
        UMask = "0007";
        ExecStart = toString [
          "${cfg.package}/bin/factorio"
          "--config=${cfg.configFile}"
          "--port=${toString cfg.port}"
          "--bind=${cfg.bind}"
          (optionalString (!cfg.loadLatestSave) "--start-server=${mkSavePath cfg.saveName}")
          "--server-settings=${
            if (cfg.extraSettingsFile != null)
            then "${stateDir}/server-settings.json"
            else serverSettingsFile
          }"
          (optionalString cfg.loadLatestSave "--start-server-load-latest")
          (optionalString (cfg.mods != []) "--mod-directory=${modDir}")
          (optionalString (cfg.admins != []) "--server-adminlist=${serverAdminsFile}")
        ];

        # Sandboxing
        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectControlGroups = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
        RestrictRealtime = true;
        RestrictNamespaces = true;
        MemoryDenyWriteExecute = true;
      };
    };

    networking.firewall.allowedUDPPorts = optional cfg.openFirewall cfg.port;
  };
}
