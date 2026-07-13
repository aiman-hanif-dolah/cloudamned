import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../data/content/roadmap_content.dart';
import '../../domain/entities/progress.dart';

class ProgressCubit extends Cubit<UserProgress> {
  ProgressCubit(this._box) : super(UserProgress.fromJson(
          Map<String, dynamic>.from(_box.get('user', defaultValue: <String, dynamic>{}) as Map? ?? {}),
        ));

  final Box _box;

  Future<void> _persist() async {
    await _box.put('user', state.toJson());
  }

  Future<void> addXp(int amount) async {
    var xp = state.xp + amount;
    var level = state.level;
    while (xp >= level * 1000) {
      xp -= level * 1000;
      level++;
    }
    emit(state.copyWith(xp: xp, level: level));
    await _persist();
  }

  Future<void> completeLab(String labId, {int score = 100}) async {
    if (state.completedLabs.contains(labId)) return;
    final lab = RoadmapContent.labById(labId);
    final completed = {...state.completedLabs, labId};
    final scores = {...state.labScores, labId: score};
    final moduleProgress = Map<String, double>.from(state.moduleProgress);

    if (lab != null) {
      final mod = RoadmapContent.moduleById(lab.moduleId);
      if (mod != null) {
        final done = mod.labs.where((l) => completed.contains(l.id)).length;
        moduleProgress[mod.id] = done / mod.labs.length;
      }
    }

    final badges = List<String>.from(state.badges);
    _maybeAwardBadges(completed, badges);

    emit(state.copyWith(
      completedLabs: completed,
      labScores: scores,
      moduleProgress: moduleProgress,
      readiness: _computeReadiness(completed),
      badges: badges,
    ));
    await addXp(lab?.xpReward ?? AppConstants.xpPerLab);
    await _persist();
  }

  Future<void> recordAnswer({required bool correct}) async {
    emit(state.copyWith(
      correctAnswers: state.correctAnswers + (correct ? 1 : 0),
      totalAnswers: state.totalAnswers + 1,
    ));
    await _persist();
  }

  Future<void> addTime(int minutes) async {
    emit(state.copyWith(timeSpentMinutes: state.timeSpentMinutes + minutes));
    await _persist();
  }

  Future<void> touchStreak() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (state.lastActiveDate == today) return;
    final yesterday = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
    final streak = state.lastActiveDate == yesterday ? state.streakDays + 1 : 1;
    emit(state.copyWith(streakDays: streak, lastActiveDate: today));
    await _persist();
  }

  void _maybeAwardBadges(Set<String> completed, List<String> badges) {
    void award(String id) {
      if (!badges.contains(id)) badges.add(id);
    }

    if (completed.length >= 1) award('first-lab');
    if (completed.length >= 10) award('lab-10');
    if (completed.length >= 50) award('lab-50');
    if (completed.any((id) => id.startsWith('lab-02'))) award('linux-starter');
    if (completed.any((id) => id.startsWith('lab-05'))) award('aws-starter');
    if (completed.contains('lab-20-02')) award('capstone');
    if (state.level >= 5) award('level-5');
  }

  ReadinessScores _computeReadiness(Set<String> completed) {
    double domain(String prefix) {
      final labs = RoadmapContent.allLabs.where((l) => l.id.startsWith(prefix)).toList();
      if (labs.isEmpty) return 0;
      final done = labs.where((l) => completed.contains(l.id)).length;
      return (done / labs.length * 100).clamp(0, 100);
    }

    final aws = domain('lab-05');
    final azure = domain('lab-06');
    final gcp = domain('lab-07');
    final linux = domain('lab-02');
    final networking = domain('lab-04');
    final terraform = domain('lab-10');
    final docker = domain('lab-08');
    final k8s = domain('lab-09');
    final security = domain('lab-13');
    final interview = domain('lab-18');
    final scores = [aws, azure, gcp, linux, networking, terraform, docker, k8s, security, interview];
    final overall = scores.reduce((a, b) => a + b) / scores.length;

    return ReadinessScores(
      overall: overall,
      aws: aws,
      azure: azure,
      gcp: gcp,
      linux: linux,
      networking: networking,
      terraform: terraform,
      docker: docker,
      kubernetes: k8s,
      security: security,
      interview: interview,
    );
  }
}
