import '../aws/aws_engine.dart';
import '../linux/linux_shell.dart';

class InvestigationStep {
  const InvestigationStep({
    required this.id,
    required this.title,
    required this.description,
    required this.actionKey,
    this.hint = '',
  });

  final String id;
  final String title;
  final String description;
  final String actionKey;
  final String hint;
}

class IncidentDefinition {
  const IncidentDefinition({
    required this.id,
    required this.severity,
    required this.customerMessage,
    required this.background,
    required this.steps,
    required this.rootCauseSummary,
    required this.resolutionSteps,
  });

  final String id;
  final String severity;
  final String customerMessage;
  final String background;
  final List<InvestigationStep> steps;
  final String rootCauseSummary;
  final List<String> resolutionSteps;
}

/// Incident-based learning orchestrator for cloudamned.
class IncidentEngine {
  IncidentEngine({required this.aws, required this.linux});

  final AwsEngine aws;
  final LinuxShell linux;

  String? activeId;
  final Set<String> completedSteps = {};
  final List<String> notes = [];

  static final catalog = <IncidentDefinition>[
    IncidentDefinition(
      id: 'website-down',
      severity: 'SEV-2',
      customerMessage: 'My website is down. Customers cannot load the homepage.',
      background:
          'prod-web-1 serves traffic behind a public IP. ALB health checks are failing. '
          'You must investigate like a Cloud Technical Engineer: logs, EC2, security groups, '
          'routes, SSH, and application (nginx) state — then restore service.',
      steps: [
        InvestigationStep(
          id: 's1',
          title: 'Read CloudWatch logs',
          description: 'Open log groups for the web instance and ALB target health.',
          actionKey: 'inspect_logs',
          hint: 'Use CloudWatch → Get log events in the incident workspace.',
        ),
        InvestigationStep(
          id: 's2',
          title: 'Check EC2 instance status',
          description: 'Confirm the instance is running and status checks pass.',
          actionKey: 'check_ec2_status',
          hint: 'Describe instance status for prod-web-1.',
        ),
        InvestigationStep(
          id: 's3',
          title: 'Review security groups',
          description: 'Verify inbound rules allow HTTP (80) from the internet / ALB.',
          actionKey: 'inspect_sg',
          hint: 'Describe security groups — look for missing TCP/80.',
        ),
        InvestigationStep(
          id: 's4',
          title: 'Verify route tables',
          description: 'Ensure public subnet has 0.0.0.0/0 → IGW.',
          actionKey: 'inspect_routes',
          hint: 'Describe route tables associated with the public subnet.',
        ),
        InvestigationStep(
          id: 's5',
          title: 'Test SSH access',
          description: 'Confirm management access to the instance.',
          actionKey: 'test_ssh',
          hint: 'Use Test SSH against prod-web-1.',
        ),
        InvestigationStep(
          id: 's6',
          title: 'Probe HTTP / nginx',
          description: 'Confirm whether anything listens on port 80.',
          actionKey: 'probe_http',
          hint: 'HTTP probe will fail until SG and nginx are fixed.',
        ),
        InvestigationStep(
          id: 's7',
          title: 'Restore service',
          description: 'Open port 80 on the security group and start nginx.',
          actionKey: 'incident_resolved',
          hint: 'Authorize TCP/80 on web-sg, then start nginx on the instance.',
        ),
      ],
      rootCauseSummary:
          'Two concurrent failures: (1) security group web-sg allowed SSH but not HTTP/80; '
          '(2) nginx was not running on prod-web-1, so the ALB target was connection-refused.',
      resolutionSteps: [
        'Authorize inbound TCP/80 (and optionally 443) on the web security group',
        'SSH or use session tools to start nginx: systemctl start nginx && systemctl enable nginx',
        'Verify curl http://<public-ip> returns 200',
        'Confirm CloudWatch/ALB target health returns healthy',
        'Update the incident ticket with root cause and fix',
      ],
    ),
    IncidentDefinition(
      id: 'cannot-ssh',
      severity: 'SEV-3',
      customerMessage: 'Cannot SSH into our bastion / EC2 instance.',
      background:
          'Engineers report SSH timeouts to a public instance. Investigate SG, NACL/routes, and instance state.',
      steps: [
        InvestigationStep(
          id: 'c1',
          title: 'Describe instance',
          description: 'Confirm running state and public IP.',
          actionKey: 'describe_instances',
        ),
        InvestigationStep(
          id: 'c2',
          title: 'Inspect security groups',
          description: 'TCP/22 must allow your admin CIDR.',
          actionKey: 'inspect_sg',
        ),
        InvestigationStep(
          id: 'c3',
          title: 'Test SSH',
          description: 'Retry SSH after fix.',
          actionKey: 'ssh_ok',
        ),
      ],
      rootCauseSummary: 'Typically missing SG rule for port 22 or instance in private subnet without bastion.',
      resolutionSteps: [
        'Add SG ingress TCP/22 from admin IP',
        'Confirm public subnet + IGW route',
        'Verify key pair and username',
      ],
    ),
  ];

  IncidentDefinition? get active =>
      catalog.where((i) => i.id == activeId).firstOrNull;

  void load(String incidentId) {
    completedSteps.clear();
    notes.clear();
    activeId = incidentId;
    if (incidentId == 'website-down') {
      aws.loadWebsiteDownIncident();
      // Mirror nginx down on linked linux shell for terminal path
      linux.fs.services.remove('nginx');
      linux.fs.packages.remove('nginx');
    } else if (incidentId == 'cannot-ssh') {
      aws.resetDefaults();
      final pub = aws.state.subnets.firstWhere((s) => s.isPublic);
      final sg = aws.state.securityGroups.first;
      // Remove any ssh rules
      sg.ingress.removeWhere((r) => r.fromPort == 22);
      aws.runInstances(subnetId: pub.id, securityGroupIds: [sg.id], name: 'bastion');
      aws.state.activeIncidentId = 'cannot-ssh';
    }
    notes.add('Incident $incidentId loaded at ${DateTime.now()}');
  }

  void syncProgress() {
    final def = active;
    if (def == null) return;
    for (final step in def.steps) {
      if (aws.completedActions.contains(step.actionKey) ||
          linux.completedActions.contains(step.actionKey)) {
        completedSteps.add(step.id);
      }
    }
  }

  double get progress {
    final def = active;
    if (def == null || def.steps.isEmpty) return 0;
    syncProgress();
    return completedSteps.length / def.steps.length;
  }

  bool get resolved {
    if (activeId == 'website-down') return aws.incidentResolved;
    if (activeId == 'cannot-ssh') return aws.completedActions.contains('ssh_ok');
    return false;
  }

  void addNote(String note) => notes.add('${DateTime.now().toIso8601String()}  $note');
}
