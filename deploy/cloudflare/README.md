# MikroTik Telegram Bot - Cloudflare Workers Deployment

## 📋 Overview

This deployment method uses **Cloudflare Workers** to host your Telegram bot, which then connects to your MikroTik RouterOS via its API. This is ideal for:

- ✅ **No need for a dedicated server** - Runs on Cloudflare's edge network
- ✅ **Automatic scaling** - Handles traffic spikes automatically
- ✅ **Global availability** - Low latency worldwide
- ✅ **Secure** - Uses Cloudflare's security features
- ✅ **Free tier available** - Up to 100,000 requests/day free

## 🚀 Quick Start

### Prerequisites

1. [Node.js](https://nodejs.org/) (v16 or later)
2. [npm](https://www.npmjs.com/) or [yarn](https://yarnpkg.com/)
3. [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/)
4. [Cloudflare Account](https://dash.cloudflare.com/sign-up)
5. MikroTik RouterOS with API enabled

### Installation

```bash
# Install Wrangler CLI globally
npm install -g wrangler

# Or use npx (no installation needed)
npx wrangler --version
```

## 🛠 Deployment Steps

### 1. Clone the Repository

```bash
cd /home/user/MikroTikfinal007
```

### 2. Navigate to Cloudflare Deployment Directory

```bash
cd deploy/cloudflare
```

### 3. Install Dependencies

```bash
npm install
```

### 4. Login to Cloudflare

```bash
# Login with your Cloudflare account
wrangler login
```

### 5. Create KV Namespaces

```bash
# Create namespace for configuration (stores sensitive data)
KV_CONFIG_NAMESPACE_ID=$(wrangler kv:namespace create "MIKROTIK_BOT_CONFIG")

# Create namespace for user data (stores updates, responses, etc.)
KV_USER_DATA_NAMESPACE_ID=$(wrangler kv:namespace create "MIKROTIK_USER_DATA")

# Extract the IDs (they will be in the output)
# Or get existing namespaces:
wrangler kv:namespace list
```

### 6. Update wrangler.toml

Edit `wrangler.toml` and replace the KV namespace IDs:

```toml
[[kv_namespaces]]
binding = "CONFIG"
id = "YOUR_KV_CONFIG_NAMESPACE_ID"  # Replace with actual ID

[[kv_namespaces]]
binding = "USER_DATA"
id = "YOUR_KV_USER_DATA_NAMESPACE_ID"  # Replace with actual ID
```

### 7. Configure Environment Variables

Set your configuration in Cloudflare KV:

```bash
# Set Telegram Token
wrangler kv:key put "TELEGRAM_TOKEN" "YOUR_TELEGRAM_BOT_TOKEN" --namespace-id "$KV_CONFIG_NAMESPACE_ID"

# Set MikroTik Configuration
wrangler kv:key put "MIKROTIK_ADDRESS" "your-router-ip" --namespace-id "$KV_CONFIG_NAMESPACE_ID"
wrangler kv:key put "MIKROTIK_USER" "admin" --namespace-id "$KV_CONFIG_NAMESPACE_ID"
wrangler kv:key put "MIKROTIK_PASSWORD" "your-password" --namespace-id "$KV_CONFIG_NAMESPACE_ID"
wrangler kv:key put "MIKROTIK_PORT" "8729" --namespace-id "$KV_CONFIG_NAMESPACE_ID"
wrangler kv:key put "MIKROTIK_USE_SSL" "true" --namespace-id "$KV_CONFIG_NAMESPACE_ID"

# Set Allowed IDs
wrangler kv:key put "ALLOWED_CHAT_IDS" "5944227208" --namespace-id "$KV_CONFIG_NAMESPACE_ID"
wrangler kv:key put "ALLOWED_USER_IDS" "5944227208" --namespace-id "$KV_CONFIG_NAMESPACE_ID"
wrangler kv:key put "ADMIN_USER_IDS" "5944227208" --namespace-id "$KV_CONFIG_NAMESPACE_ID"

# Set Monitor Target
wrangler kv:key put "MONITOR_TARGET" "1.1.1.1" --namespace-id "$KV_CONFIG_NAMESPACE_ID"
```

### 8. Deploy to Cloudflare

```bash
# Deploy the worker
npm run deploy

# Or manually:
wrangler deploy
```

### 9. Set Up Telegram Webhook

After deployment, you'll get a URL like `https://mikrotik-telegram-bot.YOUR_SUBDOMAIN.workers.dev`

```bash
# Set webhook (replace with your actual worker URL)
WORKER_URL="https://mikrotik-telegram-bot.YOUR_SUBDOMAIN.workers.dev"
curl -X POST "https://api.telegram.org/botYOUR_TELEGRAM_BOT_TOKEN/setWebhook" \
  -H "Content-Type: application/json" \
  -d "{\"url\": \"$WORKER_URL/webhook\"}"
```

### 10. Test Your Bot

Send a message to your Telegram bot with one of these commands:
- `/start` - Show welcome message
- `/status` - Get router status
- `/users` - List users
- `/help` - Show help

## 📝 Available Commands

| Command | Description | Admin Only |
|---------|-------------|------------|
| `/start` | Show welcome message | ❌ |
| `/help` | Show help | ❌ |
| `/status` | Router status | ❌ |
| `/resources` | System resources | ❌ |
| `/uptime` | Router uptime | ❌ |
| `/users` | List users | ❌ |
| `/active` | Active users | ❌ |
| `/interfaces` | Network interfaces | ❌ |
| `/profiles` | User profiles | ❌ |
| `/reboot` | Reboot router | ✅ |

## 🔒 Security Considerations

1. **KV Namespaces are private** - Only your worker can access them
2. **No secrets in code** - All sensitive data is stored in KV
3. **HTTPS by default** - All traffic is encrypted
4. **Rate limiting** - Cloudflare provides built-in DDoS protection

## 📊 Monitoring

### View Logs

```bash
# Tail logs in real-time
npm run tail

# Or with wrangler
wrangler tail
```

### Check Worker Status

```bash
# Test health endpoint
curl https://mikrotik-telegram-bot.YOUR_SUBDOMAIN.workers.dev/health

# Get configuration (masked)
curl https://mikrotik-telegram-bot.YOUR_SUBDOMAIN.workers.dev/config
```

## 🔄 Updates

### Update Configuration

```bash
# Update any configuration value
wrangler kv:key put "KEY_NAME" "NEW_VALUE" --namespace-id "$KV_CONFIG_NAMESPACE_ID"
```

### Redeploy

```bash
# After making changes to worker.js
npm run deploy
```

## ❌ Troubleshooting

### Common Issues

1. **"Bot not configured"**
   - Make sure you've set all required KV values
   - Check namespace IDs in wrangler.toml

2. **"Not authorized"**
   - Verify your Chat ID and User ID are in ALLOWED_CHAT_IDS and ALLOWED_USER_IDS
   - Use `/start` to test basic connectivity

3. **"MikroTik not configured"**
   - Check MIKROTIK_ADDRESS, MIKROTIK_USER, MIKROTIK_PASSWORD are set
   - Verify the router API is accessible

4. **Webhook not working**
   - Check the webhook URL is correct
   - Verify the worker is deployed successfully
   - Test with `curl -X POST https://YOUR_WORKER/webhook -d '{"update_id":1}'`

### Debug Mode

For local development:

```bash
# Run in development mode
npm run dev

# Test locally with curl
curl -X POST http://localhost:8787/webhook \
  -H "Content-Type: application/json" \
  -d '{"update_id":1,"message":{"chat":{"id":5944227208},"text":"/status"}}'
```

## 📚 Additional Resources

- [Cloudflare Workers Documentation](https://developers.cloudflare.com/workers/)
- [Wrangler CLI Documentation](https://developers.cloudflare.com/workers/wrangler/)
- [Telegram Bot API](https://core.telegram.org/bots/api)
- [MikroTik RouterOS API](https://help.mikrotik.com/docs/pages/viewpage.action?pageId=424334)

## 🎯 Next Steps

1. **Add more commands** - Extend the bot with custom commands
2. **Add authentication** - Implement admin verification
3. **Add monitoring** - Set up alerts for router issues
4. **Add logging** - Store logs in KV or external service
5. **Add backup** - Automatically backup router configuration

---

**Version:** 1.0.0  
**Last Updated:** August 2025  
**Maintainer:** Nassar Alshabi
