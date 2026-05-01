import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/visits/models/manager_visit_entry.dart';
import 'package:guardgrey/modules/manager/visits/repositories/manager_visit_repository.dart';

class ManagerVisitDetailScreen extends StatelessWidget {
  const ManagerVisitDetailScreen({
    super.key,
    required this.visit,
    required this.onEdit,
  });

  final ManagerVisitEntry visit;
  final VoidCallback onEdit;

  Future<void> _delete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Visit'),
        content: const Text(
          'This visit will be hidden from the active manager list.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    await ManagerVisitRepository.instance.softDeleteVisit(visit.id);
    if (!context.mounted) {
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Visit Detail',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (visit.canEditToday)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          if (visit.canEditToday)
            IconButton(
              onPressed: () => _delete(context),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          ManagerSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        visit.siteName,
                        style: AppTextStyles.title.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ManagerStatusChip(label: visit.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  formatDateTimeLabel(visit.scheduledAt),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  visit.notes.isEmpty ? 'No notes added.' : visit.notes,
                  style: AppTextStyles.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (visit.checklist.isNotEmpty) ...[
            Text(
              'Checklist',
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ManagerSurfaceCard(
              child: Column(
                children: [
                  for (final item in visit.checklist) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: AppColors.success,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item, style: AppTextStyles.bodyMedium),
                        ),
                      ],
                    ),
                    if (item != visit.checklist.last)
                      const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          Text(
            'Photos',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (visit.imageUrls.isEmpty)
            const ManagerEmptyState(
              title: 'No photo uploaded',
              message: 'Visit proof images will appear here after submission.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visit.imageUrls.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  visit.imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.neutral100,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
