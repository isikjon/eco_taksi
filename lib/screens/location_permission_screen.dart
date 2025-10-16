import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';
import '../styles/app_spacing.dart';

class LocationPermissionScreen extends StatefulWidget {
  final Widget nextScreen;

  const LocationPermissionScreen({
    super.key,
    required this.nextScreen,
  });

  @override
  State<LocationPermissionScreen> createState() => _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isChecking = true;
  bool _hasPermission = false;
  bool _serviceEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  Future<void> _checkLocationStatus() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      final permission = await Geolocator.checkPermission();

      setState(() {
        _serviceEnabled = serviceEnabled;
        _hasPermission = permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse;
        _isChecking = false;
      });

      if (_serviceEnabled && _hasPermission) {
        _navigateToNextScreen();
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isChecking = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      
      if (!serviceEnabled) {
        setState(() {
          _serviceEnabled = false;
          _isChecking = false;
        });
        
        _showLocationServiceDialog();
        return;
      }

      setState(() {
        _serviceEnabled = true;
      });

      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isChecking = false;
        });
        _showOpenSettingsDialog();
        return;
      }

      final hasPermission = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;

      setState(() {
        _hasPermission = hasPermission;
        _isChecking = false;
      });

      if (hasPermission && _serviceEnabled) {
        _navigateToNextScreen();
      }
    } catch (e) {
      setState(() {
        _isChecking = false;
      });
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Геолокация отключена', style: AppTextStyles.h3),
        content: const Text(
          'Для работы приложения необходимо включить геолокацию в настройках устройства.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openLocationSettings();
              await Future.delayed(const Duration(seconds: 1));
              _checkLocationStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  void _showOpenSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Доступ к геолокации', style: AppTextStyles.h3),
        content: const Text(
          'Доступ к геолокации запрещен навсегда. Пожалуйста, разрешите доступ в настройках приложения.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await Geolocator.openAppSettings();
              await Future.delayed(const Duration(seconds: 1));
              _checkLocationStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  void _navigateToNextScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => widget.nextScreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (_hasPermission && _serviceEnabled) {
      return widget.nextScreen;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 120,
                color: AppColors.primary,
              ),
              AppSpacing.verticalSpace32,
              Text(
                'Доступ к геолокации',
                style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpace16,
              Text(
                !_serviceEnabled
                    ? 'Для работы приложения необходимо включить геолокацию на вашем устройстве'
                    : 'Для работы приложения необходимо разрешить доступ к вашему местоположению',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpace32,
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _requestLocationPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                    ),
                  ),
                  child: Text(
                    !_serviceEnabled
                        ? 'Включить геолокацию'
                        : 'Разрешить доступ',
                    style: AppTextStyles.button,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

