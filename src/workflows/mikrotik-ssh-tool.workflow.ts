import {
  workflow,
  node,
  trigger,
  newCredential,
  expr,
} from '@n8n/workflow-sdk';

const inputTrigger = trigger({
  type: 'n8n-nodes-base.executeWorkflowTrigger',
  version: 1.1,
  config: {
    name: 'Tool Input',
    parameters: {
      inputSource: 'workflowInputs',
      workflowInputs: {
        values: [{ name: 'command', type: 'string' }],
      },
    },
  },
});

const runSsh = node({
  type: 'n8n-nodes-base.ssh',
  version: 1,
  config: {
    name: 'Run RouterOS Command',
    parameters: {
      resource: 'command',
      operation: 'execute',
      authentication: 'password',
      command: expr('{{ $json.command }}'),
      cwd: '/',
    },
    credentials: {
      sshPassword: newCredential('MikroTik SSH'),
    },
    output: [
      {
        code: 0,
        signal: null,
        stderr: '',
        stdout: 'active users: 25',
      },
    ],
  },
});

const formatResult = node({
  type: 'n8n-nodes-base.set',
  version: 3.4,
  config: {
    name: 'Format Result',
    parameters: {
      mode: 'manual',
      assignments: {
        assignments: [
          {
            id: 'result',
            name: 'result',
            type: 'string',
            value: expr(
              '{{ $json.stdout && $json.stdout.trim() ? $json.stdout : ($json.stderr ? "ERROR: " + $json.stderr : "(no output)") }}',
            ),
          },
        ],
      },
    },
  },
});

export default workflow('mikrotik-ssh-tool', 'MikroTik SSH Command Tool')
  .add(inputTrigger)
  .to(runSsh)
  .to(formatResult);
