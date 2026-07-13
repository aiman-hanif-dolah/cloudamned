import 'package:equatable/equatable.dart';

enum LabDifficulty { beginner, intermediate, advanced, expert }

enum LabType {
  theory,
  terminal,
  console,
  architecture,
  troubleshooting,
  scenario,
  exam,
  interview,
}

enum LabStatus { locked, available, inProgress, completed }

class LabObjective extends Equatable {
  const LabObjective({
    required this.id,
    required this.description,
    this.completed = false,
    this.validationKey,
  });

  final String id;
  final String description;
  final bool completed;
  final String? validationKey;

  LabObjective copyWith({bool? completed}) => LabObjective(
        id: id,
        description: description,
        completed: completed ?? this.completed,
        validationKey: validationKey,
      );

  @override
  List<Object?> get props => [id, description, completed, validationKey];
}

class Lab extends Equatable {
  const Lab({
    required this.id,
    required this.moduleId,
    required this.order,
    required this.title,
    required this.summary,
    required this.background,
    required this.objectives,
    required this.requirements,
    required this.difficulty,
    required this.type,
    required this.xpReward,
    required this.estimatedMinutes,
    required this.tags,
    this.hints = const [],
    this.prerequisites = const [],
    this.simulator = 'none',
    this.initialState = const {},
    this.validationRules = const [],
  });

  final String id;
  final String moduleId;
  final int order;
  final String title;
  final String summary;
  final String background;
  final List<LabObjective> objectives;
  final List<String> requirements;
  final LabDifficulty difficulty;
  final LabType type;
  final int xpReward;
  final int estimatedMinutes;
  final List<String> tags;
  final List<String> hints;
  final List<String> prerequisites;
  final String simulator;
  final Map<String, dynamic> initialState;
  final List<String> validationRules;

  @override
  List<Object?> get props => [id, moduleId, order, title];
}

class LearningModule extends Equatable {
  const LearningModule({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.colorKey,
    required this.labs,
    required this.skills,
  });

  final String id;
  final int order;
  final String title;
  final String subtitle;
  final String description;
  final String icon;
  final String colorKey;
  final List<Lab> labs;
  final List<String> skills;

  int get labCount => labs.length;
  int get totalXp => labs.fold(0, (s, l) => s + l.xpReward);

  @override
  List<Object?> get props => [id, order, title];
}
