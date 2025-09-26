import 'package:dgis_mobile_sdk_full/dgis.dart' as sdk;
import 'package:flutter/material.dart';

import '../../../styles/app_colors.dart';
import '../../../styles/app_spacing.dart';
import '../../../styles/app_text_styles.dart';

class MapBox extends StatelessWidget {
  const MapBox({super.key, required this.sdkContext});

  final sdk.Context sdkContext;

  @override
  Widget build(BuildContext context) {
    final mapWidgetController = sdk.MapWidgetController();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
      ),
      child: Stack(
        children: [
          // Заглушка карты
          sdk.MapWidget(
            sdkContext: sdkContext,
            mapOptions: sdk.MapOptions(),
            controller: mapWidgetController,
            // child: ,
          ),

          // Кнопка геолокации (в левом нижнем углу карты)
          Positioned(
            bottom: AppSpacing.lg,
            left: AppSpacing.lg,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.my_location,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Геолокация будет доступна с картой'),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
