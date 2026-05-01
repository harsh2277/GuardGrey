import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/widgets/list_tile.dart';
import 'package:guardgrey/core/widgets/section_header.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/data/repositories/manager_repository.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';

class ManagerProfileScreen extends StatefulWidget {
  const ManagerProfileScreen({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  State<ManagerProfileScreen> createState() => _ManagerProfileScreenState();
}

class _ManagerProfileScreenState extends State<ManagerProfileScreen> {
  final ManagerRepository _repository = ManagerRepository.instance;

  Future<void> _editProfile(ManagerModel manager) async {
    final nameController = TextEditingController(text: manager.name);
    final phoneController = TextEditingController(text: manager.phone);
    final formKey = GlobalKey<FormState>();

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: AppTextStyles.title.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Phone is required'
                    : null,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.pop(context, true);
                    }
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (shouldSave != true) {
      return;
    }

    await _repository.saveManager(
      manager.copyWith(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Profile updated successfully.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ManagerModel?>(
      stream: ManagerSessionService.instance.watchCurrentManager(),
      builder: (context, snapshot) {
        final manager = snapshot.data;

        final body =
            snapshot.connectionState == ConnectionState.waiting &&
                manager == null
            ? const Center(child: CircularProgressIndicator())
            : manager == null
            ? const ManagerEmptyState(
                title: 'No manager workspace data',
                message:
                    'Profile details will appear after the manager workspace syncs.',
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  ManagerSurfaceCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.primary50,
                          child: Text(
                            manager.name.isEmpty ? 'M' : manager.name[0],
                            style: AppTextStyles.headingSmall.copyWith(
                              color: AppColors.primary700,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          manager.name,
                          style: AppTextStyles.title.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          manager.email,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.neutral500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          manager.phone,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const SectionHeader(title: 'Details'),
                  const SizedBox(height: 12),
                  AppListTile(
                    title: manager.name,
                    subtitle: 'Manager Name',
                    leadingIcon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                  AppListTile(
                    title: manager.phone,
                    subtitle: 'Phone',
                    leadingIcon: Icons.call_outlined,
                  ),
                  const SizedBox(height: 12),
                  AppListTile(
                    title: manager.email,
                    subtitle: 'Email',
                    leadingIcon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 12),
                  const AppListTile(
                    title: 'Manager',
                    subtitle: 'Role',
                    leadingIcon: Icons.badge_outlined,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _editProfile(manager),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit Profile'),
                    ),
                  ),
                ],
              );

        if (!widget.showAppBar) {
          return body;
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Profile',
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          body: body,
        );
      },
    );
  }
}
