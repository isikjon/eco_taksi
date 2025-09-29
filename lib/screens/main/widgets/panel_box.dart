import 'dart:async';
import 'package:eco_taksi/styles/app_colors.dart';
import 'package:eco_taksi/styles/app_spacing.dart';
import 'package:eco_taksi/styles/app_text_styles.dart';
import 'package:eco_taksi/services/location_service.dart';
import 'package:flutter/material.dart';

class PanelBox extends StatefulWidget {
  const PanelBox({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<PanelBox> createState() => _PanelBoxState();
}

class _PanelBoxState extends State<PanelBox> {
  final LocationService _locationService = LocationService();
  StreamSubscription<String>? _addressSubscription;
  String _currentAddress = 'Ош';

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  void _initializeLocation() {
    _locationService.initialize();
    _addressSubscription = _locationService.addressStream.listen((address) {
      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }
    });
  }

  @override
  void dispose() {
    _addressSubscription?.cancel();
    super.dispose();
  }

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
                    _currentAddress,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Spacer(),
          ],
        ),
        InkWell(
          onTap: widget.onTap,
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
