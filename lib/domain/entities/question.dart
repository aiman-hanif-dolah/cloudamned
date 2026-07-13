import 'package:equatable/equatable.dart';

enum QuestionType {
  multipleChoice,
  trueFalse,
  fillBlank,
  multiSelect,
  terminal,
  scenario,
  architecture,
  logAnalysis,
}

class Question extends Equatable {
  const Question({
    required this.id,
    required this.type,
    required this.domain,
    required this.difficulty,
    required this.prompt,
    required this.correctAnswers,
    this.choices = const [],
    this.explanation = '',
    this.tags = const [],
    this.certification,
  });

  final String id;
  final QuestionType type;
  final String domain;
  final String difficulty;
  final String prompt;
  final List<String> choices;
  final List<String> correctAnswers;
  final String explanation;
  final List<String> tags;
  final String? certification;

  bool grade(List<String> answers) {
    final normalized = answers.map((a) => a.trim().toLowerCase()).toSet();
    final expected = correctAnswers.map((a) => a.trim().toLowerCase()).toSet();
    return normalized.length == expected.length && normalized.containsAll(expected);
  }

  @override
  List<Object?> get props => [id];
}

class ExamDefinition extends Equatable {
  const ExamDefinition({
    required this.id,
    required this.title,
    required this.certification,
    required this.durationMinutes,
    required this.passingScore,
    required this.questionCount,
    required this.domains,
    required this.description,
  });

  final String id;
  final String title;
  final String certification;
  final int durationMinutes;
  final int passingScore;
  final int questionCount;
  final List<String> domains;
  final String description;

  @override
  List<Object?> get props => [id];
}
