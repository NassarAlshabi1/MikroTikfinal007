import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mqtt_service.dart';

class MqttServiceState {
  const MqttServiceState({
    this.isConnected = false,
    this.isLoading = false,
    this.connectionMessage,
    this.error,
  });

  const MqttServiceState.initial() : this();

  final bool isConnected;
  final bool isLoading;
  final String? connectionMessage;
  final String? error;

  bool get isDisconnected => !isConnected;
  bool get hasError => error?.isNotEmpty ?? false;

  MqttServiceState copyWith({
    bool? isConnected,
    bool? isLoading,
    String? connectionMessage,
    String? error,
    bool clearError = false,
  }) {
    return MqttServiceState(
      isConnected: isConnected ?? this.isConnected,
      isLoading: isLoading ?? this.isLoading,
      connectionMessage: connectionMessage ?? this.connectionMessage,
      error: clearError ? null : error ?? this.error,
    );
  }
}

final mqttClientProvider = Provider<MqttService>((ref) {
  final service = MqttService();
  ref.onDispose(service.dispose);
  return service;
});

class MqttServiceNotifier extends StateNotifier<MqttServiceState> {
  MqttServiceNotifier(this._mqttService) : super(const MqttServiceState.initial());

  final MqttService _mqttService;

  void reconnect() {
    state = state.copyWith(isLoading: true, clearError: true);
    _mqttService.checkAndReconnect();
    state = state.copyWith(
      isLoading: false,
      isConnected: _mqttService.isConnected,
      connectionMessage: _mqttService.isConnected ? 'تم الاتصال بخدمة المزامنة.' : null,
    );
  }

  void disconnect() {
    _mqttService.disconnect();
    state = const MqttServiceState.initial();
  }
}

final mqttServiceProvider = StateNotifierProvider<MqttServiceNotifier, MqttServiceState>((ref) {
  return MqttServiceNotifier(ref.watch(mqttClientProvider));
});
