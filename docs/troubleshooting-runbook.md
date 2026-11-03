# Troubleshooting Runbook — Linux Server Monitoring Lab

## 1. Purpose

This runbook provides initial troubleshooting procedures for the Linux Server Monitoring Lab. It covers common monitoring and notification issues involving Prometheus, Grafana, Alertmanager, Node Exporter, and Telegram notifications.

The procedures follow a consistent approach:

**Symptom → Investigation → Verification → Resolution**

The commands and procedures are intended for the lab environment. Target IP addresses may change depending on the RHEL server's network configuration.

## 2. Environment Reference

| Component | Configuration |
|---|---|
| Monitored server | RHEL 10.2 |
| Exporter | Node Exporter v1.12.1 |
| Node Exporter port | TCP 9100 |
| Prometheus | Docker container |
| Prometheus URL | `http://localhost:9091` |
| Grafana URL | `http://localhost:3000` |
| Alertmanager URL | `http://localhost:9093` |
| Docker network | `monitoring` |
| Prometheus scrape interval | 15 seconds |
| Telegram notification channel | Telegram Bot |

## 3. Prometheus Container Unavailable

### Symptom

The Prometheus web interface is inaccessible, or the Prometheus container is not running.

### Investigation

Check the container status:

```bash
docker ps -a --filter name=prometheus
```

Inspect container logs:

```bash
docker logs --tail 100 prometheus
```

Check whether the host port is accessible:

```bash
curl -f http://localhost:9091/-/ready
```

### Verification

Confirm that:

- The Prometheus container is running.
- The container logs do not show an unresolved startup error.
- The Prometheus web interface responds successfully.

### Resolution

If the container is stopped, start it:

```bash
docker start prometheus
```

If the container exits again, inspect its logs and configuration before attempting further changes.

---

## 4. Node Exporter or RHEL Target Down

### Symptom

The `rhel-server` target appears as `DOWN` in the Prometheus Targets page, or the `PrometheusTargetDown` alert becomes active.

### Investigation

On the RHEL server, check Node Exporter service status:

```bash
sudo systemctl status node_exporter
```

Check whether Node Exporter is listening on port 9100:

```bash
sudo ss -lntp | grep 9100
```

From the monitoring environment, test the exporter endpoint using the current RHEL server IP:

```bash
curl http://<RHEL_SERVER_IP>:9100/metrics
```

Check the target configuration:

```bash
cat configs/prometheus.yml
```

### Verification

Confirm that:

- Node Exporter is active.
- TCP port 9100 is listening.
- The metrics endpoint returns Prometheus metrics.
- The Prometheus `rhel-server` target returns to `UP`.

### Resolution

If Node Exporter is stopped, start the service:

```bash
sudo systemctl start node_exporter
```

If the service is running but the endpoint remains inaccessible, investigate network connectivity, firewall rules, and the configured target IP.

Do not assume that a `DOWN` target means the entire RHEL server is offline.

---

## 5. Grafana Metrics Missing

### Symptom

Grafana dashboards display no data, show `No Data`, or fail to retrieve metrics from Prometheus.

### Investigation

Check whether Prometheus is accessible:

```bash
curl http://localhost:9091/api/v1/targets
```

Check the Prometheus container:

```bash
docker ps --filter name=prometheus
```

In Grafana, inspect the Prometheus datasource configuration and its connection status.

Review the dashboard query and selected time range.

### Verification

Confirm that:

- Prometheus is accessible.
- The relevant scrape target is `UP`.
- The Grafana datasource connection succeeds.
- The corresponding metric query returns data in Grafana.

### Resolution

Correct the datasource URL or dashboard query if an incorrect value is identified.

If the target is `DOWN`, troubleshoot the exporter connectivity before investigating the dashboard further.

---

## 6. Alert Not Triggering

### Symptom

An expected alert does not appear in Prometheus or does not transition to `Firing`.

### Investigation

Validate the alert rule configuration (syntax and rule file structure):

```bash
docker exec prometheus promtool check rules /etc/prometheus/alert_rules.yml
```

Inspect the rules currently loaded by Prometheus:

```bash
curl -fsS http://localhost:9091/api/v1/rules
```

Inspect the alert state through the Prometheus expression browser:

```promql
ALERTS
```

Inspect a specific alert:

```promql
ALERTS{alertname="HighCPUUsage"}
```

Check the underlying metric expression independently.

For example, CPU utilization:

```promql
100 * (1 - avg by (instance) (
  rate(node_cpu_seconds_total{job="rhel-server", mode="idle"}[5m])
))
```

Review the configured threshold and `for` duration in `configs/alert_rules.yml`.

### Verification

Confirm that:

- The alert rule is loaded.
- The underlying metric query returns data.
- The alert expression evaluates as expected.
- The condition remains active for the configured `for` duration before expecting `Firing`.

### Resolution

Correct the expression or configuration only after identifying the issue.

If the configuration file has been modified, verify that Prometheus has successfully reloaded the updated configuration. A valid rule file does not necessarily mean that the running Prometheus instance is already using the latest version.

If the condition does not remain active for the configured duration, the alert may remain Pending and subsequently return to inactive without reaching Firing.

---

## 7. Telegram Notification Not Received

### Symptom

An alert becomes `Firing` in Prometheus or Alertmanager, but no Telegram notification is received.

### Investigation

Check Alertmanager container status:

```bash
docker ps --filter name=alertmanager
```

Inspect recent Alertmanager logs:

```bash
docker logs --tail 100 alertmanager
```

Open the Alertmanager web interface:

`http://localhost:9093`

Review the alerts received by Alertmanager:

```bash
curl -fsS http://localhost:9093/api/v2/alerts
```

Inspect the Alertmanager configuration and verify the Telegram receiver settings without exposing the bot token.

### Verification

Confirm that:

- Alertmanager is running.
- Prometheus is configured to communicate with Alertmanager.
- The alert is visible in Alertmanager.
- The Telegram receiver configuration is valid.
- A test notification is successfully delivered.

### Resolution

Correct any identified configuration or connectivity issue.

If the alert does not yet appear in Alertmanager, check the Prometheus–Alertmanager communication configuration.

If the alert appears but Telegram is not receiving notifications, check the receiver configuration and the Alertmanager logs.

Consider the possibility of notification grouping or timing issues before concluding that delivery has failed.

Do not expose Telegram bot tokens in terminal output, screenshots, Git commits, or incident documentation.

---

## 8. CPU Metrics Missing

### Symptom

Grafana does not display CPU utilization, or the CPU utilization query returns no data.

### Investigation

Check the RHEL server target status in Prometheus.

Verify that the CPU metric is available:

```promql
node_cpu_seconds_total{job="rhel-server"}
```

Test the CPU utilization expression:

```promql
100 * (1 - avg by (instance) (
  rate(node_cpu_seconds_total{job="rhel-server", mode="idle"}[5m])
))
```

Check the selected Grafana dashboard time range.

### Verification

Confirm that:

- The RHEL target is `UP`.
- `node_cpu_seconds_total` is available.
- The CPU utilization expression returns a value.
- Grafana displays the corresponding metric.

### Resolution

If the target is unavailable, troubleshoot Node Exporter connectivity first.

If the metric exists but the dashboard remains empty, inspect the dashboard query and time range.

---

## 9. Operational Notes

- Always inspect the current system state before restarting services or containers.
- Use logs and monitoring interfaces as supporting evidence during troubleshooting.
- Verify service recovery after applying a corrective action.
- Distinguish confirmed root causes from possible causes.
- Do not expose credentials, tokens, or other secrets in documentation or Git commits.
- Record incident timestamps and observed symptoms accurately.
- Treat alert thresholds as lab-specific initial values rather than universal production standards.

## 10. Scope and Limitations

This runbook provides initial troubleshooting procedures for the monitoring environment.

The Node Exporter outage and recovery workflow was validated during the Day 4 incident-response exercise. Other procedures describe diagnostic and recovery steps but have not necessarily been validated through controlled failure simulations.

Additional testing is required before treating these procedures as production-ready operational standards.
