import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/roadmap_content.dart';
import '../../domain/entities/lab.dart';
import '../../domain/entities/progress.dart';
import '../progress/progress_cubit.dart';

class LabDetailPage extends StatefulWidget {
  const LabDetailPage({super.key, required this.labId});
  final String labId;

  @override
  State<LabDetailPage> createState() => _LabDetailPageState();
}

class _LabDetailPageState extends State<LabDetailPage> {
  int _hintIndex = 0;
  final _started = DateTime.now();

  String _simulatorRoute(String sim) {
    return switch (sim) {
      'linux' => AppRoutes.terminal,
      'aws' || 'azure' || 'gcp' => AppRoutes.console,
      'docker' => AppRoutes.docker,
      'kubernetes' => AppRoutes.kubernetes,
      'terraform' => AppRoutes.terraform,
      'networking' => AppRoutes.networking,
      'windows' => AppRoutes.windowsServer,
      'cicd' => AppRoutes.cicd,
      'monitoring' => AppRoutes.monitoring,
      'architecture' => AppRoutes.architecture,
      'interview' => AppRoutes.interview,
      'scenario' => AppRoutes.scenario,
      'exam' => AppRoutes.exam,
      _ => AppRoutes.terminal,
    };
  }

  Future<void> _complete(Lab lab) async {
    final minutes = DateTime.now().difference(_started).inMinutes.clamp(1, 999);
    final progress = context.read<ProgressCubit>();
    final messenger = ScaffoldMessenger.of(context);
    await progress.completeLab(lab.id, score: 100);
    await progress.addTime(minutes);
    await AppServices.instance.recordLabAttempt(lab.id, 100, minutes * 60);
    await AppServices.instance.logActivity('lab', 'Completed ${lab.title}');
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text('Lab complete · +${lab.xpReward} XP')),
    );
  }

  Future<void> _validate(Lab lab) async {
    final svc = AppServices.instance;
    final needed = lab.validationRules;
    if (needed.isEmpty) {
      await _complete(lab);
      return;
    }
    final have = <String>{
      ...svc.linuxShell.completedActions,
      ...svc.awsEngine.completedActions,
      ...svc.dockerEngine.completedActions,
      ...svc.k8sEngine.completedActions,
      ...svc.terraformEngine.completedActions,
      ...svc.networkEngine.completedActions,
    };
    final missing = needed.where((r) => !have.contains(r)).toList();
    // Soft validation: also accept partial for theory labs
    if (lab.type == LabType.theory || missing.length <= needed.length ~/ 2) {
      await _complete(lab);
      return;
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Validation incomplete'),
        content: Text(
          'Still missing:\n${missing.map((m) => '• $m').join('\n')}\n\n'
          'Continue in the ${lab.simulator} simulator, then re-check.\n'
          'Tip: theory labs and partial progress can still be marked complete from feedback.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep working')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _complete(lab);
            },
            child: const Text('Mark complete anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lab = RoadmapContent.labById(widget.labId);
    if (lab == null) {
      return ShadEmpty(
        title: 'Lab not found',
        description: widget.labId,
        action: ShadButton(
          onPressed: () => context.go(AppRoutes.labs),
          child: const Text('Back to labs'),
        ),
      );
    }

    return BlocBuilder<ProgressCubit, UserProgress>(
      builder: (context, progress) {
        final done = progress.completedLabs.contains(lab.id);
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go(AppRoutes.labs),
                        icon: const Icon(Icons.arrow_back, size: 18),
                      ),
                      Expanded(
                        child: ShadSectionHeader(
                          title: lab.title,
                          subtitle: '${lab.moduleId} · ${lab.difficulty.name} · ${lab.estimatedMinutes} min · ${lab.xpReward} XP',
                        ),
                      ),
                      if (done) const ShadBadge(label: 'Completed', variant: ShadBadgeVariant.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ShadCard(
                    header: const Text('Background', style: TextStyle(fontWeight: FontWeight.w600)),
                    child: MarkdownBody(
                      data: lab.background,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(fontSize: 13, height: 1.5, color: ShadcnColors.foreground),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShadCard(
                    header: const Text('Objectives', style: TextStyle(fontWeight: FontWeight.w600)),
                    child: Column(
                      children: [
                        for (final o in lab.objectives)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.flag_outlined, size: 16, color: ShadcnColors.primary),
                            title: Text(o.description, style: const TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ShadCard(
                    header: const Text('Requirements', style: TextStyle(fontWeight: FontWeight.w600)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final r in lab.requirements)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('• $r', style: const TextStyle(fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                  if (lab.hints.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    ShadCard(
                      header: Row(
                        children: [
                          const Text('Hints', style: TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          ShadButton(
                            size: ShadButtonSize.sm,
                            variant: ShadButtonVariant.ghost,
                            onPressed: () => setState(() {
                              _hintIndex = (_hintIndex + 1).clamp(0, lab.hints.length);
                            }),
                            child: Text(_hintIndex == 0 ? 'Reveal hint' : 'Next hint'),
                          ),
                        ],
                      ),
                      child: Text(
                        _hintIndex == 0
                            ? 'Hints are available if you get stuck.'
                            : lab.hints.take(_hintIndex).map((h) => '• $h').join('\n'),
                        style: const TextStyle(fontSize: 13, color: ShadcnColors.mutedForeground),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              width: 320,
              decoration: const BoxDecoration(
                color: ShadcnColors.panel,
                border: Border(left: BorderSide(color: ShadcnColors.border)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Interactive environment',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Simulator: ${lab.simulator}',
                      style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground)),
                  const SizedBox(height: 12),
                  ShadButton(
                    onPressed: () => context.go(_simulatorRoute(lab.simulator)),
                    icon: Icons.play_arrow,
                    child: const Text('Launch simulator'),
                  ),
                  const SizedBox(height: 8),
                  ShadButton(
                    onPressed: () => _validate(lab),
                    variant: ShadButtonVariant.secondary,
                    icon: Icons.verified_outlined,
                    child: const Text('Validate & score'),
                  ),
                  const SizedBox(height: 8),
                  ShadButton(
                    onPressed: done ? null : () => _complete(lab),
                    variant: ShadButtonVariant.outline,
                    child: Text(done ? 'Already completed' : 'Mark complete'),
                  ),
                  const SizedBox(height: 20),
                  const Text('Validation keys',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                  const SizedBox(height: 8),
                  if (lab.validationRules.isEmpty)
                    const Text('No automated keys (manual/theory)',
                        style: TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground))
                  else
                    ...lab.validationRules.map(
                      (v) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('• $v',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                      ),
                    ),
                  const Spacer(),
                  const Text(
                    'Logs & feedback appear in each simulator panel after you run commands.',
                    style: TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
