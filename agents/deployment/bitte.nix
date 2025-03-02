{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    bitte.url = "github:input-output-hk/bitte";
  };

  outputs = { self, nixpkgs, bitte }: {
    nixosConfigurations.divvyqueue-agent = bitte.mkHost {
      name = "divvyqueue-agent";
      modules = [
        {
          services.divvyqueue-agent = {
            enable = true;
            package = self.packages.${system}.divvyqueue-agent;
            environmentFile = "/run/secrets/divvyqueue-env";
            settings = {
              port = 8080;
              logLevel = "info";
              metricsPort = 9090;
            };
            serviceConfig = {
              Restart = "always";
              RestartSec = "10";
              MemoryLimit = "2G";
            };
          };

          # Monitoring
          services.prometheus = {
            enable = true;
            exporters = {
              node = {
                enable = true;
                enabledCollectors = [ "systemd" ];
              };
            };
          };

          # Logging
          services.loki = {
            enable = true;
            configuration = {
              auth_enabled = false;
              server.http_listen_port = 3100;
              ingester = {
                lifecycler = {
                  ring = {
                    kvstore.store = "inmemory";
                    replication_factor = 1;
                  };
                };
                chunk_idle_period = "5m";
                chunk_retain_period = "30s";
              };
              schema_config.configs = [{
                from = "2020-05-15";
                store = "boltdb";
                object_store = "filesystem";
                schema = "v11";
                index = {
                  prefix = "index_";
                  period = "168h";
                };
              }];
              storage_config = {
                boltdb.directory = "/var/lib/loki/index";
                filesystem.directory = "/var/lib/loki/chunks";
              };
            };
          };

          # Security
          security.acme = {
            email = "admin@example.com";
            acceptTerms = true;
          };

          networking.firewall = {
            enable = true;
            allowedTCPPorts = [ 80 443 8080 9090 ];
          };
        }
      ];
    };
  };
} 