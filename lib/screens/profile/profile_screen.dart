import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isEditing = false;
  bool _isLoading = false;
  String _userName = 'Пользователь';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final clientData = await AuthService.getCurrentClient();
      print('ProfileScreen - Loaded client data: $clientData');
      
      if (clientData != null && mounted) {
        final firstName = clientData['first_name'] ?? '';
        final lastName = clientData['last_name'] ?? '';
        final phoneNumber = clientData['phone_number'] ?? '';
        
        print('ProfileScreen - Parsed data: firstName=$firstName, lastName=$lastName, phoneNumber=$phoneNumber');
        
        setState(() {
          _firstNameController.text = firstName;
          _lastNameController.text = lastName;
          _phoneController.text = phoneNumber;
          _userName = '$firstName $lastName'.trim();
          if (_userName.isEmpty) {
            _userName = 'Пользователь';
          }
        });
      } else {
        print('ProfileScreen - No client data found');
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userData = {
        'user': {
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
        }
      };

      final result = await AuthService.updateClientProfile(userData);
      
      if (result['success']) {
        setState(() {
          _isEditing = false;
          _userName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Профиль успешно обновлен'),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Возвращаем результат обновления
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Ошибка обновления профиля'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Профиль',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: Text(
                'Редактировать',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: AppSpacing.lg),
                
                // Аватар
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.divider, width: 1),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                    size: 50,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Поля ввода
                CustomTextField(
                  label: 'Имя',
                  controller: _firstNameController,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите имя';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                CustomTextField(
                  label: 'Фамилия',
                  controller: _lastNameController,
                  enabled: _isEditing,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Введите фамилию';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                CustomTextField(
                  label: 'Номер телефона',
                  controller: _phoneController,
                  enabled: false,
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Кнопки действий
                if (_isEditing) ...[
                  CustomButton(
                    text: 'Сохранить',
                    onPressed: _saveChanges,
                    isLoading: _isLoading,
                  ),
                  
                  const SizedBox(height: AppSpacing.md),
                  
                  CustomButton(
                    text: 'Отмена',
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                      });
                      _loadUserData(); // Восстанавливаем исходные данные
                    },
                    isSecondary: true,
                  ),
                ],
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Кнопка выхода
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.divider),
                    borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.textSecondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: const Text(
                      'Выйти из профиля',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    onTap: _logout,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
