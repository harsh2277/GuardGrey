import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/visit_model.dart';

class VisitTable extends StatelessWidget {
  final List<VisitModel> visits;

  const VisitTable({super.key, required this.visits});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.3),
              1: FlexColumnWidth(1.7),
              2: FlexColumnWidth(1.6),
              3: FlexColumnWidth(1.8),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _buildHeaderRow(),
              ...List.generate(
                visits.length,
                (index) => _buildVisitRow(visits[index], index),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    const labels = ['Date', 'Day', 'Time', 'Status'];

    return TableRow(
      decoration: const BoxDecoration(color: AppColors.primary50),
      children: labels
          .map((label) => _buildCell(label, isHeader: true))
          .toList(growable: false),
    );
  }

  TableRow _buildVisitRow(VisitModel visit, int index) {
    final rowColor = index.isEven ? Colors.white : AppColors.neutral50;

    return TableRow(
      decoration: BoxDecoration(
        color: rowColor,
        border: const Border(
          bottom: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      children: [
        _buildCell(visit.date),
        _buildCell(visit.day),
        _buildCell(visit.time),
        _buildStatusCell(visit.status),
      ],
    );
  }

  Widget _buildCell(String value, {bool isHeader = false}) {
    final style = isHeader
        ? AppTextStyles.bodySmall.copyWith(
            color: AppColors.primary700,
            fontWeight: FontWeight.w700,
          )
        : AppTextStyles.bodyMedium.copyWith(
            color: AppColors.neutral800,
            fontWeight: FontWeight.w600,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    final statusColor = _statusColor(status);
    final statusBackground = statusColor.withOpacity(0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: statusBackground,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return AppColors.success;
      case 'In Progress':
        return AppColors.primary600;
      default:
        return AppColors.warningDark;
    }
  }
}
