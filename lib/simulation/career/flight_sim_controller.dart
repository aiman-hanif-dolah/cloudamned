import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/career_project.dart';
import '../failure/failure_engine.dart';
import '../forensics/forensics_engine.dart';
import '../interview/interview_replay.dart';
import '../well_architected/wa_scorer.dart';
import 'capstone_engine.dart';
import 'career_rank.dart';
import 'decision_engine.dart';
import 'discovery_engine.dart';
import 'engineering_journal.dart';
import 'mentor_engine.dart';
import 'multi_cloud_engine.dart';
import 'project_generator.dart';
import 'reputation_engine.dart';

/// Orchestrates cloudamned Cloud Engineering Flight Simulator state.
class FlightSimController {
  final progression = CareerProgression();
  final reputation = ReputationEngine();
  final generator = ProjectGenerator();
  final discovery = DiscoveryEngine();
  final mentor = MentorEngine();
  final journal = EngineeringJournal();
  final decisions = DecisionEngine();
  final multiCloud = MultiCloudEngine();
  final failures = FailureEngine();
  final forensics = ForensicsEngine()..seedHealthy();
  final wa = WellArchitectedScorer();
  final replay = InterviewReplayStore();
  final capstone = CapstoneEngine();

  CareerProject? activeGenerated;
  String? lastPromotion;

  void load(Box box) {
    final raw = box.get('flight_sim');
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final prog = map['progression'];
      if (prog is Map) {
        final p = CareerProgression.fromJson(Map<String, dynamic>.from(prog));
        progression.rank = p.rank;
        progression.careerXp = p.careerXp;
        progression.projectsCompleted = p.projectsCompleted;
      }
      final rep = map['reputation'];
      if (rep is Map) {
        reputation.loadJson(Map<String, dynamic>.from(rep));
      }
    }
  }

  Future<void> save(Box box) async {
    await box.put('flight_sim', {
      'progression': progression.toJson(),
      'reputation': reputation.toJson(),
    });
  }

  CareerProject generateProject() {
    activeGenerated = generator.generate();
    return activeGenerated!;
  }

  void beginDiscovery([CareerProject? p]) {
    final project = p ?? activeGenerated ?? generateProject();
    activeGenerated = project;
    discovery.start(project);
  }

  SimulatedFailure injectFailure() {
    final f = failures.inject();
    forensics.seedFromFailure(f);
    return f;
  }

  bool awardCareerXp(int xp) {
    final promoted = progression.addXp(xp);
    if (promoted) {
      lastPromotion = progression.rank.title;
    }
    return promoted;
  }

  void completeEngagement({
    required String customer,
    required String projectId,
    required int score,
    required List<String> decisionsMade,
    required List<String> lessons,
  }) {
    progression.projectsCompleted++;
    awardCareerXp(score * 3);
    reputation.applyProjectOutcome(
      architectureScore: score,
      securityScore: score,
      costScore: (score * 0.9).round(),
      docsScore: score,
      commsScore: score,
      incidentHandled: true,
      customerSat: score.toDouble(),
    );
    journal.autoFromProject(
      projectId: projectId,
      customerName: customer,
      score: score,
      decisions: decisionsMade,
      lessons: lessons,
    );
  }
}
