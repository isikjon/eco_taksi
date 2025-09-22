import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'user_data_service.dart';
import 'database_service.dart';
import '../utils/phone_utils.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _clientDataKey = 'client_data';

  static Future<Map<String, dynamic>> checkUserStatus(String phone, String smsCode) async {
    try {
      print('🔍 AuthService.checkUserStatus called with phone: $phone, smsCode: $smsCode');
      final response = await ApiService.instance.loginClient(phone, smsCode);
      print('🔍 AuthService.checkUserStatus response: $response');
      
      if (response['success']) {
        final data = response['data'];
        // API возвращает вложенную структуру: data.data.client
        final nestedData = data?['data'];
        final clientData = nestedData?['client'];
        final isNewUserFromApi = nestedData?['isNewUser'] ?? nestedData?['is_new_user'] ?? false;
        
        print('🔍 Parsed data: nestedData=$nestedData, clientData=$clientData, isNewUserFromApi=$isNewUserFromApi');
        
        // Проверяем, есть ли данные клиента в ответе
        if (clientData != null) {
          // Это существующий пользователь
          // Проверяем статус клиента
          if (clientData['is_active'] == false) {
            return {
              'success': false,
              'error': 'blocked',
              'message': 'Ваш аккаунт заблокирован. Обратитесь в поддержку.',
            };
          }
          
          return {
            'success': true,
            'isNewUser': false,
            'client': clientData,
          };
        } else {
          // Это новый пользователь (нет данных клиента)
          return {
            'success': true,
            'isNewUser': true,
            'client': null,
          };
        }
      } else {
        return {
          'success': false,
          'error': response['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка проверки статуса: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> saveUserDataFromStatus(Map<String, dynamic> statusResponse) async {
    try {
      print('💾 AuthService.saveUserDataFromStatus called with: $statusResponse');
      
      final clientData = statusResponse['client'];
      if (clientData != null) {
        if (clientData['is_active'] == false) {
          return {
            'success': false,
            'error': 'blocked',
            'message': 'Ваш аккаунт заблокирован. Обратитесь в поддержку.',
          };
        }
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_isLoggedInKey, true);
        await prefs.setString(_clientDataKey, jsonEncode(clientData));
        print('💾 Saved client data from status: ${jsonEncode(clientData)}');

        final String normalizedPhone = PhoneUtils.normalizePhoneNumber(clientData['phone_number'] ?? '');
        await UserDataService.instance.savePhoneNumber(normalizedPhone);

        return {
          'success': true,
          'client': clientData,
        };
      } else {
        return {
          'success': false,
          'error': 'Данные пользователя не найдены',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка сохранения данных: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> login(String phone, String smsCode) async {
    try {
      print('🔑 AuthService.login called with phone: $phone, smsCode: $smsCode');
      final response = await ApiService.instance.loginClient(phone, smsCode);
      print('🔑 AuthService.login response: $response');
      
      if (response['success']) {
        final data = response['data'];
        // API возвращает вложенную структуру: data.data.client
        final nestedData = data?['data'];
        final clientData = nestedData?['client'];
        
        print('🔑 Parsed login data: nestedData=$nestedData, clientData=$clientData');
        
        // Проверяем, есть ли данные клиента в ответе
        if (clientData != null) {
          // Это существующий пользователь
          // Проверяем статус клиента
          if (clientData['is_active'] == false) {
            return {
              'success': false,
              'error': 'blocked',
              'message': 'Ваш аккаунт заблокирован. Обратитесь в поддержку.',
            };
          }
          
          // Если клиент активен, сохраняем данные
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_isLoggedInKey, true);
          await prefs.setString(_clientDataKey, jsonEncode(clientData));
          print('Saved client data: ${jsonEncode(clientData)}');
          
          // Обновляем данные в UserDataService (сохраняем нормализованный номер)
          final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phone);
          await UserDataService.instance.savePhoneNumber(normalizedPhone);
          
          return {
            'success': true,
            'isNewUser': false,
            'client': clientData,
          };
        } else {
          // Это новый пользователь (нет данных клиента)
          return {
            'success': true,
            'isNewUser': true,
            'client': null,
          };
        }
      } else {
        return {
          'success': false,
          'error': response['error'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Ошибка авторизации: $e',
      };
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Очищаем все данные авторизации
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_clientDataKey);
      
      // Очищаем данные пользователя из UserDataService
      await UserDataService.instance.clearUserData();
      
      // Очищаем базу данных
      await DatabaseService.clearAllData();
      
      // Очищаем все остальные данные
      await prefs.clear();
      
      print('✅ Logout successful - all data cleared');
    } catch (e) {
      print('❌ Error during logout: $e');
    }
  }

  static Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> registerClient(Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.instance.registerClient(userData);
      
      if (response['success']) {
        final data = response['data'];
        final clientData = data?['client'];
        
        if (clientData != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_isLoggedInKey, true);
          await prefs.setString(_clientDataKey, jsonEncode(clientData));
          print('Saved client data after registration: ${jsonEncode(clientData)}');
          
          final String normalizedPhone = PhoneUtils.normalizePhoneNumber(userData['user']['phoneNumber']);
          await UserDataService.instance.savePhoneNumber(normalizedPhone);
          
          return {
            'success': true,
            'data': {
              'client': clientData,
            },
          };
        } else {
          // Если клиент уже существует, попробуем получить его данные через login
          final String phone = userData['user']['phoneNumber'];
          final loginResponse = await ApiService.instance.loginClient(phone, '1111'); // Используем тестовый код
          
          if (loginResponse['success'] && !loginResponse['isNewUser']) {
            final existingClientData = loginResponse['data']?['client'];
            if (existingClientData != null) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool(_isLoggedInKey, true);
              await prefs.setString(_clientDataKey, jsonEncode(existingClientData));
              print('Saved existing client data: ${jsonEncode(existingClientData)}');
              
              final String normalizedPhone = PhoneUtils.normalizePhoneNumber(phone);
              await UserDataService.instance.savePhoneNumber(normalizedPhone);
              
              return {
                'success': true,
                'data': {
                  'client': existingClientData,
                },
              };
            }
          }
        }
      }
      
      return {
        'success': false,
        'error': response['error'] ?? 'Ошибка регистрации',
      };
    } catch (e) {
      print('Registration error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> getCurrentClient() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientDataString = prefs.getString(_clientDataKey);
      print('Raw client data string: $clientDataString');
      
      if (clientDataString != null && clientDataString.isNotEmpty) {
        // Проверяем, что строка начинается с { (валидный JSON)
        if (clientDataString.startsWith('{')) {
          try {
            final clientData = jsonDecode(clientDataString) as Map<String, dynamic>;
            print('Parsed client data: $clientData');
            return clientData;
          } catch (e) {
            print('JSON parsing error: $e');
            // Если JSON невалидный, очищаем данные
            await prefs.remove(_clientDataKey);
            return null;
          }
        } else {
          print('Invalid JSON format, clearing data');
          // Очищаем невалидные данные
          await prefs.remove(_clientDataKey);
          return null;
        }
      }
      return null;
    } catch (e) {
      print('Error getting driver data: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateClientProfile(Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.instance.updateClientProfile(userData);
      
      if (response['success']) {
        final data = response['data'];
        final clientData = data?['client'];
        
        if (clientData != null) {
          // Обновляем данные в локальном хранилище
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_clientDataKey, jsonEncode(clientData));
          print('Updated client data: ${jsonEncode(clientData)}');
          
          return {
            'success': true,
            'data': {
              'client': clientData,
            },
          };
        }
      }
      
      return {
        'success': false,
        'error': response['error'] ?? 'Ошибка обновления профиля',
      };
    } catch (e) {
      print('Profile update error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> updateClientPaymentMethod(String paymentMethod) async {
    try {
      // Получаем ID клиента из локального хранилища
      final clientData = await getCurrentClient();
      if (clientData == null) {
        return {
          'success': false,
          'error': 'Данные клиента не найдены',
        };
      }
      
      final clientId = clientData['id'];
      if (clientId == null) {
        return {
          'success': false,
          'error': 'ID клиента не найден',
        };
      }
      
      final response = await ApiService.instance.updateClientPaymentMethod(clientId, paymentMethod);
      
      if (response['success']) {
        final data = response['data'];
        final updatedClientData = data?['client'];
        
        if (updatedClientData != null) {
          // Обновляем данные в локальном хранилище
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_clientDataKey, jsonEncode(updatedClientData));
          print('Updated client payment method: ${jsonEncode(updatedClientData)}');
          
          return {
            'success': true,
            'data': {
              'client': updatedClientData,
            },
          };
        }
      }
      
      return {
        'success': false,
        'error': response['error'] ?? 'Ошибка обновления способа оплаты',
      };
    } catch (e) {
      print('Payment method update error: $e');
      return {
        'success': false,
        'error': 'Ошибка сети: $e',
      };
    }
  }
}
