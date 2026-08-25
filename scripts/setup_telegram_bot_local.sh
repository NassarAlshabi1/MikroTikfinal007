#!/usr/bin/env bash
set -euo pipefail
if [[ "${EUID}" -ne 0 ]]; then echo "شغّل السكربت بصلاحيات root: sudo $0"; exit 1; fi
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="/opt/mikrotik-telegram"; CONFIG_DIR="/etc/mikrotik-telegram"; STATE_DIR="/var/lib/mikrotik-telegram"; SERVICE_USER="mikrotik-telegram"; ENV_FILE="${CONFIG_DIR}/bot.env"
read -r -p "Telegram Bot Token: " TELEGRAM_BOT_TOKEN; printf '\n'
read -r -p "Allowed Telegram Chat IDs (comma separated): " TELEGRAM_ALLOWED_CHAT_IDS
read -r -p "Allowed Telegram User IDs (comma separated): " TELEGRAM_ALLOWED_USER_IDS
read -r -p "Admin Telegram User IDs (comma separated, empty disables reboot): " TELEGRAM_ADMIN_USER_IDS
read -r -p "MikroTik address: " MIKROTIK_ADDRESS
read -r -p "MikroTik API user [telegram-monitor]: " MIKROTIK_USER; MIKROTIK_USER="${MIKROTIK_USER:-telegram-monitor}"
read -r -s -p "MikroTik API password: " MIKROTIK_PASSWORD; printf '\n'
read -r -p "MikroTik API port [8729]: " MIKROTIK_PORT; MIKROTIK_PORT="${MIKROTIK_PORT:-8729}"
read -r -p "Use TLS API? [true]: " MIKROTIK_USE_SSL; MIKROTIK_USE_SSL="${MIKROTIK_USE_SSL:-true}"
read -r -p "RouterOS CA certificate file (optional): " MIKROTIK_CA_FILE
read -r -p "User Manager customer [admin]: " USER_MANAGER_CUSTOMER; USER_MANAGER_CUSTOMER="${USER_MANAGER_CUSTOMER:-admin}"
read -r -p "External traffic interface: " TRAFFIC_INTERFACE
read -r -p "Internet monitor target [1.1.1.1]: " MONITOR_TARGET; MONITOR_TARGET="${MONITOR_TARGET:-1.1.1.1}"
read -r -p "Daily report time [23:59]: " TRAFFIC_DAILY_REPORT_TIME; TRAFFIC_DAILY_REPORT_TIME="${TRAFFIC_DAILY_REPORT_TIME:-23:59}"
[[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_ALLOWED_CHAT_IDS" && -n "$TELEGRAM_ALLOWED_USER_IDS" && -n "$MIKROTIK_ADDRESS" && -n "$MIKROTIK_PASSWORD" ]] || { echo 'كل بيانات الاعتماد والصلاحيات مطلوبة.'; exit 1; }
install -d -m 0750 "$CONFIG_DIR" "$STATE_DIR" "$INSTALL_DIR"
id -u "$SERVICE_USER" >/dev/null 2>&1 || useradd --system --home-dir "$INSTALL_DIR" --shell /usr/sbin/nologin "$SERVICE_USER"
rm -rf "$INSTALL_DIR/telegram_bot"; install -d -m 0750 "$INSTALL_DIR/telegram_bot"
cp -a "$REPO_DIR/telegram_bot/." "$INSTALL_DIR/telegram_bot/"
python3 -m venv "$INSTALL_DIR/.venv"
"$INSTALL_DIR/.venv/bin/pip" install --disable-pip-version-check --no-cache-dir -r "$REPO_DIR/telegram_bot/requirements.txt"
chown -R root:"$SERVICE_USER" "$INSTALL_DIR"; chmod -R u=rwX,g=rX,o= "$INSTALL_DIR/telegram_bot"
install -m 0644 "$REPO_DIR/deploy/systemd/mikrotik-telegram.service" /etc/systemd/system/mikrotik-telegram.service
umask 077
cat >"${ENV_FILE}.tmp" <<EOF
TELEGRAM_BOT_TOKEN=${TELEGRAM_BOT_TOKEN}
TELEGRAM_ALLOWED_CHAT_IDS=${TELEGRAM_ALLOWED_CHAT_IDS}
TELEGRAM_ALLOWED_USER_IDS=${TELEGRAM_ALLOWED_USER_IDS}
TELEGRAM_ADMIN_USER_IDS=${TELEGRAM_ADMIN_USER_IDS}
MIKROTIK_ADDRESS=${MIKROTIK_ADDRESS}
MIKROTIK_USER=${MIKROTIK_USER}
MIKROTIK_PASSWORD=${MIKROTIK_PASSWORD}
MIKROTIK_PORT=${MIKROTIK_PORT}
MIKROTIK_USE_SSL=${MIKROTIK_USE_SSL}
MIKROTIK_CA_FILE=${MIKROTIK_CA_FILE}
USER_MANAGER_CUSTOMER=${USER_MANAGER_CUSTOMER}
TELEGRAM_POLL_SECONDS=20
TELEGRAM_OFFSET_FILE=${STATE_DIR}/.telegram_offset
TELEGRAM_AUDIT_FILE=${STATE_DIR}/audit.jsonl
MONITOR_TARGET=${MONITOR_TARGET}
MONITOR_INTERVAL_SECONDS=30
TRAFFIC_INTERFACE=${TRAFFIC_INTERFACE}
TRAFFIC_INTERVAL_SECONDS=60
TRAFFIC_STATE_FILE=${STATE_DIR}/traffic-state.json
TRAFFIC_DAILY_REPORT_TIME=${TRAFFIC_DAILY_REPORT_TIME}
REBOOT_RECOVERY_ATTEMPTS=12
REBOOT_RECOVERY_INTERVAL_SECONDS=5
EOF
install -m 0640 -o root -g "$SERVICE_USER" "${ENV_FILE}.tmp" "$ENV_FILE"; rm -f "${ENV_FILE}.tmp"; chown -R "$SERVICE_USER:$SERVICE_USER" "$STATE_DIR"
systemctl daemon-reload; systemctl enable --now mikrotik-telegram.service
systemctl is-active --quiet mikrotik-telegram.service && echo 'تم تشغيل Telegram Bot.' || { journalctl -u mikrotik-telegram -n 80 --no-pager; exit 1; }
