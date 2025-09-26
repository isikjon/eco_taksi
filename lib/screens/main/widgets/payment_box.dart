import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:eco_taksi/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class PaymentBox extends StatelessWidget {
  const PaymentBox({super.key});

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
        children: [
          Text('Способ оплаты', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          ListTile(
            selected: true,
            dense: true,
            leading: Icon(Icons.circle),
            title: Text('Наличными', style: AppTextStyles.bodyMedium,),
            trailing: Icon(Icons.check),
          ),
          Divider(
            height: 1,
            thickness: 1,
            indent: 18,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
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
