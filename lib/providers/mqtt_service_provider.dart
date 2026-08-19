import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mqtt_service.dart';

final mqttServiceProvider = Provider<MqttService>((ref) => MqttService());
