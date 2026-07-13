class CloudFootprint {
  const CloudFootprint({
    required this.provider,
    required this.monthlyCost,
    required this.availability,
    required this.latencyMs,
    required this.mgmtComplexity,
    required this.securityPosture,
    required this.scalability,
    required this.notes,
  });

  final String provider;
  final int monthlyCost;
  final int availability; // 0-100
  final int latencyMs;
  final int mgmtComplexity; // higher harder
  final int securityPosture;
  final int scalability;
  final String notes;
}

/// Deploy same logical architecture across clouds and compare.
class MultiCloudEngine {
  final Map<String, bool> deployed = {
    'AWS': false,
    'Azure': false,
    'GCP': false,
  };

  /// Baseline 3-tier web + DB + LB + private subnets sized for mid workload.
  List<CloudFootprint> footprints({int users = 100000}) {
    final scale = (users / 100000).clamp(0.5, 5.0);
    return [
      CloudFootprint(
        provider: 'AWS',
        monthlyCost: (4200 * scale).round(),
        availability: 99,
        latencyMs: 28,
        mgmtComplexity: 55,
        securityPosture: 88,
        scalability: 92,
        notes: 'ALB+ASG+RDS Multi-AZ+S3; mature IaC ecosystem.',
      ),
      CloudFootprint(
        provider: 'Azure',
        monthlyCost: (4000 * scale).round(),
        availability: 98,
        latencyMs: 30,
        mgmtComplexity: 58,
        securityPosture: 87,
        scalability: 90,
        notes: 'App Gateway+VMSS+Azure SQL; strong hybrid identity.',
      ),
      CloudFootprint(
        provider: 'GCP',
        monthlyCost: (3900 * scale).round(),
        availability: 98,
        latencyMs: 27,
        mgmtComplexity: 52,
        securityPosture: 86,
        scalability: 91,
        notes: 'HTTPS LB+MIG+Cloud SQL; clean networking model.',
      ),
    ];
  }

  void markDeployed(String provider) {
    if (deployed.containsKey(provider)) deployed[provider] = true;
  }

  String comparisonReport({int users = 100000}) {
    final fps = footprints(users: users);
    final buf = StringBuffer('Multi-cloud comparison · ~$users users logical load\n\n');
    buf.writeln('Provider   Cost/mo   Avail  Latency  Mgmt  Security  Scale');
    for (final f in fps) {
      buf.writeln(
        '${f.provider.padRight(9)} '
        '\$${f.monthlyCost.toString().padLeft(5)}    '
        '${f.availability}%    '
        '${f.latencyMs}ms     '
        '${f.mgmtComplexity}    '
        '${f.securityPosture}       '
        '${f.scalability}'
        '${deployed[f.provider] == true ? '  [deployed in sim]' : ''}',
      );
    }
    fps.sort((a, b) => a.monthlyCost.compareTo(b.monthlyCost));
    buf.writeln('\nLowest cost: ${fps.first.provider}');
    fps.sort((a, b) => b.securityPosture.compareTo(a.securityPosture));
    buf.writeln('Strongest security posture (model): ${fps.first.provider}');
    buf.writeln('\nRecommendation: pick one primary cloud for ops excellence; '
        'multi-cloud only with clear DR/sovereignty drivers.');
    return buf.toString();
  }
}
