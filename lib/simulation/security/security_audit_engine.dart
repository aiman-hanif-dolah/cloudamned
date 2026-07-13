class AuditItem {
  const AuditItem({
    required this.id,
    required this.area,
    required this.finding,
    required this.severity,
    required this.remediation,
  });

  final String id;
  final String area;
  final String finding;
  final String severity;
  final String remediation;
}

class SecurityAuditEngine {
  final Set<String> flagged = {};

  static const items = <AuditItem>[
    AuditItem(
      id: 'a1',
      area: 'IAM',
      finding: 'Root account used for daily tasks; access keys present',
      severity: 'Critical',
      remediation: 'Disable root keys; break-glass only; SSO for humans',
    ),
    AuditItem(
      id: 'a2',
      area: 'MFA',
      finding: 'No MFA on privileged IAM users',
      severity: 'Critical',
      remediation: 'Enforce MFA via SCP / IAM policy',
    ),
    AuditItem(
      id: 'a3',
      area: 'Security Groups',
      finding: '0.0.0.0/0 on TCP 22 and 3389 in prod',
      severity: 'Critical',
      remediation: 'Restrict admin ports; prefer SSM Session Manager',
    ),
    AuditItem(
      id: 'a4',
      area: 'Encryption',
      finding: 'Unencrypted EBS and RDS storage',
      severity: 'High',
      remediation: 'Enable encryption with CMK; migrate volumes',
    ),
    AuditItem(
      id: 'a5',
      area: 'Certificates',
      finding: 'ACM cert expiring in 7 days without renewal alarm',
      severity: 'High',
      remediation: 'Auto-renew + EventBridge alarm',
    ),
    AuditItem(
      id: 'a6',
      area: 'Secrets',
      finding: 'DB password in user-data and Git history',
      severity: 'Critical',
      remediation: 'Secrets Manager/SSM; rotate; purge git',
    ),
    AuditItem(
      id: 'a7',
      area: 'Firewall',
      finding: 'NACL allows all inbound ephemeral mismanaged',
      severity: 'Medium',
      remediation: 'Stateful SG primary; tighten NACL if required',
    ),
    AuditItem(
      id: 'a8',
      area: 'Logging',
      finding: 'CloudTrail not multi-region; logs not immutable',
      severity: 'High',
      remediation: 'Org trail → log archive with SCP deny-delete',
    ),
    AuditItem(
      id: 'a9',
      area: 'Compliance',
      finding: 'No Config rules for public S3 / unrestricted SG',
      severity: 'High',
      remediation: 'Enable Conformance Pack / Security Hub',
    ),
    AuditItem(
      id: 'a10',
      area: 'IAM',
      finding: 'Wildcard actions on AdministratorAccess for contractors',
      severity: 'Critical',
      remediation: 'Job-function policies; time-bound access',
    ),
  ];

  void toggle(String id) {
    if (flagged.contains(id)) {
      flagged.remove(id);
    } else {
      flagged.add(id);
    }
  }

  int get score => ((flagged.length / items.length) * 100).round();

  String report() {
    final buf = StringBuffer('Security audit report\n\n');
    final list = items.where((i) => flagged.contains(i.id)).toList();
    if (list.isEmpty) {
      buf.writeln('No findings flagged yet.');
      return buf.toString();
    }
    for (final i in list) {
      buf.writeln('[${i.severity}] ${i.area}: ${i.finding}');
      buf.writeln('  Remediation: ${i.remediation}\n');
    }
    buf.writeln('Coverage: $score% of planted findings identified.');
    return buf.toString();
  }
}
