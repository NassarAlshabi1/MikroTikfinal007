#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# MikroTik Telegram Bot - Deployment Script
# Supports: Cloudflare Workers + Systemd (Linux)
# Security: No hardcoded secrets - uses environment variables or prompts
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# =============================================================================
# FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# =============================================================================
# CLOUDFLARE WORKERS DEPLOYMENT
# =============================================================================

deploy_cloudflare_workers() {
    log_info "Starting Cloudflare Workers deployment..."
    
    # Check for wrangler
    if ! command_exists wrangler; then
        log_info "Installing Wrangler CLI..."
        npm install -g wrangler || { log_error "Failed to install wrangler"; return 1; }
    fi
    
    # Check for npm
    if ! command_exists npm; then
        log_error "npm is required but not found. Please install Node.js first."
        return 1
    fi
    
    log_info "Installing dependencies (npm install)..."
    cd "$REPO_DIR"
    if [ -f package.json ]; then
        npm install || { log_error "npm install failed"; return 1; }
    else
        log_warning "No package.json found. Creating minimal setup for Cloudflare Workers..."
        mkdir -p workers
        cat > workers/package.json << 'EOF'
{
  "name": "mikrotik-telegram-worker",
  "version": "1.0.0",
  "main": "index.js",
  "dependencies": {
    "@cloudflare/workers-types": "^4.20240117.0"
  }
}
EOF
        npm install || { log_error "npm install failed"; return 1; }
    fi
    
    # Create KV namespaces if they don't exist
    log_info "Creating Cloudflare KV namespaces..."
    
    # Check if KV_CONFIG_NAMESPACE_ID is set
    if [ -z "${KV_CONFIG_NAMESPACE_ID:-}" ]; then
        log_info "Creating KV namespace for configuration..."
        KV_CONFIG_NAMESPACE_ID=$(wrangler kv:namespace create "MIKROTIK_BOT_CONFIG" 2>/dev/null | grep -oP '(?<=id: \")[^\"]+' || echo "")
        if [ -z "$KV_CONFIG_NAMESPACE_ID" ]; then
            log_warning "Could not create KV namespace automatically. Please create manually:"
            log_warning "  wrangler kv:namespace create MIKROTIK_BOT_CONFIG"
            log_warning "Then set KV_CONFIG_NAMESPACE_ID in your environment"
            return 1
        fi
        export KV_CONFIG_NAMESPACE_ID
    fi
    
    # Check if KV_USER_DATA_NAMESPACE_ID is set
    if [ -z "${KV_USER_DATA_NAMESPACE_ID:-}" ]; then
        log_info "Creating KV namespace for user data..."
        KV_USER_DATA_NAMESPACE_ID=$(wrangler kv:namespace create "MIKROTIK_USER_DATA" 2>/dev/null | grep -oP '(?<=id: \")[^\"]+' || echo "")
        if [ -z "$KV_USER_DATA_NAMESPACE_ID" ]; then
            log_warning "Could not create KV namespace automatically. Please create manually:"
            log_warning "  wrangler kv:namespace create MIKROTIK_USER_DATA"
            log_warning "Then set KV_USER_DATA_NAMESPACE_ID in your environment"
            return 1
        fi
        export KV_USER_DATA_NAMESPACE_ID
    fi
    
    log_success "KV Namespaces created:"
    log_success "  KV_CONFIG_NAMESPACE_ID: $KV_CONFIG_NAMESPACE_ID"
    log_success "  KV_USER_DATA_NAMESPACE_ID: $KV_USER_DATA_NAMESPACE_ID"
    
    # Create wrangler.toml if it doesn't exist
    if [ ! -f wrangler.toml ]; then
        log_info "Creating wrangler.toml configuration..."
        cat > wrangler.toml << EOF
name = "mikrotik-telegram-bot"
main = "workers/index.js"
compatibility_date = "2024-01-01"

# KV Namespaces
[[kv_namespaces]]
binding = "CONFIG"
id = "$KV_CONFIG_NAMESPACE_ID"

[[kv_namespaces]]
binding = "USER_DATA"
id = "$KV_USER_DATA_NAMESPACE_ID"

[vars]
ENVIRONMENT = "production"
EOF
    fi
    
    # Create worker code
    if [ ! -f workers/index.js ]; then
        log_info "Creating Cloudflare Worker code..."
        mkdir -p workers
        cat > workers/index.js << 'WORKER_EOF'
// MikroTik Telegram Bot - Cloudflare Worker
// Handles Telegram webhook and forwards to RouterOS

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url);
    
    // Telegram webhook endpoint
    if (url.pathname === '/webhook') {
      if (request.method === 'POST') {
        const update = await request.json();
        
        // Store update in KV for processing
        const updateId = update.update_id;
        await env.USER_DATA.put(`update_${updateId}`, JSON.stringify(update));
        
        // Process the update (simplified - actual bot logic would be here)
        const chatId = update.message?.chat?.id;
        const text = update.message?.text;
        
        if (text && chatId) {
          // Forward to MikroTik via API (this would be implemented in your bot)
          const responseText = `Received: ${text}`;
          
          // In a real implementation, you would:
          // 1. Verify the Telegram token
          // 2. Check allowed chat IDs
          // 3. Connect to MikroTik RouterOS
          // 4. Execute commands
          // 5. Send response back to Telegram
          
          return new Response(JSON.stringify({
            method: 'sendMessage',
            chat_id: chatId,
            text: responseText
          }), {
            headers: { 'Content-Type': 'application/json' }
          });
        }
        
        return new Response('OK', { status: 200 });
      }
      return new Response('Method Not Allowed', { status: 405 });
    }
    
    // Health check
    if (url.pathname === '/health') {
      return new Response('OK', { status: 200 });
    }
    
    return new Response('Not Found', { status: 404 });
  }
};
WORKER_EOF
    fi
    
    # Deploy to Cloudflare
    log_info "Deploying to Cloudflare Workers..."
    wrangler deploy || { log_error "Failed to deploy to Cloudflare Workers"; return 1; }
    
    # Get the worker URL
    WORKER_URL=$(wrangler deploy --dry-run 2>&1 | grep -oP 'https://[^\s]+\.workers\.dev' || echo "")
    if [ -z "$WORKER_URL" ]; then
        log_warning "Could not determine worker URL. Please check your deployment."
        log_info "You can find the URL in the wrangler output above."
    else
        log_success "Cloudflare Worker deployed successfully!"
        log_success "Worker URL: $WORKER_URL"
    fi
    
    # Set up Telegram webhook
    if [ -n "${TELEGRAM_TOKEN:-}" ] && [ -n "$WORKER_URL" ]; then
        log_info "Setting up Telegram webhook..."
        WEBHOOK_URL="$WORKER_URL/webhook"
        
        # Use curl to set webhook
        if command_exists curl; then
            curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/setWebhook" \
                -H "Content-Type: application/json" \
                -d "{\"url\": \"$WEBHOOK_URL\"}" | grep -q "\"ok\":true" && \
                log_success "Telegram webhook set to: $WEBHOOK_URL" || \
                log_error "Failed to set Telegram webhook"
        else
            log_warning "curl not found. Please manually set webhook with:"
            log_warning "  curl -X POST \"https://api.telegram.org/bot$TELEGRAM_TOKEN/setWebhook\" \\"
            log_warning "    -H \"Content-Type: application/json\" \\"
            log_warning "    -d \"{\\\"url\\\": \\\"$WEBHOOK_URL\\\"}\""
        fi
    fi
    
    log_success "Cloudflare Workers deployment completed!"
    return 0
}

# =============================================================================
# SYSTEMCTL DEPLOYMENT (Linux Service)
# =============================================================================

deploy_systemd() {
    log_info "Starting Systemd deployment..."
    
    # Check for root
    if [[ "${EUID}" -ne 0 ]]; then
        log_error "Systemd deployment requires root privileges. Please run with sudo."
        return 1
    fi
    
    # Check for systemctl
    if ! command_exists systemctl; then
        log_error "systemctl not found. This is not a systemd-based system."
        return 1
    fi
    
    # Check for Python 3
    if ! command_exists python3; then
        log_error "Python 3 is required but not found."
        return 1
    fi
    
    # Install Python venv if not exists
    if ! python3 -m venv --help >/dev/null 2>&1; then
        log_info "Installing Python venv..."
        apt-get update && apt-get install -y python3-venv || { log_error "Failed to install python3-venv"; return 1; }
    fi
    
    # Directories
    INSTALL_DIR="/opt/mikrotik-telegram"
    CONFIG_DIR="/etc/mikrotik-telegram"
    STATE_DIR="/var/lib/mikrotik-telegram"
    SERVICE_USER="mikrotik-telegram"
    
    log_info "Creating directories..."
    install -d -m 0750 "$CONFIG_DIR" "$STATE_DIR" "$INSTALL_DIR"
    
    # Create service user
    log_info "Creating service user..."
    id -u "$SERVICE_USER" >/dev/null 2>&1 || useradd --system --home-dir "$INSTALL_DIR" --shell /usr/sbin/nologin "$SERVICE_USER"
    
    # Copy bot files
    log_info "Copying bot files..."
    rm -rf "$INSTALL_DIR/telegram_bot"
    install -d -m 0750 "$INSTALL_DIR/telegram_bot"
    cp -a "$REPO_DIR/telegram_bot/." "$INSTALL_DIR/telegram_bot/"
    
    # Create Python virtual environment
    log_info "Creating Python virtual environment..."
    python3 -m venv "$INSTALL_DIR/.venv"
    "$INSTALL_DIR/.venv/bin/pip" install --disable-pip-version-check --no-cache-dir -r "$INSTALL_DIR/telegram_bot/requirements.txt"
    
    # Set permissions
    chown -R root:"$SERVICE_USER" "$INSTALL_DIR"
    chmod -R u=rwX,g=rX,o= "$INSTALL_DIR/telegram_bot"
    
    # Copy systemd service file
    log_info "Installing systemd service..."
    install -m 0644 "$SCRIPT_DIR/systemd/mikrotik-telegram.service" /etc/systemd/system/mikrotik-telegram.service
    
    # Create environment file
    log_info "Creating environment configuration..."
    ENV_FILE="/etc/mikrotik-telegram/bot.env"
    
    # Collect configuration from user
    echo "Please provide the following configuration (press Enter to skip if already set in environment):"
    
    # Telegram Configuration
    TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-}
    if [ -z "$TELEGRAM_TOKEN" ]; then
        read -r -p "Telegram Bot Token: " TELEGRAM_TOKEN
    fi
    
    CHAT_ID=${CHAT_ID:-}
    if [ -z "$CHAT_ID" ]; then
        read -r -p "Telegram Chat ID: " CHAT_ID
    fi
    
    ALLOWED_CHAT_IDS=${ALLOWED_CHAT_IDS:-$CHAT_ID}
    if [ -z "$ALLOWED_CHAT_IDS" ]; then
        read -r -p "Allowed Telegram Chat IDs (comma separated): " ALLOWED_CHAT_IDS
    fi
    
    ALLOWED_USER_IDS=${ALLOWED_USER_IDS:-}
    if [ -z "$ALLOWED_USER_IDS" ]; then
        read -r -p "Allowed Telegram User IDs (comma separated): " ALLOWED_USER_IDS
    fi
    
    ADMIN_USER_IDS=${TELEGRAM_ADMIN_USER_IDS:-}
    if [ -z "$ADMIN_USER_IDS" ]; then
        read -r -p "Admin Telegram User IDs (comma separated, empty disables reboot): " ADMIN_USER_IDS
    fi
    
    # MikroTik Configuration
    MIKROTIK_ADDRESS=${MIKROTIK_ADDRESS:-}
    if [ -z "$MIKROTIK_ADDRESS" ]; then
        read -r -p "MikroTik Router Address: " MIKROTIK_ADDRESS
    fi
    
    MIKROTIK_USER=${MIKROTIK_USER:-admin}
    read -r -p "MikroTik API User [$MIKROTIK_USER]: " MIKROTIK_USER_INPUT
    MIKROTIK_USER=${MIKROTIK_USER_INPUT:-$MIKROTIK_USER}
    
    MIKROTIK_PASSWORD=${MIKROTIK_PASSWORD:-}
    if [ -z "$MIKROTIK_PASSWORD" ]; then
        read -r -s -p "MikroTik API Password: " MIKROTIK_PASSWORD
        echo
    fi
    
    MIKROTIK_PORT=${MIKROTIK_PORT:-8729}
    read -r -p "MikroTik API Port [$MIKROTIK_PORT]: " MIKROTIK_PORT_INPUT
    MIKROTIK_PORT=${MIKROTIK_PORT_INPUT:-$MIKROTIK_PORT}
    
    MIKROTIK_USE_SSL=${MIKROTIK_USE_SSL:-true}
    read -r -p "Use TLS for MikroTik API? (true/false) [$MIKROTIK_USE_SSL]: " MIKROTIK_USE_SSL_INPUT
    MIKROTIK_USE_SSL=${MIKROTIK_USE_SSL_INPUT:-$MIKROTIK_USE_SSL}
    
    MIKROTIK_CA_FILE=${MIKROTIK_CA_FILE:-}
    read -r -p "MikroTik CA Certificate File (optional): " MIKROTIK_CA_FILE
    
    USER_MANAGER_CUSTOMER=${USER_MANAGER_CUSTOMER:-admin}
    read -r -p "User Manager Customer [$USER_MANAGER_CUSTOMER]: " USER_MANAGER_CUSTOMER_INPUT
    USER_MANAGER_CUSTOMER=${USER_MANAGER_CUSTOMER_INPUT:-$USER_MANAGER_CUSTOMER}
    
    # Bot Settings
    MONITOR_TARGET=${MONITOR_TARGET:-1.1.1.1}
    read -r -p "Monitor Target [$MONITOR_TARGET]: " MONITOR_TARGET_INPUT
    MONITOR_TARGET=${MONITOR_TARGET_INPUT:-$MONITOR_TARGET}
    
    TRAFFIC_INTERFACE=${TRAFFIC_INTERFACE:-}
    if [ -z "$TRAFFIC_INTERFACE" ]; then
        read -r -p "External Traffic Interface: " TRAFFIC_INTERFACE
    fi
    
    TRAFFIC_DAILY_REPORT_TIME=${TRAFFIC_DAILY_REPORT_TIME:-23:59}
    read -r -p "Daily Report Time [$TRAFFIC_DAILY_REPORT_TIME]: " TRAFFIC_DAILY_REPORT_TIME_INPUT
    TRAFFIC_DAILY_REPORT_TIME=${TRAFFIC_DAILY_REPORT_TIME_INPUT:-$TRAFFIC_DAILY_REPORT_TIME}
    
    # Create environment file
    umask 077
    cat >"${ENV_FILE}.tmp" <<EOF
# Telegram Configuration
TELEGRAM_BOT_TOKEN=$TELEGRAM_TOKEN
TELEGRAM_ALLOWED_CHAT_IDS=$ALLOWED_CHAT_IDS
TELEGRAM_ALLOWED_USER_IDS=$ALLOWED_USER_IDS
TELEGRAM_ADMIN_USER_IDS=$ADMIN_USER_IDS

# MikroTik Configuration
MIKROTIK_ADDRESS=$MIKROTIK_ADDRESS
MIKROTIK_USER=$MIKROTIK_USER
MIKROTIK_PASSWORD=$MIKROTIK_PASSWORD
MIKROTIK_PORT=$MIKROTIK_PORT
MIKROTIK_USE_SSL=$MIKROTIK_USE_SSL
MIKROTIK_CA_FILE=$MIKROTIK_CA_FILE
USER_MANAGER_CUSTOMER=$USER_MANAGER_CUSTOMER

# Bot Settings
TELEGRAM_POLL_SECONDS=20
TELEGRAM_OFFSET_FILE=$STATE_DIR/.telegram_offset
TELEGRAM_AUDIT_FILE=$STATE_DIR/audit.jsonl
MONITOR_TARGET=$MONITOR_TARGET
MONITOR_INTERVAL_SECONDS=30
TRAFFIC_INTERFACE=$TRAFFIC_INTERFACE
TRAFFIC_INTERVAL_SECONDS=60
TRAFFIC_STATE_FILE=$STATE_DIR/traffic-state.json
TRAFFIC_DAILY_REPORT_TIME=$TRAFFIC_DAILY_REPORT_TIME
REBOOT_RECOVERY_ATTEMPTS=12
REBOOT_RECOVERY_INTERVAL_SECONDS=5
EOF
    
    install -m 0640 -o root -g "$SERVICE_USER" "${ENV_FILE}.tmp" "$ENV_FILE"
    rm -f "${ENV_FILE}.tmp"
    chown -R "$SERVICE_USER:$SERVICE_USER" "$STATE_DIR"
    
    # Enable and start service
    log_info "Starting mikrotik-telegram service..."
    systemctl daemon-reload
    systemctl enable --now mikrotik-telegram.service
    
    # Check service status
    if systemctl is-active --quiet mikrotik-telegram.service; then
        log_success "MikroTik Telegram Bot service is running!"
        log_success "Service status: $(systemctl status mikrotik-telegram.service --no-pager -l | grep -oP 'active \([^)]+\)' || echo 'active')"
    else
        log_error "Failed to start mikrotik-telegram service"
        log_info "Checking logs..."
        journalctl -u mikrotik-telegram -n 50 --no-pager
        return 1
    fi
    
    log_success "Systemd deployment completed!"
    return 0
}

# =============================================================================
# MAIN DEPLOYMENT LOGIC
# =============================================================================

main() {
    log_info "=========================================="
    log_info "MikroTik Telegram Bot - Deployment Script"
    log_info "=========================================="
    
    # Show menu
    echo ""
    log_info "Select deployment method:"
    echo "  1) Cloudflare Workers (Webhook-based)"
    echo "  2) Systemd Service (Polling-based, Linux only)"
    echo "  3) Both (Cloudflare + Systemd)"
    echo ""
    
    read -r -p "Enter your choice [1-3]: " DEPLOY_CHOICE
    
    case "$DEPLOY_CHOICE" in
        1)
            deploy_cloudflare_workers
            ;;
        2)
            deploy_systemd
            ;;
        3)
            log_info "Deploying to Cloudflare Workers..."
            deploy_cloudflare_workers
            echo ""
            log_info "Deploying Systemd Service..."
            deploy_systemd
            ;;
        *)
            log_error "Invalid choice. Please select 1, 2, or 3."
            exit 1
            ;;
    esac
    
    # Show summary
    echo ""
    log_success "=========================================="
    log_success "Deployment Summary"
    log_success "=========================================="
    
    if [ "$DEPLOY_CHOICE" = "1" ] || [ "$DEPLOY_CHOICE" = "3" ]; then
        log_success "Cloudflare Workers: Deployed"
        if [ -n "${WORKER_URL:-}" ]; then
            log_success "  Worker URL: $WORKER_URL"
        fi
    fi
    
    if [ "$DEPLOY_CHOICE" = "2" ] || [ "$DEPLOY_CHOICE" = "3" ]; then
        log_success "Systemd Service: Installed and running"
        log_success "  Service: mikrotik-telegram"
        log_success "  Status: $(systemctl is-active mikrotik-telegram.service 2>/dev/null || echo 'inactive')"
        log_success "  Logs: journalctl -u mikrotik-telegram -f"
    fi
    
    echo ""
    log_info "Next steps:"
    if [ "$DEPLOY_CHOICE" = "1" ] || [ "$DEPLOY_CHOICE" = "3" ]; then
        log_info "  - Test your Cloudflare Worker: curl $WORKER_URL/health"
        log_info "  - Send a message to your Telegram bot to test"
    fi
    if [ "$DEPLOY_CHOICE" = "2" ] || [ "$DEPLOY_CHOICE" = "3" ]; then
        log_info "  - Check service logs: journalctl -u mikrotik-telegram -f"
        log_info "  - Test the bot by sending a command to your Telegram chat"
    fi
    
    log_success "Deployment completed!"
}

# Run main function
main "$@"
