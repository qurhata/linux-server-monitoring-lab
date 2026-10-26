# DAY 1 - Troubleshooting and Incident Notes

## 1. Docker Desktop Engine Unavailable

**Symptom:** Docker CLI returned an Internal Server Error related to the Docker
Desktop Linux engine pipe.

**Impact:** Docker commands could not be executed while the engine was unavailable.

**Investigation and Resolution:**
* Checked Docker Desktop and CLI availability.
* Restarted Docker Desktop.
* Confirmed that Docker commands worked again after the restart.

**Root Cause:** Not confirmed. The issue was temporarily resolved by restarting
Docker Desktop.

**Status:** Resolved for the current session; underlying cause remains unknown.

## 2. Node Exporter Connectivity Test Used an Incorrect Port

**Symptom:** An initial HTTP request to the RHEL server failed because the URL
omitted port `9100`, causing the client to attempt the default HTTP port `80`.

**Impact:** The initial connectivity test failed.

**Resolution:**
* Corrected the URL to `http://192.168.101.10:9100/metrics`.
* Retested the endpoint from a Docker container.
* Confirmed that Node Exporter metrics were returned successfully.

**Root Cause:** Incorrect port in the test URL.

**Status:** Resolved.

## 3. Docker CLI Permission Error in WSL

**Symptom:** Running Docker commands from Ubuntu on WSL returned a permission-
denied error when accessing `/var/run/docker.sock`.

**Impact:** Docker commands could not be run through the current WSL Docker
CLI configuration.

**Investigation and Workaround:**
* Identified that the WSL CLI was attempting to access `/var/run/docker.sock`.
* Continued running Docker commands from Windows PowerShell using the
`desktop-linux` context.

**Root Cause:** Not fully investigated. The WSL Docker socker access and CLI
configuration remain to be examined.

**Status:** Workaround available; WSL-side issue remains unresolved.

## 4. Verification Results

The following checks passed during Day 1:
* Node Exporter systemd service was active on the RHEL server.
* Node Exporter exposed metrics on TCP port `9100`.
* A Docker container successfully retrieved metrics from the RHEL server.
* Prometheus started successfully in Docker Desktop.
* Prometheus configuration loaded successfully.
* The `prometheus` and `rhel-server` scrape targets both reported UP in the
Prometheus Targets page.

## Lessons Learned
* Verify the destination port when testing service connectivity.
* Distinguish a temporary workaround from a confirmed root-cause fix.
* Validate monitoring through both service-level checks and Prometheus target
status.
* Keep troubleshooting notes so future investigations can build on documented
evidence.
