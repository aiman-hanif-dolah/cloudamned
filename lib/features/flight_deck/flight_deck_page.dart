import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/career/career_rank.dart';

/// Master hub — cloudamned Cloud Engineering Flight Simulator.
class FlightDeckPage extends StatefulWidget {
  const FlightDeckPage({super.key});

  @override
  State<FlightDeckPage> createState() => _FlightDeckPageState();
}

class _FlightDeckPageState extends State<FlightDeckPage> {
  String? _banner;

  @override
  Widget build(BuildContext context) {
    final flight = AppServices.instance.flight;
    final rank = flight.progression.rank;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadSectionHeader(
            title: 'Flight Deck',
            subtitle:
                '${flight.progression.companyName} · You are a ${rank.title} — solve customer business problems, not quizzes',
            trailing: ShadBadge(
              label: 'Rep ${flight.reputation.overall.toStringAsFixed(0)}',
              variant: ShadBadgeVariant.success,
            ),
          ),
          if (_banner != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ShadcnColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: ShadcnColors.primary.withValues(alpha: 0.4)),
              ),
              child: Text(_banner!, style: const TextStyle(fontSize: 12)),
            ),
          ],
          const SizedBox(height: 14),
          // Rank card
          ShadCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rank.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'Unlocks: ${rank.unlocks}',
                  style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground),
                ),
                const SizedBox(height: 10),
                ShadProgress(value: flight.progression.rankProgress, height: 8),
                const SizedBox(height: 6),
                Text(
                  rank.next == null
                      ? 'Max rank'
                      : 'XP ${flight.progression.careerXp}/${rank.xpToPromote} → ${rank.next!.title}',
                  style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
                ),
                const SizedBox(height: 8),
                Text(
                  'Projects completed: ${flight.progression.projectsCompleted} · '
                  'Active failures: ${flight.failures.active.length}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text('Consultant workflow', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1000 ? 3 : 2;
              final tiles = <(String, String, String, IconData, Color)>[
                ('Generate customer', 'Unlimited unique industries & constraints', AppRoutes.discovery, Icons.business, ShadcnColors.primary),
                ('Discovery interview', 'Customer answers — miss questions, miss requirements', AppRoutes.discovery, Icons.hearing, ShadcnColors.info),
                ('Platform decision', 'AWS/Azure/GCP/Hybrid tradeoffs with WHY', AppRoutes.decisions, Icons.account_tree, ShadcnColors.warning),
                ('Cloud Ops Center', 'Tickets · SLA · shift · runbooks · portfolio', AppRoutes.opsCenter, Icons.support_agent, ShadcnColors.warning),
                ('Career project delivery', '20-step engagement with validation', AppRoutes.careerSim, Icons.work_outline, ShadcnColors.success),
                ('Multi-cloud compare', 'Same design across clouds · cost/risk', AppRoutes.multiCloud, Icons.cloud_sync, ShadcnColors.gcp),
                ('Failure injection', 'Disk, AZ, IAM, TLS, pipelines… recover', AppRoutes.forensics, Icons.warning_amber, ShadcnColors.destructive),
                ('Forensics war room', 'Logs, metrics, flow, git, pipelines', AppRoutes.forensics, Icons.biotech, ShadcnColors.chart4),
                ('Incident command', 'Live tickets + SLA + RCA', AppRoutes.tickets, Icons.crisis_alert, ShadcnColors.destructive),
                ('Mentor', 'Principal Architect asks hard questions', AppRoutes.mentor, Icons.psychology, ShadcnColors.terraform),
                ('Whiteboard interview', 'Netflix, Grab, Maybank, Shopee…', AppRoutes.whiteboard, Icons.edit_note, ShadcnColors.azure),
                ('Engineering journal', 'Searchable portfolio of decisions', AppRoutes.journal, Icons.menu_book, ShadcnColors.mutedForeground),
                ('Capstone engagement', 'Full consulting bar exam', AppRoutes.capstone, Icons.flag, ShadcnColors.primary),
              ];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tiles.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                ),
                itemBuilder: (context, i) {
                  final t = tiles[i];
                  return ShadCard(
                    onTap: () => context.go(t.$3),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(t.$4, color: t.$5, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t.$1, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(t.$2,
                                  style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: ShadcnColors.mutedForeground),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ShadButton(
                onPressed: () {
                  final p = flight.generateProject();
                  setState(() {
                    _banner =
                        'New customer: ${p.customerName} (${p.industry.name}) · '
                        '${p.currency}${p.budgetMonthly}/mo · ${p.timelineWeeks}w';
                  });
                },
                icon: Icons.casino,
                child: const Text('Generate customer project'),
              ),
              const SizedBox(width: 8),
              ShadButton(
                variant: ShadButtonVariant.destructive,
                onPressed: () {
                  final f = flight.injectFailure();
                  setState(() {
                    _banner = 'FAILURE INJECTED: ${f.title} — open Forensics';
                  });
                },
                icon: Icons.bolt,
                child: const Text('Inject failure'),
              ),
              const SizedBox(width: 8),
              ShadButton(
                variant: ShadButtonVariant.secondary,
                onPressed: () {
                  final promoted = flight.awardCareerXp(150);
                  flight.save(AppServices.instance.progressBox);
                  setState(() {
                    _banner = promoted
                        ? 'PROMOTED to ${flight.progression.rank.title}!'
                        : '+150 career XP';
                  });
                },
                child: const Text('+XP (demo)'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShadCard(
            header: const Text('Thinking process (always)', style: TextStyle(fontWeight: FontWeight.w600)),
            child: const Text(
              'What is the real problem? · What causes it? · Constraints & budget? · '
              'Acceptable downtime? · Regulations? · Reuse existing? · Growth? · '
              'RTO/RPO? · Performance? · Then architecture — never reverse that order.',
              style: TextStyle(fontSize: 12, height: 1.45, color: ShadcnColors.mutedForeground),
            ),
          ),
        ],
      ),
    );
  }
}
