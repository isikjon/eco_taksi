import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../widgets/logo_widget.dart';
import '../../services/user_data_service.dart';
import 'sms_verification_screen.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    print('🔍 [FORMATTER DEBUG] Input: "${newValue.text}" -> Digits: "$text" (length: ${text.length})');
    
    // Ограничиваем только 9 цифрами (123 456 789)
    if (text.length > 9) {
      print('🔍 [FORMATTER DEBUG] Too many digits, returning old value');
      return oldValue;
    }
    
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }
    
    String formatted = '';
    if (text.length >= 1) {
      formatted = text.substring(0, 1);
    }
    if (text.length >= 2) {
      formatted += text.substring(1, 2);
    }
    if (text.length >= 3) {
      formatted += text.substring(2, 3);
    }
    if (text.length >= 4) {
      formatted += ' ${text.substring(3, 4)}';
    }
    if (text.length >= 5) {
      formatted += text.substring(4, 5);
    }
    if (text.length >= 6) {
      formatted += text.substring(5, 6);
    }
    if (text.length >= 7) {
      formatted += ' ${text.substring(6, 7)}';
    }
    if (text.length >= 8) {
      formatted += text.substring(7, 8);
    }
    if (text.length >= 9) {
      formatted += text.substring(8, 9);
    }
    
    print('🔍 [FORMATTER DEBUG] Final formatted: "$formatted" (length: ${formatted.length})');
    
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isSwitching = false;
  bool _isLoginMode = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleMode() async {
    setState(() {
      _isSwitching = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoginMode = !_isLoginMode;
        _isSwitching = false;
      });
    }
  }

  void _continue() {
    if (_phoneController.text.isEmpty) return;
    
    // Максимальное логирование для отладки
    final rawText = _phoneController.text;
    final digitsOnly = rawText.replaceAll(RegExp(r'[^\d]'), '');
    print('🔍 [PHONE DEBUG] Raw text: "$rawText" (length: ${rawText.length})');
    print('🔍 [PHONE DEBUG] Digits only: "$digitsOnly" (length: ${digitsOnly.length})');
    print('🔍 [PHONE DEBUG] Characters: ${rawText.split('').map((c) => "'$c'").join(', ')}');
    
    if (digitsOnly.length != 9) {
      print('❌ [PHONE DEBUG] Validation failed: expected 9 digits, got ${digitsOnly.length}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Введите полный номер телефона (9 цифр). Получено: ${digitsOnly.length} цифр'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    
    print('✅ [PHONE DEBUG] Validation passed: 9 digits found');
    
    setState(() {
      _isLoading = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        final fullPhoneNumber = '+996${_phoneController.text}';
        await UserDataService.instance.savePhoneNumber(fullPhoneNumber);
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SmsVerificationScreen(
              phoneNumber: _phoneController.text,
            ),
          ),
        );
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  _buildLogo(),
                  const SizedBox(height: AppSpacing.xxl),
                  _buildTitle(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRoleSelector(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPhoneInput(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildContinueButton(),
                  const Spacer(),
                  _buildLegalText(),
                  const SizedBox(height: AppSpacing.md),
                  _buildFooter(),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return const LogoWidget();
  }

  Widget _buildTitle() {
    return Text(
      _isLoginMode ? 'Логин по номеру телефона' : 'Регистрация по номеру телефона',
      style: AppTextStyles.h2.copyWith(
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: const Color(0xFFCECECE)),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
      ),
      child: const Center(
        child: Text(
          'Пользователь',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCECECE)),
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Text(
              '+996',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 0),
          Expanded(
            child: TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                PhoneNumberFormatter(),
              ],
              // style: AppTextStyles.bodyLarge.copyWith(
              //   color: AppColors.textPrimary,
              // ),
              decoration: const InputDecoration(
                hintText: '123 456 789',
                hintStyle: TextStyle(
                  color: AppColors.textHint,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _continue,
          borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                    ),
                  )
                : const Text(
                    'Продолжить',
                    style: TextStyle(
                      color: AppColors.surface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegalText() {
    return Column(
      children: [
        if (_isSwitching)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: GestureDetector(
              onTap: _toggleMode,
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: _isLoginMode ? 'У вас нету аккаунта? ' : 'У вас уже есть аккаунт? ',
                    ),
                    TextSpan(
                      text: _isLoginMode ? 'РЕГИСТРАЦИЯ' : 'ЛОГИН',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Text(
          'Нажимая кнопку вы соглашаетесь с условиями',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserAgreementScreen()),
                );
              },
              child: Text(
                'Пользовательского соглашения',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              ' и ',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                );
              },
              child: Text(
                'Политики',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            );
          },
          child: Text(
            'конфиденциальности',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      'Центр обработки, тех. поддержка, авторские права',
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textSecondary,
      ),
      textAlign: TextAlign.center,
    );
  }
}


class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Пользовательское соглашение'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''
Пользовательское соглашение приложения «Эко Такси KG»

1. Общие положения
Настоящее Пользовательское соглашение (далее — «Соглашение») регулирует отношения между администрацией мобильного приложения «Эко Такси KG» (далее — «Администрация») и физическим лицом, использующим приложение для заказа поездок (далее — «Пользователь»).
Используя приложение, Пользователь подтверждает, что ознакомился и согласен с условиями настоящего Соглашения.

⸻

2. Назначение приложения
Приложение «Эко Такси KG» предназначено для пользователей, которые заказывают услуги такси через приложение. Приложение обеспечивает доступ к заказам, выбор водителя и удобную оплату.
Администрация не является перевозчиком и не несёт ответственность за действия водителей — она предоставляет технологическую платформу для взаимодействия между пассажирами и водителями.

⸻

3. Регистрация и доступ к приложению
3.1. Для использования приложения Пользователь обязан пройти регистрацию и предоставить достоверные персональные данные.
3.2. Администрация вправе проверять предоставленную информацию и при необходимости ограничить доступ.
3.3. Пользователь несёт ответственность за сохранность своих регистрационных данных и не вправе передавать их третьим лицам.

⸻

4. Права и обязанности сторон
4.1. Пользователь обязуется:
— использовать приложение исключительно для законных целей;
— предоставлять корректные данные при регистрации и оплате;
— соблюдать правила поведения при поездках.

4.2. Администрация обязуется:
— поддерживать работоспособность приложения;
— обеспечивать защиту персональных данных Пользователя;
— информировать о существенных изменениях условий Соглашения.

⸻

5. Ответственность сторон
5.1. Пользователь несёт ответственность за корректное использование приложения и соблюдение правил при поездках.
5.2. Администрация не несёт ответственности за действия водителей и качество предоставленных услуг.
5.3. Администрация не гарантирует бесперебойную работу приложения и не отвечает за временные технические сбои.

⸻

6. Обработка персональных данных
Пользователь даёт согласие на обработку своих персональных данных в соответствии с Политикой конфиденциальности.
Обработка включает сбор, хранение, использование и передачу данных для идентификации, предоставления услуг и обеспечения работы приложения.

⸻

7. Изменение условий
Администрация имеет право изменять условия настоящего Соглашения. Новая редакция вступает в силу с момента её публикации в приложении.

⸻

8. Контакты
По вопросам, связанным с работой приложения:
📧 Email: ip.maasaliev@gmail.com
📞 Телефон: +996 559 868 878
          ''',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Политика конфиденциальности')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Text(
          '''
Политика конфиденциальности приложения «Эко Такси KG»

1. Общие положения
Настоящая Политика конфиденциальности описывает, как приложение «Эко Такси KG» собирает, использует и защищает персональные данные пользователей.

⸻

2. Персональные данные, которые собираются
— ФИО, номер телефона, адрес электронной почты;
— История поездок и предпочтения маршрутов;
— Геолокация во время использования приложения;
— Данные о платежах;
— Технические данные устройства (модель, ОС).

⸻

3. Цели обработки данных
— Регистрация и идентификация пользователей;
— Предоставление услуг такси и расчёт стоимости поездок;
— Обеспечение безопасности поездок и предотвращение мошенничества;
— Связь с пользователями и оказание технической поддержки;
— Выполнение требований законодательства Кыргызской Республики.

⸻

4. Передача данных третьим лицам
Данные передаются только для работы картографических сервисов (например, 2ГИС API) и платёжных систем в объёме, необходимом для корректной работы приложения.
Администрация не продаёт и не предоставляет персональные данные пользователям другим организациям или лицам.

⸻

5. Хранение и защита данных
Все данные защищены и хранятся на защищённых серверах с ограниченным доступом.

⸻

6. Права Пользователя
Пользователь имеет право:
— Запрашивать информацию о своих персональных данных;
— Требовать исправления или удаления данных;
— Отзывать согласие на обработку данных, связавшись с Администрацией.

⸻

7. Контакты
📧 Email: ip.maasaliev@gmail.com
📞 Телефон: +996 559 868 878
          ''',
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
      ),
    );
  }
}

