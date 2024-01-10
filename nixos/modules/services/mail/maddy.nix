{ config, lib, pkgs, ... }:

with lib;

let

  name = "maddy";

  cfg = config.services.maddy;

  defaultConfig = ''
    # Minimal configuration with TLS disabled, adapted from upstream example
    # configuration here https://github.com/foxcpp/maddy/blob/master/maddy.conf
    # Do not use this in production!

    auth.pass_table local_authdb {
      table sql_table {
        driver sqlite3
        dsn credentials.db
        table_name passwords
      }
    }

    storage.imapsql local_mailboxes {
      driver sqlite3
      dsn imapsql.db
    }

    table.chain local_rewrites {
      optional_step regexp "(.+)\+(.+)@(.+)" "$1@$3"
      optional_step static {
        entry postmaster postmaster@$(primary_domain)
      }
      optional_step file /etc/maddy/aliases
    }

    msgpipeline local_routing {
      destination postmaster $(local_domains) {
        modify {
          replace_rcpt &local_rewrites
        }
        deliver_to &local_mailboxes
      }
      default_destination {
        reject 550 5.1.1 "User doesn't exist"
      }
    }

    smtp tcp://0.0.0.0:25 {
      limits {
        all rate 20 1s
        all concurrency 10
      }
      dmarc yes
      check {
        require_mx_record
        dkim
        spf
      }
      source $(local_domains) {
        reject 501 5.1.8 "Use Submission for outgoing SMTP"
      }
      default_source {
        destination postmaster $(local_domains) {
          deliver_to &local_routing
        }
        default_destination {
          reject 550 5.1.1 "User doesn't exist"
        }
      }
    }

    submission tcp://0.0.0.0:587 {
      limits {
        all rate 50 1s
      }
      auth &local_authdb
      source $(local_domains) {
        check {
            authorize_sender {
                prepare_email &local_rewrites
                user_to_email identity
            }
        }
        destination postmaster $(local_domains) {
            deliver_to &local_routing
        }
        default_destination {
            modify {
                dkim $(primary_domain) $(local_domains) default
            }
            deliver_to &remote_queue
        }
      }
      default_source {
        reject 501 5.1.8 "Non-local sender domain"
      }
    }

    target.remote outbound_delivery {
      limits {
        destination rate 20 1s
        destination concurrency 10
      }
      mx_auth {
        dane
        mtasts {
          cache fs
          fs_dir mtasts_cache/
        }
        local_policy {
            min_tls_level encrypted
            min_mx_level none
        }
      }
    }

    target.queue remote_queue {
      target &outbound_delivery
      autogenerated_msg_domain $(primary_domain)
      bounce {
        destination postmaster $(local_domains) {
          deliver_to &local_routing
        }
        default_destination {
            reject 550 5.0.0 "Refusing to send DSNs to non-local addresses"
        }
      }
    }

    imap tcp://0.0.0.0:143 {
      auth &local_authdb
      storage &local_mailboxes
    }
  '';

in {
  options = {
    services.maddy = {

      enable = mkEnableOption (lib.mdDoc "Maddy, a free an open source mail server");

      user = mkOption {
        default = "maddy";
        type = with types; uniq str;
        description = lib.mdDoc ''
          User account under which maddy runs.

          ::: {.note}
          If left as the default value this user will automatically be created
          on system activation, otherwise the sysadmin is responsible for
          ensuring the user exists before the maddy service starts.
          :::
        '';
      };

      group = mkOption {
        default = "maddy";
        type = with types; uniq str;
        description = lib.mdDoc ''
          Group account under which maddy runs.

          ::: {.note}
          If left as the default value this group will automatically be created
          on system activation, otherwise the sysadmin is responsible for
          ensuring the group exists before the maddy service starts.
          :::
        '';
      };

      hostname = mkOption {
        default = "localhost";
        type = with types; uniq str;
        example = ''example.com'';
        description = lib.mdDoc ''
          Hostname to use. It should be FQDN.
        '';
      };

      primaryDomain = mkOption {
        default = "localhost";
        type = with types; uniq str;
        example = ''mail.example.com'';
        description = lib.mdDoc ''
          Primary MX domain to use. It should be FQDN.
        '';
      };

      localDomains = mkOption {
        type = with types; listOf str;
        default = ["$(primary_domain)"];
        example = [
          "$(primary_domain)"
          "example.com"
          "other.example.com"
        ];
        description = lib.mdDoc ''
          Define list of allowed domains.
        '';
      };

      config = mkOption {
        type = with types; nullOr lines;
        default = defaultConfig;
        description = lib.mdDoc ''
          Server configuration, see
          [https://maddy.email](https://maddy.email) for
          more information. The default configuration of this module will setup
          minimal Maddy instance for mail transfer without TLS encryption.

          ::: {.note}
          This should not be used in a production environment.
          :::
        '';
      };

      tls = {
        loader = mkOption {
          type = with types; nullOr (enum [ "off" "file" "acme" ]);
          default = "off";
          description = lib.mdDoc ''
            TLS certificates are obtained by modules called "certificate
            loaders".

            The `file` loader module reads certificates from files specified by
            the `certificates` option.

            Alternatively the `acme` module can be used to automatically obtain
            certificates using the ACME protocol.

            Module configuration is done via the `tls.extraConfig` option.

            Secrets such as API keys or passwords should not be supplied in
            plaintext. Instead the `secrets` option can be used to read secrets
            at runtime as environment variables. Secrets can be referenced with
            `{env:VAR}`.
          '';
        };

        certificates = mkOption {
          type = with types; listOf (submodule {
            options = {
              keyPath = mkOption {
                type = types.path;
                example = "/etc/ssl/mx1.example.org.key";
                description = lib.mdDoc ''
                  Path to the private key used for TLS.
                '';
              };
              certPath = mkOption {
                type = types.path;
                example = "/etc/ssl/mx1.example.org.crt";
                description = lib.mdDoc ''
                  Path to the certificate used for TLS.
                '';
              };
            };
          });
          default = [];
          example = lib.literalExpression ''
            [{
              keyPath = "/etc/ssl/mx1.example.org.key";
              certPath = "/etc/ssl/mx1.example.org.crt";
            }]
          '';
          description = lib.mdDoc ''
            A list of attribute sets containing paths to TLS certificates and
            keys. Maddy will use SNI if multiple pairs are selected.
          '';
        };

        extraConfig = mkOption {
          type = with types; nullOr lines;
          description = lib.mdDoc ''
            Arguments for the specified certificate loader.

            In case the `tls` loader is set, the defaults are considered secure
            and there is no need to change anything in most cases.
            For available options see [upstream manual](https://maddy.email/reference/tls/).

            For ACME configuration, see [following page](https://maddy.email/reference/tls-acme).
          '';
          default = "";
        };
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Open the configured incoming and outgoing mail server ports.
        '';
      };

      ensureAccounts = mkOption {
        type = with types; listOf str;
        default = [];
        description = lib.mdDoc ''
          List of IMAP accounts which get automatically created. Note that for
          a complete setup, user credentials for these accounts are required
          and can be created using the `ensureCredentials` option.
          This option does not delete accounts which are not (anymore) listed.
        '';
        example = [
          "user1@localhost"
          "user2@localhost"
        ];
      };

      ensureCredentials = mkOption {
        default = {};
        description = lib.mdDoc ''
          List of user accounts which get automatically created if they don't
          exist yet. Note that for a complete setup, corresponding mail boxes
          have to get created using the `ensureAccounts` option.
          This option does not delete accounts which are not (anymore) listed.
        '';
        example = {
          "user1@localhost".passwordFile = /secrets/user1-localhost;
          "user2@localhost".passwordFile = /secrets/user2-localhost;
        };
        type = types.attrsOf (types.submodule {
          options = {
            passwordFile = mkOption {
              type = types.path;
              example = "/path/to/file";
              default = null;
              description = lib.mdDoc ''
                Specifies the path to a file containing the
                clear text password for the user.
              '';
            };
          };
        });
      };

      secrets = lib.mkOption {
        type = with types; listOf path;
        description = lib.mdDoc ''
          A list of files containing the various secrets. Should be in the format
          expected by systemd's `EnvironmentFile` directory. Secrets can be
          referenced in the format `{env:VAR}`.
        '';
        default = [ ];
      };

    };
  };

  config = mkIf cfg.enable {

    assertions = [
      {
        assertion = cfg.tls.loader == "file" -> cfg.tls.certificates != [];
        message = ''
          If Maddy is configured to use TLS, tls.certificates with attribute sets
          of certPath and keyPath must be provided.
          Read more about obtaining TLS certificates here:
          https://maddy.email/tutorials/setting-up/#tls-certificates
        '';
      }
      {
        assertion = cfg.tls.loader == "acme" -> cfg.tls.extraConfig != "";
        message = ''
          If Maddy is configured to obtain TLS certificates using the ACME
          loader, extra configuration options must be supplied via
          tls.extraConfig option.
          See upstream documentation for more details:
          https://maddy.email/reference/tls-acme
        '';
      }
    ];

    systemd = {

      packages = [ pkgs.maddy ];
      services = {
        maddy = {
          serviceConfig = {
            User = cfg.user;
            Group = cfg.group;
            StateDirectory = [ "maddy" ];
            EnvironmentFile = cfg.secrets;
          };
          restartTriggers = [ config.environment.etc."maddy/maddy.conf".source ];
          wantedBy = [ "multi-user.target" ];
        };
        maddy-ensure-accounts = {
          script = ''
            ${optionalString (cfg.ensureAccounts != []) ''
              ${concatMapStrings (account: ''
                if ! ${pkgs.maddy}/bin/maddyctl imap-acct list | grep "${account}"; then
                  ${pkgs.maddy}/bin/maddyctl imap-acct create ${account}
                fi
              '') cfg.ensureAccounts}
            ''}
            ${optionalString (cfg.ensureCredentials != {}) ''
              ${concatStringsSep "\n" (mapAttrsToList (name: cfg: ''
                if ! ${pkgs.maddy}/bin/maddyctl creds list | grep "${name}"; then
                  ${pkgs.maddy}/bin/maddyctl creds create --password $(cat ${escapeShellArg cfg.passwordFile}) ${name}
                fi
              '') cfg.ensureCredentials)}
            ''}
          '';
          serviceConfig = {
            Type = "oneshot";
            User= "maddy";
          };
          after = [ "maddy.service" ];
          wantedBy = [ "multi-user.target" ];
        };

      };

    };

    environment.etc."maddy/maddy.conf" = {
      text = ''
        $(hostname) = ${cfg.hostname}
        $(primary_domain) = ${cfg.primaryDomain}
        $(local_domains) = ${toString cfg.localDomains}
        hostname ${cfg.hostname}

        ${if (cfg.tls.loader == "file") then ''
          tls file ${concatStringsSep " " (
            map (x: x.certPath + " " + x.keyPath
          ) cfg.tls.certificates)} ${optionalString (cfg.tls.extraConfig != "") ''
            { ${cfg.tls.extraConfig} }
          ''}
        '' else if (cfg.tls.loader == "acme") then ''
          tls {
            loader acme {
              ${cfg.tls.extraConfig}
            }
          }
        '' else if (cfg.tls.loader == "off") then ''
          tls off
        '' else ""}

        ${cfg.config}
      '';
    };

    users.users = optionalAttrs (cfg.user == name) {
      ${name} = {
        isSystemUser = true;
        group = cfg.group;
        description = "Maddy mail transfer agent user";
      };
    };

    users.groups = optionalAttrs (cfg.group == name) {
      ${cfg.group} = { };
    };

    networking.firewall = mkIf cfg.openFirewall {
      allowedTCPPorts = [ 25 143 587 ];
    };

    environment.systemPackages = [
      pkgs.maddy
    ];
  };
}
