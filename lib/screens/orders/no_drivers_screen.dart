import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../widgets/custom_button.dart';

class NoDriversScreen extends StatelessWidget {
  const NoDriversScreen({super.key});

  Future<void> _callDispatcher() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+996555123456');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Поиск водителя',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.all24,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.car_crash_outlined,
                  size: 60,
                  color: AppColors.error,
                ),
              ),
              AppSpacing.verticalSpace32,
              Text(
                'К сожалению',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpace16,
              Text(
                'Нет водителей, которые могут\nобслужить вас в данный момент',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.verticalSpace32,
              Container(
                padding: AppSpacing.all16,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: AppBorderRadius.all16,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    AppSpacing.horizontalSpace12,
                    Expanded(
                      child: Text(
                        'Попробуйте позвонить диспетчеру\nдля оформления заказа',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.verticalSpace32,
              CustomButton(
                text: 'Позвонить диспетчеру',
                onPressed: _callDispatcher,
                icon: Icons.phone,
              ),
              AppSpacing.verticalSpace16,
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Вернуться назад',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
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

