import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class OrderService {
  static final OrderService _instance = OrderService._internal();
  factory OrderService() => _instance;
  OrderService._internal();

  final StreamController<Map<String, dynamic>> _orderUpdatesController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get orderUpdates => _orderUpdatesController.stream;

  Map<String, dynamic>? _currentOrder;
  Map<String, dynamic>? get currentOrder => _currentOrder;

  void setCurrentOrder(Map<String, dynamic> order) {
    _currentOrder = order;
    _orderUpdatesController.add(order);
    _saveCurrentOrderToPrefs();
  }

  void clearCurrentOrder() {
    _currentOrder = null;
    _orderUpdatesController.add({});
    _clearCurrentOrderFromPrefs();
  }

  void updateOrderStatus(String status) {
    if (_currentOrder != null) {
      _currentOrder!['status'] = status;
      _orderUpdatesController.add(_currentOrder!);
      _saveCurrentOrderToPrefs();
    }
  }

  void updateOrderData(Map<String, dynamic> orderData) {
    _currentOrder = orderData;
    _orderUpdatesController.add(orderData);
    _saveCurrentOrderToPrefs();
  }

  Future<void> _saveCurrentOrderToPrefs() async {
    if (_currentOrder != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_order', json.encode(_currentOrder));
    }
  }

  Future<void> _clearCurrentOrderFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_order');
  }

  Future<void> loadCurrentOrderFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orderString = prefs.getString('current_order');
      if (orderString != null) {
        _currentOrder = json.decode(orderString);
        _orderUpdatesController.add(_currentOrder!);
      }
    } catch (e) {
      print('❌ [OrderService] Error loading current order: $e');
    }
  }

  Future<Map<String, dynamic>> createOrder({
    required String clientPhone,
    String? clientName,
    required String pickupAddress,
    required double pickupLatitude,
    required double pickupLongitude,
    required String destinationAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    required String tariff,
    required double price,
    double? distance,
    int? duration,
    String? paymentMethod,
    String? notes,
  }) async {
    try {
      print('🔍 [OrderService] Creating order...');
      
      final requestBody = {
        'client_phone': clientPhone,
        'client_name': clientName,
        'pickup_address': pickupAddress,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'destination_address': destinationAddress,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
        'tariff': tariff,
        'price': price,
        'distance': distance,
        'duration': duration,
        'payment_method': paymentMethod ?? 'cash',
        'notes': notes ?? '',
      };

      print('🔍 [OrderService] Request body: $requestBody');

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/clients/create-order'),
        headers: ApiConfig.defaultHeaders,
        body: json.encode(requestBody),
      );

      print('🔍 [OrderService] Response status: ${response.statusCode}');
      print('🔍 [OrderService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          final orderData = result['data']['order'];
          setCurrentOrder(orderData);
          return {
            'success': true,
            'order': orderData,
            'driver': result['data']['driver'],
          };
        } else {
          return {
            'success': false,
            'error': result['error'] ?? 'Ошибка создания заказа',
            'error_code': result['error_code'],
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ [OrderService] Error creating order: $e');
      return {
        'success': false,
        'error': 'Ошибка создания заказа: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getOrderStatus(int orderId) async {
    try {
      print('🔍 [OrderService] Getting order status for order $orderId');

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/clients/orders/$orderId/status'),
        headers: ApiConfig.defaultHeaders,
      );

      print('🔍 [OrderService] Response status: ${response.statusCode}');
      print('🔍 [OrderService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['success']) {
          final orderData = result['data']['order'];
          if (_currentOrder != null && _currentOrder!['id'] == orderId) {
            updateOrderData(orderData);
          }
          return {
            'success': true,
            'order': orderData,
          };
        } else {
          return {
            'success': false,
            'error': result['error'] ?? 'Ошибка получения статуса',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}: ${response.body}',
        };
      }
    } catch (e) {
      print('❌ [OrderService] Error getting order status: $e');
      return {
        'success': false,
        'error': 'Ошибка получения статуса: $e',
      };
    }
  }

  void dispose() {
    _orderUpdatesController.close();
  }
}
