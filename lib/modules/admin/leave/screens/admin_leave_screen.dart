import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/core/utils/date_time_display.dart';
import 'package:guardgrey/modules/manager/common/widgets/manager_ui.dart';
import 'package:guardgrey/modules/manager/leave/models/manager_leave_request.dart';
import 'package:guardgrey/modules/manager/leave/repositories/manager_leave_repository.dart';

class AdminLeaveScreen extends StatefulWidget {
  const AdminLeaveScreen({super.key});

  @override
  State<AdminLeaveScreen> createState() => _AdminLeaveScreenState();
}

class _AdminLeaveScreenState extends State<AdminLeaveScreen> {
  final ManagerLeaveRepository _repository = ManagerLeaveRepository.instance;
  String _statusFilter = 'All';

  Future<void> _updateStatus(ManagerLeaveRequest leave, String status) async {
    await _repository.updateLeaveStatus(leave.id, status);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: status == 'Approved'
            ? AppColors.success
            : AppColors.error,
        content: Text(
          '${leave.managerName.isEmpty ? 'Leave' : leave.managerName} marked as $status.',
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
        ),
      ),
    );
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
          'Manager Leave',
          style: AppTextStyles.title.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: StreamBuilder<List<ManagerLeaveRequest>>(
        stream: _repository.watchAllLeaves(),
        builder: (context, snapshot) {
          final leaves = snapshot.data ?? const <ManagerLeaveRequest>[];
          if (snapshot.connectionState == ConnectionState.waiting &&
              leaves.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredLeaves = _statusFilter == 'All'
              ? leaves
              : leaves
                    .where(
                      (leave) =>
                          leave.status.trim().toLowerCase() ==
                          _statusFilter.toLowerCase(),
                    )
                    .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _LeaveSummary(leaves: leaves),
              const SizedBox(height: 18),
              Text(
                'Status',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.neutral800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['All', 'Pending', 'Approved', 'Rejected']
                      .map(
                        (status) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(status),
                            selected: _statusFilter == status,
                            onSelected: (_) {
                              setState(() {
                                _statusFilter = status;
                              });
                            },
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 18),
              if (filteredLeaves.isEmpty)
                const ManagerEmptyState(
                  title: 'No leave requests found',
                  message:
                      'Manager leave requests will appear here when requests are submitted.',
                )
              else
                ...filteredLeaves.map(
                  (leave) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AdminLeaveCard(
                      leave: leave,
                      onApprove: leave.canManage
                          ? () => _updateStatus(leave, 'Approved')
                          : null,
                      onReject: leave.canManage
                          ? () => _updateStatus(leave, 'Rejected')
                          : null,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LeaveSummary extends StatelessWidget {
  const _LeaveSummary({required this.leaves});

  final List<ManagerLeaveRequest> leaves;

  @override
  Widget build(BuildContext context) {
    int countWhere(String status) => leaves
        .where((leave) => leave.status.trim().toLowerCase() == status)
        .length;

    final metrics = <_SummaryMetric>[
      _SummaryMetric(
        label: 'Total',
        value: leaves.length.toString(),
        color: AppColors.primary600,
        background: AppColors.primary50,
      ),
      _SummaryMetric(
        label: 'Pending',
        value: countWhere('pending').toString(),
        color: AppColors.warningDark,
        background: AppColors.warningLight,
      ),
      _SummaryMetric(
        label: 'Approved',
        value: countWhere('approved').toString(),
        color: AppColors.successDark,
        background: AppColors.successLight,
      ),
      _SummaryMetric(
        label: 'Rejected',
        value: countWhere('rejected').toString(),
        color: AppColors.errorDark,
        background: AppColors.errorLight,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: metrics
          .map(
            (metric) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 52) / 2,
              child: ManagerSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: metric.background,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        metric.label,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: metric.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      metric.value,
                      style: AppTextStyles.headingSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _AdminLeaveCard extends StatelessWidget {
  const _AdminLeaveCard({required this.leave, this.onApprove, this.onReject});

  final ManagerLeaveRequest leave;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    return ManagerSurfaceCard(
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.managerName.isEmpty
                          ? 'Manager Leave Request'
                          : leave.managerName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      leave.leaveType,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.neutral700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatDateLabel(leave.fromDate)} - ${formatDateLabel(leave.toDate)}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.neutral500,
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
          if (leave.reason.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
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
          ],
          if (leave.canManage) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorDark,
                      side: const BorderSide(color: AppColors.errorLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Approve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

class _SummaryMetric {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;
}
