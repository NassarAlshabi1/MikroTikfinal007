import {
  workflow,
  node,
  trigger,
  newCredential,
  placeholder,
  expr,
} from '@n8n/workflow-sdk';

const webhook = trigger({
  type: 'n8n-nodes-base.webhook',
  version: 2,
  config: {
    name: 'MikroTik Alert Webhook',
    parameters: {
      httpMethod: 'POST',
      path: 'mikrotik-alert',
      responseMode: 'onReceived',
    },
    output: [
      {
        body: {
          message: 'Interface ether1 is DOWN at 2026-08-26 04:40:00',
        },
      },
    ],
  },
});

const sendTelegram = node({
  type: 'n8n-nodes-base.telegram',
  version: 1.2,
  config: {
    name: 'Send Telegram Alert',
    parameters: {
      resource: 'message',
      operation: 'sendMessage',
      chatId: placeholder('Telegram chat ID to send alerts to'),
      text: expr('🚨 MikroTik Alert\n\n{{ $json.body.message }}'),
      additionalFields: {
        appendAttribution: false,
      },
    },
    credentials: {
      telegramApi: newCredential('Telegram account'),
    },
  },
});

export default workflow('telegram-mikrotik-alerts', 'Telegram MikroTik Alerts')
  .add(webhook)
  .to(sendTelegram);
