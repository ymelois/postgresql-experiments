{
  description = "PostgreSQL Experiments";

  inputs = {
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
  };

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            ccacheWrapper = prev.ccacheWrapper.override {
              extraConfig = ''
                export CCACHE_DIR=/var/cache/ccache
                export CCACHE_MAXSIZE=20GiB
                export CCACHE_COMPRESS=1
                export CCACHE_UMASK=007
                export CCACHE_SLOPPINESS=random_seed
              '';
            };
          })
        ];
      };
      stdenv = pkgs.ccacheStdenv;
      postgresql = pkgs.callPackage ./nix/pkgs/postgresql { inherit stdenv; };
    in
    {
      packages.${system} = {
        inherit postgresql;
        default = postgresql;
      };

      checks.${system}.default = pkgs.testers.runNixOSTest {
        name = "boot-postgresql";

        nodes.machine1 = { config, ... }: {
          environment.systemPackages = [
            self.packages.${system}.postgresql
          ];
          users.users."postgres" = {
            isNormalUser = true;
          };
          system.stateVersion = config.system.nixos.release;
        };

        testScript = ''
          machine1.wait_for_unit("default.target")

          machine1.succeed("mkdir -p /usr/local/pgsql/data")
          machine1.succeed("chown postgres /usr/local/pgsql/data")
          machine1.succeed("su - postgres --command 'initdb -D /usr/local/pgsql/data'")
          machine1.succeed("su - postgres --command 'pg_ctl -D /usr/local/pgsql/data -l logfile start'")
          machine1.succeed("su - postgres --command 'createdb test'")
          print(machine1.succeed("""su - postgres --command 'psql test --command "SELECT version();"'"""))
        '';
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ ];
      };
    };
}
