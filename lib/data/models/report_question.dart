class ReportQuestion {
  const ReportQuestion({required this.question, required this.description});

  final String question;
  final String description;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'question': question, 'description': description};
  }

  factory ReportQuestion.fromMap(Map<String, dynamic> map) {
    return ReportQuestion(
      question: (map['question'] as String? ?? '').trim(),
      description: (map['description'] as String? ?? '').trim(),
    );
  }
}
