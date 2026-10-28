# Day 3 — Prometheus Alerting (Checkpoint)

## Objective

Configure and validate initial Prometheus alert rules for the RHEL server monitoring lab.

## Implemented

- Added `rule_files` to `configs/prometheus.yml`.
- Added `configs/alert_rules.yml` with four alert rules:
  - `PrometheusTargetDown`: target down for 1 minute.
  - `HighCPUUsage`: CPU utilization above 80% for 5 minutes.
  - `HighMemoryUsage`: memory utilization above 85% for 5 minutes.
  - `HighRootFilesystemUsage`: root filesystem utilization above 85% for 5 minutes.
- Validated the rule file with `promtool check rules`.
- Validated the Prometheus configuration with both configuration files mounted.
- Recreated the Prometheus container with both configuration files mounted read-only.
- Preserved the existing Prometheus data volume.
- Confirmed Prometheus readiness and successful rule evaluation.

## Validation Results

All four alert rules were loaded and evaluated successfully.

At the time of validation, each rule reported:
- `health: ok`
- `state: inactive`

Inactive is expected when the alert condition is not met.

## Threshold Notes

The CPU, memory, and filesystem thresholds are initial lab values, not universal production recommendations.

## Not Yet Implemented

- Alertmanager deployment and configuration.
- Prometheus-to-Alertmanager integration.
- Telegram bot notification delivery.
- End-to-end alert notification testing.

## Current Status

Day 2 Grafana monitoring remains implemented. Day 3 is in progress; this checkpoint covers Prometheus alert-rule configuration and validation only.

## Next Steps

1. Set up a Telegram bot securely.
2. Deploy Alertmanager.
3. Configure Prometheus to send alerts to Alertmanager.
4. Test an alert end-to-end and verify Telegram delivery.
