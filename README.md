# rajo-grafana

Monitoring stack for Fortigate and Cisco SNMP devices powered by Prometheus, Grafana, and the Prometheus SNMP exporter.

## Layout

```
.
├── infra/
│   ├── lambda/
│   │   └── alert_router/           # Minimal Lambda that relays Alertmanager webhooks to SNS
│   └── terraform files             # SNS & alert-router infrastructure (API GW + Lambda)
├── alertmanager/
│   └── alertmanager.yml             # Alertmanager configuration
├── docker-compose.yaml
├── fortigate/
│   └── fortigate-key.yaml          # API key material for the Fortigate exporter
├── grafana/
│   ├── dashboards/                 # JSON dashboards to be auto-loaded
│   └── provisioning/               # Datasource & dashboard provisioning configs
├── prometheus/
│   ├── prometheus.yml              # Prometheus server configuration
│   ├── rules/                      # Alerting rules consumed by Prometheus
│   ├── snmp/                       # SNMP exporter modules
│   └── targets/                    # Generated file_sd targets (cisco-switches.yml)
└── scripts/
    └── discover_cisco_snmp_subnet.py
```

## Getting Started

1. Fill in `fortigate/fortigate-key.yaml` with the real host(s) and API key(s) for every Fortigate you want to scrape.
2. Adjust Prometheus in `prometheus/prometheus.yml`, add alerting rules under `prometheus/rules/`, and tune the SNMP exporter modules under `prometheus/snmp/` as needed.
3. Configure Alertmanager integrations in `alertmanager/alertmanager.yml`. Use the Terraform under `infra/` to provision the SNS fan-out plus the `/alerts` API Gateway REST API + Lambda bridge protected by an AWS WAF IP allow list.
4. (Optional) Run `scripts/discover_cisco_snmp_subnet.py` to populate `prometheus/targets/cisco-switches.yml`. Prometheus reads this file through file-based service discovery.
5. Start the stack: `docker compose up -d`.

Grafana provisions the default Prometheus datasource plus any dashboards placed in `grafana/dashboards/`. Update the provisioning files under `grafana/provisioning/` if you add additional datasources or folders.

## Triggering Test Alerts

Send synthetic alerts directly to Alertmanager to verify email/SNS paths:

```bash
# Warning severity (tests SES email path)
curl -XPOST http://localhost:9093/api/v2/alerts \
  -H 'Content-Type: application/json' \
  -d '[
        {
          "labels": {"alertname": "EmailTest", "severity": "warning"},
          "annotations": {"summary": "Testing email delivery"},
          "startsAt": "'$(date -Iseconds)'"
        }
      ]'

# Critical severity (tests API Gateway -> Lambda -> SNS path)
curl -XPOST http://localhost:9093/api/v2/alerts \
  -H 'Content-Type: application/json' \
  -d '[
        {
          "labels": {"alertname": "CriticalTest", "severity": "critical"},
          "annotations": {"summary": "Testing SMS delivery"},
          "startsAt": "'$(date -Iseconds)'"
        }
      ]'
```

Each call returns `{"status":"success"}` and should trigger the configured receivers. Use `docker compose logs -f alertmanager` plus AWS SES/SNS dashboards to confirm delivery.
