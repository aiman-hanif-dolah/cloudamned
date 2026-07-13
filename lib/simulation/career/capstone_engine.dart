import '../../domain/entities/career_project.dart';
import 'project_generator.dart';

class CapstoneCheckpoint {
  const CapstoneCheckpoint({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;
}

/// Final consulting engagement — full-spectrum evaluation.
class CapstoneEngine {
  CareerProject? engagement;
  final Set<String> done = {};
  final Map<String, int> scores = {};

  static const checkpoints = <CapstoneCheckpoint>[
    CapstoneCheckpoint(id: 'discovery', title: 'Requirement gathering', description: 'Run discovery with ≥80% critical coverage'),
    CapstoneCheckpoint(id: 'design', title: 'Architecture design', description: 'Multi-AZ, private data, HA documented'),
    CapstoneCheckpoint(id: 'cloud', title: 'Cloud selection', description: 'Defend platform with tradeoffs'),
    CapstoneCheckpoint(id: 'migration', title: 'Migration planning', description: 'Waves, pilot, cutover, rollback'),
    CapstoneCheckpoint(id: 'iac', title: 'Terraform deployment', description: 'Validated plan/apply path'),
    CapstoneCheckpoint(id: 'linux', title: 'Linux administration', description: 'Services, hardening notes'),
    CapstoneCheckpoint(id: 'windows', title: 'Windows administration', description: 'IIS/AD/ops notes if in scope'),
    CapstoneCheckpoint(id: 'network', title: 'Networking', description: 'VPC, routes, SG design'),
    CapstoneCheckpoint(id: 'monitor', title: 'Monitoring', description: 'Alarms + ownership'),
    CapstoneCheckpoint(id: 'security', title: 'Security hardening', description: 'MFA, encryption, least privilege'),
    CapstoneCheckpoint(id: 'cicd', title: 'CI/CD implementation', description: 'Pipeline + rollback'),
    CapstoneCheckpoint(id: 'backup', title: 'Backup strategy', description: 'Retention + restore test'),
    CapstoneCheckpoint(id: 'dr', title: 'Disaster Recovery', description: 'RTO/RPO + failover steps'),
    CapstoneCheckpoint(id: 'incident', title: 'Incident handling', description: 'Resolve injected SEV with RCA'),
    CapstoneCheckpoint(id: 'comms', title: 'Customer communication', description: 'Graded update ≥70'),
    CapstoneCheckpoint(id: 'docs', title: 'Documentation', description: 'Architecture + runbook + handover'),
    CapstoneCheckpoint(id: 'exec', title: 'Executive presentation', description: 'Non-jargon value + ask'),
    CapstoneCheckpoint(id: 'kt', title: 'Knowledge transfer', description: 'Ops walkthrough complete'),
  ];

  void start({CareerProject? project}) {
    engagement = project ?? ProjectGenerator().generate();
    done.clear();
    scores.clear();
  }

  void complete(String id, int score) {
    done.add(id);
    scores[id] = score.clamp(0, 100);
  }

  double get progress => done.length / checkpoints.length;

  int get overall {
    if (scores.isEmpty) return 0;
    return (scores.values.reduce((a, b) => a + b) / scores.length).round();
  }

  bool get passed => progress >= 1.0 && overall >= 75;

  String report() {
    final buf = StringBuffer('CAPSTONE — ${engagement?.customerName ?? 'Enterprise'}\n');
    buf.writeln('Progress ${(progress * 100).round()}% · Score $overall/100 · ${passed ? 'PASS' : 'IN PROGRESS'}\n');
    for (final c in checkpoints) {
      final s = scores[c.id];
      final mark = done.contains(c.id) ? '✓' : '·';
      buf.writeln('$mark ${c.title.padRight(28)} ${s?.toString() ?? '-'}');
    }
    buf.writeln('\nEnterprise bar: complete all checkpoints with average ≥75.');
    return buf.toString();
  }
}
