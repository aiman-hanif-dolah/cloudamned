import 'package:equatable/equatable.dart';

class UserProgress extends Equatable {
  const UserProgress({
    this.xp = 0,
    this.level = 1,
    this.completedLabs = const {},
    this.labScores = const {},
    this.moduleProgress = const {},
    this.timeSpentMinutes = 0,
    this.correctAnswers = 0,
    this.totalAnswers = 0,
    this.badges = const [],
    this.streakDays = 0,
    this.lastActiveDate,
    this.readiness = const ReadinessScores(),
    this.dailyChallengeId,
    this.dailyChallengeDone = false,
  });

  final int xp;
  final int level;
  final Set<String> completedLabs;
  final Map<String, int> labScores;
  final Map<String, double> moduleProgress;
  final int timeSpentMinutes;
  final int correctAnswers;
  final int totalAnswers;
  final List<String> badges;
  final int streakDays;
  final String? lastActiveDate;
  final ReadinessScores readiness;
  final String? dailyChallengeId;
  final bool dailyChallengeDone;

  double get accuracy => totalAnswers == 0 ? 0 : correctAnswers / totalAnswers;
  int get xpToNextLevel => level * 1000;
  double get levelProgress => xpToNextLevel == 0 ? 0 : (xp % xpToNextLevel) / xpToNextLevel;

  UserProgress copyWith({
    int? xp,
    int? level,
    Set<String>? completedLabs,
    Map<String, int>? labScores,
    Map<String, double>? moduleProgress,
    int? timeSpentMinutes,
    int? correctAnswers,
    int? totalAnswers,
    List<String>? badges,
    int? streakDays,
    String? lastActiveDate,
    ReadinessScores? readiness,
    String? dailyChallengeId,
    bool? dailyChallengeDone,
  }) {
    return UserProgress(
      xp: xp ?? this.xp,
      level: level ?? this.level,
      completedLabs: completedLabs ?? this.completedLabs,
      labScores: labScores ?? this.labScores,
      moduleProgress: moduleProgress ?? this.moduleProgress,
      timeSpentMinutes: timeSpentMinutes ?? this.timeSpentMinutes,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      totalAnswers: totalAnswers ?? this.totalAnswers,
      badges: badges ?? this.badges,
      streakDays: streakDays ?? this.streakDays,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      readiness: readiness ?? this.readiness,
      dailyChallengeId: dailyChallengeId ?? this.dailyChallengeId,
      dailyChallengeDone: dailyChallengeDone ?? this.dailyChallengeDone,
    );
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'level': level,
        'completedLabs': completedLabs.toList(),
        'labScores': labScores,
        'moduleProgress': moduleProgress,
        'timeSpentMinutes': timeSpentMinutes,
        'correctAnswers': correctAnswers,
        'totalAnswers': totalAnswers,
        'badges': badges,
        'streakDays': streakDays,
        'lastActiveDate': lastActiveDate,
        'readiness': readiness.toJson(),
        'dailyChallengeId': dailyChallengeId,
        'dailyChallengeDone': dailyChallengeDone,
      };

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      xp: json['xp'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      completedLabs: Set<String>.from(json['completedLabs'] as List? ?? []),
      labScores: Map<String, int>.from(json['labScores'] as Map? ?? {}),
      moduleProgress: Map<String, double>.from(
        (json['moduleProgress'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()),
        ),
      ),
      timeSpentMinutes: json['timeSpentMinutes'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      totalAnswers: json['totalAnswers'] as int? ?? 0,
      badges: List<String>.from(json['badges'] as List? ?? []),
      streakDays: json['streakDays'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] as String?,
      readiness: ReadinessScores.fromJson(
        Map<String, dynamic>.from(json['readiness'] as Map? ?? {}),
      ),
      dailyChallengeId: json['dailyChallengeId'] as String?,
      dailyChallengeDone: json['dailyChallengeDone'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [xp, level, completedLabs, timeSpentMinutes];
}

class ReadinessScores extends Equatable {
  const ReadinessScores({
    this.overall = 0,
    this.aws = 0,
    this.azure = 0,
    this.gcp = 0,
    this.linux = 0,
    this.networking = 0,
    this.terraform = 0,
    this.docker = 0,
    this.kubernetes = 0,
    this.security = 0,
    this.interview = 0,
  });

  final double overall;
  final double aws;
  final double azure;
  final double gcp;
  final double linux;
  final double networking;
  final double terraform;
  final double docker;
  final double kubernetes;
  final double security;
  final double interview;

  Map<String, dynamic> toJson() => {
        'overall': overall,
        'aws': aws,
        'azure': azure,
        'gcp': gcp,
        'linux': linux,
        'networking': networking,
        'terraform': terraform,
        'docker': docker,
        'kubernetes': kubernetes,
        'security': security,
        'interview': interview,
      };

  factory ReadinessScores.fromJson(Map<String, dynamic> json) => ReadinessScores(
        overall: (json['overall'] as num?)?.toDouble() ?? 0,
        aws: (json['aws'] as num?)?.toDouble() ?? 0,
        azure: (json['azure'] as num?)?.toDouble() ?? 0,
        gcp: (json['gcp'] as num?)?.toDouble() ?? 0,
        linux: (json['linux'] as num?)?.toDouble() ?? 0,
        networking: (json['networking'] as num?)?.toDouble() ?? 0,
        terraform: (json['terraform'] as num?)?.toDouble() ?? 0,
        docker: (json['docker'] as num?)?.toDouble() ?? 0,
        kubernetes: (json['kubernetes'] as num?)?.toDouble() ?? 0,
        security: (json['security'] as num?)?.toDouble() ?? 0,
        interview: (json['interview'] as num?)?.toDouble() ?? 0,
      );

  ReadinessScores copyWith({
    double? overall,
    double? aws,
    double? azure,
    double? gcp,
    double? linux,
    double? networking,
    double? terraform,
    double? docker,
    double? kubernetes,
    double? security,
    double? interview,
  }) {
    return ReadinessScores(
      overall: overall ?? this.overall,
      aws: aws ?? this.aws,
      azure: azure ?? this.azure,
      gcp: gcp ?? this.gcp,
      linux: linux ?? this.linux,
      networking: networking ?? this.networking,
      terraform: terraform ?? this.terraform,
      docker: docker ?? this.docker,
      kubernetes: kubernetes ?? this.kubernetes,
      security: security ?? this.security,
      interview: interview ?? this.interview,
    );
  }

  @override
  List<Object?> get props => [overall, aws, azure, gcp, linux, networking, terraform];
}
