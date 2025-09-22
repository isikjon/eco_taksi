import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import 'partners_screen.dart';
import 'tariffs_screen.dart';
import 'about_screen.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

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
          'Информация',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Пункт "Партнеры"
              _buildInfoOption(
                context,
                'Партнеры',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PartnersScreen(),
                  ),
                ),
              ),
              
              // Пункт "Тарифы"
              _buildInfoOption(
                context,
                'Тарифы',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TariffsScreen(),
                  ),
                ),
              ),
              
              // Пункт "О приложении"
              _buildInfoOption(
                context,
                'О приложении',
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoOption(BuildContext context, String title, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider.withOpacity(0.7),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 24,
        ),
        onTap: onTap,
      ),
    );
  }
}
