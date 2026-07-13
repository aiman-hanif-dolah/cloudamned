import 'dart:math';

import 'ops_models.dart';

/// Large catalog of realistic cloud ops incidents for Cloud Operations Center.
class IncidentCatalog {
  static final _rng = Random(7);
  static int _seq = 200;

  static List<OpsTicket> seedQueue({int count = 24}) {
    final list = <OpsTicket>[];
    for (var i = 0; i < count; i++) {
      list.add(generate());
    }
    return list;
  }

  static OpsTicket generate() {
    _seq++;
    final template = _templates[_rng.nextInt(_templates.length)];
    final customer = _customers[_rng.nextInt(_customers.length)];
    final provider = CloudProviderLabel.values[_rng.nextInt(CloudProviderLabel.values.length)];
    final priority = template.priority;
    final number = 'OPS${_seq.toString().padLeft(6, '0')}';

    return OpsTicket(
      number: number,
      customerName: customer,
      priority: priority,
      severity: priority.label,
      affectedService: template.service,
      provider: provider,
      description: '${template.description}\n\nCustomer: $customer\nProvider: ${provider.name}',
      investigationSteps: template.steps,
      correctRootCause: template.rootCause,
      correctResolution: template.resolution,
      runbookId: template.runbookId,
      timeline: [
        TimelineEvent(
          at: DateTime.now().subtract(Duration(minutes: _rng.nextInt(40))),
          actor: 'Service Desk',
          message: 'Ticket $number created from ${template.source}',
          kind: 'create',
        ),
      ],
    );
  }

  static const _customers = [
    'Nusantara Retail Sdn Bhd',
    'Meridian Logistics',
    'Sunrise Clinic Group',
    'Pacific Media Hub',
    'Atlas Manufacturing',
    'Horizon University',
    'Quantum Insurance',
    'Vertex Fintech',
    'Cascade Hospitality',
    'Prime Telecom Ops',
  ];

  static final _templates = <_IncTemplate>[
    _IncTemplate(
      'Cannot SSH into Linux VM',
      'bastion / app-linux-01',
      'Engineers report SSH timeout to public IP. Recent SG change suspected.',
      OpsPriority.p2High,
      'monitoring alert',
      ['Check instance state', 'Review Security Group ingress :22', 'Verify NACL & route to IGW', 'Test from bastion', 'Check key pair / username'],
      'Security Group no longer allows TCP/22 from admin CIDR after change window.',
      'Restore least-privilege SSH rule (or prefer SSM Session Manager); document change.',
      'rb-ssh-recover',
    ),
    _IncTemplate(
      'Windows Server not responding',
      'win-app-02',
      'RDP fails; monitoring shows host reachable but services hung.',
      OpsPriority.p1Critical,
      'customer call',
      ['Check status checks', 'Console screenshot', 'Review Event Viewer last boot', 'Memory / disk pressure', 'Service status (IIS/SQL)'],
      'Disk full on C: caused service hangs; RDP stack unresponsive.',
      'Free disk / expand volume; restart critical services; add disk alarm.',
      'rb-expand-storage',
    ),
    _IncTemplate(
      'Website unavailable',
      'prod-web / ALB',
      'Customers report 504/timeout on homepage. SEV-2.',
      OpsPriority.p1Critical,
      'synthetic monitor',
      ['ALB target health', 'Security Group :80/:443', 'Instance CPU/mem', 'App logs / nginx', 'Recent deploy history'],
      'ALB targets unhealthy: nginx down after deploy + SG missing HTTP from ALB.',
      'Start nginx, fix SG, rollback deploy if needed; update customer.',
      'rb-restart-service',
    ),
    _IncTemplate(
      'SSL Certificate expired',
      'portal.customer.example',
      'Browsers show certificate date invalid.',
      OpsPriority.p1Critical,
      'customer email',
      ['Inspect cert expiry', 'ALB/ACM or nginx cert path', 'DNS host match', 'Renewal pipeline'],
      'TLS certificate expired; auto-renew failed silently.',
      'Issue/attach new cert; add expiry alarm; fix renewal job.',
      'rb-rotate-certs',
    ),
    _IncTemplate(
      'DNS propagation issue',
      'www.customer.example',
      'Some regions resolve old IP after migration.',
      OpsPriority.p2High,
      'customer chat',
      ['dig/nslookup from multiple resolvers', 'TTL values', 'Hosted zone records', 'Recent cutover notes'],
      'Low TTL not set before cutover; residual cache on old A record.',
      'Correct records; communicate TTL wait; document pre-cutover TTL checklist.',
      'rb-dns-cutover',
    ),
    _IncTemplate(
      'Database connection timeout',
      'prod-rds / app-tier',
      'App pool errors: connection timed out to DB.',
      OpsPriority.p1Critical,
      'APM alert',
      ['DB status Multi-AZ', 'SG app→DB 3306/5432', 'Connection count', 'Slow queries', 'Recent IAM/auth change'],
      'DB SG lost app-tier source after terraform apply drift.',
      'Restore SG rule; lock TF; verify pool health.',
      'rb-db-connectivity',
    ),
    _IncTemplate(
      'Disk full',
      '/var on log-aggregator',
      'Fluent Bit crashing; SIEM gaps.',
      OpsPriority.p2High,
      'disk alarm',
      ['df -h', 'largest directories', 'logrotate status', 'volume size', 'retention policy'],
      '/var/log filled by unrotated app logs.',
      'Purge/rotate; expand EBS; fix logrotate; alert at 80%.',
      'rb-expand-storage',
    ),
    _IncTemplate(
      'Memory exhausted',
      'api-worker-3',
      'OOM killer active; process restarts.',
      OpsPriority.p2High,
      'node exporter',
      ['free -m / Task Manager', 'top processes', 'recent deploy', 'leak vs traffic spike', 'limits'],
      'Memory leak in new worker build after yesterday deploy.',
      'Rollback build; raise temporary limits; open app bug with evidence.',
      'rb-restart-service',
    ),
    _IncTemplate(
      'High CPU',
      'web-asg',
      'CPU 95% sustained; latency rising.',
      OpsPriority.p2High,
      'CloudWatch',
      ['CPU by process', 'request rate', 'noisy neighbor', 'autoscaling activity', 'runaway cron'],
      'Traffic spike + inefficient endpoint; ASG max already reached.',
      'Scale max; cache/rate-limit hot path; schedule capacity review.',
      'rb-scale-compute',
    ),
    _IncTemplate(
      'Application crash',
      'orders-api',
      'Process exits with code 1 every few minutes.',
      OpsPriority.p2High,
      'systemd',
      ['journalctl -u', 'last deploy', 'config env', 'dependency health', 'core dumps'],
      'Missing env secret after secrets rotation.',
      'Restore secret; restart unit; verify health endpoint.',
      'rb-rotate-secrets',
    ),
    _IncTemplate(
      'Docker container restarting',
      'payments-sidecar',
      'Restart count climbing; CrashLoop-like pattern.',
      OpsPriority.p2High,
      'docker events',
      ['docker ps -a', 'logs --tail', 'healthcheck', 'resource limits', 'image tag'],
      'Bad config mount path after compose change.',
      'Fix volume path; redeploy; pin image digest.',
      'rb-restart-docker',
    ),
    _IncTemplate(
      'Terraform deployment failed',
      'infra-network module',
      'Apply fails mid-run; partial resources.',
      OpsPriority.p3Medium,
      'CI pipeline',
      ['Read error output', 'state lock', 'drift', 'IAM of runner', 'plan vs apply'],
      'State lock held by crashed runner + SG rule conflict.',
      'Careful unlock; import/resolve conflict; re-apply; postmortem.',
      'rb-tf-recover',
    ),
    _IncTemplate(
      'Pipeline failed',
      'github-actions prod-deploy',
      'Deploy stage red; prod not updated.',
      OpsPriority.p2High,
      'CI webhook',
      ['Job logs', 'failed test', 'artifact', 'permissions', 'last green commit'],
      'Integration test hit staging outage; deploy gated incorrectly on flaky test.',
      'Quarantine flaky test; redeploy known-good; fix staging.',
      'rb-pipeline-retry',
    ),
    _IncTemplate(
      'Load Balancer unhealthy targets',
      'app-alb',
      'All targets fail health checks on /health.',
      OpsPriority.p1Critical,
      'ALB metrics',
      ['Health check path/port', 'SG ALB→instance', 'App listening', 'AZ registration', 'recent change'],
      'Health check path changed in app but not ALB target group.',
      'Align health path; verify 200; tighten change process.',
      'rb-alb-health',
    ),
    _IncTemplate(
      'Security Group blocking traffic',
      'app ↔ redis',
      'Cache timeouts after network ticket.',
      OpsPriority.p2High,
      'customer',
      ['SG matrix', 'source ENI', 'port 6379', 'NACL', 'flow logs'],
      'SG update removed redis ingress from app SG.',
      'Restore rule; use IaC; peer review SG diffs.',
      'rb-sg-fix',
    ),
    _IncTemplate(
      'Route Table incorrect',
      'private-subnet-b',
      'No outbound package updates from private instances.',
      OpsPriority.p3Medium,
      'ops request',
      ['Route tables', '0.0.0.0/0 target', 'NAT health', 'subnet association', 'IGW misuse'],
      'Private subnet associated to public RT without NAT route.',
      'Associate correct RT with NAT; verify yum/apt; document.',
      'rb-route-fix',
    ),
    _IncTemplate(
      'Internet Gateway detached',
      'vpc-prod',
      'Public instances lost internet after maintenance.',
      OpsPriority.p1Critical,
      'change window',
      ['IGW attachment', 'public routes', 'ENI public IPs', 'change ticket'],
      'IGW accidentally detached during cleanup script.',
      'Re-attach IGW; fix routes; disable destructive scripts in prod.',
      'rb-igw-attach',
    ),
    _IncTemplate(
      'NAT Gateway unavailable',
      'nat-a',
      'Private subnet egress failing; 5xx on outbound APIs.',
      OpsPriority.p1Critical,
      'cloud health',
      ['NAT state', 'EIP', 'AZ impact', 'routes', 'failover NAT'],
      'NAT Gateway failed in single AZ; no secondary NAT.',
      'Failover route to healthy NAT; plan multi-AZ NAT/endpoints.',
      'rb-nat-failover',
    ),
    _IncTemplate(
      'Cloud Storage permission denied',
      's3://customer-backups',
      'App cannot PutObject after role change.',
      OpsPriority.p2High,
      'app logs',
      ['Bucket policy', 'IAM role', 'KMS key policy', 'VPC endpoint policy', 'CloudTrail deny'],
      'Bucket policy denies new task role principal.',
      'Update policy least-privilege; verify put; audit trail.',
      'rb-storage-acl',
    ),
    _IncTemplate(
      'IAM policy incorrect',
      'deploy-role',
      'CD cannot DescribeImages / UpdateService.',
      OpsPriority.p2High,
      'pipeline',
      ['CloudTrail AccessDenied', 'role policies', 'SCPs', 'permission boundary', 'last change'],
      'Permission boundary tightened without updating deploy policy.',
      'Grant required actions; document boundary process.',
      'rb-iam-fix',
    ),
    _IncTemplate(
      'Backup failed',
      'AWS Backup / vault-prod',
      'Nightly backup job failed 3 nights.',
      OpsPriority.p2High,
      'backup report',
      ['Job status', 'IAM for backup role', 'resource tags', 'vault policy', 'retention'],
      'Tag-based selection missed after retagging campaign.',
      'Fix tags; re-run backup; verify restore test.',
      'rb-backup-restore',
    ),
    _IncTemplate(
      'Cloud Monitoring alert flood',
      'ops workspace',
      'Pager flooded with non-actionable CPU alerts.',
      OpsPriority.p3Medium,
      'on-call',
      ['Alert thresholds', 'noise ratio', 'grouping', 'runbooks linked', 'SLO alignment'],
      'Thresholds too low post-scale event; no silence windows.',
      'Tune thresholds; add dampening; link runbooks.',
      'rb-alert-tune',
    ),
    _IncTemplate(
      'Kubernetes pod CrashLoopBackOff',
      'checkout-api',
      'Pods restarting; service partial outage.',
      OpsPriority.p1Critical,
      'kubectl',
      ['kubectl describe/logs', 'probes', 'configmap/secret', 'resource limits', 'rollout history'],
      'Bad secret after rotation; app cannot start.',
      'Fix secret; rollout restart; verify endpoints.',
      'rb-k8s-pod',
    ),
    _IncTemplate(
      'Customer cannot login (identity)',
      'SSO portal',
      'Users report authentication loop after IdP change.',
      OpsPriority.p1Critical,
      'service desk',
      ['IdP status', 'SAML/OIDC config', 'clock skew', 'recent change', 'error codes'],
      'ACS URL mismatch after IdP metadata update.',
      'Correct ACS; test SP flow; communicate ETA.',
      'rb-identity',
    ),
  ];
}

class _IncTemplate {
  const _IncTemplate(
    this.title,
    this.service,
    this.description,
    this.priority,
    this.source,
    this.steps,
    this.rootCause,
    this.resolution,
    this.runbookId,
  );

  final String title;
  final String service;
  final String description;
  final OpsPriority priority;
  final String source;
  final List<String> steps;
  final String rootCause;
  final String resolution;
  final String runbookId;
}
