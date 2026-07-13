import '../failure/failure_engine.dart';

/// Aggregates logs/metrics/history for investigation (forensics mode).
class ForensicsEngine {
  final List<String> appLogs = [];
  final List<String> linuxLogs = [];
  final List<String> windowsEvents = [];
  final List<String> cloudWatch = [];
  final List<String> azureMonitor = [];
  final List<String> stackdriver = [];
  final List<String> auditLogs = [];
  final List<String> authLogs = [];
  final List<String> terraformPlans = [];
  final List<String> gitCommits = [];
  final List<String> pipelineHistory = [];
  final List<String> metrics = [];
  final List<String> alerts = [];
  final List<String> flowLogs = [];

  void seedHealthy() {
    _clear();
    appLogs.addAll([
      'INFO request_id=1 GET /health 200 12ms',
      'INFO request_id=2 GET /api/orders 200 45ms',
    ]);
    linuxLogs.addAll([
      'systemd: Started Session',
      'sshd: Accepted publickey for cloudeng',
    ]);
    windowsEvents.add('Information: Service Control Manager — IIS running');
    cloudWatch.add('CPUUtilization avg=22%');
    metrics.add('p95_latency_ms=80');
    gitCommits.add('a1b2c3 deploy: bump web 1.8.2');
    pipelineHistory.add('pipeline #1284 SUCCESS 3m12s');
  }

  void seedFromFailure(SimulatedFailure f) {
    seedHealthy();
    appLogs.add('ERROR ${f.symptoms}');
    for (final l in f.logs) {
      if (l.toLowerCase().contains('kernel') || l.contains('ext4') || l.contains('oom')) {
        linuxLogs.add(l);
      } else if (l.contains('CloudWatch') || l.contains('ALB') || l.contains('CPU')) {
        cloudWatch.add(l);
      } else if (l.contains('AccessDenied') || l.contains('CloudTrail')) {
        auditLogs.add(l);
      } else if (l.contains('pipeline') || l.contains('##[error]')) {
        pipelineHistory.add(l);
      } else if (l.contains('Flow') || l.contains('REJECT') || l.contains('packet')) {
        flowLogs.add(l);
      } else {
        appLogs.add(l);
      }
    }
    alerts.add('ALARM ${f.title}');
    authLogs.add('auth: last success 10m ago; elevated deny count');
    terraformPlans.add('Plan: 0 add, 1 change, 0 destroy (drift suspected)');
    azureMonitor.add('(mirror) activity log spike on network security group');
    stackdriver.add('(mirror) gce instance unreachable check');
    windowsEvents.add('Warning: Application error correlating with dependency timeout');
  }

  void _clear() {
    for (final l in [
      appLogs,
      linuxLogs,
      windowsEvents,
      cloudWatch,
      azureMonitor,
      stackdriver,
      auditLogs,
      authLogs,
      terraformPlans,
      gitCommits,
      pipelineHistory,
      metrics,
      alerts,
      flowLogs,
    ]) {
      l.clear();
    }
  }

  Map<String, List<String>> bundles() => {
        'Application logs': appLogs,
        'Linux logs': linuxLogs,
        'Windows Event Viewer': windowsEvents,
        'CloudWatch': cloudWatch,
        'Azure Monitor': azureMonitor,
        'Stackdriver / Cloud Logging': stackdriver,
        'Audit logs': auditLogs,
        'Authentication logs': authLogs,
        'Terraform plans': terraformPlans,
        'Git commits': gitCommits,
        'Pipeline history': pipelineHistory,
        'Metrics': metrics,
        'Alerts': alerts,
        'Network flow logs': flowLogs,
      };
}
