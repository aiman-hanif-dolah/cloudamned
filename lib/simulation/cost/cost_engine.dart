class CostFinding {
  const CostFinding({
    required this.id,
    required this.title,
    required this.monthlyWaste,
    required this.recommendation,
    required this.category,
  });

  final String id;
  final String title;
  final int monthlyWaste;
  final String recommendation;
  final String category;
}

/// "Our AWS bill doubled" investigation lab.
class CostEngine {
  final Set<String> selected = {};

  static const findings = <CostFinding>[
    CostFinding(
      id: 'idle-ec2',
      title: 'Idle EC2 (t3.large × 4, CPU < 2%)',
      monthlyWaste: 280,
      recommendation: 'Stop/rightsize or schedule off-hours.',
      category: 'Compute',
    ),
    CostFinding(
      id: 'unattached-ebs',
      title: 'Unattached EBS volumes (12 × 100GB gp3)',
      monthlyWaste: 120,
      recommendation: 'Snapshot then delete orphan volumes.',
      category: 'Storage',
    ),
    CostFinding(
      id: 'old-snaps',
      title: 'Aged EBS snapshots (no lifecycle)',
      monthlyWaste: 90,
      recommendation: 'DLM lifecycle: retain 14 daily.',
      category: 'Storage',
    ),
    CostFinding(
      id: 'idle-alb',
      title: 'ALB with zero targets',
      monthlyWaste: 25,
      recommendation: 'Delete unused load balancer.',
      category: 'Networking',
    ),
    CostFinding(
      id: 'data-transfer',
      title: 'Cross-AZ & egress spike',
      monthlyWaste: 400,
      recommendation: 'Keep chatty tiers co-located; add CloudFront for static.',
      category: 'Data Transfer',
    ),
    CostFinding(
      id: 'nat-ha',
      title: 'NAT Gateway per AZ underutilized + processing',
      monthlyWaste: 180,
      recommendation: 'VPC endpoints for S3/Dynamo; review NAT necessity.',
      category: 'Networking',
    ),
    CostFinding(
      id: 'cf-miss',
      title: 'No CloudFront — origin heavy transfer',
      monthlyWaste: 220,
      recommendation: 'CDN for static assets.',
      category: 'CDN',
    ),
    CostFinding(
      id: 'od-only',
      title: '100% On-Demand steady-state fleet',
      monthlyWaste: 350,
      recommendation: 'Compute Savings Plans / RIs for baseline.',
      category: 'Commitments',
    ),
    CostFinding(
      id: 's3-standard',
      title: 'S3 Standard for 80TB cold logs',
      monthlyWaste: 900,
      recommendation: 'Lifecycle to IA/Glacier Instant/Deep Archive.',
      category: 'Storage',
    ),
  ];

  int get wasteIdentified =>
      findings.where((f) => selected.contains(f.id)).fold(0, (a, b) => a + b.monthlyWaste);

  int get totalWaste => findings.fold(0, (a, b) => a + b.monthlyWaste);

  void toggle(String id) {
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
  }

  String report() {
    final buf = StringBuffer('Cost optimization report\n');
    buf.writeln('Customer complaint: AWS bill doubled.\n');
    buf.writeln('Identified monthly waste: \$${wasteIdentified} / \$${totalWaste} catalogued\n');
    for (final f in findings.where((f) => selected.contains(f.id))) {
      buf.writeln('• [${f.category}] ${f.title}');
      buf.writeln('  Waste ≈ \$${f.monthlyWaste}/mo');
      buf.writeln('  Action: ${f.recommendation}\n');
    }
    if (selected.isEmpty) buf.writeln('Select findings from the bill breakdown.');
    buf.writeln('Next: enable Budgets + Cost Anomaly Detection; weekly FinOps review.');
    return buf.toString();
  }
}
