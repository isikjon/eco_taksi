import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_spacing.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

class AdditionalStopScreen extends StatelessWidget {
  const AdditionalStopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.black, size: 40),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
      ),
      body: ListView(
        padding: AppSpacing.h16,
        children: [
          Text('Дополнительная остановка', style: AppTextStyles.h2),
          const SizedBox(height: AppSpacing.md),
          TextFormField(),
        ],
      ),
    );
  }
}
