import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.indigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.indigo.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text("⛅", style: TextStyle(fontSize: 40)),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "28°",
                style: TextStyle(
                  color: AppColors.film,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                "Partly Cloudy",
                style: TextStyle(color: AppColors.filmDim, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                "Dhaka, BD",
                style: TextStyle(color: AppColors.film, fontSize: 12),
              ),
              Text(
                "💧 72% Humidity",
                style: TextStyle(color: AppColors.filmDim, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
