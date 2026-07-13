import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../simulation/interview/design_evaluator.dart';

/// Interviewer simulator — design questions + local rubric scoring.
class InterviewPage extends StatefulWidget {
  const InterviewPage({super.key});

  @override
  State<InterviewPage> createState() => _InterviewPageState();
}

class _InterviewPageState extends State<InterviewPage> {
  int _tab = 0; // 0 catalog, 1 active design
  DesignPrompt? _prompt;
  int _followUp = -1;
  final _answer = TextEditingController();
  DesignScore? _score;
  final _history = <String>[];

  void _start(DesignPrompt p) {
    setState(() {
      _prompt = p;
      _tab = 1;
      _followUp = -1;
      _score = null;
      _answer.clear();
      _history
        ..clear()
        ..add('Interviewer: ${p.prompt}');
    });
  }

  void _submit() {
    final p = _prompt;
    if (p == null || _answer.text.trim().isEmpty) return;
    final text = _answer.text.trim();
    final score = DesignInterviewBank.evaluate(p, text);
    setState(() {
      _history.add('You: $text');
      _score = score;
      _history.add(
        'Interviewer feedback — overall ${score.overall}/100 '
        '(scale ${score.scalability}, security ${score.security}, '
        'cost ${score.cost}, fault-tolerance ${score.faultTolerance})',
      );
      for (final f in score.feedback) {
        _history.add('  · $f');
      }
    });
    AppServices.instance.progressCubit.recordAnswer(correct: score.overall >= 70);
    if (score.overall >= 70) {
      AppServices.instance.progressCubit.addXp(150);
    }
  }

  void _askFollowUp() {
    final p = _prompt;
    if (p == null || p.followUps.isEmpty) return;
    final next = (_followUp + 1) % p.followUps.length;
    setState(() {
      _followUp = next;
      _history.add('Interviewer (follow-up): ${p.followUps[next]}');
      _score = null;
      _answer.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadSectionHeader(
            title: 'Interview Mode',
            subtitle:
                'The simulator is the interviewer — design systems, defend trade-offs, get scored on scalability, security, cost, fault tolerance',
            trailing: _tab == 1
                ? ShadButton(
                    size: ShadButtonSize.sm,
                    variant: ShadButtonVariant.outline,
                    onPressed: () => setState(() {
                      _tab = 0;
                      _prompt = null;
                    }),
                    child: const Text('All scenarios'),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Expanded(child: _tab == 0 ? _catalog() : _session()),
        ],
      ),
    );
  }

  Widget _catalog() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.8,
      children: [
        for (final p in DesignInterviewBank.prompts)
          ShadCard(
            onTap: () => _start(p),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShadBadge(label: 'SYSTEM DESIGN', variant: ShadBadgeVariant.secondary),
                const SizedBox(height: 10),
                Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                Expanded(
                  child: Text(
                    p.prompt,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground, height: 1.35),
                  ),
                ),
                const Text(
                  'Start interview →',
                  style: TextStyle(fontSize: 12, color: ShadcnColors.primary, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _session() {
    final p = _prompt!;
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ShadCard(
            header: Text(p.title, style: const TextStyle(fontWeight: FontWeight.w600)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ShadcnColors.secondary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: ShadcnColors.border),
                  ),
                  child: Text(
                    _followUp >= 0 ? p.followUps[_followUp] : p.prompt,
                    style: const TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rubric: ${p.rubric}',
                  style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground, height: 1.35),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TextField(
                    controller: _answer,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      hintText:
                          'Design your answer…\n\nStructure tip: requirements → high-level design → data plane → security → cost → ops/failover',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ShadButton(onPressed: _submit, child: const Text('Submit answer')),
                    const SizedBox(width: 8),
                    ShadButton(
                      variant: ShadButtonVariant.secondary,
                      onPressed: _askFollowUp,
                      child: const Text('Ask follow-up'),
                    ),
                    if (_score != null) ...[
                      const Spacer(),
                      ShadBadge(
                        label: 'Overall ${_score!.overall}/100',
                        variant: _score!.overall >= 70
                            ? ShadBadgeVariant.success
                            : ShadBadgeVariant.warning,
                      ),
                    ],
                  ],
                ),
                if (_score != null) ...[
                  const SizedBox(height: 12),
                  _scoreBars(_score!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ShadPanel(
            title: 'Interview transcript',
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final line in _history)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: line.startsWith('You:')
                            ? ShadcnColors.foreground
                            : line.startsWith('Interviewer')
                                ? ShadcnColors.info
                                : ShadcnColors.mutedForeground,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _scoreBars(DesignScore s) {
    Widget bar(String label, int v) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 11))),
              Expanded(child: ShadProgress(value: v / 100)),
              const SizedBox(width: 8),
              Text('$v', style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground)),
            ],
          ),
        );
    return Column(
      children: [
        bar('Scalability', s.scalability),
        bar('Security', s.security),
        bar('Cost efficiency', s.cost),
        bar('Fault tolerance', s.faultTolerance),
      ],
    );
  }
}
