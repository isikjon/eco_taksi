import 'dart:async';
import 'dart:math';

import 'package:eco_taksi/config/dgis_sdk_config.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:eco_taksi/screens/main/widgets/comment_for_driver_box.dart';
import 'package:eco_taksi/screens/main/widgets/order_box.dart';
import 'package:eco_taksi/screens/main/widgets/panel_box.dart';
import 'package:eco_taksi/screens/main/widgets/payment_box.dart';
import 'package:eco_taksi/screens/main/widgets/search_box_bottom.dart';
import 'package:eco_taksi/screens/main/widgets/search_route_bottom.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../services/auth_service.dart';
import '../profile/profile_screen.dart';
import '../security/security_screen.dart';
import '../orders/order_history_screen.dart';
import '../support/support_screen.dart';
import '../info/info_screen.dart';
import '../auth/phone_auth_screen.dart';
import '../payment/payment_method_screen.dart';
import 'widgets/order_another_human.dart';

class SimpleMainScreen extends StatefulWidget {
  const SimpleMainScreen({super.key});

  @override
  State<SimpleMainScreen> createState() => _SimpleMainScreenState();
}

class _SimpleMainScreenState extends State<SimpleMainScreen>
    with TickerProviderStateMixin {
  String _userName = 'Пользователь';
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  sdk.Map? _sdkMap;
  StreamSubscription<sdk.Location?>? locationSubscription;
  bool _isSelectingPoint = false;
  sdk.GeoPoint? _selectedPoint;
  sdk.TrafficRoute? _currentRoute;
  sdk.RouteMapObjectSource? _routeSource;
  String _routeInfo = '';

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final sdkContext = AppContainer().initializeSdk();
  final _mapWidgetController = sdk.MapWidgetController();

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _initSdkAndMap();

    // Инициализация анимации пульсации
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Запуск анимации
    _animationController.repeat(reverse: true);
  }

  Future<void> _initSdkAndMap() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      print("Разрешение на геолокацию не предоставлено");
      return;
    }

    final locationService = sdk.LocationService(sdkContext);

    // Получаем карту асинхронно
    _mapWidgetController.getMapAsync((m) async {
      _sdkMap = m;

      // Добавляем "синюю точку" на карту
      final locationSource = sdk.MyLocationMapObjectSource(
        sdkContext,
        const sdk.MyLocationControllerSettings(
          bearingSource: sdk.BearingSource.satellite,
        ),
      );
      _sdkMap?.addSource(locationSource);

      final loc = await locationService.lastLocation().firstWhere(
        (l) => l != null,
        orElse: () => null,
      );

      if (loc != null) {
        final cameraPos = sdk.CameraPosition(
          point: loc.coordinates.value,
          zoom: const sdk.Zoom(15),
        );
        _sdkMap?.camera.moveToCameraPosition(
          cameraPos,
          const Duration(milliseconds: 500),
          sdk.CameraAnimationType.linear,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    locationSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final clientData = await AuthService.getCurrentClient();
      if (clientData != null && mounted) {
        final firstName = clientData['first_name'] ?? '';
        final lastName = clientData['last_name'] ?? '';
        setState(() {
          _userName = '$firstName $lastName'.trim();
          if (_userName.isEmpty) {
            _userName = 'Пользователь';
          }
        });
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(),
      body: GestureDetector(
        onTapDown: _isSelectingPoint ? _onMapTap : null,
        child: sdk.MapWidget(
          sdkContext: sdkContext,
          mapOptions: sdk.MapOptions(),
          controller: _mapWidgetController,
          child: Stack(
            children: [
              // Верхняя панель с адресом и поиском (скрывается в режиме выбора точки)
              if (!_isSelectingPoint)
                PanelBox(onTap: onShowSearchAddressBottom),


            // Панель выбора точки (показывается только в режиме выбора)
            if (_isSelectingPoint)
              _buildPointSelectionPanel(),

            // Информация о маршруте (показывается после построения маршрута)
            if (_routeInfo.isNotEmpty && !_isSelectingPoint)
              _buildRouteInfoPanel(),

            // // Маркер выбранной точки
            // if (_selectedPoint != null && _isSelectingPoint)
            //   _buildSelectedPointMarker(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Показываем диалог подтверждения
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из аккаунта'),
        content: const Text('Вы уверены, что хотите выйти из аккаунта?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Показываем индикатор загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Выполняем выход
        await AuthService.logout();

        // Закрываем диалог загрузки
        if (mounted) Navigator.of(context).pop();

        // Перенаправляем на экран авторизации
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const PhoneAuthScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Закрываем диалог загрузки
        if (mounted) Navigator.of(context).pop();

        // Показываем ошибку
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка при выходе: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildAnimatedCircle() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 8 * _pulseAnimation.value,
                  spreadRadius: 2 * _pulseAnimation.value,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.8,
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 20,),
            // Профиль пользователя
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.textSecondary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Пункты меню
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem('Способ оплаты'),
                  _buildDrawerItem('Безопасность'),
                  _buildDrawerItem('История заказов'),
                  _buildDrawerItem('Настройки'),
                  _buildDrawerItem('Служба поддержки'),
                  _buildDrawerItem('Информация'),
                ],
              ),
            ),

            const Divider(),

            // Выход
            ListTile(
              leading: _buildAnimatedCircle(),
              title: const Text(
                'Выйти',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16),
              ),
              onTap: () {
                Navigator.pop(context);
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(String title) {
    return ListTile(
      leading: _buildAnimatedCircle(),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context);

        if (title == 'Способ оплаты') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentMethodScreen(),
            ),
          );
        } else if (title == 'Настройки') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          ).then((result) {
            // Если профиль был обновлен, перезагружаем данные пользователя
            if (result == true) {
              _loadUserName();
            }
          });
        } else if (title == 'Безопасность') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SecurityScreen()),
          );
        } else if (title == 'История заказов') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
          );
        } else if (title == 'Служба поддержки') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SupportScreen()),
          );
        } else if (title == 'Информация') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InfoScreen()),
          );
        }
      },
    );
  }

  void onShowSearchAddressBottom() {
    // onSearchBottom();
    _scaffoldKey.currentState?.showBottomSheet(
      (context) {
        return PopScope(
          canPop: false,
          child: DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            shouldCloseOnMinExtent: false,
            expand: false,
            builder: (context, scrollController) {
              return SearchRouteBottom(
                controller: scrollController,
                onTap: onSearchBottom,
                onShowCommentBottom: onCommentForDiverBottom,
                onShowOrderAnotherHumanBottom: onOrderAnotherHumanBottom,
                onShowPaymentBottom: onOPaymentBoxBottom,
                onShowOrderBoxBottom: onOrderBoxBottom,
                sdkContext: sdkContext,
              );
            },
          ),
        );
      },
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      enableDrag: false,
    );
  }

  void onSearchBottom() {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: SearchBoxBottom(sdkContext: sdkContext),
        );
      },
    ).then((result) {
      // Обрабатываем результат от SearchBoxBottom
      if (result != null && result['action'] == 'select_point') {
        // Переключаемся в режим выбора точки
        setState(() {
          _isSelectingPoint = true;
        });
      } else if (result != null && result['coordinates'] != null) {
        // Если выбрана точка из поиска, устанавливаем её как выбранную
        setState(() {
          _selectedPoint = result['coordinates'];
          _isSelectingPoint = false;
        });
        // Строим маршрут к выбранной точке
        _buildRouteToSelectedPoint();
      }
    });
  }

  void onCommentForDiverBottom() {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: CommentForDriverBox(),
        );
      },
    );
  }

  void onOrderAnotherHumanBottom() {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: OrderAnotherHuman(),
        );
      },
    );
  }

  void onOPaymentBoxBottom() {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.4,
          child: PaymentBox(),
        );
      },
    );
  }

  // void onOrderBoxBottom() {
  //   showModalBottomSheet(
  //     isScrollControlled: true,
  //     useSafeArea: true,
  //     context: context,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) {
  //       return FractionallySizedBox(
  //         heightFactor: 0.4,
  //         child: OrderBox(),
  //       );
  //     },
  //   );
  // }

  void onOrderBoxBottom() {
    // onSearchBottom();
    _scaffoldKey.currentState?.showBottomSheet(
          (context) {
        return PopScope(
          canPop: false,
          child: DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            shouldCloseOnMinExtent: false,
            expand: false,
            builder: (context, scrollController) {
              return OrderBox();
            },
          ),
        );
      },
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      enableDrag: false,
    );
  }


  Widget _buildPointSelectionPanel() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.touch_app,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Нажмите на карту, чтобы выбрать точку',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _cancelPointSelection,
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            if (_selectedPoint != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Выбранная точка: ${_selectedPoint!.latitude.value.toStringAsFixed(6)}, ${_selectedPoint!.longitude.value.toStringAsFixed(6)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _confirmPointSelection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Подтвердить',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelPointSelection,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.textSecondary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Отмена',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }


  void _cancelPointSelection() {
    setState(() {
      _isSelectingPoint = false;
      _selectedPoint = null;
    });
  }

  void _confirmPointSelection() async {
    if (_selectedPoint != null) {
      // Строим маршрут от текущей позиции до выбранной точки
      await _buildRouteToSelectedPoint();
    }

    _cancelPointSelection();
  }

  void _onMapTap(TapDownDetails details) async {
    if (_isSelectingPoint && _sdkMap != null) {
      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final localPosition = renderBox.globalToLocal(details.globalPosition);

      // Получаем текущую позицию камеры
      final cameraPosition = _sdkMap!.camera.position;
      final centerPoint = cameraPosition.point;
      final zoom = cameraPosition.zoom.value;

      // Размеры экрана
      final screenSize = MediaQuery.of(context).size;
      final screenCenterX = screenSize.width / 2;
      final screenCenterY = screenSize.height / 2;

      // Смещение от центра экрана в пикселях
      final deltaX = localPosition.dx - screenCenterX;
      final deltaY = localPosition.dy - screenCenterY;

      // Конвертация пикселей в градусы (приближенная формула для Меркатора)
      // Коэффициент зависит от zoom level
      final metersPerPixel = 156543.03392 * cos(centerPoint.latitude.value * pi / 180) / pow(2, zoom);

      // Конвертируем пиксели в метры, затем в градусы
      final deltaLat = -(deltaY * metersPerPixel) / 111111; // 1 градус ≈ 111км
      final deltaLng = (deltaX * metersPerPixel) / (111111 * cos(centerPoint.latitude.value * pi / 180));

      final selectedLat = centerPoint.latitude.value + deltaLat;
      final selectedLng = centerPoint.longitude.value + deltaLng;

      final newPoint = sdk.GeoPoint(
        latitude: sdk.Latitude(selectedLat),
        longitude: sdk.Longitude(selectedLng),
      );

      setState(() {
        _selectedPoint = newPoint;
      });

      print('Выбрана точка: $selectedLat, $selectedLng');
      print('Центр камеры: ${centerPoint.latitude.value}, ${centerPoint.longitude.value}');
      print('Zoom: $zoom');
    }
  }


  Future<void> _buildRouteToSelectedPoint() async {
    if (_selectedPoint == null || _sdkMap == null) return;

    try {
      // Получаем текущую позицию пользователя
      final currentLocation = await _getCurrentLocation();
      if (currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось определить текущее местоположение'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Создаем точки маршрута
      final startPoint = sdk.RouteSearchPoint(
        coordinates: sdk.GeoPoint(
          latitude: sdk.Latitude(currentLocation.latitude),
          longitude: sdk.Longitude(currentLocation.longitude),
        ),
      );

      final finishPoint = sdk.RouteSearchPoint(
        coordinates: _selectedPoint!,
      );

      // Настройки маршрута для автомобиля
      final routeSearchOptions = sdk.RouteSearchOptions.car(
        sdk.CarRouteSearchOptions(),
      );

      // Создаем TrafficRouter
      final trafficRouter = sdk.TrafficRouter(sdkContext);

      // Ищем маршрут
      final routesFuture = trafficRouter.findRoute(startPoint, finishPoint, routeSearchOptions);
      final routes = await routesFuture.value;

      if (routes.isNotEmpty) {
        _currentRoute = routes.first;

        // Очищаем предыдущий маршрут если есть
        if (_routeSource != null) {
          _sdkMap!.removeSource(_routeSource!);
        }

        // Создаем источник данных для маршрута
        _routeSource = sdk.RouteMapObjectSource(
          sdkContext,
          sdk.RouteVisualizationType.normal,
        );

        // Добавляем источник на карту
        _sdkMap!.addSource(_routeSource!);

        // Добавляем маршрут на карту
        _routeSource!.addObject(sdk.RouteMapObject(_currentRoute!, true, const sdk.RouteIndex(0)));

        // Получаем информацию о маршруте
        _routeInfo = 'Маршрут построен к точке ${_selectedPoint!.latitude.value.toStringAsFixed(4)}, ${_selectedPoint!.longitude.value.toStringAsFixed(4)}';

        // Показываем информацию о маршруте
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Маршрут успешно построен'),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );

        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось построить маршрут'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Ошибка построения маршрута: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка построения маршрута: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      print('Ошибка получения местоположения: $e');
      return null;
    }
  }


  Widget _buildRouteInfoPanel() {
    return Positioned(
      bottom: 100,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.route,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Маршрут построен',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _routeInfo,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _clearRoute,
              icon: const Icon(Icons.close),
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSelectedPointMarker() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.5 - 20,
      left: MediaQuery.of(context).size.width * 0.5 - 20,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(
          Icons.location_on,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  void _clearRoute() {
    if (_routeSource != null && _sdkMap != null) {
      _sdkMap!.removeSource(_routeSource!);
    }
    setState(() {
      _currentRoute = null;
      _routeSource = null;
      _routeInfo = '';
    });
  }

}
