String formatDateTimeLabel(DateTime dateTime) {
  final date = _formatDate(dateTime);
  final time = _formatTime(dateTime);
  return '$date • $time';
}

String formatDateLabel(DateTime dateTime) => _formatDate(dateTime);

String formatTimeLabel(DateTime dateTime) => _formatTime(dateTime);

String _formatDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day.toString().padLeft(2, '0')} '
      '${months[date.month - 1]} ${date.year}';
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour == 0
      ? 12
      : dateTime.hour > 12
      ? dateTime.hour - 12
      : dateTime.hour;
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '${hour.toString().padLeft(2, '0')}:'
      '${dateTime.minute.toString().padLeft(2, '0')} $period';
}
