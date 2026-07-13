/// Enterprise landing zone builder + Well-Architected style grading.
class LandingZoneEngine {
  final Set<String> enabled = {};
  final List<String> history = [];

  static const catalog = <LzComponent>[
    LzComponent('org', 'AWS Organizations', 'Account governance root', 'Operational Excellence'),
    LzComponent('accounts', 'Multi-account structure', 'Security / Log / Shared / Workload accounts', 'Security'),
    LzComponent('iam', 'IAM baseline', 'Password policy, permission boundaries', 'Security'),
    LzComponent('idc', 'IAM Identity Center', 'SSO / workforce identity', 'Security'),
    LzComponent('cloudtrail', 'CloudTrail (org trail)', 'API audit in log archive', 'Security'),
    LzComponent('config', 'AWS Config', 'Resource compliance rules', 'Reliability'),
    LzComponent('guardduty', 'GuardDuty', 'Threat detection', 'Security'),
    LzComponent('cloudwatch', 'CloudWatch', 'Central metrics/logs/alarms', 'Operational Excellence'),
    LzComponent('budgets', 'AWS Budgets', 'Cost anomaly & budget alerts', 'Cost Optimization'),
    LzComponent('vpc', 'Hub VPC', 'Inspection / shared services VPC', 'Reliability'),
    LzComponent('subnets', 'Multi-AZ subnets', 'Public/private/data tiers', 'Reliability'),
    LzComponent('tgw', 'Transit Gateway', 'Spoke connectivity', 'Performance'),
    LzComponent('sg', 'Security Groups baseline', 'Least privilege defaults', 'Security'),
    LzComponent('nacl', 'Network ACLs', 'Subnet boundary controls', 'Security'),
    LzComponent('rtb', 'Route tables', 'Centralized egress patterns', 'Reliability'),
    LzComponent('igw', 'Internet Gateway', 'Public ingress/egress edge', 'Reliability'),
    LzComponent('nat', 'NAT Gateway (per AZ)', 'Private egress HA', 'Reliability'),
    LzComponent('vpn', 'Site-to-Site VPN', 'Hybrid connectivity', 'Reliability'),
    LzComponent('backup', 'AWS Backup vault', 'Org backup policies', 'Reliability'),
    LzComponent('kms', 'KMS encryption', 'CMKs for data services', 'Security'),
  ];

  void toggle(String id) {
    if (enabled.contains(id)) {
      enabled.remove(id);
      history.add('Disabled $id');
    } else {
      enabled.add(id);
      history.add('Enabled $id');
    }
  }

  void enableAll() {
    enabled
      ..clear()
      ..addAll(catalog.map((c) => c.id));
    history.add('Enabled full landing zone baseline');
  }

  Map<String, int> pillarScores() {
    final pillars = <String, List<bool>>{};
    for (final c in catalog) {
      pillars.putIfAbsent(c.pillar, () => []).add(enabled.contains(c.id));
    }
    return {
      for (final e in pillars.entries)
        e.key: e.value.isEmpty
            ? 0
            : ((e.value.where((x) => x).length / e.value.length) * 100).round(),
    };
  }

  int get overallScore {
    if (catalog.isEmpty) return 0;
    return ((enabled.length / catalog.length) * 100).round();
  }

  List<String> gaps() =>
      catalog.where((c) => !enabled.contains(c.id)).map((c) => c.name).toList();

  String gradeReport() {
    final pillars = pillarScores();
    final buf = StringBuffer('Landing Zone Well-Architected review\n');
    buf.writeln('Overall foundation coverage: $overallScore%\n');
    for (final e in pillars.entries) {
      buf.writeln('${e.key}: ${e.value}%');
    }
    final g = gaps();
    if (g.isNotEmpty) {
      buf.writeln('\nMissing controls:');
      for (final x in g.take(8)) {
        buf.writeln(' • $x');
      }
    } else {
      buf.writeln('\nAll baseline controls present. Review account SCPs next.');
    }
    return buf.toString();
  }
}

class LzComponent {
  const LzComponent(this.id, this.name, this.description, this.pillar);
  final String id;
  final String name;
  final String description;
  final String pillar;
}
