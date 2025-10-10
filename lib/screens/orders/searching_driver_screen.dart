import 'dart:async';
import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../styles/app_border_radius.dart';
import '../../services/client_websocket_service.dart';
import '../../services/order_service.dart';
import 'no_drivers_screen.dart';
import 'driver_on_way_screen.dart';

class SearchingDriverScreen extends StatefulWidget {
  final Map<String, dynamic>? orderData;

  const SearchingDriverScreen({
    super.key,
    this.orderData,
  });

  @override
  State<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends State<SearchingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  Timer? _timeoutTimer;
  StreamSubscription? _wsSubscription;
  
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );

    _startListening();
    _startTimeout();
  }

  void _startListening() {
    if (widget.orderData == null) {
      print('⚠️ [SearchingDriver] No order data, skipping WebSocket listener');
      return;
    }
    
    _wsSubscription = ClientWebSocketService().messages.listen((message) {
      if (_disposed) return;

      final messageType = message['type'];
      print('🔍 [SearchingDriver] Received message: $messageType');

      switch (messageType) {
        case 'order_accepted':
          _timeoutTimer?.cancel();
          _navigateToDriverOnWay(message['order']);
          break;

        case 'order_rejected':
          _timeoutTimer?.cancel();
          _navigateToNoDrivers();
          break;

        case 'order_status_update':
          final orderData = message['data'];
          final status = orderData['status'];
          print('🔍 [SearchingDriver] Order status: $status');
          
          if (status == 'accepted' || status == 'navigating_to_a') {
            _timeoutTimer?.cancel();
            _navigateToDriverOnWay(orderData);
          } else if (status == 'rejected_by_driver') {
            _timeoutTimer?.cancel();
            _navigateToNoDrivers();
          }
          break;

        default:
          print('⚠️ [SearchingDriver] Unhandled message type: $messageType');
      }
    });
  }

  void _startTimeout() {
    // Увеличиваем таймаут до 2 минут
    _timeoutTimer = Timer(const Duration(seconds: 120), () {
      if (!_disposed && mounted) {
        print('⏱️ [SearchingDriver] Timeout reached (120s)');
        _navigateToNoDrivers();
      }
    });
  }

  void _navigateToDriverOnWay(Map<String, dynamic> orderData) {
    if (!mounted || _disposed) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DriverOnWayScreen(orderData: orderData),
      ),
    );
  }

  void _navigateToNoDrivers() {
    if (!mounted || _disposed) return;
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const NoDriversScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _animationController.dispose();
    _timeoutTimer?.cancel();
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            OrderService().clearCurrentOrder();
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Поиск водителя',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.all24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Transform.rotate(
                      angle: _rotationAnimation.value * 2 * 3.14159,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_taxi,
                          size: 60,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  );
                },
              ),
              AppSpacing.verticalSpace32,
              Text(
                'Ищем водителя...',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpace16,
              Text(
                'Пожалуйста, подождите\nМы подбираем ближайшего водителя',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpace32,
              SizedBox(
                width: double.infinity,
                child: LinearProgressIndicator(
                  backgroundColor: AppColors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

