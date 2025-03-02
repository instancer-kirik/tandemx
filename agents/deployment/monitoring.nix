{
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_port = 3000;
        domain = "metrics.example.com";
      };
      security = {
        admin_user = "admin";
        admin_password = "$__file{/run/secrets/grafana-admin-password}";
      };
      analytics.reporting_enabled = false;
    };
    provision = {
      enable = true;
      datasources = [{
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://localhost:9090";
      } {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://localhost:3100";
      }];
      dashboards = [{
        name = "DivvyQueue";
        options.path = ./dashboards;
      }];
    };
  };

  # DivvyQueue agent metrics
  services.prometheus.scrapeConfigs = [{
    job_name = "divvyqueue";
    static_configs = [{
      targets = [ "localhost:8080" ];
      labels = {
        service = "divvyqueue-agent";
        environment = "production";
      };
    }];
    metrics_path = "/metrics";
    scheme = "http";
  }];

  # Alert rules
  services.prometheus.rules = [
    {
      name = "divvyqueue";
      rules = [
        {
          alert = "HighErrorRate";
          expr = ''rate(divvyqueue_errors_total[5m]) > 0.1'';
          for = "5m";
          labels = {
            severity = "critical";
            service = "divvyqueue";
          };
          annotations = {
            summary = "High error rate in DivvyQueue agent";
            description = "Error rate is {{ $value }} for the last 5 minutes";
          };
        }
        {
          alert = "PositionVerificationDelay";
          expr = ''divvyqueue_position_verification_delay_seconds > 300'';
          for = "5m";
          labels = {
            severity = "warning";
            service = "divvyqueue";
          };
          annotations = {
            summary = "Position verification is delayed";
            description = "Position verification is delayed by {{ $value }} seconds";
          };
        }
      ];
    }
  ];
} 