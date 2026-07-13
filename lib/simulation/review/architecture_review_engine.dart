class ArchFlaw {
  const ArchFlaw({
    required this.id,
    required this.title,
    required this.detail,
    required this.severity,
    required this.pillar,
  });

  final String id;
  final String title;
  final String detail;
  final String severity;
  final String pillar;
}

class ArchDiagram {
  const ArchDiagram({
    required this.id,
    required this.title,
    required this.description,
    required this.components,
    required this.flaws,
  });

  final String id;
  final String title;
  final String description;
  final List<String> components;
  final List<ArchFlaw> flaws;
}

/// Users review intentionally flawed architectures.
class ArchitectureReviewEngine {
  final Set<String> found = {};

  static const diagrams = <ArchDiagram>[
    ArchDiagram(
      id: 'broken-web',
      title: '3-tier web (broken)',
      description: 'Internet → ALB → EC2 → RDS. Several critical mistakes planted.',
      components: [
        'Single AZ VPC',
        'ALB in public subnet',
        'EC2 in public subnet with 0.0.0.0/0 SSH',
        'RDS in public subnet',
        'No automated backups',
        'IAM user access keys on EC2',
        'S3 bucket public read',
        'No CloudTrail',
        'No CloudWatch alarms',
        'No MFA on root',
        'No encryption on RDS',
      ],
      flaws: [
        ArchFlaw(
          id: 'f1',
          title: 'Database in public subnet',
          detail: 'RDS must be private; no public accessibility.',
          severity: 'Critical',
          pillar: 'Security',
        ),
        ArchFlaw(
          id: 'f2',
          title: 'No backups',
          detail: 'Enable automated backups / AWS Backup.',
          severity: 'Critical',
          pillar: 'Reliability',
        ),
        ArchFlaw(
          id: 'f3',
          title: 'Single Availability Zone',
          detail: 'Multi-AZ for ALB targets and database.',
          severity: 'High',
          pillar: 'Reliability',
        ),
        ArchFlaw(
          id: 'f4',
          title: 'No Auto Scaling',
          detail: 'ASG for web tier elasticity.',
          severity: 'Medium',
          pillar: 'Performance',
        ),
        ArchFlaw(
          id: 'f5',
          title: 'Overly permissive SSH',
          detail: 'SSH 0.0.0.0/0 on instance SG.',
          severity: 'Critical',
          pillar: 'Security',
        ),
        ArchFlaw(
          id: 'f6',
          title: 'Public S3 bucket',
          detail: 'Block public access; use OAI/OAC if CDN.',
          severity: 'Critical',
          pillar: 'Security',
        ),
        ArchFlaw(
          id: 'f7',
          title: 'No CloudTrail',
          detail: 'Enable org trail to log archive.',
          severity: 'High',
          pillar: 'Security',
        ),
        ArchFlaw(
          id: 'f8',
          title: 'No monitoring',
          detail: 'CloudWatch alarms for 5xx/CPU/RDS.',
          severity: 'High',
          pillar: 'Operational Excellence',
        ),
        ArchFlaw(
          id: 'f9',
          title: 'No MFA',
          detail: 'Enforce MFA on root and privileged users.',
          severity: 'Critical',
          pillar: 'Security',
        ),
        ArchFlaw(
          id: 'f10',
          title: 'Missing encryption',
          detail: 'Encrypt RDS and EBS with KMS.',
          severity: 'High',
          pillar: 'Security',
        ),
        ArchFlaw(
          id: 'f11',
          title: 'No DR plan',
          detail: 'Define RTO/RPO and backup restore drills.',
          severity: 'High',
          pillar: 'Reliability',
        ),
        ArchFlaw(
          id: 'f12',
          title: 'Long-lived access keys on EC2',
          detail: 'Use instance profiles/roles instead.',
          severity: 'High',
          pillar: 'Security',
        ),
      ],
    ),
  ];

  ArchDiagram get current => diagrams.first;

  void toggleFound(String flawId) {
    if (found.contains(flawId)) {
      found.remove(flawId);
    } else {
      found.add(flawId);
    }
  }

  double get progress => found.length / current.flaws.length;

  int get score => (progress * 100).round();
}
