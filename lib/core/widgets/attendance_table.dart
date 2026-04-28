import 'package:flutter/material.dart';

import 'package:guardgrey/core/theme/app_colors.dart';
import 'package:guardgrey/core/theme/app_text_styles.dart';
import 'package:guardgrey/data/models/attendance_record.dart';

class AttendanceTable extends StatelessWidget {
  const AttendanceTable({super.key, required this.records, this.onManagerTap});

  final List<AttendanceRecord> records;
  final ValueChanged<AttendanceRecord>? onManagerTap;

  @override
  Widget build(BuildContext context) {
    final minWidth = MediaQuery.of(context).size.width + 280;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.neutral200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: minWidth),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2.7),
                1: FlexColumnWidth(1.45),
                2: FlexColumnWidth(1.8),
                3: FlexColumnWidth(1.65),
                4: FlexColumnWidth(1.7),
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
        ),
      ),
    );
  }

  TableRow _buildHeaderRow() {
    const labels = ['Name', 'Status', 'Date', 'Check-In', 'Check-Out'];

    return TableRow(
      decoration: const BoxDecoration(color: AppColors.primary50),
      children: labels
          .map((label) => _buildCell(label, isHeader: true))
          .toList(growable: false),
    );
  }

  TableRow _buildDataRow(AttendanceRecord record, int index) {
    final rowColor = index.isEven ? Colors.white : AppColors.neutral50;

    return TableRow(
      decoration: BoxDecoration(
        color: rowColor,
        border: const Border(
          bottom: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      children: [
        _buildManagerCell(record),
        _buildStatusCell(record.status),
        _buildCell(record.date),
        _buildCell(record.checkIn),
        _buildCell(record.checkOut),
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
        softWrap: false,
        overflow: TextOverflow.visible,
        style: style,
      ),
    );
  }

  Widget _buildManagerCell(AttendanceRecord record) {
    final content = Text(
      record.name,
      style: AppTextStyles.bodyMedium.copyWith(
        color: onManagerTap == null
            ? AppColors.neutral800
            : AppColors.primary700,
        fontWeight: FontWeight.w700,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: onManagerTap == null
          ? content
          : InkWell(
              onTap: () => onManagerTap!(record),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: content,
              ),
            ),
    );
  }

  Widget _buildStatusCell(String status) {
    final isPresent = status == 'Present';
    final statusColor = isPresent ? AppColors.successDark : AppColors.errorDark;
    final backgroundColor = isPresent
        ? AppColors.successLight
        : AppColors.errorLight;

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
