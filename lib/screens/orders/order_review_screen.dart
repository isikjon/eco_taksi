import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../styles/app_border_radius.dart';
import '../../widgets/custom_button.dart';
import '../../services/order_service.dart';
import '../main/simple_main_screen.dart';

class OrderReviewScreen extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderReviewScreen({super.key, required this.orderData});

  @override
  State<OrderReviewScreen> createState() => _OrderReviewScreenState();
}

class _OrderReviewScreenState extends State<OrderReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitReview() {
    OrderService().clearCurrentOrder();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Спасибо за ваш отзыв!',
          style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.success,
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const SimpleMainScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final price = widget.orderData['price']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Оцените поездку',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppSpacing.all24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: AppSpacing.all24,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppColors.success,
                ),
              ),
              AppSpacing.verticalSpace24,
              Text(
                'Поездка завершена!',
                style: AppTextStyles.h1.copyWith(color: AppColors.textPrimary),
              ),
              AppSpacing.verticalSpace8,
              Text(
                'Стоимость: $price сом',
                style: AppTextStyles.h3.copyWith(color: AppColors.primary),
              ),
              AppSpacing.verticalSpace32,
              Text(
                'Оцените поездку',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
              ),
              AppSpacing.verticalSpace16,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: AppColors.warning,
                    ),
                  );
                }),
              ),
              AppSpacing.verticalSpace24,
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Оставьте комментарий (необязательно)',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: AppBorderRadius.all16,
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.all16,
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppBorderRadius.all16,
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
              AppSpacing.verticalSpace32,
              CustomButton(
                text: 'Отправить отзыв',
                onPressed: _submitReview,
              ),
              AppSpacing.verticalSpace16,
              TextButton(
                onPressed: () {
                  OrderService().clearCurrentOrder();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const SimpleMainScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: Text(
                  'Пропустить',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
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

