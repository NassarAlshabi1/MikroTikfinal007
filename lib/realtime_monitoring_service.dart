import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class RealtimeMonitoringService {
  static final RealtimeMonitoringService _instance = RealtimeMonitoringService._();
  static RealtimeMonitoringService get instance => _instance;
  RealtimeMonitoringService._();

  WebSocketChannel? _wsChannel;
  MqttServerClient? _mqttClient;
  StreamController<Map<String, dynamic>>? _dataController;
  Timer? _reconnectTimer;
  bool _isConnected = false;
  final List<Function(Map<String, dynamic>)> _listeners = [];

  bool get isConnected => _isConnected;

  Stream<Map<String, dynamic>> get dataStream => _dataController?.stream ?? const Stream.empty();

  void addListener(Function(Map<String, dynamic>) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(Map<String, dynamic>) listener) {
    _listeners.remove(listener);
  }

  Future<void> connectWebSocket(String ip, int port) async {
    try {
      final wsUrl = 'ws://$ip:$port/ws';
      _wsChannel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _wsChannel!.stream.listen(
        (data) {
          try {
            final json = jsonDecode(data) as Map<String, dynamic>;
            _notifyListeners(json);
          } catch (e) {
            debugPrint('Error parsing WebSocket data: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          _isConnected = false;
          _scheduleReconnect();
        },
        onDone: () {
          debugPrint('WebSocket connection closed');
          _isConnected = false;
          _scheduleReconnect();
        },
      );

      _isConnected = true;
    } catch (e) {
      debugPrint('Failed to connect WebSocket: $e');
      _scheduleReconnect();
    }
  }

  Future<void> connectMqtt({
    required String broker,
    required int port,
    required String clientId,
    String? username,
    String? password,
  }) async {
    try {
      _mqttClient = MqttServerClient(broker, clientId);
      _mqttClient!.port = port;
      _mqttClient!.logging(on: false);
      
      final connMess = MqttConnectMessage().withClientIdentifier(clientId);
      if (username != null && password != null) {
        connMess.authenticateAs(username, password);
      }
      
      _mqttClient!.connectionMessage = connMess;
      
      await _mqttClient!.connect();
      
      _mqttClient!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? messages) {
        for (final message in messages ?? []) {
          final payload = message.payload as MqttPublishMessage?;
          if (payload != null) {
            try {
              final data = jsonDecode(String.fromCharCodes(payload.payload.message)) as Map<String, dynamic>;
              _notifyListeners(data);
            } catch (e) {
              debugPrint('Error parsing MQTT message: $e');
            }
          }
        }
      });

      _isConnected = true;
    } catch (e) {
      debugPrint('Failed to connect MQTT: $e');
    }
  }

  void _notifyListeners(Map<String, dynamic> data) {
    for (final listener in _listeners) {
      listener(data);
    }
    _dataController?.add(data);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      debugPrint('Attempting to reconnect...');
      // Reconnect logic would go here
    });
  }

  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    await _wsChannel?.sink.close();
    await _mqttClient?.unsubscribe('#');
    await _mqttClient?.disconnect();
    _isConnected = false;
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _dataController?.close();
    _listeners.clear();
  }
}
