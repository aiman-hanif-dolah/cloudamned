class OpsInterviewQuestion {
  const OpsInterviewQuestion({
    required this.id,
    required this.prompt,
    required this.keywords,
    required this.modelPoints,
  });

  final String id;
  final String prompt;
  final List<String> keywords;
  final String modelPoints;
}

class OpsInterviewScore {
  const OpsInterviewScore({
    required this.technical,
    required this.structure,
    required this.communication,
    required this.overall,
    required this.feedback,
  });

  final int technical;
  final int structure;
  final int communication;
  final int overall;
  final String feedback;
}

abstract final class OpsInterviewBank {
  static const questions = <OpsInterviewQuestion>[
    OpsInterviewQuestion(
      id: 'ssh',
      prompt: 'A customer cannot access their EC2 instance over SSH. What would you check first?',
      keywords: ['security group', 'nacl', 'route', 'status', 'key', 'public ip', 'ssm', 'instance state'],
      modelPoints: 'Instance state/status checks → SG/NACL/routes/IGW → key/username → prefer SSM.',
    ),
    OpsInterviewQuestion(
      id: 'slow-linux',
      prompt: 'A Linux server suddenly becomes slow. How would you investigate?',
      keywords: ['cpu', 'memory', 'disk', 'iowait', 'top', 'load', 'logs', 'process'],
      modelPoints: 'top/vmstat/iostat, df, journalctl, recent changes, noisy process, then mitigate.',
    ),
    OpsInterviewQuestion(
      id: 'migration-explain',
      prompt: 'How would you explain cloud migration to a non-technical customer?',
      keywords: ['risk', 'cost', 'downtime', 'benefit', 'phased', 'business', 'rollback'],
      modelPoints: 'Business outcomes first; phased approach; downtime honesty; rollback; cost tradeoffs.',
    ),
    OpsInterviewQuestion(
      id: 'escalate',
      prompt: 'When would you escalate an issue instead of continuing investigation?',
      keywords: ['time', 'sla', 'blast', 'security', 'provider', 'skill', 'evidence'],
      modelPoints: 'SLA risk, security, provider outage, beyond skill with evidence package ready.',
    ),
    OpsInterviewQuestion(
      id: 'cpu-alert',
      prompt: 'A monitoring alert reports high CPU usage. What are your next steps?',
      keywords: ['validate', 'process', 'traffic', 'scale', 'deploy', 'threshold', 'runbook'],
      modelPoints: 'Validate metric → identify process/traffic → recent deploy → scale/mitigate → tune alert.',
    ),
    OpsInterviewQuestion(
      id: 'rca',
      prompt: 'What information should be included in a Root Cause Analysis?',
      keywords: ['timeline', 'impact', 'root', 'contributing', 'fix', 'prevention', 'detection'],
      modelPoints: 'Impact, timeline, root vs contributing, detection gaps, fix, prevention actions.',
    ),
    OpsInterviewQuestion(
      id: 'prioritize',
      prompt: 'How would you prioritise two simultaneous critical incidents?',
      keywords: ['impact', 'users', 'revenue', 'sla', 'blast', 'safety', 'customer'],
      modelPoints: 'Business impact & safety first; parallelize; communicate; escalate for capacity.',
    ),
    OpsInterviewQuestion(
      id: 'comms-wip',
      prompt: 'How do you communicate progress while an incident is still under investigation?',
      keywords: ['update', 'eta', 'known', 'next', 'honest', 'cadence', 'status'],
      modelPoints: 'Cadenced updates: what we know, what we are doing next, next update time; no false certainty.',
    ),
  ];

  static OpsInterviewScore grade(OpsInterviewQuestion q, String answer) {
    final text = answer.toLowerCase();
    final hits = q.keywords.where((k) => text.contains(k)).length;
    final technical = (30 + hits / q.keywords.length * 70).round().clamp(0, 100);
    final structure = text.contains('first') || text.contains('then') || text.contains('1.') || text.contains('step')
        ? 80
        : answer.trim().length > 120
            ? 65
            : 40;
    final communication = answer.trim().length < 50
        ? 35
        : answer.trim().length > 400
            ? 75
            : 85;
    final overall = ((technical + structure + communication) / 3).round();
    return OpsInterviewScore(
      technical: technical,
      structure: structure,
      communication: communication,
      overall: overall,
      feedback:
          'Keywords $hits/${q.keywords.length}. Model: ${q.modelPoints}\n'
          'Scores T$technical S$structure C$communication.',
    );
  }
}
