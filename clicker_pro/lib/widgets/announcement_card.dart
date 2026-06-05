import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AnnouncementCard extends StatelessWidget {
  final String title;
  final String body;

  // এখানে আমরা ডিফল্ট লেখা দিয়ে দিচ্ছি যাতে কোনো কিছু না দিলেও এরর না আসে
  const AnnouncementCard({
    super.key,
    this.title = "Important Announcement",
    this.body = "No new announcements at the moment.",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.void3,
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: AppColors.accent, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign, color: AppColors.accent, size: 20),
              const SizedBox(width: 8),
              Text(
                "Pinned",
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                "2h ago",
                style: TextStyle(color: AppColors.filmDim, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.film,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(color: AppColors.filmDim, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
