# Day 3 — Prometheus Alerting and Telegram Notifications

## Objective

Configure Prometheus alert rules, deploy Alertmanager, integrate Telegram notifications, and verify the end-to-end alerting workflow for the RHEL server monitoring lab.

## 1. Prometheus Alert Rules

Configured `configs/prometheus.yml` to load alert rules from `/etc/prometheus/alert_rules.yml` and forward alerts to Alertmanager at `alertmanager:9093`.

Added four alert rules in `configs/alert_rules.yml`:

| Alert | Condition | Duration | Severity |
|---|---|---|---|
| `PrometheusTargetDown` | RHEL server scrape target is down | 1 minute | Critical |
| `HighCPUUsage` | CPU utilization above 80% | 5 minutes | Warning |
| `HighMemoryUsage` | Memory utilization above 85% | 5 minutes | Warning |
| `HighRootFilesystemUsage` | Root filesystem utilization above 85% | 5 minutes | Warning |

The CPU, memory, and filesystem thresholds are initial lab values and are not universal production recommendations.

### Validation

- Validated alert rules using `promtool check rules`.
- Confirmed that all four alert rules loaded and evaluated successfully.
- Confirmed that the rules reported healthy evaluation status.
- Verified that the four alerts were inactive when their conditions were not met.

## 2. Alertmanager Deployment

Deployed Alertmanager using the `prom/alertmanager` Docker image.

Configuration highlights:

- Connected Alertmanager to the existing `monitoring` Docker network.
- Published port `9093` for the Alertmanager web interface.
- Configured the Telegram receiver in `configs/alertmanager.yml`.
- Configured alert grouping by `alertname` and `job`.
- Set `group_wait` to 10 seconds, `group_interval` to 5 minutes, and `repeat_interval` to 4 hours.
- Enabled resolved notifications using `send_resolved: true`.
- Mounted the Alertmanager configuration and Telegram bot token as read-only files.
- Configured the container with the `unless-stopped` restart policy.

### Validation

- Validated the rendered configuration using `amtool check-config`.
- Confirmed that `http://localhost:9093/-/ready` returned HTTP `200 OK`.
- Confirmed that Prometheus reported an active Alertmanager endpoint at `http://alertmanager:9093/api/v2/alerts`.
- Confirmed that Prometheus reported no dropped Alertmanager endpoints.

## 3. Telegram Integration and Secret Handling

Created a Telegram bot and configured it as the Alertmanager notification receiver.

Implemented a template-based configuration workflow:

- `configs/alertmanager.yml.template` stores the receiver configuration with a `TELEGRAM_CHAT_ID` placeholder.
- `.env` stores the Telegram chat ID and is excluded from Git.
- `~/.config/linux-server-monitoring-lab/telegram_bot_token` stores the bot token outside the repository.
- `scripts/render-alertmanager-config.sh` renders the final `configs/alertmanager.yml` using the configured chat ID.
- File permissions on the token file were restricted using `chmod 600`.

The bot token and chat ID are sensitive configuration values and must not be committed to the repository.

The rendered Alertmanager configuration contains the actual chat ID, so it must also be treated as sensitive local configuration and excluded from version control.

## 4. End-to-End Notification Testing

Created a temporary `TelegramTestAlert` rule to test the complete notification path.

The test rule used the PromQL expression `vector(1)` with `for: 0m`, ensuring that the alert condition was immediately eligible to fire.

### Test procedure

1. Added the temporary test rule to `configs/alert_rules.yml`.
2. Validated the rule file using `promtool check rules`.
3. Reloaded Prometheus by sending the `HUP` signal to the container.
4. Confirmed that `TelegramTestAlert` entered the firing state.
5. Confirmed that the alert appeared in Alertmanager.
6. Received the corresponding alert notification in Telegram.
7. Removed the temporary test rule.
8. Revalidated the rule file and confirmed that only the four original monitoring rules remained.
9. Reloaded Prometheus and verified that the four original rules were inactive.

### Result

The end-to-end test confirmed that Prometheus could evaluate an alert, forward it to Alertmanager, and deliver a notification to Telegram.

The temporary test rule was removed after testing. It is not part of the final monitoring configuration.

## 5. Troubleshooting and Observations

### Alert state after removing the test rule

After removing `TelegramTestAlert`, Prometheus was reloaded and the alert rules were revalidated. The Prometheus Alerts page subsequently showed four inactive rules.

### Notification delay

A notification associated with the test and cleanup process appeared approximately 3–4 minutes later than expected.

The precise source of the delay has not been established. Further investigation would be required to distinguish between Prometheus evaluation, alert-state transitions, Alertmanager processing, and notification delivery latency.

The configured `group_wait` of 10 seconds does not, by itself, explain the observed delay.

## 6. Current Status

- Prometheus alert rules: Implemented and validated.
- Alertmanager: Deployed and readiness check passed.
- Prometheus-to-Alertmanager integration: Verified.
- Telegram notification delivery: Verified through an end-to-end test.
- Temporary test rule: Removed.
- Final alert rule count: Four.
- Remaining investigation: Notification latency.

Day 2 Grafana monitoring remains implemented. Day 3 now includes the initial alerting and Telegram notification workflow.

## 7. Lessons Learned

- Validate configuration files before reloading monitoring services.
- Use a controlled test alert to verify the complete notification path.
- Keep bot tokens outside the repository and exclude sensitive configuration files from version control.
- Distinguish alert evaluation status from notification delivery status.
- Record observed delays without assuming a root cause before gathering evidence.

## 8. Next Steps

1. Investigate the observed notification delivery delay.
2. Verify resolved-alert notification delivery.
3. Perform a controlled incident-response exercise, including failure detection, alert delivery, service recovery, and recovery verification.
4. Review alert thresholds and notification behavior under controlled test conditions.
