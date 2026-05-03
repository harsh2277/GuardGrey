import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/data/models/field_visit_model.dart';
import 'package:guardgrey/data/repositories/field_visit_repository.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';

class FieldVisitDetailScreen extends StatelessWidget {
  const FieldVisitDetailScreen({super.key, required this.visitId});

  final String visitId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FieldVisitModel?>(
      stream: FieldVisitRepository.instance.watchFieldVisit(visitId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final visit = snapshot.data;
        if (visit == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const ManagerEmptyState(
              title: 'Field visit not found',
              message: 'The selected visit is no longer available.',
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Field Visit Detail',
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
            children: [
              ManagerSurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary50,
                          backgroundImage: visit.profileImage.isNotEmpty
                              ? NetworkImage(visit.profileImage)
                              : null,
                          child: visit.profileImage.isEmpty
                              ? Text(
                                  visit.managerName.isEmpty
                                      ? 'M'
                                      : visit.managerName[0],
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.primary700,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visit.siteName,
                                style: AppTextStyles.title.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                visit.managerName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.neutral600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ManagerStatusChip(label: visit.status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _DetailLine(
                      icon: Icons.schedule_outlined,
                      label: 'Visit Time',
                      value: formatDateTimeLabel(visit.dateTime),
                    ),
                    const SizedBox(height: 12),
                    _DetailLine(
                      icon: Icons.pin_drop_outlined,
                      label: 'Location',
                      value: visit.location.address,
                    ),
                    const SizedBox(height: 12),
                    _DetailLine(
                      icon: Icons.notes_outlined,
                      label: 'Notes',
                      value: visit.notes.isEmpty
                          ? 'No notes added.'
                          : visit.notes,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Photo Proof',
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (visit.imageUrls.isEmpty)
                const ManagerEmptyState(
                  title: 'No images uploaded',
                  message: 'Photo proof will appear here after upload.',
                )
              else
                GridView.builder(
                  itemCount: visit.imageUrls.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                  ),
                  itemBuilder: (context, index) {
                    final url = visit.imageUrls[index];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.neutral100,
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary700, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.neutral500,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
