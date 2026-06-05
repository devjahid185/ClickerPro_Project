import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class LensLoader extends StatelessWidget {
  const LensLoader({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: const CircularProgressIndicator(
          color: AppColors.orange,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
