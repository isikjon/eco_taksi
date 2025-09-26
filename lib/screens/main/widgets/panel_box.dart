import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_spacing.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class PanelBox extends StatelessWidget {
  const PanelBox({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 50,),
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                icon: const Icon(Icons.menu, size: 40),
                onPressed: () => Scaffold.of(context).openDrawer(),
                color: AppColors.primaryDark,
              ),
            ),
            Expanded(
              flex: 10,
              child: Column(
                children: [
                  Text(
                    'Ваш адрес',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ffff',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Spacer(),
          ],
        ),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 48,
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.borderRadiusSmall),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: AppSpacing.md),
                const Icon(Icons.search, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Куда едем?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
