import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/attendance_record.dart';

class AttendanceTable extends StatelessWidget {
  const AttendanceTable({
    super.key,
    required this.records,
  });

  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.7),
            3: FlexColumnWidth(1.5),
            4: FlexColumnWidth(1.6),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            _buildHeaderRow(),
            ...List.generate(
              records.length,
              (index) => _buildDataRow(records[index], index),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    const labels = ['Name', 'Status', 'Date', 'Check-In', 'Check-Out'];

    return TableRow(
      decoration: const BoxDecoration(color: AppColors.primary50),
      children: labels
          .map(
            (label) => _buildCell(
              label,
              isHeader: true,
            ),
          )
          .toList(growable: false),
    );
  }

  TableRow _buildDataRow(AttendanceRecord record, int index) {
    final rowColor = index.isEven ? Colors.white : AppColors.neutral50;

    return TableRow(
      decoration: BoxDecoration(
        color: rowColor,
        border: const Border(
          bottom: BorderSide(
            color: AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      children: [
        _buildCell(record.name),
        _buildStatusCell(record.status),
        _buildCell(record.date),
        _buildCell(record.checkIn),
        _buildCell(record.checkOut),
      ],
    );
  }

  Widget _buildCell(
    String value, {
    bool isHeader = false,
  }) {
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
    final isPresent = status == 'Present';
    final statusColor = isPresent ? AppColors.successDark : AppColors.errorDark;
    final backgroundColor =
        isPresent ? AppColors.successLight : AppColors.errorLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: backgroundColor,
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
}
