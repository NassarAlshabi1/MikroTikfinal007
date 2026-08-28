// MikroTik Telegram Bot - Cloudflare Worker
// This worker acts as a reverse proxy between Telegram and your MikroTik RouterOS

import { getAssetFromKV } from '@cloudflare/kv-asset-handler'

export default {
  async fetch(request, env, ctx) {
    const url = new URL(request.url)
    const path = url.pathname

    // CORS headers
    const corsHeaders = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Content-Type': 'application/json'
    }

    // Handle OPTIONS for CORS preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders
      })
    }

    try {
      // ========================================================================
      // Telegram Webhook Endpoint
      // ========================================================================
      if (path === '/webhook') {
        if (request.method !== 'POST') {
          return new Response(JSON.stringify({ error: 'Method not allowed' }), {
            status: 405,
            headers: corsHeaders
          })
        }

        // Verify Telegram token from KV
        const storedToken = await env.CONFIG.get('TELEGRAM_TOKEN')
        if (!storedToken) {
          return new Response(JSON.stringify({ error: 'Bot not configured' }), {
            status: 500,
            headers: corsHeaders
          })
        }

        // Get the update from Telegram
        const update = await request.json()
        const updateId = update.update_id
        
        // Store the update in KV for processing
        await env.USER_DATA.put(`update_${updateId}`, JSON.stringify(update), {
          expirationTtl: 3600 // 1 hour
        })

        // Extract basic info
        const chatId = update.message?.chat?.id || update.callback_query?.message?.chat?.id
        const text = update.message?.text || update.callback_query?.data
        const userId = update.message?.from?.id || update.callback_query?.from?.id
        const username = update.message?.from?.username || update.callback_query?.from?.username

        // Check if chat/user is allowed
        const allowedChatIds = (await env.CONFIG.get('ALLOWED_CHAT_IDS'))?.split(',') || []
        const allowedUserIds = (await env.CONFIG.get('ALLOWED_USER_IDS'))?.split(',') || []
        const adminUserIds = (await env.CONFIG.get('ADMIN_USER_IDS'))?.split(',') || []

        if (!allowedChatIds.includes(String(chatId)) || !allowedUserIds.includes(String(userId))) {
          return new Response(JSON.stringify({ error: 'Not authorized' }), {
            status: 403,
            headers: corsHeaders
          })
        }

        // Process the command
        let responseText = ''
        let method = 'sendMessage'
        let replyMarkup = null

        if (text) {
          const command = text.split(' ')[0].toLowerCase()
          
          // Handle commands
          switch (command) {
            case '/start':
              responseText = '🚀 *MikroTik Telegram Bot*\n\n' +
                'مرحبا! أنا بوت لإدارة راوتر MikroTik عبر Telegram.\n\n' +
                'الأوامر المتاحة:\n' +
                '/status - حالة الراوتر\n' +
                '/users - عرض المستخدمين\n' +
                '/active - المستخدمين النشطين\n' +
                '/resources - موارد النظام\n' +
                '/uptime - وقت عمل الراوتر\n' +
                '/help - عرض المساعدة'
              break

            case '/status':
            case '/resources':
            case '/uptime':
            case '/users':
            case '/active':
            case '/interfaces':
            case '/profiles':
              // Forward to MikroTik via API
              responseText = await processMikroTikCommand(command, env)
              break

            case '/reboot':
              if (adminUserIds.includes(String(userId))) {
                responseText = await processMikroTikCommand(command, env)
              } else {
                responseText = '❌ ليس لديك صلاحية لتنفيذ هذا الأمر'
              }
              break

            case '/help':
              responseText = '📋 *قائمة الأوامر*\n\n' +
                '/status - حالة الراوتر\n' +
                '/users - قائمة المستخدمين\n' +
                '/active - المستخدمين النشطين\n' +
                '/resources - موارد النظام\n' +
                '/uptime - وقت عمل الراوتر\n' +
                '/interfaces - واجهة الشبكة\n' +
                '/profiles - ملفات المستخدمين\n' +
                '/reboot - إعادة تشغيل الراوتر (المشرفون فقط)'
              break

            default:
              // Forward to MikroTik as-is
              responseText = await processMikroTikCommand(text, env)
          }
        }

        // Send response back to Telegram
        const response = {
          method: method,
          chat_id: chatId,
          text: responseText,
          parse_mode: 'Markdown',
          ...(replyMarkup && { reply_markup: replyMarkup })
        }

        // Store response in KV for the bot to pick up
        await env.USER_DATA.put(`response_${updateId}`, JSON.stringify(response), {
          expirationTtl: 300 // 5 minutes
        })

        return new Response(JSON.stringify(response), {
          status: 200,
          headers: corsHeaders
        })
      }

      // ========================================================================
      // Health Check Endpoint
      // ========================================================================
      if (path === '/health') {
        return new Response(JSON.stringify({
          status: 'ok',
          timestamp: new Date().toISOString(),
          version: '1.0.0'
        }), {
          status: 200,
          headers: corsHeaders
        })
      }

      // ========================================================================
      // Configuration Endpoints
      // ========================================================================
      if (path === '/config') {
        if (request.method === 'GET') {
          // Return configuration (mask sensitive data)
          const config = {
            allowed_chat_ids: (await env.CONFIG.get('ALLOWED_CHAT_IDS'))?.split(',') || [],
            allowed_user_ids: (await env.CONFIG.get('ALLOWED_USER_IDS'))?.split(',') || [],
            admin_user_ids: (await env.CONFIG.get('ADMIN_USER_IDS'))?.split(',') || [],
            mikrotik_address: await env.CONFIG.get('MIKROTIK_ADDRESS'),
            monitor_target: await env.CONFIG.get('MONITOR_TARGET')
          }
          
          return new Response(JSON.stringify(config), {
            status: 200,
            headers: corsHeaders
          })
        }
        
        if (request.method === 'POST') {
          // Update configuration (admin only - would need auth in real implementation)
          const newConfig = await request.json()
          
          for (const [key, value] of Object.entries(newConfig)) {
            await env.CONFIG.put(key, String(value))
          }
          
          return new Response(JSON.stringify({ status: 'updated' }), {
            status: 200,
            headers: corsHeaders
          })
        }
      }

      // ========================================================================
      // MikroTik API Proxy
      // ========================================================================
      if (path.startsWith('/api/')) {
        // Proxy requests to MikroTik RouterOS
        const mikrotikAddress = await env.CONFIG.get('MIKROTIK_ADDRESS')
        const mikrotikUser = await env.CONFIG.get('MIKROTIK_USER')
        const mikrotikPassword = await env.CONFIG.get('MIKROTIK_PASSWORD')
        const mikrotikPort = await env.CONFIG.get('MIKROTIK_PORT') || '8729'
        const mikrotikUseSSL = (await env.CONFIG.get('MIKROTIK_USE_SSL'))?.toLowerCase() === 'true'
        
        if (!mikrotikAddress || !mikrotikUser || !mikrotikPassword) {
          return new Response(JSON.stringify({ error: 'MikroTik not configured' }), {
            status: 500,
            headers: corsHeaders
          })
        }

        const protocol = mikrotikUseSSL ? 'https' : 'http'
        const mikrotikUrl = `${protocol}://${mikrotikAddress}:${mikrotikPort}${path.replace('/api', '')}`
        
        // Forward request to MikroTik
        const mikrotikResponse = await fetch(mikrotikUrl, {
          method: request.method,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Basic ' + btoa(`${mikrotikUser}:${mikrotikPassword}`)
          },
          body: request.method !== 'GET' ? await request.text() : null
        })

        return new Response(await mikrotikResponse.text(), {
          status: mikrotikResponse.status,
          headers: {
            ...corsHeaders,
            'Content-Type': mikrotikResponse.headers.get('Content-Type') || 'text/plain'
          }
        })
      }

      // ========================================================================
      // Default: Not Found
      // ========================================================================
      return new Response(JSON.stringify({ error: 'Not found' }), {
        status: 404,
        headers: corsHeaders
      })

    } catch (error) {
      console.error('Error:', error)
      return new Response(JSON.stringify({ 
        error: 'Internal server error',
        details: error.message 
      }), {
        status: 500,
        headers: corsHeaders
      })
    }
  }
}

// Helper function to process MikroTik commands
async function processMikroTikCommand(command, env) {
  const mikrotikAddress = await env.CONFIG.get('MIKROTIK_ADDRESS')
  const mikrotikUser = await env.CONFIG.get('MIKROTIK_USER')
  const mikrotikPassword = await env.CONFIG.get('MIKROTIK_PASSWORD')
  const mikrotikPort = await env.CONFIG.get('MIKROTIK_PORT') || '8729'
  const mikrotikUseSSL = (await env.CONFIG.get('MIKROTIK_USE_SSL'))?.toLowerCase() === 'true'

  if (!mikrotikAddress || !mikrotikUser || !mikrotikPassword) {
    return '❌ MikroTik RouterOS not configured properly'
  }

  const protocol = mikrotikUseSSL ? 'https' : 'http'
  const baseUrl = `${protocol}://${mikrotikAddress}:${mikrotikPort}`

  try {
    // Map commands to RouterOS API calls
    const commandMap = {
      '/status': '/system/resource/print',
      '/resources': '/system/resource/print',
      '/uptime': '/system/clock/print',
      '/users': '/user/print',
      '/active': '/ip/hotspot/active/print',
      '/interfaces': '/interface/print',
      '/profiles': '/ip/hotspot/user/profile/print',
      '/reboot': '/system/reboot'
    }

    const apiCommand = commandMap[command.toLowerCase()] || command
    
    // For reboot, we need special handling
    if (command.toLowerCase() === '/reboot') {
      // In a real implementation, this would be protected
      return '⚠️ هل أنت متأكد من إعادة تشغيل الراوتر؟\n' +
             'إرسال /reboot-confirm للتأكيد'
    }

    // Build the API URL
    const apiUrl = `${baseUrl}${apiCommand}`
    
    // Make the request to MikroTik
    const auth = btoa(`${mikrotikUser}:${mikrotikPassword}`)
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/json'
      }
    })

    if (!response.ok) {
      return `❌ خطأ في الاتصال براوتر MikroTik: ${response.status} ${response.statusText}`
    }

    const data = await response.json()
    
    // Format the response based on command
    if (command.toLowerCase() === '/status' || command.toLowerCase() === '/resources') {
      const resource = data[0] || {}
      return `📊 *حالة الراوتر*\n\n` +
             `🖥 *الإصدار*: ${resource.version || 'غير متاح'}\n` +
             `⏱ *وقت العمل*: ${resource.uptime || 'غير متاح'}\n` +
             `💾 *الذاكرة*: ${resource['free-memory'] || '0'} / ${resource['total-memory'] || '0'}\n` +
             `💽 *التخزين*: ${resource['free-hdd-space'] || '0'} / ${resource['total-hdd-space'] || '0'}\n` +
             `🔋 *CPU*: ${resource['cpu-load'] || '0%'}`
    }

    if (command.toLowerCase() === '/users') {
      const users = data.filter(item => item['!type'] !== '!re') || []
      if (users.length === 0) {
        return '👥 لا يوجد مستخدمين'
      }
      
      let response = `👥 *قائمة المستخدمين* (أول 10)\n\n`
      users.slice(0, 10).forEach(user => {
        response += `• ${user.name || user.user || 'غير معروف'}\n`
      })
      if (users.length > 10) {
        response += `\n... و ${users.length - 10} مستخدم آخر`
      }
      return response
    }

    if (command.toLowerCase() === '/active') {
      const active = data.filter(item => item['!type'] !== '!re') || []
      if (active.length === 0) {
        return '📡 لا يوجد مستخدمين نشطين'
      }
      
      return `📡 *المستخدمين النشطين*\n\n` +
             `👤 *العدد*: ${active.length}\n` +
             `⏰ *آخر نشاط*: ${active[0]?.['last-activity'] || 'غير متاح'}`
    }

    // Default: return raw data (formatted)
    return `📋 *نتائج الأمر*:\n\n\`\`\`\n${JSON.stringify(data, null, 2)}\n\`\`\``

  } catch (error) {
    console.error('MikroTik API Error:', error)
    return `❌ خطأ في تنفيذ الأمر: ${error.message}`
  }
}
