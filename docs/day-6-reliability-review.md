# Day 6 — Operational Troubleshooting & Reliability Review

## 1. Operational Readiness Review

Conducted an operational readiness review of the monitoring stack to verify the availability of its main components and their communication.

### Verification Results

| Component | Verification | Result |
|---|---|---|
| Prometheus | Container status and readiness endpoint | Passed |
| Grafana | Dashboard and Prometheus datasource connectivity | Passed |
| Alertmanager | Container status and readiness endpoint | Passed |
| Prometheus Targets | Prometheus and RHEL scrape targets | Both UP |
| Prometheus Rules | Runtime rule inspection | All rules loaded, health OK |
| Alertmanager | Runtime status and receiver registration | Passed |
| Telegram Receiver | Configuration inspection | Receiver registered |

### Prometheus Configuration

Runtime configuration was inspected through the Prometheus status API.

The following settings were confirmed:

- Scrape interval: 15 seconds.
- Scrape timeout: 10 seconds.
- Evaluation interval: 1 minute.
- Data retention: 15 days.
- Alertmanager endpoint: `alertmanager:9093`.
- RHEL Node Exporter target: `192.168.101.13:9100`.

Prometheus successfully recognized Alertmanager as an active endpoint, with no dropped Alertmanager entries.

### Grafana Metrics Retrieval

Grafana datasource configuration was verified through the Grafana UI.

- Datasource: Prometheus.
- Datasource type: Prometheus.
- URL: `http://host.docker.internal:9091`.
- Default datasource: Enabled.

The following PromQL queries were tested successfully:

- `up`
- `node_cpu_seconds_total`
- CPU utilization expression.
- Memory utilization expression.
- Root filesystem utilization expression.

Both Prometheus and RHEL metrics were successfully retrieved through Grafana.

**Result:** The monitoring stack was operational during the readiness review.

---

## 2. Troubleshooting Validation

Selected troubleshooting procedures from `docs/troubleshooting-runbook.md` were reviewed and validated against the running environment.

### 2.1 Prometheus Container Unavailable

**Validation performed:**

- Inspected Prometheus container status.
- Reviewed recent container logs.
- Checked the Prometheus readiness endpoint.

**Results:**

- Prometheus container was running.
- Configuration loading completed successfully.
- Prometheus reported that it was ready to receive web requests.
- No unresolved startup errors were observed in the inspected logs.

**Status:** Healthy-state validation completed.

**Limitation:** Prometheus container failure and recovery were not simulated during Day 6.

### 2.2 Node Exporter or RHEL Target Down

**Validation performed:**

- Checked the Node Exporter systemd service.
- Verified TCP port `9100` was listening.
- Retrieved metrics directly from the RHEL server.
- Retrieved metrics from within the Prometheus container.
- Inspected Prometheus active targets.

**Results:**

- Node Exporter service was active and enabled.
- TCP port `9100` was listening.
- Metrics were successfully retrieved from the RHEL server.
- Prometheus successfully scraped the RHEL target.
- Both configured scrape targets reported `UP`.

**Status:** Healthy-state validation completed.

**Additional evidence:** A controlled Node Exporter outage and recovery had previously been tested and documented on Day 4.

### 2.3 Grafana Metrics Missing

**Validation performed:**

- Inspected Grafana datasource configuration.
- Checked the datasource provisioning directory.
- Executed Prometheus queries through Grafana Explore.

**Results:**

- Prometheus datasource was configured as the default datasource.
- Datasource URL matched the expected configuration.
- The datasource provisioning directory contained no provisioning files.
- Grafana successfully retrieved metrics from Prometheus.

**Status:** Healthy-state validation completed.

### 2.4 Alert Not Triggering

**Validation performed:**

- Executed `promtool check rules`.
- Inspected Prometheus runtime rules through `/api/v1/rules`.
- Inspected the `ALERTS` metric.
- Independently evaluated CPU, memory, and filesystem utilization expressions.

**Results:**

All four configured alert rules were loaded successfully and reported `health: ok`.

| Alert | Threshold | For Duration | Runtime State |
|---|---:|---:|---|
| PrometheusTargetDown | Target unavailable | 1 minute | Inactive |
| HighCPUUsage | CPU >80% | 5 minutes | Inactive |
| HighMemoryUsage | Memory >85% | 5 minutes | Inactive |
| HighRootFilesystemUsage | Root FS >85% | 5 minutes | Inactive |

Resource utilization during the review:

| Metric | Observed Value | Threshold |
|---|---:|---:|
| CPU Usage | 1.45% | 80% |
| Memory Usage | 77.77% | 85% |
| Root Filesystem Usage | 36.57% | 85% |

The `ALERTS` query returned an empty result because no alert instances were in `Pending` or `Firing` state at the time of inspection.

**Status:** Rule configuration, runtime loading, and underlying metric expressions validated.

**Limitation:** Only healthy-state evaluation was performed. Memory and filesystem threshold breaches were not simulated. No new alert transition to `Firing` was tested during Day 6.

### 2.5 Telegram Notification Not Received

**Validation performed:**

- Checked Alertmanager container status.
- Reviewed recent Alertmanager logs.
- Accessed the Alertmanager web interface.
- Inspected alerts through `/api/v2/alerts`.
- Reviewed Alertmanager runtime configuration and receiver registration.

**Results:**

- Alertmanager container was running.
- No apparent configuration or notification delivery errors were found in the inspected logs.
- Alertmanager web interface was accessible.
- Alertmanager API responded successfully with an empty alert list.
- Telegram receiver was registered.
- Runtime configuration confirmed Telegram integration and `send_resolved: true`.

**Status:** Healthy-state validation completed.

**Historical evidence:** Telegram firing and resolved notifications had previously been delivered successfully during Day 3 and Day 4 testing.

**Limitation:** No new Telegram notification was generated during Day 6. Current delivery success was therefore not independently retested.

---

## 3. Reliability Review

The monitoring architecture was reviewed to identify potential single points of failure, persistence limitations, and operational risks.

### 3.1 Single Points of Failure

| Component | Potential Failure Impact |
|---|---|
| Windows host / Docker Desktop | Monitoring services become unavailable if the host or Docker environment fails. |
| WSL2 | May affect Docker management through the Ubuntu WSL environment. |
| Prometheus | Metrics collection, rule evaluation, and alert generation are interrupted. |
| RHEL VM | Host metrics become unavailable. |
| Node Exporter | Prometheus loses access to RHEL host metrics. |
| Alertmanager | Alert notifications cannot be routed through the configured Alertmanager instance. |
| Internet connectivity / Telegram | External notification delivery may fail while local monitoring remains operational. |

The current monitoring architecture relies on a single physical laptop running Docker Desktop and a virtualized RHEL server.

Consequently, the monitoring stack does not provide host-level or service-level high availability.

### 3.2 Container Restart Policy

Container restart policies were inspected using Docker inspection commands.

| Container | Restart Policy | Assessment |
|---|---|---|
| Prometheus | `no` | No automatic restart policy configured. |
| Grafana | `no` | No automatic restart policy configured. |
| Alertmanager | `unless-stopped` | Configured for automatic restart unless manually stopped. |

Prometheus and Grafana may remain stopped after a Docker daemon restart or container exit, depending on the circumstances.

Alertmanager has a more resilient restart configuration.

### 3.3 Persistent Storage Assessment

Container mounts were inspected to identify persistent data and configuration storage.

| Component | Storage Configuration | Assessment |
|---|---|---|
| Prometheus | Named volume mounted at `/prometheus` | Persistent TSDB storage configured. |
| Grafana | No mounts configured | Internal database and dashboard data remain in the container writable layer. |
| Alertmanager | Named volume mounted at `/alertmanager` | Persistent storage configured. |

Additional observations:

- Prometheus configuration and alert rules are mounted as read-only files.
- Alertmanager configuration and Telegram bot token are mounted as read-only files.
- Grafana has no persistent volume or bind mount.
- Grafana datasource and dashboard configuration were created through the UI rather than file-based provisioning.

**Risk:** If the Grafana container is removed and recreated without persistent storage or backup, its internal database, dashboards, and datasource configuration may be lost.

A normal container restart does not itself imply data loss.

---

## 4. Reliability Recommendations

The following improvements were identified for future implementation.

| Area | Recommendation | Priority |
|---|---|---|
| Container recovery | Configure suitable restart policies for Prometheus and Grafana. | High |
| Grafana persistence | Implement a persistent volume for Grafana internal data. | High |
| Configuration management | Consider provisioning Grafana datasources and dashboards through configuration files. | Medium |
| Monitoring availability | Consider separating the monitoring host from the monitored infrastructure. | Medium |
| Notification resilience | Consider an alternative notification channel for external delivery failures. | Medium |
| Backup and recovery | Establish backup and restoration procedures for persistent monitoring data. | Medium |

These recommendations are assessment outcomes only. No hardening or configuration changes were implemented during Day 6.

---

## 5. Scope and Limitations

The Day 6 activity focused on operational readiness, troubleshooting procedure validation, and reliability assessment.

The following activities were not performed:

- Prometheus container failure and recovery simulation.
- Grafana container failure and recovery simulation.
- Controlled memory and filesystem alert threshold breaches.
- New Telegram firing and resolved notification tests.
- Container restart policy modifications.
- Grafana persistent volume implementation.
- Monitoring high-availability implementation.
- Backup and restoration testing.

Previous Day 3 and Day 4 test results remain documented separately and are not presented as new Day 6 tests.

---

## 6. Conclusion

The Linux Server Monitoring Lab successfully passed the operational readiness checks performed during Day 6.

Prometheus, Grafana, Alertmanager, and the RHEL Node Exporter target were operational during the review. Prometheus successfully collected metrics, evaluated alert rules, and maintained communication with Alertmanager. Grafana successfully retrieved and visualized metrics from the configured Prometheus datasource.

The troubleshooting runbook procedures reviewed during this session were consistent with the observed environment and configuration.

The reliability assessment identified several improvement opportunities, particularly container restart policies, Grafana persistent storage, and the dependency on a single physical host.

No configuration changes were made during this session. The identified improvements will be considered as potential scope for a separate server hardening project.

**Day 6 Status:** Operational readiness review, troubleshooting validation, and reliability assessment completed.
