import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_routes.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../domain/entities/progress.dart';
import '../progress/progress_cubit.dart';

class _NavItem {
  const _NavItem(this.label, this.route, this.icon, {this.section});
  final String label;
  final String route;
  final IconData icon;
  final String? section;
}

const _nav = <_NavItem>[
  _NavItem('Dashboard', AppRoutes.dashboard, Icons.dashboard_outlined, section: 'HOME'),
  _NavItem('Flight Deck', AppRoutes.flightDeck, Icons.flight_takeoff),
  _NavItem('Cloud Ops Center', AppRoutes.opsCenter, Icons.support_agent, section: 'OPERATIONS DESK'),
  _NavItem('Service Desk', AppRoutes.opsTickets, Icons.confirmation_number_outlined),
  _NavItem('Support Shift', AppRoutes.opsShift, Icons.schedule),
  _NavItem('Ops Monitoring', AppRoutes.opsMonitoring, Icons.monitor_heart_outlined),
  _NavItem('Ops KB / Runbooks', AppRoutes.opsKb, Icons.menu_book),
  _NavItem('Ops Portfolio', AppRoutes.opsPortfolio, Icons.folder_special_outlined),
  _NavItem('Ops Interview', AppRoutes.opsInterview, Icons.record_voice_over_outlined),
  _NavItem('Discovery', AppRoutes.discovery, Icons.hearing, section: 'CONSULTING'),
  _NavItem('Platform Decisions', AppRoutes.decisions, Icons.account_tree_outlined),
  _NavItem('Career Simulation', AppRoutes.careerSim, Icons.business_center_outlined),
  _NavItem('Capstone', AppRoutes.capstone, Icons.flag_outlined),
  _NavItem('Mentor', AppRoutes.mentor, Icons.psychology_outlined),
  _NavItem('Journal', AppRoutes.journal, Icons.menu_book_outlined),
  _NavItem('Daily Engineer', AppRoutes.daily, Icons.today_outlined, section: 'OPERATIONS'),
  _NavItem('Tickets / IR', AppRoutes.tickets, Icons.confirmation_number_outlined),
  _NavItem('Forensics', AppRoutes.forensics, Icons.biotech_outlined),
  _NavItem('Landing Zone', AppRoutes.landingZone, Icons.account_balance_outlined),
  _NavItem('Migration Lab', AppRoutes.migration, Icons.swap_horiz),
  _NavItem('Multi-Cloud', AppRoutes.multiCloud, Icons.cloud_sync_outlined),
  _NavItem('Well-Architected', AppRoutes.wellArchitected, Icons.architecture),
  _NavItem('Arch Review', AppRoutes.archReview, Icons.fact_check_outlined),
  _NavItem('Cost Lab', AppRoutes.costLab, Icons.attach_money),
  _NavItem('Security Audit', AppRoutes.securityAudit, Icons.policy_outlined),
  _NavItem('Documentation', AppRoutes.documentation, Icons.description_outlined),
  _NavItem('Meetings & Comms', AppRoutes.meetings, Icons.groups_outlined),
  _NavItem('Skill Analytics', AppRoutes.skills, Icons.insights_outlined),
  _NavItem('Learning Roadmap', AppRoutes.roadmap, Icons.map_outlined, section: 'LEARNING'),
  _NavItem('Labs', AppRoutes.labs, Icons.science_outlined),
  _NavItem('Career Progress', AppRoutes.career, Icons.trending_up),
  _NavItem('Cloud Console', AppRoutes.console, Icons.cloud_outlined, section: 'SIMULATORS'),
  _NavItem('Linux Terminal', AppRoutes.terminal, Icons.terminal),
  _NavItem('Windows Server', AppRoutes.windowsServer, Icons.desktop_windows_outlined),
  _NavItem('Terraform', AppRoutes.terraform, Icons.code),
  _NavItem('Docker Lab', AppRoutes.docker, Icons.view_in_ar_outlined),
  _NavItem('Kubernetes', AppRoutes.kubernetes, Icons.hub_outlined),
  _NavItem('Networking', AppRoutes.networking, Icons.device_hub_outlined),
  _NavItem('Monitoring', AppRoutes.monitoring, Icons.monitor_heart_outlined),
  _NavItem('CI/CD', AppRoutes.cicd, Icons.merge_type),
  _NavItem('Architecture', AppRoutes.architecture, Icons.account_tree_outlined),
  _NavItem('Interview Mode', AppRoutes.interview, Icons.record_voice_over_outlined, section: 'ASSESSMENT'),
  _NavItem('Whiteboard', AppRoutes.whiteboard, Icons.edit_note),
  _NavItem('Incident Lab', AppRoutes.scenario, Icons.support_agent_outlined),
  _NavItem('Exam Mode', AppRoutes.exam, Icons.quiz_outlined),
  _NavItem('Knowledge Base', AppRoutes.knowledge, Icons.menu_book_outlined),
  _NavItem('Achievements', AppRoutes.achievements, Icons.emoji_events_outlined, section: 'PROGRESS'),
  _NavItem('Statistics', AppRoutes.statistics, Icons.bar_chart_outlined),
];

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _collapsed = false;

  void _go(String route) {
    if (GoRouterState.of(context).uri.path != route) {
      context.go(route);
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isMod = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    if (!isMod) return KeyEventResult.ignored;

    final shortcuts = <LogicalKeyboardKey, String>{
      LogicalKeyboardKey.digit1: AppRoutes.dashboard,
      LogicalKeyboardKey.digit2: AppRoutes.roadmap,
      LogicalKeyboardKey.digit3: AppRoutes.labs,
      LogicalKeyboardKey.digit4: AppRoutes.terminal,
      LogicalKeyboardKey.digit5: AppRoutes.console,
      LogicalKeyboardKey.keyT: AppRoutes.terminal,
      LogicalKeyboardKey.keyL: AppRoutes.labs,
      LogicalKeyboardKey.keyR: AppRoutes.roadmap,
    };
    final route = shortcuts[event.logicalKey];
    if (route != null) {
      _go(route);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.bracketLeft) {
      setState(() => _collapsed = !_collapsed);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final width = _collapsed
        ? AppConstants.sidebarCollapsedWidth
        : AppConstants.sidebarWidth;

    return Focus(
      autofocus: true,
      onKeyEvent: _onKey,
      child: Scaffold(
        body: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: width,
              decoration: const BoxDecoration(
                color: ShadcnColors.sidebar,
                border: Border(right: BorderSide(color: ShadcnColors.sidebarBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SidebarHeader(
                    collapsed: _collapsed,
                    onToggle: () => setState(() => _collapsed = !_collapsed),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      children: [
                        for (final item in _nav) ...[
                          if (item.section != null && !_collapsed)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                              child: Text(
                                item.section!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: ShadcnColors.mutedForeground,
                                ),
                              ),
                            ),
                          if (item.section != null && _collapsed)
                            const Divider(height: 16),
                          _NavTile(
                            item: item,
                            selected: location == item.route ||
                                (item.route != '/' && location.startsWith(item.route)),
                            collapsed: _collapsed,
                            onTap: () => _go(item.route),
                          ),
                        ],
                      ],
                    ),
                  ),
                  BlocBuilder<ProgressCubit, UserProgress>(
                    builder: (context, progress) {
                      return _SidebarFooter(progress: progress, collapsed: _collapsed);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _TopBar(location: location),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.collapsed, required this.onToggle});
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 8 : 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: ShadcnColors.sidebarBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ShadcnColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ShadcnColors.primary.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.cloud, size: 16, color: ShadcnColors.primary),
          ),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'cloudamned',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
          IconButton(
            onPressed: onToggle,
            icon: Icon(
              collapsed ? Icons.chevron_right : Icons.chevron_left,
              size: 18,
              color: ShadcnColors.mutedForeground,
            ),
            tooltip: collapsed ? 'Expand sidebar' : 'Collapse sidebar (Ctrl+[)',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 10, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? ShadcnColors.sidebarAccent : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: selected
            ? Border.all(color: ShadcnColors.border)
            : Border.all(color: Colors.transparent),
      ),
      child: Row(
        mainAxisAlignment: collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Icon(
            item.icon,
            size: 16,
            color: selected ? ShadcnColors.primary : ShadcnColors.mutedForeground,
          ),
          if (!collapsed) ...[
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? ShadcnColors.foreground : ShadcnColors.mutedForeground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );

    return Tooltip(
      message: item.label,
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: child,
      ),
    );
  }
}

class _SidebarFooter extends StatelessWidget {
  const _SidebarFooter({required this.progress, required this.collapsed});
  final UserProgress progress;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ShadcnColors.sidebarBorder)),
      ),
      child: collapsed
          ? Column(
              children: [
                Text('L${progress.level}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Level ${progress.level}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text('${progress.xp} XP',
                        style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress.levelProgress,
                    minHeight: 4,
                    backgroundColor: ShadcnColors.secondary,
                    color: ShadcnColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${progress.completedLabs.length} labs · ${progress.streakDays}d streak',
                  style: const TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground),
                ),
              ],
            ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.location});
  final String location;

  String get _title {
    final match = _nav.where((n) => location == n.route || (n.route != '/' && location.startsWith(n.route)));
    if (match.isNotEmpty) return match.first.label;
    return 'cloudamned';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: ShadcnColors.panelHeader,
        border: Border(bottom: BorderSide(color: ShadcnColors.border)),
      ),
      child: Row(
        children: [
          Text(
            _title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: ShadcnColors.secondary,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ShadcnColors.border),
            ),
            child: const Text(
              'OFFLINE SIMULATION',
              style: TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground, letterSpacing: 0.5),
            ),
          ),
          const Spacer(),
          const Text(
            'Ctrl+1–5 · Ctrl+T terminal · Ctrl+[ sidebar',
            style: TextStyle(fontSize: 10, color: ShadcnColors.mutedForeground),
          ),
        ],
      ),
    );
  }
}
