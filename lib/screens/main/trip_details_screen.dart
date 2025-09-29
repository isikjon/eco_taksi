import 'package:eco_taksi/screens/main/additional_stop_screen.dart';
import 'package:eco_taksi/styles/app_assets.dart';
import 'package:eco_taksi/styles/app_border_radius.dart';
import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_spacing.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TripDetailsScreen extends StatelessWidget {
  const TripDetailsScreen({super.key});

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
          Text('Детали поездки', style: AppTextStyles.h2),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          Row(
            spacing: 8,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 15, color: AppColors.greenLight),
                  const SizedBox(height: 4),
                  Container(
                    width: 0.9,
                    height: 30,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.circle, size: 15, color: AppColors.offline),
                ],
              ),
              Expanded(
                child: Column(
                  spacing: 8,
                  children: [
                    _buildBox(address: 'Ош'),
                    _buildBox(
                      address: 'Введите точку отправления',
                      isShowAdd: true,
                      onTap: () => _goToPageAdditionalStop(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildAnotherParametr(
            title: 'Оплата наличными',
            widget: SvgPicture.asset(AppAssets.arrowRight),
          ),
          const SizedBox(height: 8),
          _buildAnotherParametr(
            title: 'Стоимость',
            widget: Text('1 000 р.', style: AppTextStyles.bodyLarge),
          ),
          const SizedBox(height: 8),
          _buildAnotherParametr(
            title: 'Машина',
            widget: Text(
              'синий LADA (ВАЗ) Vesta ',
              style: AppTextStyles.bodyLarge,
            ),
          ),
          const SizedBox(height: 8),
          _buildAnotherParametr(
            title: 'Гос. номер',
            widget: Text('7940МР-1', style: AppTextStyles.bodyLarge),
          ),
          const SizedBox(height: 8),
          _buildAnotherParametr(
            title: 'Тариф',
            widget: Text('Эконом', style: AppTextStyles.bodyLarge),
          ),
        ],
      ),
    );
  }

  _buildAnotherParametr({
    String? title,
    VoidCallback? onTap,
    required Widget widget,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        spacing: 6,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title ?? '', style: AppTextStyles.bodyLarge),
              widget,
            ],
          ),
          Divider(color: AppColors.greyDivider),
        ],
      ),
    );
  }

  _buildBox({String? address, bool? isShowAdd, VoidCallback? onTap}) {
    return InkWell(
      child: Container(
        width: double.infinity,
        padding: AppSpacing.all12.copyWith(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorderRadius.all10,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(address ?? '', style: AppTextStyles.bodyLarge),
            if (isShowAdd ?? false)
              InkWell(onTap: onTap, child: Icon(Icons.add)),
          ],
        ),
      ),
    );
  }

  void _goToPageAdditionalStop(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return AdditionalStopScreen();
    }));
  }
}
