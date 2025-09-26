import 'package:eco_taksi/screens/main/trip_details_screen.dart';
import 'package:eco_taksi/styles/app_assets.dart';
import 'package:eco_taksi/styles/app_border_radius.dart';
import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:eco_taksi/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class OrderBox extends StatelessWidget {
  const OrderBox({super.key});

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
          const SizedBox(height: 2),
          Text('Через 6 мин приедет', style: AppTextStyles.h3),
          Row(
            spacing: 25,
            children: [
              Text('синий LADA (ВАЗ) Vesta', style: AppTextStyles.bodyMedium),
              Text('7940МР-1', style: AppTextStyles.bodyMedium),
            ],
          ),
          Row(
            spacing: 16,
            children: [
              Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: AppColors.grey,
                  borderRadius: AppBorderRadius.all100,
                ),
              ),
              Column(
                spacing: 4,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Гулецкий Антон Анатольевич'),
                  Row(
                    spacing: 4,
                    children: [
                      Icon(Icons.star_border_sharp, size: 16),
                      Text('5.0'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCard(icon: Icons.call_rounded, label: 'Позвонить'),
              _buildCard(icon: Icons.chat, label: 'Написать'),
              _buildCard(icon: Icons.description, label: 'Детали', onTap: () => _goToPage(context)),
              _buildCard(icon: Icons.clear, label: 'Отменить'),
            ],
          ),
        ],
      ),
    );
  }

  void _goToPage(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return TripDetailsScreen();
    }));
  }

  _buildCard({String? label, IconData? icon, VoidCallback? onTap}) {
    return Column(
      spacing: 4,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppBorderRadius.all100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: Icon(icon)),
          ),
        ),
        Text(
          label ?? '',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.black),
        ),
      ],
    );
  }
}
