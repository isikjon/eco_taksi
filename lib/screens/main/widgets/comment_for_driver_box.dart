import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:flutter/material.dart';

import '../../../widgets/custom_button.dart';

class CommentForDriverBox extends StatelessWidget {
  const CommentForDriverBox({super.key});

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
          Text('Комментарий водителю', style: AppTextStyles.h3,),
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
