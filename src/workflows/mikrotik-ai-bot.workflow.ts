import {
  workflow,
  node,
  trigger,
  newCredential,
  languageModel,
  memory,
  tool,
  nodeJson,
  expr,
} from '@n8n/workflow-sdk';

const telegramTrigger = trigger({
  type: 'n8n-nodes-base.telegramTrigger',
  version: 1.5,
  config: {
    name: 'Telegram Trigger',
    parameters: {
      updates: ['message'],
    },
    credentials: {
      telegramApi: newCredential('Telegram Bot'),
    },
    output: [
      {
        message: {
          message_id: 101,
          from: { id: 123456789, is_bot: false, first_name: 'Admin' },
          chat: { id: 123456789, first_name: 'Admin', type: 'private' },
          date: 1756172400,
          text: 'كم عدد المستخدمين المتصلين الآن؟',
        },
      },
    ],
  },
});

const systemMessage = `أنت مساعد ذكي لإدارة راوتر MikroTik يعمل بنظام RouterOS v6 مع User Manager v1.
تتلقى رسائل من المستخدم باللغة العربية وتحوّلها إلى أوامر RouterOS الصحيحة، ثم تنفّذها عبر الأداة run_router_command.
الأداة run_router_command تأخذ حقلاً واحداً اسمه command يحتوي أمر RouterOS CLI كاملاً، وتُعيد النص الناتج من الراوتر.

إعدادات هذا الراوتر:
- نوع اتصال الزبائن: Hotspot.
- الـ customer/owner في User Manager: admin.
- عند إنشاء كرت: ولّد رقماً عشوائياً مكوّناً من 8 أرقام واستخدمه كـ username وكلمة المرور معاً (اسم المستخدم = كلمة المرور).
- اسم الباقة (profile) يؤخذ من طلب المستخدم (مثلاً «كرت ابو 200» ← الباقة 200).

أمثلة على تحويل الطلبات إلى أوامر RouterOS v6:
- عدد المستخدمين المتصلين حالياً: /ip hotspot active print count-only
- حالة النظام (المعالج/الذاكرة/مدة التشغيل): /system resource print
- إعادة تشغيل الراوتر: /system reboot  (نفّذه فقط بعد تأكيد صريح من المستخدم)
- إنشاء كرت User Manager (رقم عشوائي 8 أرقام): /tool user-manager user add customer=admin username=<الرقم> password=<الرقم نفسه>  ثم ربط الباقة: /tool user-manager user create-and-activate-profile customer=admin user=<الرقم> profile=<اسم الباقة>  وبعد الإنشاء أبلغ المستخدم برقم الكرت.
- حذف الكروت المنتهية: راجع /tool user-manager user print ثم احذف المنتهية (لا تحذف إلا بعد تأكيد المستخدم)
- فحص كرت معيّن: /tool user-manager user print where username=<الرقم>  و  /tool user-manager session print where user=<الرقم>

قواعد مهمة:
1. لا تنفّذ أي أمر مدمّر (إعادة تشغيل، حذف) إلا بعد أن يؤكد المستخدم صراحةً.
2. إذا لم تكن متأكداً من الأمر الصحيح، اسأل المستخدم بدل التخمين.
3. لخّص النتيجة للمستخدم بالعربية بشكل واضح ومنسّق.
4. لا تخترع أرقاماً أو نتائج — اعتمد فقط على ما تُعيده الأداة.`;

const aiAgent = node({
  type: '@n8n/n8n-nodes-langchain.agent',
  version: 3.1,
  config: {
    name: 'MikroTik AI Agent',
    parameters: {
      promptType: 'define',
      text: expr('{{ $json.message.text }}'),
      options: {
        systemMessage,
      },
    },
    subnodes: {
      model: languageModel({
        type: '@n8n/n8n-nodes-langchain.lmChatOpenAi',
        version: 1.3,
        config: {
          name: 'OpenAI Chat Model',
          parameters: {
            model: { __rl: true, mode: 'list', value: 'gpt-5-mini' },
          },
          credentials: {
            openAiApi: newCredential('OpenAI account'),
          },
        },
      }),
      memory: memory({
        type: '@n8n/n8n-nodes-langchain.memoryBufferWindow',
        version: 1.4,
        config: {
          name: 'Chat Memory',
          parameters: {
            sessionIdType: 'customKey',
            sessionKey: nodeJson(telegramTrigger, 'message.chat.id'),
            contextWindowLength: 10,
          },
        },
      }),
      tools: [
        tool({
          type: '@n8n/n8n-nodes-langchain.toolWorkflow',
          version: 2.2,
          config: {
            name: 'run_router_command',
            parameters: {
              description:
                'Executes a RouterOS CLI command on the MikroTik router over SSH and returns the raw text output. Input: a single field "command" containing the full RouterOS command.',
              source: 'database',
              workflowId: {
                __rl: true,
                mode: 'id',
                value: 'JjpxVRsYmUT1kxCV',
                cachedResultName: 'MikroTik SSH Command Tool',
              },
              workflowInputs: {
                mappingMode: 'defineBelow',
                value: {
                  command: expr("{{ $fromAI('command', 'The full RouterOS CLI command to execute', 'string') }}"),
                },
                schema: [
                  {
                    id: 'command',
                    displayName: 'command',
                    type: 'string',
                    required: true,
                    display: true,
                    canBeUsedToMatch: true,
                  },
                ],
                matchingColumns: [],
              },
            },
          },
        }),
      ],
    },
  },
});

const sendReply = node({
  type: 'n8n-nodes-base.telegram',
  version: 1.2,
  config: {
    name: 'Send Telegram Reply',
    parameters: {
      resource: 'message',
      operation: 'sendMessage',
      chatId: nodeJson(telegramTrigger, 'message.chat.id'),
      text: expr('{{ $json.output }}'),
      additionalFields: {
        appendAttribution: false,
      },
    },
    credentials: {
      telegramApi: newCredential('Telegram Bot'),
    },
  },
});

export default workflow('mikrotik-ai-bot', 'MikroTik AI Telegram Bot')
  .add(telegramTrigger)
  .to(aiAgent)
  .to(sendReply);
