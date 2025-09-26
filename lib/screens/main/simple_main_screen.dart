import 'dart:async';

import 'package:eco_taksi/config/dgis_sdk_config.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:eco_taksi/screens/main/widgets/comment_for_driver_box.dart';
import 'package:eco_taksi/screens/main/widgets/map_box.dart';
import 'package:eco_taksi/screens/main/widgets/order_box.dart';
import 'package:eco_taksi/screens/main/widgets/panel_box.dart';
import 'package:eco_taksi/screens/main/widgets/payment_box.dart';
import 'package:eco_taksi/screens/main/widgets/search_box_bottom.dart';
import 'package:eco_taksi/screens/main/widgets/search_route_bottom.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
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
  sdk.LocationService? _locationService;
  StreamSubscription<sdk.Location?>? locationSubscription;

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
      body: sdk.MapWidget(
        sdkContext: sdkContext,
        mapOptions: sdk.MapOptions(),
        controller: _mapWidgetController,
        child: Stack(
          children: [
            // Верхняя панель с адресом и поиском
            PanelBox(onTap: onShowSearchAddressBottom),
            // _buildTopPanel(),
            // Нижняя панель с часто посещаемыми адресами
            // _buildBottomPanel(),
          ],
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
    );
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

  void onOrderBoxBottom() {
    showModalBottomSheet(
      isScrollControlled: true,
      useSafeArea: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.4,
          child: OrderBox(),
        );
      },
    );
  }
}
