import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';

import '../../features/progress/progress_cubit.dart';
import '../../simulation/aws/aws_engine.dart';
import '../../simulation/career/career_sim_engine.dart';
import '../../simulation/career/flight_sim_controller.dart';
import '../../simulation/cost/cost_engine.dart';
import '../../simulation/daily/daily_engineer_engine.dart';
import '../../simulation/docs/documentation_engine.dart';
import '../../simulation/docker/docker_engine.dart';
import '../../simulation/k8s/k8s_engine.dart';
import '../../simulation/landing_zone/landing_zone_engine.dart';
import '../../simulation/linux/linux_shell.dart';
import '../../simulation/networking/network_engine.dart';
import '../../simulation/review/architecture_review_engine.dart';
import '../../simulation/security/security_audit_engine.dart';
import '../../simulation/terraform/terraform_engine.dart';
import '../../simulation/ops/ops_center_engine.dart';
import '../../simulation/tickets/ticket_engine.dart';
import '../constants/app_constants.dart';
import 'db_bootstrap.dart';

/// Simple service locator — no Riverpod required.
class AppServices {
  AppServices._();
  static final instance = AppServices._();

  late final Box progressBox;
  late final Box settingsBox;
  late final ProgressCubit progressCubit;
  late final AppDatabase db;

  final linuxShell = LinuxShell();
  /// Blank AWS account for full console clone (manual VPC build).
  final awsEngine = AwsEngine(seedDefaults: false);
  final dockerEngine = DockerEngine();
  final k8sEngine = K8sEngine();
  late final TerraformEngine terraformEngine;
  final networkEngine = NetworkEngine()..seedDefault();

  // Career simulation stack (cloudamned)
  final careerSim = CareerSimEngine();
  final tickets = TicketEngine();
  final landingZone = LandingZoneEngine();
  final dailyEngineer = DailyEngineerEngine();
  final archReview = ArchitectureReviewEngine();
  final costEngine = CostEngine();
  final securityAudit = SecurityAuditEngine();
  final docs = DocumentationEngine();
  final flight = FlightSimController();
  /// Additive: Cloud Operations Center (does not replace TicketEngine / Incident Lab).
  final opsCenter = OpsCenterEngine();

  Future<void> init() async {
    await Hive.initFlutter();
    progressBox = await Hive.openBox(AppConstants.hiveBoxProgress);
    settingsBox = await Hive.openBox(AppConstants.hiveBoxSettings);
    flight.load(progressBox);

    db = await openAppDatabase();

    progressCubit = ProgressCubit(progressBox);
    await progressCubit.touchStreak();
    terraformEngine = TerraformEngine(aws: awsEngine);
    await flight.save(progressBox);

    if (kIsWeb) {
      // Web: ensure we mark platform once for telemetry-style local flags
      await settingsBox.put('platform', 'web');
    }
  }

  Future<void> logActivity(String kind, String message) async {
    await db.logActivity(kind, message);
  }

  Future<void> recordLabAttempt(String labId, int score, int durationSec) async {
    await db.recordLabAttempt(labId, score, durationSec);
  }
}
