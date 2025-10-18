import 'dart:io';

import 'package:flutter/material.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'styles/app_theme.dart';
import 'screens/auth/phone_auth_screen.dart';
import 'screens/main/simple_main_screen.dart';
import 'screens/location_permission_screen.dart';

late sdk.Context sdkContext;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    final iosKey  = const sdk.KeyFromAsset('dgissdk_ios.key');
    final androidKey  = const sdk.KeyFromAsset('dgissdk.key');

    final key =  sdk.KeySource.fromAsset(Platform.isAndroid ? androidKey : iosKey);

    sdkContext = sdk.DGis.initialize(keySource: key);
  } catch (e) {
    print('Ошибка инициализации SDK: $e');
  }
  
  runApp(const TaxiApp());
}

class TaxiApp extends StatelessWidget {
  const TaxiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eco Такси',
      theme: AppTheme.lightTheme,
      home: const LocationPermissionScreen(
        nextScreen: AuthWrapper(),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _savedPhoneNumber;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await LocationService().initialize();
    } catch (e) {
      print('Ошибка инициализации LocationService: $e');
    }
    
    await _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      final clientData = await AuthService.getCurrentClient();
      
      setState(() {
        _isLoggedIn = isLoggedIn;
        _savedPhoneNumber = clientData?['phoneNumber'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (_isLoading) {
    //   return const Scaffold(
    //     body: Center(
    //       child: CircularProgressIndicator(),
    //     ),
    //   );
    // }

    if (_isLoggedIn) {
      return const SimpleMainScreen();
    } else {
      return const PhoneAuthScreen();
    }
  }
}

