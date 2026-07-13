import 'dart:math';

class DailyBlock {
  DailyBlock({
    required this.time,
    required this.title,
    required this.kind,
    required this.prompt,
    this.completed = false,
    this.score,
    this.notes = '',
  });

  final String time;
  final String title;
  final String kind;
  final String prompt;
  bool completed;
  int? score;
  String notes;
}

/// Simulates a Cloud Technical Engineer workday.
class DailyEngineerEngine {
  DailyEngineerEngine() {
    schedule = _generate(Random(DateTime.now().day));
  }

  late List<DailyBlock> schedule;
  final List<String> summary = [];

  int get completedCount => schedule.where((b) => b.completed).length;
  double get progress => schedule.isEmpty ? 0 : completedCount / schedule.length;

  int get dayScore {
    final scored = schedule.where((b) => b.score != null).map((b) => b.score!);
    if (scored.isEmpty) return 0;
    return (scored.reduce((a, b) => a + b) / scored.length).round();
  }

  void complete(int index, {required int score, String notes = ''}) {
    if (index < 0 || index >= schedule.length) return;
    schedule[index].completed = true;
    schedule[index].score = score.clamp(0, 100);
    schedule[index].notes = notes;
    summary.add('${schedule[index].time} ${schedule[index].title}: $score/100');
  }

  void reshuffle() {
    schedule = _generate(Random(DateTime.now().millisecondsSinceEpoch));
    summary.clear();
  }

  List<DailyBlock> _generate(Random rng) {
    final templates = [
      DailyBlock(
        time: '09:00',
        title: 'Stand-up',
        kind: 'meeting',
        prompt: 'Share yesterday, today, blockers in ≤3 sentences for the platform squad.',
      ),
      DailyBlock(
        time: '09:30',
        title: 'Resolve ticket',
        kind: 'ticket',
        prompt: 'INC queue: pick critical ticket, investigate, post customer update, document RCA draft.',
      ),
      DailyBlock(
        time: '10:15',
        title: 'Terraform deployment',
        kind: 'iac',
        prompt: 'Plan + apply networking module to staging. Note blast radius and rollback.',
      ),
      DailyBlock(
        time: '11:00',
        title: 'Customer meeting',
        kind: 'customer',
        prompt: 'Explain multi-AZ choice vs single-AZ savings to a non-technical finance lead.',
      ),
      DailyBlock(
        time: '12:00',
        title: 'Lunch',
        kind: 'break',
        prompt: 'Optional: review Well-Architected lens notes (auto-complete when acknowledged).',
      ),
      DailyBlock(
        time: '13:00',
        title: 'Architecture review',
        kind: 'architecture',
        prompt: 'Review peer design: flag public DB subnet and missing backups.',
      ),
      DailyBlock(
        time: '14:00',
        title: 'Migration planning',
        kind: 'migration',
        prompt: 'Draft pilot wave for 2 web nodes + read replica. Include success metrics.',
      ),
      DailyBlock(
        time: '15:00',
        title: 'Production deployment',
        kind: 'deploy',
        prompt: 'Change window: deploy ALB listener rule. List validation checks post-change.',
      ),
      DailyBlock(
        time: '16:00',
        title: 'Incident response',
        kind: 'incident',
        prompt: 'SEV-2: elevated 5xx. Outline first 15 minutes of bridge actions.',
      ),
      DailyBlock(
        time: '17:00',
        title: 'Documentation',
        kind: 'docs',
        prompt: 'Update runbook section for certificate rotation.',
      ),
      DailyBlock(
        time: '18:00',
        title: 'Daily summary',
        kind: 'wrap',
        prompt: 'Write EOD summary: delivered, risks, tomorrow top-3.',
      ),
    ];

    // Occasionally swap afternoon blocks for variety
    if (rng.nextBool()) {
      final a = templates[6];
      final b = templates[7];
      templates[6] = DailyBlock(
        time: a.time,
        title: 'Cost review',
        kind: 'cost',
        prompt: 'NAT + idle EBS found. Propose savings without hurting HA.',
      );
      templates[7] = b;
    }
    return templates;
  }
}
