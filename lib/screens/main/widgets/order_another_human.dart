import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:eco_taksi/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class OrderAnotherHuman extends StatelessWidget {
  const OrderAnotherHuman({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text('Кто поедет?', style: AppTextStyles.h3,),
          TextFormField(),
          CustomButton(
            text: 'Готово',
            onPressed: () {
              Navigator.pop(context);
            },

          ),
        ],
      ),
    );
  }
}
