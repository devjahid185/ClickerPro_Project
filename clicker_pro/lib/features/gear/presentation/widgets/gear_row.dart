// lib/features/gear/presentation/widgets/gear_row.dart

import 'package:flutter/material.dart';

import '../../../../core/format/booking_format.dart';
import '../../../../theme/app_colors.dart';
import '../../domain/gear_item.dart';
import '../../../../theme/app_theme.dart';

class GearRow extends StatelessWidget {
  const GearRow({
    super.key,
    required this.item,
    required this.lang,
    required this.onDelete,
  });

  final GearItem item;
  final String lang;
  final Future<void> Function() onDelete;

  IconData _categoryIcon() {
    switch (item.category) {
      case 'Camera':
        return Icons.photo_camera_outlined;
      case 'Lens':
        return Icons.camera_outlined;
      case 'Flash':
        return Icons.flash_on_outlined;
      case 'Tripod':
        return Icons.architecture_outlined;
      case 'Drone':
        return Icons.flight_outlined;
      case 'Audio':
        return Icons.mic_none_outlined;
      case 'Lighting':
        return Icons.wb_iridescent_outlined;
      case 'Storage':
        return Icons.sd_storage_outlined;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('gear-${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.redSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.red),
        ),
        child: Icon(Icons.delete_outline, color: AppColors.red),
      ),
      confirmDismiss: (_) async {
        await onDelete();
        // Controller already removes the row optimistically, so we don't
        // also need Dismissible to remove it; returning false keeps the
        // widget tree consistent।
        return false;
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.glass,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.indigoSoft,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.indigo.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(_categoryIcon(), color: AppColors.indigo, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      color: AppColors.film,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      item.brand,
                      item.category,
                      if (item.condition != null) item.condition,
                    ].whereType<String>().join(' • '),
                    style: TextStyle(
                      color: AppColors.filmDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              BookingFormat.money(
                item.value,
                lang: lang,
                bnNumerals: lang == 'bn',
              ),
              style: TextStyle(
                color: AppColors.gold,
                fontFamily: AppText.brandFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
