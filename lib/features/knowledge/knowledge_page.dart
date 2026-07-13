import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/question_bank.dart';
import '../../domain/entities/question.dart';

class KnowledgePage extends StatefulWidget {
  const KnowledgePage({super.key});

  @override
  State<KnowledgePage> createState() => _KnowledgePageState();
}

class _KnowledgePageState extends State<KnowledgePage> {
  String _domain = 'all';
  late Question _current;
  String? _selected;
  String? _feedback;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    final pool = _domain == 'all'
        ? QuestionBank.all
        : QuestionBank.byDomain(_domain);
    final list = List<Question>.from(pool)..shuffle();
    setState(() {
      _current = list.first;
      _selected = null;
      _feedback = null;
    });
  }

  void _check() {
    if (_selected == null) return;
    final ok = _current.grade([_selected!]);
    AppServices.instance.progressCubit.recordAnswer(correct: ok);
    setState(() {
      _feedback = ok
          ? 'Correct. ${_current.explanation}'
          : 'Incorrect. ${_current.explanation}\nAnswer: ${_current.correctAnswers.join(', ')}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final domains = ['all', 'cloud', 'linux', 'networking', 'aws', 'azure', 'gcp', 'docker', 'kubernetes', 'terraform', 'security'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          ShadSectionHeader(
            title: 'Knowledge Base',
            subtitle: '${QuestionBank.all.length}+ questions · MCQ · T/F · scenarios · log analysis',
            trailing: DropdownButton<String>(
              value: _domain,
              items: [for (final d in domains) DropdownMenuItem(value: d, child: Text(d))],
              onChanged: (v) {
                _domain = v ?? 'all';
                _next();
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ShadCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      ShadBadge(label: _current.domain),
                      const SizedBox(width: 8),
                      ShadBadge(label: _current.difficulty, variant: ShadBadgeVariant.outline),
                      if (_current.certification != null) ...[
                        const SizedBox(width: 8),
                        ShadBadge(label: _current.certification!, variant: ShadBadgeVariant.secondary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_current.prompt, style: const TextStyle(fontSize: 15, height: 1.45, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 16),
                  if (_current.choices.isNotEmpty)
                    ..._current.choices.map(
                      (c) => RadioListTile<String>(
                        value: c,
                        groupValue: _selected,
                        title: Text(c, style: const TextStyle(fontSize: 13)),
                        onChanged: _feedback != null ? null : (v) => setState(() => _selected = v),
                      ),
                    )
                  else
                    ShadInput(
                      hint: 'Type answer',
                      onChanged: (v) => _selected = v,
                    ),
                  if (_feedback != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ShadcnColors.secondary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: ShadcnColors.border),
                      ),
                      child: Text(_feedback!, style: const TextStyle(fontSize: 13, height: 1.4)),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      ShadButton(
                        onPressed: _feedback == null ? _check : null,
                        child: const Text('Check'),
                      ),
                      const SizedBox(width: 8),
                      ShadButton(
                        variant: ShadButtonVariant.secondary,
                        onPressed: _next,
                        child: const Text('Next question'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
