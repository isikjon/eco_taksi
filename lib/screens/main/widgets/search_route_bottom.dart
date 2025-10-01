import 'dart:async';
import 'package:eco_taksi/styles/app_assets.dart';
import 'package:eco_taksi/styles/app_border_radius.dart';
import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_spacing.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:eco_taksi/widgets/custom_button.dart';
import 'package:eco_taksi/services/location_service.dart';
import 'package:eco_taksi/screens/main/widgets/search_box_bottom.dart';
import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchRouteBottom extends StatefulWidget {
  const SearchRouteBottom({
    super.key,
    required this.controller,
    required this.onTap,
    required this.onShowCommentBottom,
    required this.onShowPaymentBottom,
    required this.onShowOrderAnotherHumanBottom,
    required this.onShowOrderBoxBottom,
    required this.sdkContext,
    required this.selectedAddress,
    required this.onTapDestinationAddress,
    required this.destinationAddress,
    this.routeDistance,
  });

  final ScrollController controller;
  final VoidCallback onTap;
  final VoidCallback onTapDestinationAddress;
  final VoidCallback onShowCommentBottom;
  final VoidCallback onShowPaymentBottom;
  final VoidCallback onShowOrderAnotherHumanBottom;
  final VoidCallback onShowOrderBoxBottom;
  final sdk.Context sdkContext;
  final String selectedAddress;
  final String destinationAddress;
  final String? routeDistance;

  @override
  State<SearchRouteBottom> createState() => _SearchRouteBottomState();
}

class _SearchRouteBottomState extends State<SearchRouteBottom> {
  int? _currentIndex;
  final LocationService _locationService = LocationService();
  StreamSubscription<String>? _addressSubscription;

  void onSelectedTariff(int? index) => setState(() => _currentIndex = index);

  @override
  void initState() {
    super.initState();
    // _currentAddress = widget.selectedAddress;
    // _initializeLocation();
  }


  @override
  void dispose() {
    _addressSubscription?.cancel();
    super.dispose();
  }


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
      child: SingleChildScrollView(
        controller: widget.controller,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                      _buildBox(address: widget.selectedAddress, onTap: widget.onTap),
                      _buildBox(address: widget.destinationAddress, onTap: widget.onTapDestinationAddress),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Text('_routeDistance: ${widget.routeDistance ?? 'gg'}'),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.22,
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTariff(
                    image: AppAssets.econom,
                    tariffName: 'Эконом',
                    tariffPrice: '333',
                    tariffTime: '5',
                    index: 0,
                  ),
                  _buildTariff(
                    image: AppAssets.comfort,
                    tariffName: 'Комфрорт',
                    tariffPrice: '677',
                    tariffTime: '5',
                    index: 1,
                  ),
                  _buildTariff(
                    image: AppAssets.mineven,
                    tariffName: 'Минивэн',
                    tariffPrice: '3433',
                    tariffTime: '5',
                    index: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildAnotherParametr(title: 'Коментарий водителю', onTap: widget.onShowCommentBottom),
            const SizedBox(height: 16),
            _buildAnotherParametr(title: 'Заказать другому человеку', onTap: widget.onShowOrderAnotherHumanBottom),
            const SizedBox(height: 16),
            _buildAnotherParametr(title: 'Способ оплаты', onTap: widget.onShowPaymentBottom),
            const SizedBox(height: 16),
            CustomButton(text: 'Заказать', onPressed: () {
              // Navigator.pop(context);
              widget.onShowOrderBoxBottom.call();
            },),
          ],
        ),
      ),
    );
  }

  _buildTariff({
    String? image,
    String? tariffName,
    String? tariffPrice,
    String? tariffTime,
    int? index,
  }) {
    return InkWell(
      onTap: () => onSelectedTariff(index),
      child: Container(
        margin: AppSpacing.r8.copyWith(bottom: 10),
        padding: AppSpacing.all16,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorderRadius.all16,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Image.asset(image ?? '', width: 100),
            Text(
              tariffName ?? '',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.black),
            ),
            SizedBox(height: 7),
            Text(
              "${widget.routeDistance}км $tariffPrice c",
              style: AppTextStyles.h3.copyWith(color: AppColors.black),
            ),
            SizedBox(height: 7),
            Container(
              alignment: Alignment.center,
              height: 24,
              width: 61,
              decoration: BoxDecoration(
                color: index == _currentIndex
                    ? AppColors.greenLight
                    : AppColors.grey,
                borderRadius: AppBorderRadius.all100,
              ),
              child: Text(
                '$tariffTime мин',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.background,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _buildBox({String? address, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? widget.onTap,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.all12.copyWith(),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppBorderRadius.all16,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Text(address ?? '', style: AppTextStyles.bodyLarge),
      ),
    );
  }

  _buildAnotherParametr({String? title, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title ?? '', style: AppTextStyles.bodyLarge),
              SvgPicture.asset(AppAssets.arrowRight),
            ],
          ),
          Divider(color: AppColors.greyDivider),
        ],
      ),
    );
  }
}
