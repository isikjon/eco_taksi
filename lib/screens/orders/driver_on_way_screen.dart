import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/client_websocket_service.dart';
import '../../widgets/custom_button.dart';
import 'trip_in_progress_screen.dart';
import 'order_review_screen.dart';

class DriverOnWayScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const DriverOnWayScreen({super.key, required this.orderData});

  @override
  State<DriverOnWayScreen> createState() => _DriverOnWayScreenState();
}

class _DriverOnWayScreenState extends State<DriverOnWayScreen> {
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
      print('🔍 [DriverOnWay] Received message: $messageType');

      switch (messageType) {
        case 'driver_arrived':
          _showDriverArrivedNotification();
          setState(() => _currentOrderData = message['order']);
          break;

        case 'order_status_update':
          final order = message['order'];
          setState(() => _currentOrderData = order);
          
          if (order['status'] == 'navigating_to_b') {
            _navigateToTripInProgress();
          } else if (order['status'] == 'completed') {
            _navigateToReview();
          }
          break;

        case 'order_completed':
          _navigateToReview();
          break;
      }
    });
  }

  void _showDriverArrivedNotification() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Водитель прибыл',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToTripInProgress() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TripInProgressScreen(orderData: _currentOrderData),
      ),
    );
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
    final driverName = _currentOrderData['driver_name'] ?? 'Не указано';
    final driverPhone = _currentOrderData['driver_phone'] ?? 'Не указано';
    final pickupAddress = _currentOrderData['pickup_address'] ?? '';
    final destinationAddress = _currentOrderData['destination_address'] ?? '';
    final price = _currentOrderData['price']?.toString() ?? '0';
    final status = _currentOrderData['status'] ?? 'accepted';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Водитель в пути',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300,
              color: AppColors.grey.withOpacity(0.2),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_taxi, size: 80, color: AppColors.primary),
                    AppSpacing.verticalSpace16,
                    Text(
                      status == 'arrived_at_a' 
                          ? 'Водитель прибыл' 
                          : 'Водитель едет к вам',
                      style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: AppSpacing.all16,
              child: Column(
                children: [
                  Container(
                    padding: AppSpacing.all16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppBorderRadius.all16,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Водитель', style: AppTextStyles.h3),
                        AppSpacing.verticalSpace12,
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Icon(Icons.person, size: 30, color: AppColors.primary),
                            ),
                            AppSpacing.horizontalSpace12,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(driverName, style: AppTextStyles.bodyLarge),
                                  Text(driverPhone, style: AppTextStyles.bodyMedium),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: _callDriver,
                              icon: Icon(Icons.phone, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.verticalSpace16,
                  Container(
                    padding: AppSpacing.all16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppBorderRadius.all16,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Детали поездки', style: AppTextStyles.h3),
                        AppSpacing.verticalSpace12,
                        _buildDetailRow(Icons.location_on, 'Откуда', pickupAddress),
                        AppSpacing.verticalSpace8,
                        _buildDetailRow(Icons.location_on_outlined, 'Куда', destinationAddress),
                        AppSpacing.verticalSpace8,
                        _buildDetailRow(Icons.attach_money, 'Стоимость', '$price сом'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        AppSpacing.horizontalSpace8,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text(value, style: AppTextStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

