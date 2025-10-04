import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/client_websocket_service.dart';
import 'order_review_screen.dart';

class TripInProgressScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const TripInProgressScreen({super.key, required this.orderData});

  @override
  State<TripInProgressScreen> createState() => _TripInProgressScreenState();
}

class _TripInProgressScreenState extends State<TripInProgressScreen> {
  StreamSubscription? _wsSubscription;
  late Map<String, dynamic> _currentOrderData;

  @override
  void initState() {
    super.initState();
    _currentOrderData = widget.orderData;
    _startListening();
  }

  void _startListening() {
    _wsSubscription = ClientWebSocketService().messages.listen((message) {
      if (!mounted) return;

      final messageType = message['type'];
      print('🔍 [TripInProgress] Received message: $messageType');

      switch (messageType) {
        case 'order_status_update':
          final order = message['order'];
          setState(() => _currentOrderData = order);
          
          if (order['status'] == 'completed') {
            _navigateToReview();
          }
          break;

        case 'order_completed':
          _navigateToReview();
          break;
      }
    });
  }

  void _navigateToReview() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => OrderReviewScreen(orderData: _currentOrderData),
      ),
    );
  }

  Future<void> _callDriver() async {
    final driverPhone = _currentOrderData['driver_phone'] ?? '';
    if (driverPhone.isNotEmpty) {
      final Uri phoneUri = Uri(scheme: 'tel', path: driverPhone);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      }
    }
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final destinationAddress = _currentOrderData['destination_address'] ?? '';
    final price = _currentOrderData['price']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Вы в пути',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: _callDriver,
            icon: const Icon(Icons.phone, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: AppColors.grey.withOpacity(0.2),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation, size: 80, color: AppColors.primary),
                    AppSpacing.verticalSpace16,
                    Text(
                      'Едем к месту назначения',
                      style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: AppSpacing.all16,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Куда едем', style: AppTextStyles.h3),
                AppSpacing.verticalSpace12,
                Row(
                  children: [
                    Icon(Icons.location_on, color: AppColors.primary),
                    AppSpacing.horizontalSpace8,
                    Expanded(
                      child: Text(
                        destinationAddress,
                        style: AppTextStyles.bodyLarge,
                      ),
                    ),
                  ],
                ),
                AppSpacing.verticalSpace16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Стоимость поездки', style: AppTextStyles.bodyMedium),
                    Text(
                      '$price сом',
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

