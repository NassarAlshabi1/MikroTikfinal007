#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# MikroTik Telegram Bot - Full Cloudflare Workers Deployment Script
# Automates: Login, KV creation, configuration, deployment, and webhook setup
# Usage: ./deploy-full.sh
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
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

log_header() {
    echo -e "\n${PURPLE}==========================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}==========================================${NC}"
}

# =============================================================================
# CONFIGURATION COLLECTION
# =============================================================================

collect_config() {
    log_header "Configuration Collection"
    
    echo ""
    log_info "Please provide the following configuration."
    log_info "Values can also be set as environment variables before running this script."
    echo ""
    
    # Telegram Configuration
    TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-}
    if [ -z "$TELEGRAM_TOKEN" ]; then
        read -r -p "Telegram Bot Token (from @BotFather): " TELEGRAM_TOKEN
        if [ -z "$TELEGRAM_TOKEN" ]; then
            log_error "Telegram Bot Token is required!"
            log_info "Get it from @BotFather: https://t.me/BotFather"
            exit 1
        fi
    fi
    
    CHAT_ID=${CHAT_ID:-}
    if [ -z "$CHAT_ID" ]; then
        read -r -p "Your Telegram Chat ID: " CHAT_ID
        if [ -z "$CHAT_ID" ]; then
            log_error "Chat ID is required!"
            log_info "Get it from: https://api.telegram.org/bot$TELEGRAM_TOKEN/getUpdates"
            exit 1
        fi
    fi
    
    ALLOWED_CHAT_IDS=${ALLOWED_CHAT_IDS:-$CHAT_ID}
    read -r -p "Allowed Chat IDs (comma separated) [$ALLOWED_CHAT_IDS]: " ALLOWED_CHAT_IDS_INPUT
    ALLOWED_CHAT_IDS=${ALLOWED_CHAT_IDS_INPUT:-$ALLOWED_CHAT_IDS}
    
    ALLOWED_USER_IDS=${ALLOWED_USER_IDS:-}
    if [ -z "$ALLOWED_USER_IDS" ]; then
        read -r -p "Allowed User IDs (comma separated): " ALLOWED_USER_IDS
        if [ -z "$ALLOWED_USER_IDS" ]; then
            log_error "Allowed User IDs is required!"
            exit 1
        fi
    fi
    
    ADMIN_USER_IDS=${ADMIN_USER_IDS:-}
    read -r -p "Admin User IDs (comma separated, empty disables reboot) [$ADMIN_USER_IDS]: " ADMIN_USER_IDS_INPUT
    ADMIN_USER_IDS=${ADMIN_USER_IDS_INPUT:-$ADMIN_USER_IDS}
    
    # MikroTik Configuration
    MIKROTIK_ADDRESS=${MIKROTIK_ADDRESS:-}
    if [ -z "$MIKROTIK_ADDRESS" ]; then
        read -r -p "MikroTik Router IP or Hostname: " MIKROTIK_ADDRESS
        if [ -z "$MIKROTIK_ADDRESS" ]; then
            log_error "MikroTik Router Address is required!"
            exit 1
        fi
    fi
    
    MIKROTIK_USER=${MIKROTIK_USER:-admin}
    read -r -p "MikroTik API Username [$MIKROTIK_USER]: " MIKROTIK_USER_INPUT
    MIKROTIK_USER=${MIKROTIK_USER_INPUT:-$MIKROTIK_USER}
    
    MIKROTIK_PASSWORD=${MIKROTIK_PASSWORD:-}
    if [ -z "$MIKROTIK_PASSWORD" ]; then
        read -r -s -p "MikroTik API Password: " MIKROTIK_PASSWORD
        echo
        if [ -z "$MIKROTIK_PASSWORD" ]; then
            log_error "MikroTik Password is required!"
            exit 1
        fi
    fi
    
    MIKROTIK_PORT=${MIKROTIK_PORT:-8729}
    read -r -p "MikroTik API Port [$MIKROTIK_PORT]: " MIKROTIK_PORT_INPUT
    MIKROTIK_PORT=${MIKROTIK_PORT_INPUT:-$MIKROTIK_PORT}
    
    MIKROTIK_USE_SSL=${MIKROTIK_USE_SSL:-true}
    read -r -p "Use TLS for MikroTik API? (true/false) [$MIKROTIK_USE_SSL]: " MIKROTIK_USE_SSL_INPUT
    MIKROTIK_USE_SSL=${MIKROTIK_USE_SSL_INPUT:-$MIKROTIK_USE_SSL}
    
    MIKROTIK_CA_FILE=${MIKROTIK_CA_FILE:-}
    read -r -p "MikroTik CA Certificate File (optional, for self-signed certs): " MIKROTIK_CA_FILE
    
    # Bot Settings
    MONITOR_TARGET=${MONITOR_TARGET:-1.1.1.1}
    read -r -p "Monitor Target for Internet Check [$MONITOR_TARGET]: " MONITOR_TARGET_INPUT
    MONITOR_TARGET=${MONITOR_TARGET_INPUT:-$MONITOR_TARGET}
    
    TRAFFIC_INTERFACE=${TRAFFIC_INTERFACE:-}
    read -r -p "External Traffic Interface (optional): " TRAFFIC_INTERFACE
    
    # Export all variables for use in other functions
    export TELEGRAM_TOKEN CHAT_ID ALLOWED_CHAT_IDS ALLOWED_USER_IDS ADMIN_USER_IDS
    export MIKROTIK_ADDRESS MIKROTIK_USER MIKROTIK_PASSWORD MIKROTIK_PORT MIKROTIK_USE_SSL MIKROTIK_CA_FILE
    export MONITOR_TARGET TRAFFIC_INTERFACE
}

# =============================================================================
# CLOUDFLARE LOGIN
# =============================================================================

cloudflare_login() {
    log_header "Cloudflare Login"
    
    if npx wrangler whoami &> /dev/null; then
        log_success "Already logged in to Cloudflare!"
        WRANGLER_ACCOUNT=$(npx wrangler whoami 2>&1 | grep -oP 'id:\s*\K[^\s]+' || echo "unknown")
        log_info "Account ID: $WRANGLER_ACCOUNT"
        return 0
    fi
    
    log_info "Logging in to Cloudflare..."
    log_info "This will open a browser window for OAuth authentication."
    log_info "If browser doesn't open, copy the URL and open it manually."
    echo ""
    
    # Try to login
    if npx wrangler login 2>&1; then
        log_success "Successfully logged in to Cloudflare!"
        WRANGLER_ACCOUNT=$(npx wrangler whoami 2>&1 | grep -oP 'id:\s*\K[^\s]+' || echo "unknown")
        log_info "Account ID: $WRANGLER_ACCOUNT"
        return 0
    else
        log_error "Failed to login to Cloudflare"
        log_info "Please run: npx wrangler login"
        log_info "Then re-run this script."
        return 1
    fi
}

# =============================================================================
# CREATE KV NAMESPACES
# =============================================================================

create_kv_namespaces() {
    log_header "Creating KV Namespaces"
    
    # Create CONFIG namespace
    if [ -z "${KV_CONFIG_ID:-}" ]; then
        log_info "Creating CONFIG KV namespace..."
        KV_CONFIG_ID=$(npx wrangler kv:namespace create "MIKROTIK_BOT_CONFIG" 2>&1 | grep -oP '(?<=id: \")[^\"]+' | head -1 || echo "")
        
        if [ -z "$KV_CONFIG_ID" ]; then
            # Try alternative method
            KV_CONFIG_ID=$(npx wrangler kv:namespace create "MIKROTIK_BOT_CONFIG" 2>&1 | grep -oP '[0-9a-f]{32}' | head -1 || echo "")
        fi
        
        if [ -z "$KV_CONFIG_ID" ]; then
            log_error "Failed to create CONFIG KV namespace"
            log_info "Please create manually:"
            log_info "  npx wrangler kv:namespace create MIKROTIK_BOT_CONFIG"
            log_info "Then set KV_CONFIG_ID environment variable and re-run."
            return 1
        fi
        log_success "CONFIG KV Namespace created: $KV_CONFIG_ID"
    else
        log_info "Using existing CONFIG KV Namespace: $KV_CONFIG_ID"
    fi
    
    # Create USER_DATA namespace
    if [ -z "${KV_USER_ID:-}" ]; then
        log_info "Creating USER_DATA KV namespace..."
        KV_USER_ID=$(npx wrangler kv:namespace create "MIKROTIK_USER_DATA" 2>&1 | grep -oP '(?<=id: \")[^\"]+' | head -1 || echo "")
        
        if [ -z "$KV_USER_ID" ]; then
            KV_USER_ID=$(npx wrangler kv:namespace create "MIKROTIK_USER_DATA" 2>&1 | grep -oP '[0-9a-f]{32}' | head -1 || echo "")
        fi
        
        if [ -z "$KV_USER_ID" ]; then
            log_error "Failed to create USER_DATA KV namespace"
            log_info "Please create manually:"
            log_info "  npx wrangler kv:namespace create MIKROTIK_USER_DATA"
            log_info "Then set KV_USER_ID environment variable and re-run."
            return 1
        fi
        log_success "USER_DATA KV Namespace created: $KV_USER_ID"
    else
        log_info "Using existing USER_DATA KV Namespace: $KV_USER_ID"
    fi
    
    # Export for use in other functions
    export KV_CONFIG_ID KV_USER_ID
    return 0
}

# =============================================================================
# UPDATE WRANGLER.TOML
# =============================================================================

update_wrangler_toml() {
    log_header "Updating wrangler.toml"
    
    if [ ! -f "$SCRIPT_DIR/wrangler.toml" ]; then
        log_error "wrangler.toml not found in $SCRIPT_DIR"
        return 1
    fi
    
    # Backup original
    cp "$SCRIPT_DIR/wrangler.toml" "$SCRIPT_DIR/wrangler.toml.bak"
    log_info "Backup created: wrangler.toml.bak"
    
    # Update KV IDs
    sed -i "s/YOUR_KV_CONFIG_NAMESPACE_ID/$KV_CONFIG_ID/g" "$SCRIPT_DIR/wrangler.toml"
    sed -i "s/YOUR_KV_USER_DATA_NAMESPACE_ID/$KV_USER_ID/g" "$SCRIPT_DIR/wrangler.toml"
    
    log_success "wrangler.toml updated with KV namespace IDs"
    
    # Show the updated file
    echo ""
    log_info "Updated wrangler.toml:"
    cat "$SCRIPT_DIR/wrangler.toml"
    echo ""
    
    return 0
}

# =============================================================================
# INSTALL DEPENDENCIES
# =============================================================================

install_dependencies() {
    log_header "Installing Dependencies"
    
    cd "$SCRIPT_DIR"
    
    if [ -f "package.json" ]; then
        log_info "Installing npm packages..."
        if npm install 2>&1; then
            log_success "Dependencies installed successfully"
            return 0
        else
            log_error "Failed to install dependencies"
            return 1
        fi
    else
        log_info "No package.json found. Using default setup."
        return 0
    fi
}

# =============================================================================
# STORE CONFIGURATION IN KV
# =============================================================================

store_configuration() {
    log_header "Storing Configuration in KV"
    
    # Telegram Configuration
    log_info "Storing Telegram configuration..."
    npx wrangler kv:key put "TELEGRAM_TOKEN" "$TELEGRAM_TOKEN" --namespace-id "$KV_CONFIG_ID" || {
        log_error "Failed to store TELEGRAM_TOKEN"
        return 1
    }
    npx wrangler kv:key put "ALLOWED_CHAT_IDS" "$ALLOWED_CHAT_IDS" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "ALLOWED_USER_IDS" "$ALLOWED_USER_IDS" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "ADMIN_USER_IDS" "$ADMIN_USER_IDS" --namespace-id "$KV_CONFIG_ID"
    
    # MikroTik Configuration
    log_info "Storing MikroTik configuration..."
    npx wrangler kv:key put "MIKROTIK_ADDRESS" "$MIKROTIK_ADDRESS" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_USER" "$MIKROTIK_USER" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_PASSWORD" "$MIKROTIK_PASSWORD" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_PORT" "$MIKROTIK_PORT" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_USE_SSL" "$MIKROTIK_USE_SSL" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "MIKROTIK_CA_FILE" "$MIKROTIK_CA_FILE" --namespace-id "$KV_CONFIG_ID"
    
    # Bot Settings
    log_info "Storing bot settings..."
    npx wrangler kv:key put "MONITOR_TARGET" "$MONITOR_TARGET" --namespace-id "$KV_CONFIG_ID"
    npx wrangler kv:key put "TRAFFIC_INTERFACE" "$TRAFFIC_INTERFACE" --namespace-id "$KV_CONFIG_ID"
    
    log_success "All configuration stored in KV successfully!"
    
    return 0
}

# =============================================================================
# DEPLOY WORKER
# =============================================================================

deploy_worker() {
    log_header "Deploying Worker to Cloudflare"
    
    cd "$SCRIPT_DIR"
    
    log_info "Deploying worker..."
    DEPLOY_OUTPUT=$(npx wrangler deploy 2>&1) || {
        log_error "Failed to deploy worker"
        echo "$DEPLOY_OUTPUT"
        return 1
    }
    
    # Extract worker URL
    WORKER_URL=$(echo "$DEPLOY_OUTPUT" | grep -oP 'https://[^\s]+\.workers\.dev' | head -1 || echo "")
    
    if [ -z "$WORKER_URL" ]; then
        # Try alternative pattern
        WORKER_URL=$(echo "$DEPLOY_OUTPUT" | grep -oP 'https://[^\s]+\.workers\.dev' || echo "")
    fi
    
    if [ -z "$WORKER_URL" ]; then
        log_warning "Could not extract worker URL automatically"
        log_info "Deployment output:"
        echo "$DEPLOY_OUTPUT"
        read -r -p "Enter your Worker URL: " WORKER_URL
    fi
    
    export WORKER_URL
    log_success "Worker deployed successfully!"
    log_success "Worker URL: $WORKER_URL"
    
    return 0
}

# =============================================================================
# SETUP TELEGRAM WEBHOOK
# =============================================================================

setup_webhook() {
    log_header "Setting Up Telegram Webhook"
    
    WEBHOOK_URL="$WORKER_URL/webhook"
    log_info "Webhook URL: $WEBHOOK_URL"
    
    # Set webhook
    log_info "Setting webhook with Telegram..."
    SET_WEBHOOK_OUTPUT=$(curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/setWebhook" \
        -H "Content-Type: application/json" \
        -d "{\"url\": \"$WEBHOOK_URL\"}" 2>&1) || true
    
    # Check result
    if echo "$SET_WEBHOOK_OUTPUT" | grep -q '"ok":true'; then
        log_success "Telegram webhook set successfully!"
    else
        log_warning "Failed to set webhook automatically"
        log_info "Response: $SET_WEBHOOK_OUTPUT"
        log_info "Please manually set webhook with:"
        echo ""
        log_info "curl -X POST \\"
        log_info "  https://api.telegram.org/bot$TELEGRAM_TOKEN/setWebhook \\"
        log_info "  -H 'Content-Type: application/json' \\"
        log_info "  -d '{\"url\": \"$WEBHOOK_URL\"}'"
        echo ""
        return 1
    fi
    
    # Verify webhook
    log_info "Verifying webhook..."
    WEBHOOK_INFO=$(curl -s -X GET "https://api.telegram.org/bot$TELEGRAM_TOKEN/getWebhookInfo" 2>&1) || true
    
    if echo "$WEBHOOK_INFO" | grep -q '"ok":true'; then
        WEBHOOK_URL_FROM_API=$(echo "$WEBHOOK_INFO" | grep -oP '"url":\s*"\K[^"]+' || echo "")
        if [ "$WEBHOOK_URL_FROM_API" = "$WEBHOOK_URL" ]; then
            log_success "Webhook verified! URL matches."
        else
            log_warning "Webhook URL mismatch!"
            log_info "Expected: $WEBHOOK_URL"
            log_info "Actual: $WEBHOOK_URL_FROM_API"
        fi
    else
        log_warning "Could not verify webhook"
    fi
    
    export WEBHOOK_URL
    return 0
}

# =============================================================================
# TEST WORKER
# =============================================================================

test_worker() {
    log_header "Testing Worker"
    
    # Test health endpoint
    log_info "Testing health endpoint..."
    HEALTH_TEST=$(curl -s -X GET "$WORKER_URL/health" 2>&1) || true
    
    if echo "$HEALTH_TEST" | grep -q '"status":"ok"'; then
        log_success "Health check passed!"
    else
        log_warning "Health check failed"
        log_info "Response: $HEALTH_TEST"
    fi
    
    # Test with a sample update
    log_info "Testing with sample Telegram update..."
    SAMPLE_TEST=$(curl -s -X POST "$WORKER_URL/webhook" \
        -H "Content-Type: application/json" \
        -d '{"update_id":1,"message":{"chat":{"id":'$CHAT_ID'},"from":{"id":'"$ALLOWED_USER_IDS"'},"text":"/start"}}' 2>&1) || true
    
    log_info "Sample test response: $SAMPLE_TEST"
    
    return 0
}

# =============================================================================
# SHOW SUMMARY
# =============================================================================

show_summary() {
    log_header "Deployment Summary"
    
    echo ""
    log_success "✅ Cloudflare Login: Successful"
    log_success "✅ KV Namespaces:"
    log_success "   CONFIG: $KV_CONFIG_ID"
    log_success "   USER_DATA: $KV_USER_ID"
    log_success "✅ Worker URL: $WORKER_URL"
    log_success "✅ Webhook URL: $WEBHOOK_URL"
    
    echo ""
    log_info "Configuration stored in KV:"
    log_info "  - Telegram Token: *** (hidden)"
    log_info "  - Allowed Chat IDs: $ALLOWED_CHAT_IDS"
    log_info "  - Allowed User IDs: $ALLOWED_USER_IDS"
    log_info "  - MikroTik Address: $MIKROTIK_ADDRESS"
    log_info "  - MikroTik User: $MIKROTIK_USER"
    log_info "  - MikroTik Port: $MIKROTIK_PORT"
    log_info "  - Use TLS: $MIKROTIK_USE_SSL"
    
    echo ""
    log_info "Next Steps:"
    log_info "1. Send a message to your Telegram bot"
    log_info "2. Try commands: /start, /status, /users, /active"
    log_info "3. Check worker logs: npx wrangler tail"
    
    echo ""
    log_info "Useful Commands:"
    log_info "  - View logs: cd $SCRIPT_DIR && npx wrangler tail"
    log_info "  - Redeploy: cd $SCRIPT_DIR && npx wrangler deploy"
    log_info "  - Delete: cd $SCRIPT_DIR && npx wrangler delete"
    log_info "  - Update KV: npx wrangler kv:key put KEY VALUE --namespace-id ID"
    
    echo ""
    log_success "Deployment completed successfully! 🎉"
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    echo -e "${CYAN}
╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   MikroTik Telegram Bot - Full Deployment Script        ║${NC}"
    echo -e "${CYAN}║   Automated Cloudflare Workers Deployment              ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    
    # Step 1: Collect Configuration
    if ! collect_config; then
        exit 1
    fi
    
    # Step 2: Cloudflare Login
    if ! cloudflare_login; then
        exit 1
    fi
    
    # Step 3: Create KV Namespaces
    if ! create_kv_namespaces; then
        exit 1
    fi
    
    # Step 4: Update wrangler.toml
    if ! update_wrangler_toml; then
        exit 1
    fi
    
    # Step 5: Install Dependencies
    if ! install_dependencies; then
        exit 1
    fi
    
    # Step 6: Store Configuration
    if ! store_configuration; then
        exit 1
    fi
    
    # Step 7: Deploy Worker
    if ! deploy_worker; then
        exit 1
    fi
    
    # Step 8: Setup Webhook
    if ! setup_webhook; then
        log_warning "Webhook setup may have failed, but worker is deployed"
    fi
    
    # Step 9: Test Worker
    test_worker
    
    # Step 10: Show Summary
    show_summary
    
    return 0
}

# Run main
main "$@"
