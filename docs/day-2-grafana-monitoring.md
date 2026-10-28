# Day 2 — Grafana Dashboard & Linux Server Monitoring

## Overview

Day 2 extends the Linux Server Monitoring & Incident Response Lab by integrating Grafana with Prometheus and building a dashboard to visualize resource utilization and network traffic on a RHEL server.

## Architecture

- **Monitored server:** RHEL 10.2
- **Metrics exporter:** Node Exporter v1.12.1
- **Metrics collection and storage:** Prometheus
- **Visualization:** Grafana
- **Monitored target:** `192.168.101.10:9100`
- **Prometheus endpoint:** `http://localhost:9091`
- **Grafana endpoint:** `http://localhost:3000`

Grafana queries Prometheus as its data source. Prometheus scrapes metrics exposed by Node Exporter on the RHEL server.

## Dashboard Panels

The `Linux Server Monitoring` dashboard contains five time-series panels:

1. **RHEL CPU Utilization** — estimates CPU utilization from the idle CPU time counter.
2. **RHEL Memory Utilization** — estimates memory usage using total memory and available memory.
3. **RHEL Root Filesystem Usage** — calculates root filesystem usage from filesystem size and available space.
4. **RHEL Network Receive (RX)** — measures incoming network traffic on `ens160`.
5. **RHEL Network Transmit (TX)** — measures outgoing network traffic on `ens160`.

The loopback interface (`lo`) is excluded from the network panels to focus on the VM's primary network interface.

## PromQL Queries

### CPU Utilization

```promql
100 * (1 - avg by (instance) (
  rate(node_cpu_seconds_total{job="rhel-server", mode="idle"}[5m])
))
```

### Memory Utilization

```promql
100 * (
  1 -
  node_memory_MemAvailable_bytes{job="rhel-server"}
  /
  node_memory_MemTotal_bytes{job="rhel-server"}
)
```

### Root Filesystem Usage

```promql
100 * (
  1 -
  node_filesystem_avail_bytes{
    job="rhel-server",
    mountpoint="/",
    fstype!~"tmpfs|overlay|squashfs"
  }
  /
  node_filesystem_size_bytes{
    job="rhel-server",
    mountpoint="/",
    fstype!~"tmpfs|overlay|squashfs"
  }
)
```

### Network Receive (RX)

```promql
rate(node_network_receive_bytes_total{job="rhel-server", device="ens160"}[5m])
```

### Network Transmit (TX)

```promql
rate(node_network_transmit_bytes_total{job="rhel-server", device="ens160"}[5m])
```

## Verification

- Prometheus target status was verified as `UP`.
- Grafana's Prometheus data source passed its connection test.
- CPU, memory, root filesystem, network RX, and network TX panels displayed time-series data.
- The dashboard was saved successfully.
- The dashboard time range was adjusted during troubleshooting to display available recent metrics.

## Evidence

- Prometheus targets: [`screenshots/prometheus_targets.png`](../screenshots/prometheus_targets.png)
- Grafana dashboard: [`screenshots/grafana_dashboard.png`](../screenshots/grafana_dashboard.png)

## Notes

- Network traffic panels use a five-minute rate window, so values represent estimated bytes per second rather than cumulative bytes.
- Metric values depend on actual server workload and may remain low during idle periods.
- Dashboard persistence depends on the Grafana storage configuration. Back up or persist Grafana data before removing or recreating its container.

## Outcome

A saved Grafana dashboard was created to visualize five core Linux server monitoring metrics using Prometheus and Node Exporter.
