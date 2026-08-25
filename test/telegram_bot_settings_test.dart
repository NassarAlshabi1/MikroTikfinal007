import 'package:flutter_test/flutter_test.dart';
import 'package:mikrotik_manager/services/telegram_bot_settings.dart';

void main() {
  test('uses RouterOS v6 bot defaults', () {
    final settings = TelegramBotSettings.defaults();

    expect(settings.botToken, isEmpty);
    expect(settings.pollSeconds, 20);
    expect(settings.monitorTarget, '1.1.1.1');
    expect(settings.monitorIntervalSeconds, 30);
    expect(settings.trafficInterface, 'ether1');
    expect(settings.trafficIntervalSeconds, 60);
    expect(settings.dailyReportTime, '23:59');
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
}
