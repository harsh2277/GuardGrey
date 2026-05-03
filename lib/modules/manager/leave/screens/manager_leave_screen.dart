import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/data/models/manager_model.dart';
import 'package:guardgrey/modules/manager/common/services/manager_session_service.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/leave/models/manager_leave_request.dart';
import 'package:guardgrey/modules/manager/leave/repositories/manager_leave_repository.dart';

class ManagerLeaveScreen extends StatefulWidget {
  const ManagerLeaveScreen({super.key});

  @override
  State<ManagerLeaveScreen> createState() => _ManagerLeaveScreenState();
}

class _ManagerLeaveScreenState extends State<ManagerLeaveScreen> {
  final ManagerLeaveRepository _repository = ManagerLeaveRepository.instance;

  Future<void> _openForm(
    ManagerModel manager, {
    ManagerLeaveRequest? existing,
  }) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _LeaveFormScreen(manager: manager, existing: existing),
      ),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            existing == null
                ? 'Leave request submitted.'
                : 'Leave request updated.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    }
  }

  Future<void> _deleteLeave(ManagerLeaveRequest leave) async {
    await _repository.deleteLeave(leave.id);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        content: Text(
          'Leave request deleted.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ManagerModel?>(
      stream: ManagerSessionService.instance.watchCurrentManager(),
      builder: (context, managerSnapshot) {
        final manager = managerSnapshot.data;

        return Scaffold(
          backgroundColor: AppColors.backgroundLight,
          appBar: AppBar(
            backgroundColor: AppColors.backgroundLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Leave',
              style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          body: manager == null
              ? const ManagerEmptyState(
                  title: 'No manager workspace data',
                  message:
                      'Leave details will appear after the manager profile is available.',
                )
              : StreamBuilder<List<ManagerLeaveRequest>>(
                  stream: _repository.watchLeaves(manager.id),
                  builder: (context, snapshot) {
                    final leaves =
                        snapshot.data ?? const <ManagerLeaveRequest>[];
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        leaves.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (leaves.isEmpty) {
                      return ManagerEmptyState(
                        title: 'No leave requests yet',
                        message:
                            'Apply leave from the action button when you need time off.',
                        action: FilledButton(
                          onPressed: () => _openForm(manager),
                          child: const Text('Apply Leave'),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                      itemCount: leaves.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final leave = leaves[index];
                        return _LeaveCard(
                          leave: leave,
                          onTap: leave.canManage
                              ? () => _openForm(manager, existing: leave)
                              : null,
                          onEdit: leave.canManage
                              ? () => _openForm(manager, existing: leave)
                              : null,
                          onDelete: leave.canManage
                              ? () => _deleteLeave(leave)
                              : null,
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: manager == null
              ? null
              : FloatingActionButton(
                  onPressed: () => _openForm(manager),
                  tooltip: 'Apply Leave',
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({
    required this.leave,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final ManagerLeaveRequest leave;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ManagerSurfaceCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.event_busy_outlined,
                  color: AppColors.primary600,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.leaveType,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.neutral900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDateLabel(leave.fromDate)} - ${formatDateLabel(leave.toDate)}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ManagerStatusChip(label: leave.status),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              leave.reason,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral700,
              ),
            ),
          ),
          if (leave.canManage) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorDark,
                      side: const BorderSide(color: AppColors.errorLight),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LeaveFormScreen extends StatefulWidget {
  const _LeaveFormScreen({required this.manager, this.existing});

  final ManagerModel manager;
  final ManagerLeaveRequest? existing;

  @override
  State<_LeaveFormScreen> createState() => _LeaveFormScreenState();
}

class _LeaveFormScreenState extends State<_LeaveFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final ManagerLeaveRepository _repository = ManagerLeaveRepository.instance;
  final List<String> _types = const ['Casual Leave', 'Sick Leave', 'Emergency'];
  late String _selectedType;
  late DateTime _fromDate;
  late DateTime _toDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _selectedType = existing?.leaveType ?? _types.first;
    _fromDate = existing?.fromDate ?? DateTime.now();
    _toDate = existing?.toDate ?? DateTime.now();
    _reasonController.text = existing?.reason ?? '';
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFromDate}) async {
    final initialDate = isFromDate ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      if (isFromDate) {
        _fromDate = picked;
        if (_toDate.isBefore(_fromDate)) {
          _toDate = _fromDate;
        }
      } else {
        _toDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_toDate.isBefore(_fromDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            'To date must be on or after from date.',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    final existing = widget.existing;
    final request = ManagerLeaveRequest(
      id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      managerId: widget.manager.id,
      managerName: widget.manager.name,
      leaveType: _selectedType,
      fromDate: _fromDate,
      toDate: _toDate,
      reason: _reasonController.text.trim(),
      status: existing?.status ?? 'Pending',
      createdAt: existing?.createdAt,
      updatedAt: DateTime.now(),
    );
    await _repository.saveLeave(request);
    if (!mounted) {
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
          widget.existing == null ? 'Apply Leave' : 'Edit Leave',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const ManagerFormLabel('Leave Type'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(hintText: 'Choose leave type'),
              items: _types
                  .map(
                    (type) => DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedType = value;
                });
              },
            ),
            const SizedBox(height: 12),
            const ManagerFormLabel('From Date'),
            const SizedBox(height: 8),
            _DateField(
              value: formatDateLabel(_fromDate),
              onTap: () => _pickDate(isFromDate: true),
            ),
            const SizedBox(height: 12),
            const ManagerFormLabel('To Date'),
            const SizedBox(height: 8),
            _DateField(
              value: formatDateLabel(_toDate),
              onTap: () => _pickDate(isFromDate: false),
            ),
            const SizedBox(height: 12),
            const ManagerFormLabel('Reason'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Briefly describe the reason for leave',
              ),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Reason is required'
                  : null,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(_isSaving ? 'Saving...' : 'Save Leave Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: const InputDecoration(),
        child: Row(
          children: [
            Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
            const Icon(Icons.calendar_today_outlined, size: 18),
          ],
        ),
      ),
    );
  }
}
