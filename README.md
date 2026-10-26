# Linux Server Monitoring & Incident Response Lab

## Overview

A personal hands-on IT Operations Lab for monitoring a RHEL 10.2 Linux
server using Prometheus and Node Exporter with Grafana planned for
visualization.

The project focuses on Linux administration, infrastructure monitoring,
network connectivity, service management, and troubleshooting.

## Objectives

- Deploy Node Exporter as a systemd service on RHEL.
- Collect Linux server metrics with Prometheus.
- Visualize infrastructure metrics with Grafana.
- Document troubleshooting steps and incident findings.

## Architecture

- **Monitored server:** RHEL 10.2
- **Metrics exporter:** Prometheus Node Exporter
- **Monitoring system:** Prometheus in Docker Desktop
- **Configuration and version control:** Ubuntu on WSL 2 and Git

### Metrics flow

RHEL Server → Node Exporter (:9100) → Prometheus (:9090 inside container)

Prometheus is exposed on Windows at `localhost:9091`

## Current Implementation

- [x] Install Node Exporter on RHEL 10.2.
- [x] Configure Node Exporter as a systemd service.
- [x] Verify network connectivity to Node Exporter.
- [x] Deploy Prometheus using Docker Desktop.
- [x] Configure Prometheus scrape targets.
- [x] Verify Prometheus and RHEL targets are UP.
- [ ] Deploy Grafana.
- [ ] Build a monitoring dashboard.
- [x] Document troubleshooting incidents.
- [x] Capture Prometheus target status screenshot.

## Repository Structure

```text
linux-server-monitoring-lab/
├── configs/
│   └── prometheus.yml
├── docs/
├── incident-reports/
├── screenshots/
├── scripts/
├── .gitignore
└── README.md
```

## Environment

- Windows with Docker Desktop
- Ubuntu on WSL 2
- VMWare virtual machine running RHEL 10.2
- Prometheus 3.15.1
- Node Exporter 1.12.1

## Configuration Notes

The current Prometheus configuration uses a local lab IP address.
Update the target address in `configs/prometheus.yml` to match your
own environment when reproducing this lab.

## Disclaimer

This is a personal learning lab built in a virtualized environment.
It is not intended as a production-ready monitoring deployment.
