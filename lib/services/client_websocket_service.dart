import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'order_service.dart';

class ClientWebSocketService {
  static final ClientWebSocketService _instance = ClientWebSocketService._internal();
  factory ClientWebSocketService() => _instance;
  ClientWebSocketService._internal();

  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  String? _clientPhone;

  final StreamController<Map<String, dynamic>> _messageController =
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  bool get isConnected => _isConnected;

  Future<void> connect(String clientPhone) async {
    if (_isConnected && _clientPhone == clientPhone) {
      print('🔍 [ClientWebSocket] Already connected');
      return;
    }

    _clientPhone = clientPhone;
    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    try {
      if (_channel != null) {
        await disconnect();
      }

      final normalizedPhone = _clientPhone!.replaceAll(RegExp(r'[^\d]'), '');
      final wsUrl = ApiConfig.baseUrl
          .replaceFirst('http://', 'ws://')
          .replaceFirst('https://', 'wss://');
      
      final uri = Uri.parse('$wsUrl/ws/orders/client/$normalizedPhone');
      
      print('🔍 [ClientWebSocket] Connecting to: $uri');

      _channel = WebSocketChannel.connect(uri);

      _subscription = _channel!.stream.listen(
        (dynamic message) {
          _handleMessage(message);
        },
        onError: (error) {
          print('❌ [ClientWebSocket] Error: $error');
          _handleDisconnect();
        },
        onDone: () {
          print('🔍 [ClientWebSocket] Connection closed');
          _handleDisconnect();
        },
      );

      _isConnected = true;
      print('✅ [ClientWebSocket] Connected successfully');

      _startPingTimer();

    } catch (e) {
      print('❌ [ClientWebSocket] Connection error: $e');
      _handleDisconnect();
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = json.decode(message as String);
      print('📥 [ClientWebSocket] Received: $data');

      final messageType = data['type'];
      
      switch (messageType) {
        case 'pong':
          print('💓 [ClientWebSocket] Pong received');
          break;

        case 'order_accepted':
          print('✅ [ClientWebSocket] Order accepted by driver');
          final orderData = data['data'];
          OrderService().updateOrderData(orderData);
          _messageController.add({
            'type': 'order_accepted',
            'order': orderData,
          });
          break;

        case 'order_rejected':
          print('❌ [ClientWebSocket] Order rejected by driver');
          final orderData = data['data'];
          OrderService().clearCurrentOrder();
          _messageController.add({
            'type': 'order_rejected',
            'order': orderData,
          });
          break;

        case 'driver_arrived':
          print('📍 [ClientWebSocket] Driver arrived at pickup point');
          final orderData = data['data'];
          OrderService().updateOrderData(orderData);
          _messageController.add({
            'type': 'driver_arrived',
            'order': orderData,
          });
          break;

        case 'order_completed':
          print('✅ [ClientWebSocket] Order completed');
          final orderData = data['data'];
          OrderService().updateOrderData(orderData);
          _messageController.add({
            'type': 'order_completed',
            'order': orderData,
          });
          break;

        case 'order_status_update':
          print('🔄 [ClientWebSocket] Order status updated');
          final orderData = data['data'];
          OrderService().updateOrderData(orderData);
          _messageController.add({
            'type': 'order_status_update',
            'order': orderData,
          });
          break;

        case 'error':
          print('❌ [ClientWebSocket] Server error: ${data['message']}');
          _messageController.add({
            'type': 'error',
            'message': data['message'],
          });
          break;

        default:
          print('⚠️ [ClientWebSocket] Unknown message type: $messageType');
          _messageController.add(data);
      }
    } catch (e) {
      print('❌ [ClientWebSocket] Error handling message: $e');
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _subscription?.cancel();
    _subscription = null;
    _pingTimer?.cancel();
    _pingTimer = null;

    if (_clientPhone != null) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected && _clientPhone != null) {
        print('🔄 [ClientWebSocket] Attempting to reconnect...');
        _connectInternal();
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        sendMessage({
          'type': 'ping',
          'timestamp': DateTime.now().toIso8601String(),
        });
      } else {
        timer.cancel();
      }
    });
  }

  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final jsonMessage = json.encode(message);
        _channel!.sink.add(jsonMessage);
        print('📤 [ClientWebSocket] Sent: $message');
      } catch (e) {
        print('❌ [ClientWebSocket] Error sending message: $e');
      }
    } else {
      print('⚠️ [ClientWebSocket] Cannot send message: not connected');
    }
  }

  Future<void> disconnect() async {
    print('🔌 [ClientWebSocket] Disconnecting...');
    
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _pingTimer?.cancel();
    _pingTimer = null;
    _subscription?.cancel();
    _subscription = null;
    
    await _channel?.sink.close();
    _channel = null;
    
    _isConnected = false;
    _clientPhone = null;
    
    print('✅ [ClientWebSocket] Disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}

