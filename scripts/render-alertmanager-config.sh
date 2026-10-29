#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_DIR}/.env"
TEMPLATE_FILE="${PROJECT_DIR}/configs/alertmanager.yml.template"
OUTPUT_FILE="${PROJECT_DIR}/configs/alertmanager.yml"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: .env file not found."
    exit 1
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "ERROR: Alertmanager template not found."
    exit 1
fi

set -a
source "$ENV_FILE"
set +a

if [[ ! "${TELEGRAM_CHAT_ID:-}" =~ ^-?[0-9]+$ ]]; then
    echo "ERROR: TELEGRAM_CHAT_ID is missing or invalid."
    exit 1
fi

sed "s|\${TELEGRAM_CHAT_ID}|${TELEGRAM_CHAT_ID}|g" \
    "$TEMPLATE_FILE" > "$OUTPUT_FILE"

echo "Alertmanager configuration rendered successfully."
