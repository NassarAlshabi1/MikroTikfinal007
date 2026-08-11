import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'mqtt_service.dart';

class MqttServiceState {
  final bool isConnected;
  final String? connectionMessage;
  final bool isLoading;
  final String? error;
  
  MqttServiceState({
    this.isConnected = false,
    this.connectionMessage,
    this.isLoading = false,
    this.error,
  });
  
  MqttServiceState copyWith({
    bool? isConnected,
    String? connectionMessage,
    bool? isLoading,
    String? error,
  }) {
    return MqttServiceState(
      isConnected: isConnected ?? this.isConnected,
      connectionMessage: connectionMessage ?? this.connectionMessage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class MqttServiceNotifier extends StateNotifier<MqttServiceState> {
  final MqttService _mqttService;
  
  MqttServiceNotifier(this._mqttService) : super(MqttServiceState.initial());
  
  Future<void> connect(String ip, String username, String password, int port) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = await _mqttService.connect(ip, username, password, port);
      state = state.copyWith(
        isConnected: true,
        connectionMessage: 'تم الاتصال بنجاح',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        error: e.toString(),
        isLoading: false,
      );
    }
  }
  
  Future<void> disconnect() async {
    _mqttService.disconnect();
    state = MqttServiceState.initial();
  }
}

final mqttServiceProvider = StateNotifierProvider<MqttServiceNotifier, MqttServiceState>((ref) {
  final mqttService = MqttService();
  return MqttServiceNotifier(mqttService);
});

extension on MqttServiceState {
  bool get isConnected => this.isConnected;
  bool get isDisconnected => !this.isConnected;
  bool get isLoading => this.isLoading;
  bool get hasError => this.error != null && this.error!.isNotEmpty;
}
