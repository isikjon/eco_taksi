import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';

class TariffsScreen extends StatelessWidget {
  const TariffsScreen({super.key});

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
          'Тарифы',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              // Тариф "Эконом"
              _buildTariffCard(
                'Эконом',
                'Базовый тариф для повседневных поездок',
                'От 50 сом',
                Icons.directions_car,
                AppColors.primary,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Тариф "Стандарт"
              _buildTariffCard(
                'Стандарт',
                'Комфортные поездки с улучшенным сервисом',
                'От 80 сом',
                Icons.directions_car_outlined,
                AppColors.primary,
              ),
              
              const SizedBox(height: AppSpacing.md),
              
              // Тариф "Комфорт"
              _buildTariffCard(
                'Комфорт',
                'Премиум сервис с максимальным комфортом',
                'От 120 сом',
                Icons.directions_car_filled,
                AppColors.primary,
              ),
              
              const SizedBox(height: AppSpacing.xl),
              
              // Дополнительная информация
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дополнительная информация',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                    
                    const SizedBox(height: AppSpacing.md),
                    
                    _buildInfoItem('• Стоимость может изменяться в зависимости от расстояния и времени'),
                    _buildInfoItem('• В праздничные дни действуют повышенные тарифы'),
                    _buildInfoItem('• Дополнительные услуги оплачиваются отдельно'),
                    _buildInfoItem('• Минимальная стоимость поездки - 50 сом'),
                    _buildInfoItem('• Оплата производится наличными или картой'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTariffCard(String title, String description, String price, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.borderRadius),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),
          
          const SizedBox(width: AppSpacing.lg),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                Text(
                  description,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.sm),
                
                Text(
                  price,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        text,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: 16,
        ),
      ),
    );
  }
}
