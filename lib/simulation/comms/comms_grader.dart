class CustomerQuestion {
  const CustomerQuestion({
    required this.id,
    required this.question,
    required this.keywords,
    required this.modelAnswer,
  });

  final String id;
  final String question;
  final List<String> keywords;
  final String modelAnswer;
}

class CommsScore {
  const CommsScore({
    required this.technical,
    required this.business,
    required this.professional,
    required this.confidence,
    required this.overall,
    required this.feedback,
  });

  final int technical;
  final int business;
  final int professional;
  final int confidence;
  final int overall;
  final List<String> feedback;
}

abstract final class CommsGrader {
  static const questions = <CustomerQuestion>[
    CustomerQuestion(
      id: 'q1',
      question: 'Why migrate at all?',
      keywords: ['cost', 'agility', 'scale', 'dr', 'security', 'capex', 'opex', 'elasticity'],
      modelAnswer:
          'Migration reduces CapEx to OpEx, improves elasticity for demand spikes, enables managed DR and stronger security baselines when designed correctly.',
    ),
    CustomerQuestion(
      id: 'q2',
      question: 'Why AWS?',
      keywords: ['ecosystem', 'region', 'windows', 'rds', 'maturity', 'partner', 'service'],
      modelAnswer:
          'AWS offers mature Windows/SQL patterns, broad regional presence, and a deep service ecosystem for landing zones, observability, and managed data.',
    ),
    CustomerQuestion(
      id: 'q3',
      question: 'Why not Azure?',
      keywords: ['entra', 'hybrid', 'ad', 'license', 'trade-off', 'fit', 'workload'],
      modelAnswer:
          'Azure is excellent for Entra/AD-centric estates. Choice depends on identity strategy, licenses, and workload fit—not brand preference.',
    ),
    CustomerQuestion(
      id: 'q4',
      question: 'Why does this cost more?',
      keywords: ['ha', 'multi-az', 'nat', 'managed', 'support', 'transfer', 'baseline'],
      modelAnswer:
          'HA (multi-AZ), managed databases, egress, and NAT often raise bills vs fragile single-server setups. We separate must-have resilience from optional spend.',
    ),
    CustomerQuestion(
      id: 'q5',
      question: 'Can downtime be avoided?',
      keywords: ['pilot', 'replication', 'blue', 'green', 'cutover', 'rpo', 'near-zero'],
      modelAnswer:
          'Near-zero is possible with replication and phased cutover, but not free. We define RPO/RTO and pick tools (DMS, dual-write, blue/green) accordingly.',
    ),
    CustomerQuestion(
      id: 'q6',
      question: 'Can we rollback?',
      keywords: ['rollback', 'dns', 'snapshot', 'abort', 'failback', 'plan'],
      modelAnswer:
          'Yes—every cutover has abort criteria, DNS failback, and data reverse path tested in pilot.',
    ),
    CustomerQuestion(
      id: 'q7',
      question: 'Why is our website slow?',
      keywords: ['latency', 'cpu', 'database', 'cache', 'cdn', 'region', 'query'],
      modelAnswer:
          'We triage metrics: edge latency, origin CPU, DB slow queries, chatty chat cross-AZ, missing CDN/cache—then fix the hottest path first.',
    ),
  ];

  static CommsScore grade(CustomerQuestion q, String answer) {
    final text = answer.toLowerCase();
    final hits = q.keywords.where((k) => text.contains(k)).length;
    final technical = (30 + (hits / q.keywords.length) * 70).round().clamp(0, 100);
    final business = text.contains('cost') ||
            text.contains('budget') ||
            text.contains('risk') ||
            text.contains('customer') ||
            text.contains('downtime')
        ? (50 + hits * 5).clamp(0, 100)
        : (25 + hits * 5).clamp(0, 100);
    final professional = answer.trim().length < 40
        ? 30
        : answer.contains('!') && answer.split('!').length > 3
            ? 55
            : 80;
    final confidence = answer.trim().length > 120
        ? 85
        : answer.trim().length > 60
            ? 70
            : 45;
    final overall = ((technical + business + professional + confidence) / 4).round();
    final feedback = <String>[
      'Technical accuracy: $technical/100 (keyword coverage $hits/${q.keywords.length}).',
      'Business understanding: $business/100.',
      'Professional tone: $professional/100.',
      'Confidence/completeness: $confidence/100.',
      'Model talking points: ${q.modelAnswer}',
    ];
    return CommsScore(
      technical: technical,
      business: business,
      professional: professional,
      confidence: confidence,
      overall: overall,
      feedback: feedback,
    );
  }
}
