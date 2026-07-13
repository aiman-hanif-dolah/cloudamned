import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/achievements/achievements_page.dart';
import '../../features/arch_review/arch_review_page.dart';
import '../../features/architecture/architecture_page.dart';
import '../../features/capstone/capstone_page.dart';
import '../../features/career/career_page.dart';
import '../../features/career_sim/career_simulation_page.dart';
import '../../features/cicd/cicd_page.dart';
import '../../features/console/console_page.dart';
import '../../features/cost/cost_lab_page.dart';
import '../../features/daily/daily_engineer_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/decisions/decisions_page.dart';
import '../../features/discovery/discovery_page.dart';
import '../../features/docs/documentation_page.dart';
import '../../features/docker/docker_page.dart';
import '../../features/exam/exam_page.dart';
import '../../features/flight_deck/flight_deck_page.dart';
import '../../features/forensics/forensics_page.dart';
import '../../features/interview/interview_page.dart';
import '../../features/journal/journal_page.dart';
import '../../features/knowledge/knowledge_page.dart';
import '../../features/kubernetes/kubernetes_page.dart';
import '../../features/labs/lab_detail_page.dart';
import '../../features/labs/labs_page.dart';
import '../../features/landing_zone/landing_zone_page.dart';
import '../../features/meetings/meetings_page.dart';
import '../../features/mentor/mentor_page.dart';
import '../../features/migration/migration_lab_page.dart';
import '../../features/monitoring/monitoring_page.dart';
import '../../features/multi_cloud/multi_cloud_page.dart';
import '../../features/networking/networking_page.dart';
import '../../features/roadmap/roadmap_page.dart';
import '../../features/scenario/scenario_page.dart';
import '../../features/security_audit/security_audit_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/skills/skills_page.dart';
import '../../features/statistics/statistics_page.dart';
import '../../features/terminal/terminal_page.dart';
import '../../features/terraform/terraform_page.dart';
import '../../features/tickets/tickets_page.dart';
import '../../features/well_architected/wa_page.dart';
import '../../features/whiteboard/whiteboard_page.dart';
import '../../features/windows_server/windows_server_page.dart';
import '../constants/app_routes.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

GoRouter createRouter() {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: AppRoutes.dashboard,
    routes: [
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (c, s) => const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: AppRoutes.flightDeck,
            pageBuilder: (c, s) => const NoTransitionPage(child: FlightDeckPage()),
          ),
          GoRoute(
            path: AppRoutes.discovery,
            pageBuilder: (c, s) => const NoTransitionPage(child: DiscoveryPage()),
          ),
          GoRoute(
            path: AppRoutes.decisions,
            pageBuilder: (c, s) => const NoTransitionPage(child: DecisionsPage()),
          ),
          GoRoute(
            path: AppRoutes.multiCloud,
            pageBuilder: (c, s) => const NoTransitionPage(child: MultiCloudPage()),
          ),
          GoRoute(
            path: AppRoutes.forensics,
            pageBuilder: (c, s) => const NoTransitionPage(child: ForensicsPage()),
          ),
          GoRoute(
            path: AppRoutes.mentor,
            pageBuilder: (c, s) => const NoTransitionPage(child: MentorPage()),
          ),
          GoRoute(
            path: AppRoutes.whiteboard,
            pageBuilder: (c, s) => const NoTransitionPage(child: WhiteboardPage()),
          ),
          GoRoute(
            path: AppRoutes.journal,
            pageBuilder: (c, s) => const NoTransitionPage(child: JournalPage()),
          ),
          GoRoute(
            path: AppRoutes.capstone,
            pageBuilder: (c, s) => const NoTransitionPage(child: CapstonePage()),
          ),
          GoRoute(
            path: AppRoutes.wellArchitected,
            pageBuilder: (c, s) => const NoTransitionPage(child: WellArchitectedPage()),
          ),
          GoRoute(
            path: AppRoutes.careerSim,
            pageBuilder: (c, s) => const NoTransitionPage(child: CareerSimulationPage()),
          ),
          GoRoute(
            path: AppRoutes.roadmap,
            pageBuilder: (c, s) => const NoTransitionPage(child: RoadmapPage()),
          ),
          GoRoute(
            path: AppRoutes.labs,
            pageBuilder: (c, s) => const NoTransitionPage(child: LabsPage()),
            routes: [
              GoRoute(
                path: ':labId',
                pageBuilder: (c, s) => NoTransitionPage(
                  child: LabDetailPage(labId: s.pathParameters['labId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.career,
            pageBuilder: (c, s) => const NoTransitionPage(child: CareerPage()),
          ),
          GoRoute(
            path: AppRoutes.landingZone,
            pageBuilder: (c, s) => const NoTransitionPage(child: LandingZonePage()),
          ),
          GoRoute(
            path: AppRoutes.migration,
            pageBuilder: (c, s) => const NoTransitionPage(child: MigrationLabPage()),
          ),
          GoRoute(
            path: AppRoutes.tickets,
            pageBuilder: (c, s) => const NoTransitionPage(child: TicketsPage()),
          ),
          GoRoute(
            path: AppRoutes.daily,
            pageBuilder: (c, s) => const NoTransitionPage(child: DailyEngineerPage()),
          ),
          GoRoute(
            path: AppRoutes.archReview,
            pageBuilder: (c, s) => const NoTransitionPage(child: ArchReviewPage()),
          ),
          GoRoute(
            path: AppRoutes.costLab,
            pageBuilder: (c, s) => const NoTransitionPage(child: CostLabPage()),
          ),
          GoRoute(
            path: AppRoutes.securityAudit,
            pageBuilder: (c, s) => const NoTransitionPage(child: SecurityAuditPage()),
          ),
          GoRoute(
            path: AppRoutes.documentation,
            pageBuilder: (c, s) => const NoTransitionPage(child: DocumentationPage()),
          ),
          GoRoute(
            path: AppRoutes.meetings,
            pageBuilder: (c, s) => const NoTransitionPage(child: MeetingsPage()),
          ),
          GoRoute(
            path: AppRoutes.skills,
            pageBuilder: (c, s) => const NoTransitionPage(child: SkillsPage()),
          ),
          GoRoute(
            path: AppRoutes.console,
            pageBuilder: (c, s) => const NoTransitionPage(child: ConsolePage()),
          ),
          GoRoute(
            path: AppRoutes.terminal,
            pageBuilder: (c, s) => const NoTransitionPage(child: TerminalPage()),
          ),
          GoRoute(
            path: AppRoutes.windowsServer,
            pageBuilder: (c, s) => const NoTransitionPage(child: WindowsServerPage()),
          ),
          GoRoute(
            path: AppRoutes.terraform,
            pageBuilder: (c, s) => const NoTransitionPage(child: TerraformPage()),
          ),
          GoRoute(
            path: AppRoutes.docker,
            pageBuilder: (c, s) => const NoTransitionPage(child: DockerPage()),
          ),
          GoRoute(
            path: AppRoutes.kubernetes,
            pageBuilder: (c, s) => const NoTransitionPage(child: KubernetesPage()),
          ),
          GoRoute(
            path: AppRoutes.networking,
            pageBuilder: (c, s) => const NoTransitionPage(child: NetworkingPage()),
          ),
          GoRoute(
            path: AppRoutes.monitoring,
            pageBuilder: (c, s) => const NoTransitionPage(child: MonitoringPage()),
          ),
          GoRoute(
            path: AppRoutes.cicd,
            pageBuilder: (c, s) => const NoTransitionPage(child: CicdPage()),
          ),
          GoRoute(
            path: AppRoutes.architecture,
            pageBuilder: (c, s) => const NoTransitionPage(child: ArchitecturePage()),
          ),
          GoRoute(
            path: AppRoutes.interview,
            pageBuilder: (c, s) => const NoTransitionPage(child: InterviewPage()),
          ),
          GoRoute(
            path: AppRoutes.scenario,
            pageBuilder: (c, s) => const NoTransitionPage(child: ScenarioPage()),
          ),
          GoRoute(
            path: AppRoutes.exam,
            pageBuilder: (c, s) => const NoTransitionPage(child: ExamPage()),
          ),
          GoRoute(
            path: AppRoutes.knowledge,
            pageBuilder: (c, s) => const NoTransitionPage(child: KnowledgePage()),
          ),
          GoRoute(
            path: AppRoutes.achievements,
            pageBuilder: (c, s) => const NoTransitionPage(child: AchievementsPage()),
          ),
          GoRoute(
            path: AppRoutes.statistics,
            pageBuilder: (c, s) => const NoTransitionPage(child: StatisticsPage()),
          ),
        ],
      ),
    ],
  );
}
