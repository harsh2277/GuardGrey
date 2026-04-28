import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/models/visit_model.dart';
import 'package:guardgrey/data/repositories/guard_grey_repository.dart';

class ManagerVisitsScreen extends StatelessWidget {
  const ManagerVisitsScreen({
    super.key,
    this.initialSiteId,
    this.initialSiteName,
  });

  final String? initialSiteId;
  final String? initialSiteName;

  GuardGreyRepository get _repository => GuardGreyRepository.instance;

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          initialSiteName == null ? 'My Visits' : '$initialSiteName Visits',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<ManagerModel?>(
        stream: _repository.watchManagerByEmail(email),
        builder: (context, managerSnapshot) {
          final manager = managerSnapshot.data;
          if (managerSnapshot.connectionState == ConnectionState.waiting &&
              manager == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (manager == null) {
            return _buildMessage('Visit history is not available.');
          }

          return StreamBuilder<List<VisitModel>>(
            stream: _repository.watchVisits(),
            builder: (context, visitsSnapshot) {
              final visits = (visitsSnapshot.data ?? const <VisitModel>[])
                  .where((visit) => visit.managerId == manager.id)
                  .where(
                    (visit) =>
                        initialSiteId == null || visit.siteId == initialSiteId,
                  )
                  .toList(growable: false);

              if (visits.isEmpty) {
                return _buildMessage('No site visits found.');
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                itemCount: visits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final visit = visits[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.neutral200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visit.siteName,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${visit.date} • ${visit.time}',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),
                        if (visit.notes.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            visit.notes,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.neutral700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral500),
        ),
      ),
    );
  }
}
