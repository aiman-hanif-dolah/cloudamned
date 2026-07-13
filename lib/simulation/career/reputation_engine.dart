/// Professional reputation dimensions for cloudamned flight simulator.
class ReputationEngine {
  final Map<String, double> metrics = {
    for (final m in dimensions) m: 45.0,
  };

  static const dimensions = [
    'Customer Satisfaction',
    'Technical Accuracy',
    'Incident Resolution',
    'Architecture Quality',
    'Documentation Quality',
    'Communication',
    'Security Awareness',
    'Cost Optimisation',
    'Automation',
    'Leadership',
    'Engineering Discipline',
    'Professionalism',
  ];

  double get overall {
    if (metrics.isEmpty) return 0;
    return metrics.values.reduce((a, b) => a + b) / metrics.length;
  }

  void bump(String dimension, double delta) {
    if (!metrics.containsKey(dimension)) return;
    metrics[dimension] = (metrics[dimension]! + delta).clamp(0, 100);
  }

  void applyProjectOutcome({
    required int architectureScore,
    required int securityScore,
    required int costScore,
    required int docsScore,
    required int commsScore,
    required bool incidentHandled,
    required double customerSat,
  }) {
    bump('Architecture Quality', (architectureScore - 50) / 10);
    bump('Security Awareness', (securityScore - 50) / 10);
    bump('Cost Optimisation', (costScore - 50) / 10);
    bump('Documentation Quality', (docsScore - 50) / 10);
    bump('Communication', (commsScore - 50) / 10);
    bump('Customer Satisfaction', (customerSat - 50) / 8);
    if (incidentHandled) bump('Incident Resolution', 4);
    bump('Technical Accuracy', (architectureScore + securityScore) / 40);
    bump('Engineering Discipline', 2);
    bump('Professionalism', commsScore >= 70 ? 3 : 0.5);
  }

  String summary() {
    final buf = StringBuffer('Engineering reputation · overall ${overall.toStringAsFixed(0)}/100\n\n');
    final sorted = metrics.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in sorted) {
      buf.writeln('${e.key.padRight(26)} ${e.value.toStringAsFixed(0)}');
    }
    final weak = sorted.reversed.take(3).map((e) => e.key).join(', ');
    buf.writeln('\nFocus areas: $weak');
    return buf.toString();
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(metrics);

  void loadJson(Map<String, dynamic> j) {
    for (final e in j.entries) {
      metrics[e.key] = (e.value as num).toDouble();
    }
  }
}
