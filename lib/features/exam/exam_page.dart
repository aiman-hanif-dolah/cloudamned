import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import '../../core/theme/shadcn_colors.dart';
import '../../core/widgets/shadcn_widgets.dart';
import '../../data/content/question_bank.dart';
import '../../domain/entities/question.dart';

class ExamPage extends StatefulWidget {
  const ExamPage({super.key});

  @override
  State<ExamPage> createState() => _ExamPageState();
}

class _ExamPageState extends State<ExamPage> {
  ExamDefinition? _exam;
  List<Question> _questions = [];
  int _index = 0;
  final Map<String, String> _answers = {};
  Timer? _timer;
  int _remaining = 0;
  bool _finished = false;
  int? _score;

  void _start(ExamDefinition exam) {
    _timer?.cancel();
    setState(() {
      _exam = exam;
      _questions = QuestionBank.sample(count: exam.questionCount.clamp(5, 40), cert: exam.certification);
      if (_questions.length < 10) {
        _questions = QuestionBank.sample(count: exam.questionCount.clamp(10, 40));
      }
      _index = 0;
      _answers.clear();
      _remaining = exam.durationMinutes * 60;
      _finished = false;
      _score = null;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _finish();
        return;
      }
      setState(() => _remaining--);
    });
  }

  void _finish() {
    _timer?.cancel();
    var correct = 0;
    for (final q in _questions) {
      final a = _answers[q.id];
      if (a != null && q.grade([a])) correct++;
    }
    final score = _questions.isEmpty ? 0 : ((correct / _questions.length) * 100).round();
    setState(() {
      _finished = true;
      _score = score;
    });
    AppServices.instance.logActivity(
      'exam',
      'exam=${_exam?.id ?? 'practice'} score=$score passed=${score >= (_exam?.passingScore ?? 70)}',
    );
    AppServices.instance.progressCubit.addXp(score >= 70 ? 750 : 200);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _clock {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_exam == null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ShadSectionHeader(
              title: 'Exam Mode',
              subtitle: 'AWS CCP · SAA · AZ-900 · GCP ACE — timed practice, offline question bank',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  for (final e in QuestionBank.exams)
                    ShadCard(
                      onTap: () => _start(e),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(e.description,
                              style: const TextStyle(fontSize: 12, color: ShadcnColors.mutedForeground)),
                          const Spacer(),
                          Text(
                            '${e.questionCount} Q · ${e.durationMinutes} min · pass ${e.passingScore}%',
                            style: const TextStyle(fontSize: 11, color: ShadcnColors.mutedForeground),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (_finished) {
      final pass = (_score ?? 0) >= (_exam!.passingScore);
      return Center(
        child: SizedBox(
          width: 480,
          child: ShadCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(pass ? Icons.emoji_events : Icons.replay, size: 40,
                    color: pass ? ShadcnColors.success : ShadcnColors.warning),
                const SizedBox(height: 12),
                Text('Score: $_score%', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                Text(pass ? 'PASSED' : 'NOT PASSED',
                    style: TextStyle(color: pass ? ShadcnColors.success : ShadcnColors.destructive)),
                const SizedBox(height: 16),
                ShadButton(
                  onPressed: () => setState(() => _exam = null),
                  child: const Text('Back to exams'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _questions[_index];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Text(_exam!.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              ShadBadge(label: _clock, variant: ShadBadgeVariant.warning),
              const SizedBox(width: 8),
              Text('${_index + 1}/${_questions.length}'),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ShadCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(q.prompt, style: const TextStyle(fontSize: 15, height: 1.4)),
                  const SizedBox(height: 16),
                  if (q.choices.isNotEmpty)
                    ...q.choices.map(
                      (c) => RadioListTile<String>(
                        value: c,
                        groupValue: _answers[q.id],
                        title: Text(c, style: const TextStyle(fontSize: 13)),
                        onChanged: (v) => setState(() => _answers[q.id] = v ?? ''),
                      ),
                    )
                  else
                    ShadInput(
                      hint: 'Your answer',
                      onChanged: (v) => _answers[q.id] = v,
                    ),
                  const Spacer(),
                  Row(
                    children: [
                      ShadButton(
                        variant: ShadButtonVariant.outline,
                        onPressed: _index > 0 ? () => setState(() => _index--) : null,
                        child: const Text('Previous'),
                      ),
                      const Spacer(),
                      if (_index < _questions.length - 1)
                        ShadButton(
                          onPressed: () => setState(() => _index++),
                          child: const Text('Next'),
                        )
                      else
                        ShadButton(
                          onPressed: _finish,
                          variant: ShadButtonVariant.success,
                          child: const Text('Submit exam'),
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
