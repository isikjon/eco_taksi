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
import 'dart:async';
import '../../../services/order_service.dart';
import '../../../services/client_websocket_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  String _screenState = 'form';
  Timer? _searchTimer;

  final Map<String, double> _tariffPrices = {
    'Эконом': 48,
    'Комфорт': 60,
    'Бизнес': 80,
  };

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

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
    print('🚀 === START ORDER CREATION ===');
    print('📍 Pickup: ${widget.pickupLatitude}, ${widget.pickupLongitude}');
    print('📍 Destination: ${widget.destinationLatitude}, ${widget.destinationLongitude}');
    print('📍 Pickup Address: ${widget.selectedAddress}');
    print('📍 Destination Address: ${widget.destinationAddress}');
    print('📏 Distance: ${widget.routeDistance}');
    
    if (widget.pickupLatitude == null || widget.pickupLongitude == null) {
      print('❌ Pickup coordinates missing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите точку отправления')),
      );
      return;
    }

    if (widget.destinationLatitude == null || widget.destinationLongitude == null) {
      print('❌ Destination coordinates missing');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите точку назначения')),
      );
      return;
    }

    try {
      print('📱 Getting client data from SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final clientDataString = prefs.getString('client_data');
      
      print('👤 Client data string: $clientDataString');
      
      String clientName = 'Клиент';
      String clientPhone = '';
      
      if (clientDataString != null) {
        try {
          final clientData = json.decode(clientDataString);
          clientName = '${clientData['first_name']} ${clientData['last_name']}';
          clientPhone = clientData['phone_number'] ?? '';
          print('👤 Client name: $clientName');
          print('📞 Client phone: $clientPhone');
        } catch (e) {
          print('❌ Error parsing client data: $e');
        }
      }

      if (clientPhone.isEmpty) {
        print('❌ Client phone is empty');
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

      print('🚗 Tariff: $selectedTariff');
      print('💰 Price: $price');
      print('📏 Distance: $distance');
      print('⏱️ Duration: $duration');

      print('🔌 Connecting to WebSocket...');
      await ClientWebSocketService().connect(clientPhone);
      print('✅ WebSocket connected');

      print('📤 Creating order via API...');
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

      print('📥 Order result: $result');

      setState(() {
        _screenState = 'searching';
      });

      if (result['success']) {
        print('✅ Order created successfully - waiting for driver...');
      } else {
        print('❌ Order creation failed: ${result['error']}');
        if (result['error_code'] != 'NO_DRIVERS_AVAILABLE') {
          setState(() {
            _screenState = 'form';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['error'] ?? 'Ошибка создания заказа')),
          );
          return;
        }
      }

      _searchTimer = Timer(const Duration(seconds: 10), () {
        if (mounted) {
          print('⏱️ Timeout - no drivers found');
          setState(() {
            _screenState = 'no_drivers';
          });
        }
      });
    } catch (e, stackTrace) {
      print('❌ Error creating order: $e');
      print('❌ Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
    
    print('🏁 === END ORDER CREATION ===');
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
      child: _screenState == 'searching'
          ? _buildSearchingState()
          : _screenState == 'no_drivers'
              ? _buildNoDriversState()
              : SingleChildScrollView(
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

  Widget _buildSearchingState() {
    return Center(
      child: Padding(
        padding: AppSpacing.all24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              strokeWidth: 4,
            ),
            AppSpacing.verticalSpace32,
            Text(
              'Поиск свободных водителей поблизости',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpace32,
            CustomButton(
              text: 'Назад',
              onPressed: () {
                _searchTimer?.cancel();
                setState(() {
                  _screenState = 'form';
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDriversState() {
    return Center(
      child: Padding(
        padding: AppSpacing.all24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'К сожалению, свободных водителей поблизости нет',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpace16,
            Text(
              'Позвоните диспетчеру для оформления заказа',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpace32,
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Назад',
                    onPressed: () {
                      setState(() {
                        _screenState = 'form';
                      });
                    },
                  ),
                ),
                AppSpacing.horizontalSpace12,
                Expanded(
                  child: CustomButton(
                    text: 'Позвонить диспетчеру',
                    onPressed: () async {
                      final Uri phoneUri = Uri(scheme: 'tel', path: '+996111111111');
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Не удалось совершить звонок')),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
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

