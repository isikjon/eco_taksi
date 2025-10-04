import 'package:eco_taksi/styles/app_assets.dart';
import 'package:eco_taksi/styles/app_border_radius.dart';
import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_spacing.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:eco_taksi/widgets/custom_button.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../services/order_service.dart';
import '../../../services/client_websocket_service.dart';
import '../../orders/searching_driver_screen.dart';

class SearchRouteBottom extends StatefulWidget {
  const SearchRouteBottom({
    super.key,
    required this.controller,
    required this.onTap,
    required this.onShowCommentBottom,
    required this.onShowPaymentBottom,
    required this.onShowOrderAnotherHumanBottom,
    required this.onShowOrderBoxBottom,
    required this.sdkContext,
    required this.selectedAddress,
    required this.onTapDestinationAddress,
    required this.destinationAddress,
    this.routeDistance,
    this.pickupLatitude,
    this.pickupLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
  });

  final ScrollController controller;
  final VoidCallback onTap;
  final VoidCallback onTapDestinationAddress;
  final VoidCallback onShowCommentBottom;
  final VoidCallback onShowPaymentBottom;
  final VoidCallback onShowOrderAnotherHumanBottom;
  final VoidCallback onShowOrderBoxBottom;
  final sdk.Context sdkContext;
  final String selectedAddress;
  final String destinationAddress;
  final String? routeDistance;
  final double? pickupLatitude;
  final double? pickupLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;

  @override
  State<SearchRouteBottom> createState() => _SearchRouteBottomState();
}

class _SearchRouteBottomState extends State<SearchRouteBottom> {
  int? _currentIndex;

  final Map<String, double> _tariffPrices = {
    'Эконом': 48,
    'Комфорт': 60,
    'Бизнес': 80,
  };

  void onSelectedTariff(int? index) => setState(() => _currentIndex = index);

  double _calculatePrice(String tariff) {
    if (widget.routeDistance == null || widget.routeDistance!.isEmpty) {
      return 0;
    }
    
    try {
      final distance = double.parse(widget.routeDistance!);
      final pricePerKm = _tariffPrices[tariff] ?? 48;
      return distance * pricePerKm;
    } catch (e) {
      return 0;
    }
  }

  int _calculateTime() {
    if (widget.routeDistance == null || widget.routeDistance!.isEmpty) {
      return 5;
    }
    
    try {
      final distance = double.parse(widget.routeDistance!);
      final averageSpeed = 40;
      final timeInHours = distance / averageSpeed;
      final timeInMinutes = (timeInHours * 60).ceil();
      return timeInMinutes < 1 ? 1 : timeInMinutes;
    } catch (e) {
      return 5;
    }
  }

  String _getSelectedTariff() {
    switch (_currentIndex) {
      case 0:
        return 'Эконом';
      case 1:
        return 'Комфорт';
      case 2:
        return 'Бизнес';
      default:
        return 'Эконом';
    }
  }

  Future<void> _handleOrderCreation() async {
    if (widget.pickupLatitude == null || widget.pickupLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите точку отправления')),
      );
      return;
    }

    if (widget.destinationLatitude == null || widget.destinationLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите точку назначения')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final clientPhone = prefs.getString('client_phone') ?? '';
      final clientDataString = prefs.getString('client_data');
      
      String clientName = 'Клиент';
      if (clientDataString != null) {
        try {
          final clientData = json.decode(clientDataString);
          clientName = '${clientData['first_name']} ${clientData['last_name']}';
        } catch (e) {
          print('Error parsing client data: $e');
        }
      }

      if (clientPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка: номер телефона не найден')),
        );
        return;
      }

      final selectedTariff = _getSelectedTariff();
      final price = _calculatePrice(selectedTariff);
      final distance = widget.routeDistance != null && widget.routeDistance!.isNotEmpty
          ? double.tryParse(widget.routeDistance!)
          : null;
      final duration = _calculateTime();

      await ClientWebSocketService().connect(clientPhone);

      final result = await OrderService().createOrder(
        clientPhone: clientPhone,
        clientName: clientName,
        pickupAddress: widget.selectedAddress,
        pickupLatitude: widget.pickupLatitude!,
        pickupLongitude: widget.pickupLongitude!,
        destinationAddress: widget.destinationAddress,
        destinationLatitude: widget.destinationLatitude!,
        destinationLongitude: widget.destinationLongitude!,
        tariff: selectedTariff,
        price: price,
        distance: distance,
        duration: duration,
      );

      if (result['success']) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SearchingDriverScreen(
              orderData: result['order'],
            ),
          ),
        );
      } else {
        if (result['error_code'] == 'NO_DRIVERS_AVAILABLE') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Нет доступных водителей')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Ошибка создания заказа')),
          );
        }
      }
    } catch (e) {
      print('Error creating order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SingleChildScrollView(
        controller: widget.controller,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              spacing: 8,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 15, color: AppColors.greenLight),
                    const SizedBox(height: 4),
                    Container(
                      width: 0.9,
                      height: 30,
                      color: AppColors.primaryDark,
                    ),
                    const SizedBox(height: 4),
                    Icon(Icons.circle, size: 15, color: AppColors.offline),
                  ],
                ),
                Expanded(
                  child: Column(
                    spacing: 8,
                    children: [
                      _buildBox(address: widget.selectedAddress, onTap: widget.onTap),
                      _buildBox(address: widget.destinationAddress, onTap: widget.onTapDestinationAddress),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Text('_routeDistance: ${widget.routeDistance ?? 'gg'}'),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.22,
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTariff(
                    image: AppAssets.econom,
                    tariffName: 'Эконом',
                    index: 0,
                  ),
                  _buildTariff(
                    image: AppAssets.comfort,
                    tariffName: 'Комфорт',
                    index: 1,
                  ),
                  _buildTariff(
                    image: AppAssets.mineven,
                    tariffName: 'Бизнес',
                    index: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAnotherParametr(title: 'Коментарий водителю', onTap: widget.onShowCommentBottom),
            const SizedBox(height: 16),
            _buildAnotherParametr(title: 'Заказать другому человеку', onTap: widget.onShowOrderAnotherHumanBottom),
            const SizedBox(height: 16),
            _buildAnotherParametr(title: 'Способ оплаты', onTap: widget.onShowPaymentBottom),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Заказать', 
              onPressed: _handleOrderCreation,
            ),
          ],
        ),
      ),
    );
  }

  _buildTariff({
    String? image,
    String? tariffName,
    int? index,
  }) {
    final calculatedPrice = _calculatePrice(tariffName ?? 'Эконом');
    final calculatedTime = _calculateTime();
    final isSelected = index == _currentIndex;
    
    String distanceText = '0 метров';
    if (widget.routeDistance != null && widget.routeDistance!.isNotEmpty) {
      try {
        final distance = double.parse(widget.routeDistance!);
        if (distance < 1.0) {
          final meters = (distance * 1000).toStringAsFixed(0);
          distanceText = '$meters метров';
        } else {
          distanceText = '${distance.toStringAsFixed(2)} км';
        }
      } catch (e) {
        distanceText = '0 метров';
      }
    }
    
    return InkWell(
      onTap: () => onSelectedTariff(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: AppSpacing.r8.copyWith(bottom: 10),
        padding: AppSpacing.all16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorderRadius.all16,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                  ? AppColors.primary.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(image ?? '', width: 100),
            Text(
              tariffName ?? '',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.black),
            ),
            SizedBox(height: 7),
            Text(
              "$distanceText - ${calculatedPrice.toStringAsFixed(0)} сомов",
              style: AppTextStyles.h3.copyWith(color: AppColors.black),
            ),
            SizedBox(height: 7),
            Container(
              alignment: Alignment.center,
              height: 24,
              width: 61,
              decoration: BoxDecoration(
                color: index == _currentIndex
                    ? AppColors.greenLight
                    : AppColors.grey,
                borderRadius: AppBorderRadius.all100,
              ),
              child: Text(
                '$calculatedTime мин',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildBox({String? address, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? widget.onTap,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.all12.copyWith(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorderRadius.all16,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(address ?? '', style: AppTextStyles.bodyLarge),
      ),
    );
  }

  _buildAnotherParametr({String? title, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title ?? '', style: AppTextStyles.bodyLarge),
              SvgPicture.asset(AppAssets.arrowRight),
            ],
          ),
          Divider(color: AppColors.greyDivider),
        ],
      ),
    );
  }
}
