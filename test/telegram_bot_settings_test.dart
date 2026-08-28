import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/services/telegram_bot_settings.dart';

void main() {
  test('uses RouterOS v6 bot defaults', () {
    final settings = TelegramBotSettings.defaults();

    expect(settings.deploymentMode, TelegramDeploymentMode.routerOsScript);
    expect(settings.botToken, isEmpty);
    expect(settings.pollSeconds, 20);
    expect(settings.routerPollSeconds, 10);
    expect(settings.monitorTarget, '1.1.1.1');
    expect(settings.monitorIntervalSeconds, 30);
    expect(settings.trafficInterface, 'ether1');
    expect(settings.trafficIntervalSeconds, 60);
    expect(settings.dailyReportTime, '23:59');
    expect(settings.umCustomer, 'admin');
    expect(settings.umProfile, 'default');
    expect(settings.defaultCardLimit, '1w');
    expect(settings.workerUrl, isEmpty);
    expect(settings.isConfigured, isFalse);
  });

  test('copyWith preserves values not explicitly changed', () {
    final settings = TelegramBotSettings.defaults(botToken: 'token').copyWith(
        allowedChatIds: '5944227208',
        allowedUserIds: '5944227208',
        trafficInterface: 'pppoe-out1');

    expect(settings.botToken, 'token');
    expect(settings.allowedChatIds, '5944227208');
    expect(settings.trafficInterface, 'pppoe-out1');
    expect(settings.pollSeconds, 20);
    expect(settings.isConfigured, isTrue);
  });

  test('router mode requires UM customer and profile', () {
    final base = TelegramBotSettings.defaults(
      botToken: 'token',
    ).copyWith(allowedChatIds: '5944227208', allowedUserIds: '5944227208');

    expect(base.deploymentMode, TelegramDeploymentMode.routerOsScript);
    // الافتراضيات تملك customer/profile جاهزين.
    expect(base.isDeploymentConfigured, isTrue);

    final missingProfile = base.copyWith(umProfile: '');
    expect(missingProfile.isDeploymentConfigured, isFalse);
  });

  test('worker mode requires worker URL', () {
    final base = TelegramBotSettings.defaults(
      botToken: 'token',
    ).copyWith(allowedChatIds: '5944227208', allowedUserIds: '5944227208');

    final worker = base.copyWith(
      deploymentMode: TelegramDeploymentMode.cloudflareWorker,
      workerUrl: 'https://nassar-mikrotik.example.workers.dev',
    );
    expect(worker.isDeploymentConfigured, isTrue);

    final noUrl = worker.copyWith(workerUrl: '');
    expect(noUrl.isDeploymentConfigured, isFalse);
  });

  test('python mode only needs telegram credentials', () {
    final base = TelegramBotSettings.defaults(
      botToken: 'token',
    ).copyWith(
      allowedChatIds: '5944227208',
      allowedUserIds: '5944227208',
      deploymentMode: TelegramDeploymentMode.localPython,
      workerUrl: '',
      umCustomer: '',
      umProfile: '',
    );
    expect(base.isDeploymentConfigured, isTrue);
  });

  test('deployment mode roundtrips through copyWith', () {
    final original = TelegramBotSettings.defaults();
    for (final mode in TelegramDeploymentMode.values) {
      expect(original.copyWith(deploymentMode: mode).deploymentMode, mode);
    }
  });

  test('routerPollSeconds roundtrips through copyWith', () {
    final settings =
        TelegramBotSettings.defaults().copyWith(routerPollSeconds: 30);
    expect(settings.routerPollSeconds, 30);
    expect(
      settings.copyWith().routerPollSeconds,
      30,
      reason: 'copyWith بدون قيمة يجب أن يحافظ على القيمة الحالية',
    );
  });
}
