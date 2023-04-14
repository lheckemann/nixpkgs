import ./make-test-python.nix ({ pkgs, lib, ... }:

let inherit (import ./ssh-keys.nix pkgs)
      snakeOilPrivateKey snakeOilPublicKey;
in {
  name = "openssh";
  meta = with pkgs.lib.maintainers; {
    maintainers = [ aszlig eelco ];
  };

  nodes = {

    server =
      { ... }:

      {
        services.openssh.enable = true;
        security.pam.services.sshd.limits =
          [ { domain = "*"; item = "memlock"; type = "-"; value = 1024; } ];
        users.users.root.openssh.authorizedKeys.keys = [
          snakeOilPublicKey
        ];
      };

    server_lazy =
      { ... }:

      {
        services.openssh = { enable = true; startWhenNeeded = true; };
        security.pam.services.sshd.limits =
          [ { domain = "*"; item = "memlock"; type = "-"; value = 1024; } ];
        users.users.root.openssh.authorizedKeys.keys = [
          snakeOilPublicKey
        ];
      };

    server_localhost_only =
      { ... }:

      {
        services.openssh = {
          enable = true; listenAddresses = [ { addr = "127.0.0.1"; port = 22; } ];
        };
      };

    server_localhost_only_lazy =
      { ... }:

      {
        services.openssh = {
          enable = true; startWhenNeeded = true; listenAddresses = [ { addr = "127.0.0.1"; port = 22; } ];
        };
      };

    client =
      { ... }: {
        programs.ssh.knownHosts = {
          server.publicKey = snakeOilPublicKey;
          server_lazy.publicKeyFile = pkgs.writeText "snakeoil-host-key" snakeOilPublicKey;
        };
      };

  };

  testScript = ''
    start_all()

    server.wait_for_unit("sshd")
    server.succeed("cp ${snakeOilPrivateKey} /etc/ssh/ssh_host_ed25519_key")
    server.succeed("cat ${lib.escapeShellArg snakeOilPrivateKey} >/etc/ssh/ssh_host_ed25519_key.pub")
    server.succeed("chmod 0600 /etc/ssh/ssh_host_ed25519_key")

    server_lazy.succeed("cp ${snakeOilPrivateKey} /etc/ssh/ssh_host_ed25519_key")
    server_lazy.succeed("cat ${lib.escapeShellArg snakeOilPrivateKey} >/etc/ssh/ssh_host_ed25519_key.pub")
    server_lazy.succeed("chmod 0600 /etc/ssh/ssh_host_ed25519_key")

    client.succeed("cat /etc/ssh/ssh_known_hosts")

    with subtest("manual-authkey"):
        client.succeed("mkdir -m 700 /root/.ssh")
        client.succeed(
            '${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N ""'
        )
        public_key = client.succeed(
            "${pkgs.openssh}/bin/ssh-keygen -y -f /root/.ssh/id_ed25519"
        )
        public_key = public_key.strip()
        client.succeed("chmod 600 /root/.ssh/id_ed25519")

        server.succeed("mkdir -m 700 /root/.ssh")
        server.succeed("echo '{}' > /root/.ssh/authorized_keys".format(public_key))
        server_lazy.succeed("mkdir -m 700 /root/.ssh")
        server_lazy.succeed("echo '{}' > /root/.ssh/authorized_keys".format(public_key))

        client.wait_for_unit("network.target")
        client.succeed(
            "ssh -vvv server 'echo hello world' >&2",
            timeout=30
        )
        client.succeed(
            "ssh server 'ulimit -l' | grep 1024",
            timeout=30
        )

        client.succeed(
            "ssh server_lazy 'echo hello world' >&2",
            timeout=30
        )
        client.succeed(
            "ssh server_lazy 'ulimit -l' | grep 1024",
            timeout=30
        )

    with subtest("configured-authkey"):
        client.succeed(
            "cat ${snakeOilPrivateKey} > privkey.snakeoil"
        )
        client.succeed("chmod 600 privkey.snakeoil")
        client.succeed(
            "ssh -i privkey.snakeoil server true",
            timeout=30
        )
        client.succeed(
            "ssh -i privkey.snakeoil server_lazy true",
            timeout=30
        )

    with subtest("localhost-only"):
        server_localhost_only.succeed("ss -nlt | grep '127.0.0.1:22'")
        server_localhost_only_lazy.succeed("ss -nlt | grep '127.0.0.1:22'")
  '';
})
