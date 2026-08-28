#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# MikroTik Telegram Bot - Webhook Setup Script
# Automates: KV namespace creation, configuration, and Telegram webhook setup
# Usage: ./setup-webhook.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# =============================================================================
# CONFIGURATION - Edit these values or they will be prompted
# =============================================================================

# Telegram Configuration
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-}
CHAT_ID=${CHAT_ID:-}
ALLOWED_CHAT_IDS=${ALLOWED_CHAT_IDS:-}
ALLOWED_USER_IDS=${ALLOWED_USER_IDS:-}
ADMIN_USER_IDS=${ADMIN_USER_IDS:-}

# MikroTik Configuration
MIKROTIK_ADDRESS=${MIKROTIK_ADDRESS:-}
MIKROTIK_USER=${MIKROTIK_USER:-admin}
MIKROTIK_PASSWORD=${MIKROTIK_PASSWORD:-}
MIKROTIK_PORT=${MIKROTIK_PORT:-8729}
MIKROTIK_USE_SSL=${MIKROTIK_USE_SSL:-true}
MIKROTIK_CA_FILE=${MIKROTIK_CA_FILE:-}

# Bot Settings
MONITOR_TARGET=${MONITOR_TARGET:-1.1.1.1}
TRAFFIC_INTERFACE=${TRAFFIC_INTERFACE:-}

# =============================================================================
# MAIN SETUP
# =============================================================================

main() {
    log_info "=========================================="
    log_info "MikroTik Telegram Bot - Webhook Setup"
    log_info "=========================================="
    
    # Check for wrangler
    if ! command -v npx &> /dev/null; then
        log_error "npx is required. Please install Node.js first."
        exit 1
    fi
    
    # Check if already logged in
    if ! npx wrangler whoami &> /dev/null; then
        log_info "Please login to Cloudflare first:"
        log_info "  npx wrangler login"
        log_info "This will open a browser for OAuth authentication."
        log_info "After login, re-run this script."
        exit 1
    fi
    
    log_success "You are logged in to Cloudflare!"
    
    # Step 1: Create KV Namespaces
    log_info ""
    log_info "Step 1: Creating KV Namespaces..."
    
    KV_CONFIG_ID=${KV_CONFIG_NAMESPACE_ID:-}
    KV_USER_ID=${KV_USER_DATA_NAMESPACE_ID:-}
    
    if [ -z "$KV_CONFIG_ID" ]; then
        log_info "Creating CONFIG KV namespace..."
        KV_CONFIG_ID=$(npx wrangler kv:namespace create "MIKROTIK_BOT_CONFIG" 2>&1 | grep -oP '(?<=id: \")[^\"]+' || echo "")
        if [ -z "$KV_CONFIG_ID" ]; then
            log_error "Failed to create CONFIG KV namespace"
            log_info "Try manually: npx wrangler kv:namespace create MIKROTIK_BOT_CONFIG"
            exit 1
        fi
        log_success "CONFIG KV Namespace ID: $KV_CONFIG_ID"
    else
        log_info "Using existing CONFIG KV Namespace: $KV_CONFIG_ID"
    fi
    
    if [ -z "$KV_USER_ID" ]; then
        log_info "Creating USER_DATA KV namespace..."
        KV_USER_ID=$(npx wrangler kv:namespace create "MIKROTIK_USER_DATA" 2>&1 | grep -oP '(?<=id: \")[^\"]+' || echo "")
        if [ -z "$KV_USER_ID" ]; then
            log_error "Failed to create USER_DATA KV namespace"
            log_info "Try manually: npx wrangler kv:namespace create MIKROTIK_USER_DATA"
            exit 1
        fi
        log_success "USER_DATA KV Namespace ID: $KV_USER_ID"
    else
        log_info "Using existing USER_DATA KV Namespace: $KV_USER_ID"
    fi
    
    # Step 2: Update wrangler.toml
    log_info ""
    log_info "Step 2: Updating wrangler.toml..."
    
    if [ ! -f "$SCRIPT_DIR/wrangler.toml" ]; then
        log_error "wrangler.toml not found in $SCRIPT_DIR"
        exit 1
    fi
    
    # Backup original file
    cp "$SCRIPT_DIR/wrangler.toml" "$SCRIPT_DIR/wrangler.toml.bak"
    
    # Update KV namespace IDs
    sed -i "s/YOUR_KV_CONFIG_NAMESPACE_ID/$KV_CONFIG_ID/g" "$SCRIPT_DIR/wrangler.toml"
    sed -i "s/YOUR_KV_USER_DATA_NAMESPACE_ID/$KV_USER_ID/g" "$SCRIPT_DIR/wrangler.toml"
    
    log_success "Updated wrangler.toml with KV namespace IDs"
    
    # Step 3: Collect Configuration
    log_info ""
    log_info "Step 3: Collecting Configuration..."
    
    echo ""
    log_info "Please provide the following (press Enter to use defaults):"
    
    # Telegram Token
    if [ -z "$TELEGRAM_TOKEN" ]; then
        read -r -p "Telegram Bot Token: " TELEGRAM_TOKEN
        if [ -z "$TELEGRAM_TOKEN" ]; then
            log_error "Telegram Bot Token is required"
            exit 1
        fi
    fi
    
    # Chat ID
    if [ -z "$CHAT_ID" ]; then
        read -r -p "Your Telegram Chat ID: " CHAT_ID
    fi
    
    # Allowed IDs
    ALLOWED_CHAT_IDS=${ALLOWED_CHAT_IDS:-$CHAT_ID}
    if [ -z "$ALLOWED_CHAT_IDS" ]; then
        read -r -p "Allowed Chat IDs (comma separated) [$CHAT_ID]: " ALLOWED_CHAT_IDS_INPUT
        ALLOWED_CHAT_IDS=${ALLOWED_CHAT_IDS_INPUT:-$CHAT_ID}
    fi
    
    ALLOWED_USER_IDS=${ALLOWED_USER_IDS:-}
    if [ -z "$ALLOWED_USER_IDS" ]; then
        read -r -p "Allowed User IDs (comma separated): " ALLOWED_USER_IDS
    fi
    
    ADMIN_USER_IDS=${ADMIN_USER_IDS:-}
    if [ -z "$ADMIN_USER_IDS" ]; then
        read -r -p "Admin User IDs (comma separated, empty disables reboot): " ADMIN_USER_IDS
    fi
    
    # MikroTik Configuration
    if [ -z "$MIKROTIK_ADDRESS" ]; then
        read -r -p "MikroTik Router IP/Hostname: " MIKROTIK_ADDRESS
        if [ -z "$MIKROTIK_ADDRESS" ]; then
            log_error "MikroTik Router Address is required"
            exit 1
        fi
    fi
    
    read -r -p "MikroTik API User [$MIKROTIK_USER]: " MIKROTIK_USER_INPUT
    MIKROTIK_USER=${MIKROTIK_USER_INPUT:-$MIKROTIK_USER}
    
    if [ -z "$MIKROTIK_PASSWORD" ]; then
        read -r -s -p "MikroTik API Password: " MIKROTIK_PASSWORD
        echo
        if [ -z "$MIKROTIK_PASSWORD" ]; then
            log_error "MikroTik Password is required"
            exit 1
        fi
    fi
    
    read -r -p "MikroTik API Port [$MIKROTIK_PORT]: " MIKROTIK_PORT_INPUT
    MIKROTIK_PORT=${MIKROTIK_PORT_INPUT:-$MIKROTIK_PORT}
    
    read -r -p "Use TLS for MikroTik API? (true/false) [$MIKROTIK_USE_SSL]: " MIKROTIK_USE_SSL_INPUT
    MIKROTIK_USE_SSL=${MIKROTIK_USE_SSL_INPUT:-$MIKROTIK_USE_SSL}
    
    read -r -p "MikroTik CA Certificate File (optional): " MIKROTIK_CA_FILE
    
    read -r -p "Monitor Target [$MONITOR_TARGET]: " MONITOR_TARGET_INPUT
    MONITOR_TARGET=${MONITOR_TARGET_INPUT:-$MONITOR_TARGET}
    
    read -r -p "Traffic Interface: " TRAFFIC_INTERFACE
    
    # Step 4: Store Configuration in KV
    log_info ""
    log_info "Step 4: Storing Configuration in KV..."
    
    # Telegram Configuration
    npx wrangler kv:key put "TELEGRAM_TOKEN" "$TELEGRAM_TOKEN" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "ALLOWED_CHAT_IDS" "$ALLOWED_CHAT_IDS" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "ALLOWED_USER_IDS" "$ALLOWED_USER_IDS" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "ADMIN_USER_IDS" "$ADMIN_USER_IDS" --namespace-id "$KV_CONFIG_ID"
    
    # MikroTik Configuration
    npx wrangler kv:key put "MIKROTIK_ADDRESS" "$MIKROTIK_ADDRESS" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_USER" "$MIKROTIK_USER" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_PASSWORD" "$MIKROTIK_PASSWORD" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_PORT" "$MIKROTIK_PORT" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_USE_SSL" "$MIKROTIK_USE_SSL" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_CA_FILE" "$MIKROTIK_CA_FILE" --namespace-id "$KV_CONFIG_ID"
    
    # Bot Settings
    npx wrangler kv:key put "MONITOR_TARGET" "$MONITOR_TARGET" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "TRAFFIC_INTERFACE" "$TRAFFIC_INTERFACE" --namespace-id "$KV_CONFIG_ID"
    
    log_success "Configuration stored in KV!"
    
    # Step 5: Deploy Worker
    log_info ""
    log_info "Step 5: Deploying Worker to Cloudflare..."
    
    cd "$SCRIPT_DIR"
    
    # Deploy
    DEPLOY_OUTPUT=$(npx wrangler deploy 2>&1) || {
        log_error "Failed to deploy worker"
        echo "$DEPLOY_OUTPUT"
        exit 1
    }
    
    # Extract worker URL
    WORKER_URL=$(echo "$DEPLOY_OUTPUT" | grep -oP 'https://[^\s]+\.workers\.dev' || echo "")
    
    if [ -z "$WORKER_URL" ]; then
        log_warning "Could not extract worker URL from output"
        log_info "Deployment output:"
        echo "$DEPLOY_OUTPUT"
        log_info "Please manually get the URL from the output above"
        read -r -p "Enter your Worker URL: " WORKER_URL
    fi
    
    log_success "Worker deployed successfully!"
    log_success "Worker URL: $WORKER_URL"
    
    # Step 6: Setup Telegram Webhook
    log_info ""
    log_info "Step 6: Setting up Telegram Webhook..."
    
    WEBHOOK_URL="$WORKER_URL/webhook"
    
    # Set webhook
    SET_WEBHOOK_OUTPUT=$(curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/setWebhook" \
        -H "Content-Type: application/json" \
        -d "{\"url\": \"$WEBHOOK_URL\"}" 2>&1) || true
    
    # Check if webhook was set successfully
    if echo "$SET_WEBHOOK_OUTPUT" | grep -q '"ok":true'; then
        log_success "Telegram webhook set successfully!"
        log_success "Webhook URL: $WEBHOOK_URL"
    else
        log_warning "Failed to set webhook automatically"
        log_info "Please manually set the webhook with:"
        echo ""
        log_info "curl -X POST \\"
        log_info "  https://api.telegram.org/bot$TELEGRAM_TOKEN/setWebhook \\"
        log_info "  -H 'Content-Type: application/json' \\"
        log_info "  -d '{\"url\": \"$WEBHOOK_URL\"}'"
        echo ""
    fi
    
    # Step 7: Verify Webhook
    log_info ""
    log_info "Step 7: Verifying Webhook..."
    
    WEBHOOK_INFO=$(curl -s -X GET "https://api.telegram.org/bot$TELEGRAM_TOKEN/getWebhookInfo" 2>&1) || true
    
    if echo "$WEBHOOK_INFO" | grep -q '"ok":true'; then
        WEBHOOK_URL_FROM_API=$(echo "$WEBHOOK_INFO" | grep -oP '"url":\s*"\K[^"]+' || echo "")
        if [ "$WEBHOOK_URL_FROM_API" = "$WEBHOOK_URL" ]; then
            log_success "Webhook verified! URL matches: $WEBHOOK_URL"
        else
            log_warning "Webhook URL mismatch!"
            log_info "Expected: $WEBHOOK_URL"
            log_info "Actual: $WEBHOOK_URL_FROM_API"
        fi
    else
        log_warning "Could not verify webhook"
        log_info "Response: $WEBHOOK_INFO"
    fi
    
    # Step 8: Test Worker
    log_info ""
    log_info "Step 8: Testing Worker..."
    
    # Test health endpoint
    HEALTH_TEST=$(curl -s -X GET "$WORKER_URL/health" 2>&1) || true
    if echo "$HEALTH_TEST" | grep -q '"status":"ok"'; then
        log_success "Worker health check passed!"
    else
        log_warning "Worker health check failed"
        log_info "Response: $HEALTH_TEST"
    fi
    
    # Summary
    log_info ""
    log_info "=========================================="
    log_success "Setup Summary"
    log_info "=========================================="
    log_success "KV CONFIG Namespace: $KV_CONFIG_ID"
    log_success "KV USER_DATA Namespace: $KV_USER_ID"
    log_success "Worker URL: $WORKER_URL"
    log_success "Webhook URL: $WEBHOOK_URL"
    log_info ""
    log_info "Next Steps:"
    log_info "1. Send a message to your Telegram bot"
    log_info "2. Try commands: /start, /status, /users"
    log_info "3. Check logs: npx wrangler tail"
    log_info ""
    log_info "To view worker logs:"
    log_info "  cd $SCRIPT_DIR && npx wrangler tail"
    log_info ""
    log_info "To redeploy after changes:"
    log_info "  cd $SCRIPT_DIR && npx wrangler deploy"
    log_info ""
    log_success "Setup completed!"
}

# Run main
main "$@"
