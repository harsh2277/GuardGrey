import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../modules/admin/data/admin_dummy_data.dart';
import '../../modules/admin/models/manager_model.dart';
import '../../modules/admin/widgets/admin_search_bar.dart';

class ManagersListScreen extends StatefulWidget {
  const ManagersListScreen({super.key});

  @override
  State<ManagersListScreen> createState() => _ManagersListScreenState();
}

class _ManagersListScreenState extends State<ManagersListScreen> {
  String _searchQuery = '';

  List<ManagerModel> get _filteredManagers {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return AdminDummyData.managers;
    }

    return AdminDummyData.managers.where((manager) {
      return manager.name.toLowerCase().contains(query) ||
          manager.email.toLowerCase().contains(query) ||
          manager.phone.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final managers = _filteredManagers;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Managers',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          children: [
            AdminSearchBar(
              height: 50,
              hintText: 'Search managers...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: managers.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      itemCount: managers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final manager = managers[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: AppColors.neutral200),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppColors.primary50,
                                child: Text(
                                  manager.name.substring(0, 1),
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color: AppColors.primary600,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      manager.name,
                                      style: AppTextStyles.bodyLarge.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.neutral900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      manager.email,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.neutral600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      manager.phone,
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.neutral500,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.neutral400,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary50,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.groups_outlined,
              color: AppColors.primary600,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No managers available',
            style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Manager profiles will appear here once data is available.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.neutral500,
            ),
          ),
        ],
      ),
    );
  }
}
