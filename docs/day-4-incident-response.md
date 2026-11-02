# Day 4 — Incident Response and Alert Validation

## 1. Objectives

The objectives of Day 4 were to:

- Validate Prometheus alert detection during a simulated Node Exporter failure.
- Verify Telegram notification delivery for firing and resolved alerts.
- Test service recovery and monitoring restoration.
- Observe the behavior of the `HighCPUUsage` alert under changing CPU utilization.
- Review the monitoring system's behavior during a simulated incident.

## 2. Test Environment

The incident-response exercise used the existing Linux server monitoring environment:

| Component | Configuration |
|---|---|
| Monitoring server | Prometheus running in Docker |
| Visualization | Grafana |
| Alert management | Alertmanager |
| Notification channel | Telegram Bot |
| Monitored server | RHEL 10.2 |
| Exporter | Node Exporter v1.12.1 |
| Node Exporter endpoint | `192.168.101.12:9100` |
| Prometheus scrape interval | 15 seconds |
| Prometheus rule evaluation interval | Default: 1 minute |

The `PrometheusTargetDown` alert uses a `for` duration of 1 minute, while `HighCPUUsage` uses a `for` duration of 5 minutes.

## 3. Incident Simulation: Node Exporter Failure

### 3.1 Failure Injection

A controlled service failure was simulated by stopping Node Exporter on the RHEL server:

```bash
sudo systemctl stop node_exporter
```

The service status was checked to confirm that Node Exporter had stopped successfully.

### 3.2 Prometheus Detection

After the service was stopped, the `rhel-server` scrape target changed from `UP` to `DOWN` in the Prometheus Targets page.

The `PrometheusTargetDown` alert subsequently transitioned from Pending to Firing.

The following PromQL query was used to verify the alert state:

```promql
ALERTS{alertname="PrometheusTargetDown"}
```

The query returned a firing alert with the following labels:

- `alertname`: PrometheusTargetDown
- `alertstate`: firing
- `instance`: 192.168.101.12:9100
- `job`: rhel-server
- `severity`: critical

### 3.3 Telegram Notification

The firing notification was successfully received through Telegram after Prometheus transitioned the alert to Firing.

This confirmed that the notification path from Prometheus to Alertmanager and then to Telegram was operational.

## 4. Service Recovery and Resolved Notification

### 4.1 Service Restoration

Node Exporter was started again on the RHEL server:

```bash
sudo systemctl start node_exporter
```

The service returned to an active state, and the Prometheus `rhel-server` target became `UP` again.

The target recovery was observed at approximately 17:06:46 WIB.

### 4.2 Alert Resolution

After the monitored endpoint recovered, `PrometheusTargetDown` transitioned back to an inactive state.

The Alertmanager interface subsequently showed no active alerts.

A Telegram resolved notification was successfully received at approximately 17:09:38 WIB.

This verified that the `send_resolved: true` configuration was working as expected.

## 5. High CPU Alert Investigation

During the incident exercise, the Grafana CPU utilization panel displayed a significant increase in CPU usage, followed by a gap in the graph while Node Exporter was unavailable.

After Node Exporter recovered, CPU utilization was observed at approximately 89.7% at 17:07:36 WIB. It subsequently decreased to approximately 1.76% at 17:12:02 WIB and remained at a low level during the later observation period.

The following PromQL query was used to inspect CPU utilization:

```promql
100 * (1 - avg by (instance) (
  rate(node_cpu_seconds_total{job="rhel-server", mode="idle"}[5m])
))
```

### 5.1 Alert State Verification

The following query was used to inspect the `HighCPUUsage` alert:

```promql
ALERTS{alertname="HighCPUUsage"}
```

Two Pending periods were observed:

| Approximate period (WIB) | Alert state |
|---|---|
| 16:56:50–16:57:32 | Pending |
| 17:07:48–17:08:44 | Pending |

No Firing series was returned by the following query during the inspected time range:

```promql
ALERTS{alertname="HighCPUUsage", alertstate="firing"}
```

### 5.2 Findings

The `HighCPUUsage` rule requires CPU utilization to remain above 80% for 5 minutes before transitioning to Firing.

The two observed Pending periods were shorter than the configured duration. Therefore, the alert did not reach Firing during the inspected periods.

The exact cause of the CPU utilization spikes could not be confirmed from the available observations.

## 6. Verification Results

The following checks were completed during Day 4:

- Node Exporter failure was successfully simulated.
- Prometheus detected the RHEL server target as DOWN.
- `PrometheusTargetDown` transitioned to Firing.
- Telegram firing notification was successfully delivered.
- Node Exporter was successfully restored.
- The RHEL server target returned to UP.
- `PrometheusTargetDown` returned to an inactive state.
- Telegram resolved notification was successfully delivered.
- `HighCPUUsage` entered Pending during two observed periods but did not reach Firing.
- Grafana displayed a CPU graph gap during the Node Exporter outage.

## 7. Findings and Lessons Learned

- Monitoring alerts can be validated through controlled service-failure simulations.
- Alert delivery and resolution should both be tested to verify the complete notification workflow.
- The Prometheus `for` duration determines how long a condition must persist before an alert transitions from Pending to Firing.
- A monitoring graph gap during an exporter outage indicates that metric collection was interrupted; it does not, by itself, establish the underlying cause of the outage.
- Alert state queries provide additional evidence when investigating transitions between Pending, Firing, and inactive states.
- Incident timestamps based on manual observation should be treated as approximate rather than exact measurements.

## 8. Conclusion

The Day 4 incident-response exercise successfully validated the monitoring and notification workflow for a simulated Node Exporter failure.

Prometheus detected the failure, generated a firing alert, and delivered a Telegram notification through Alertmanager. After Node Exporter was restored, Prometheus detected the recovery and Alertmanager successfully delivered a resolved notification.

The `HighCPUUsage` alert was also investigated. Although it entered Pending during two observed periods, it did not reach Firing because the condition was not observed to persist for the configured 5-minute duration.

The exercise demonstrated the ability of the monitoring environment to detect a service outage, notify the operator, and report service recovery.
