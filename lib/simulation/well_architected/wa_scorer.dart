class WaResult {
  const WaResult({
    required this.pillars,
    required this.overall,
    required this.recommendations,
  });

  final Map<String, int> pillars;
  final int overall;
  final List<String> recommendations;
}

/// Scores architectures like an experienced cloud architect (offline rules).
class WellArchitectedScorer {
  WaResult score({
    required Set<String> components,
    required bool multiAz,
    required bool privateData,
    required bool backups,
    required bool monitoring,
    required bool leastPrivilege,
    required bool encryption,
    required bool costTags,
    required bool asgOrServerless,
    required bool sustainabilityNotes,
  }) {
    final lower = components.map((e) => e.toLowerCase()).toSet();
    bool has(String k) => lower.any((c) => c.contains(k));

    int clamp(int v) => v.clamp(0, 100);

    final operational = clamp(
      40 +
          (monitoring ? 20 : 0) +
          (has('runbook') || has('alarm') ? 15 : 0) +
          (has('pipeline') || has('ci') ? 15 : 0) +
          (has('trail') || has('config') ? 10 : 0),
    );

    final security = clamp(
      30 +
          (privateData ? 20 : 0) +
          (leastPrivilege ? 15 : 0) +
          (encryption ? 15 : 0) +
          (has('waf') || has('shield') ? 10 : 0) +
          (has('mfa') ? 10 : 0) -
          (has('0.0.0.0/0') ? 20 : 0),
    );

    final reliability = clamp(
      35 +
          (multiAz ? 25 : 0) +
          (backups ? 20 : 0) +
          (has('multi-az') || has('failover') ? 10 : 0) +
          (has('dr') ? 10 : 0),
    );

    final performance = clamp(
      45 +
          (asgOrServerless ? 20 : 0) +
          (has('cache') || has('cloudfront') || has('cdn') ? 15 : 0) +
          (has('alb') || has('load') ? 10 : 0),
    );

    final cost = clamp(
      40 +
          (costTags ? 15 : 0) +
          (has('lifecycle') || has('savings') || has('reserved') ? 20 : 0) +
          (has('rightsize') || has('spot') ? 15 : 0) -
          (has('nat') && !has('endpoint') ? 5 : 0),
    );

    final sustainability = clamp(
      50 +
          (sustainabilityNotes ? 20 : 0) +
          (asgOrServerless ? 15 : 0) +
          (has('graviton') || has('arm') || has('efficient') ? 15 : 0),
    );

    final pillars = {
      'Operational Excellence': operational,
      'Security': security,
      'Reliability': reliability,
      'Performance Efficiency': performance,
      'Cost Optimization': cost,
      'Sustainability': sustainability,
    };

    final overall =
        (pillars.values.reduce((a, b) => a + b) / pillars.length).round();

    final recs = <String>[];
    if (!multiAz) recs.add('Spread tier-1 across ≥2 AZs; eliminate single-AZ SPOF.');
    if (!privateData) recs.add('Move data stores to private subnets; no public DB endpoints.');
    if (!backups) recs.add('Enable automated backups + restore drills with measured RTO/RPO.');
    if (!monitoring) recs.add('Define SLIs, alarms, and ownership before go-live.');
    if (!leastPrivilege) recs.add('Replace broad IAM with job-function roles and boundaries.');
    if (!encryption) recs.add('Encrypt at rest (KMS/CMK) and enforce TLS in transit.');
    if (!costTags) recs.add('Mandatory tagging + budgets; kill idle NAT/EBS/ALB.');
    if (!asgOrServerless) recs.add('Add horizontal elasticity (ASG/serverless) for spiky load.');
    if (recs.isEmpty) {
      recs.add('Solid baseline. Next: chaos drills, cost anomaly detection, platform standards.');
    }

    return WaResult(pillars: pillars, overall: overall, recommendations: recs);
  }
}
