import 'dart:math';

enum FailureKind {
  diskCorruption,
  instanceCrash,
  regionOutage,
  azFailure,
  dnsPropagation,
  sslExpiration,
  iamPermission,
  firewallMisconfig,
  terraformState,
  pipelineFailure,
  memoryExhaustion,
  storageFull,
  highCpu,
  databaseDeadlock,
  networkPartition,
  packetLoss,
  certificateMismatch,
  kernelPanic,
  containerCrashLoop,
}

class SimulatedFailure {
  SimulatedFailure({
    required this.id,
    required this.kind,
    required this.title,
    required this.symptoms,
    required this.logs,
    required this.remediationHints,
    this.resolved = false,
  });

  final String id;
  final FailureKind kind;
  final String title;
  final String symptoms;
  final List<String> logs;
  final List<String> remediationHints;
  bool resolved;
}

/// Injects realistic failures — nothing always works.
class FailureEngine {
  FailureEngine([int? seed]) : _rng = Random(seed);

  final Random _rng;
  final List<SimulatedFailure> active = [];
  final List<SimulatedFailure> history = [];

  SimulatedFailure inject([FailureKind? kind]) {
    final k = kind ?? FailureKind.values[_rng.nextInt(FailureKind.values.length)];
    final f = _build(k);
    active.add(f);
    return f;
  }

  void resolve(String id) {
    final i = active.indexWhere((f) => f.id == id);
    if (i < 0) return;
    active[i].resolved = true;
    history.insert(0, active.removeAt(i));
  }

  SimulatedFailure _build(FailureKind k) {
    final id = 'fail-${DateTime.now().millisecondsSinceEpoch}-${_rng.nextInt(999)}';
    return switch (k) {
      FailureKind.diskCorruption => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Disk corruption on data volume',
          symptoms: 'I/O errors, app 500s, filesystem remount read-only',
          logs: [
            'kernel: BLK_STS_IOERR status=0x0',
            'ext4: I/O error while writing superblock',
            'app: disk quota / write failed EIO',
          ],
          remediationHints: ['Snapshot if possible', 'Replace volume from backup', 'fsck offline'],
        ),
      FailureKind.instanceCrash => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Instance crash / unexpected stop',
          symptoms: 'Health checks fail, no SSH',
          logs: ['CloudWatch: StatusCheckFailed_Instance=1', 'hypervisor: instance reachability check failed'],
          remediationHints: ['Start instance', 'Replace from ASG', 'Check system log'],
        ),
      FailureKind.azFailure => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Availability Zone impairment',
          symptoms: 'Targets in one AZ unhealthy; elevated latency',
          logs: ['AWS Health: AZ power event (simulated)', 'ALB: unhealthy host count rising in az-a'],
          remediationHints: ['Shift traffic', 'Scale in other AZs', 'Verify multi-AZ design'],
        ),
      FailureKind.regionOutage => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Region-level service degradation',
          symptoms: 'Control plane slow; cross-region failover needed',
          logs: ['Service Health Dashboard: elevated error rates', 'API: RequestLimitExceeded spikes'],
          remediationHints: ['DR runbook', 'Failover DNS', 'Communicate SEV-1'],
        ),
      FailureKind.sslExpiration => SimulatedFailure(
          id: id,
          kind: k,
          title: 'TLS certificate expired',
          symptoms: 'Browsers show NET::ERR_CERT_DATE_INVALID',
          logs: ['nginx: SSL_CTX_use_certificate failed', 'ALB: certificate expired'],
          remediationHints: ['Issue/renew ACM or cert', 'Attach listener cert', 'Add expiry alarm'],
        ),
      FailureKind.iamPermission => SimulatedFailure(
          id: id,
          kind: k,
          title: 'IAM permission denied',
          symptoms: 'Deploy role cannot DescribeImages / PutObject',
          logs: ['AccessDenied: User is not authorized to perform: ec2:DescribeImages', 'CloudTrail event deny'],
          remediationHints: ['Least-privilege grant', 'Check SCP', 'Validate instance profile'],
        ),
      FailureKind.firewallMisconfig => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Security group / NACL misconfiguration',
          symptoms: 'Timeouts to :443; ICMP unreachable',
          logs: ['VPC Flow Log: REJECT tcp 443', 'curl: Connection timed out'],
          remediationHints: ['Review SG ingress', 'NACL ephemeral ports', 'Route tables'],
        ),
      FailureKind.terraformState => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Terraform state corruption / lock',
          symptoms: 'state lock timeout; resource drift',
          logs: ['Error acquiring the state lock', 'Resource already exists'],
          remediationHints: ['force-unlock carefully', 'import', 'refresh + plan'],
        ),
      FailureKind.pipelineFailure => SimulatedFailure(
          id: id,
          kind: k,
          title: 'CI/CD pipeline failed',
          symptoms: 'Deploy stage red; prod not updated',
          logs: ['##[error] Process completed with exit code 1', 'Tests failed: health endpoint 503'],
          remediationHints: ['Read job logs', 'Rollback artifact', 'Fix tests'],
        ),
      FailureKind.containerCrashLoop => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Container CrashLoopBackOff',
          symptoms: 'Pods restarting; service partial',
          logs: ['Back-off restarting failed container', 'OOMKilled', 'Error: config file not found'],
          remediationHints: ['kubectl describe/logs', 'Fix config/limits', 'Rollback deploy'],
        ),
      FailureKind.highCpu => SimulatedFailure(
          id: id,
          kind: k,
          title: 'High CPU saturation',
          symptoms: 'Latency up; autoscaling thrash',
          logs: ['CPUUtilization 95%', 'load average 18.2'],
          remediationHints: ['Scale out', 'Profile hot path', 'rate limit'],
        ),
      FailureKind.storageFull => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Disk full',
          symptoms: 'Writes fail; logs stop',
          logs: ['No space left on device', 'df -h: /var 100%'],
          remediationHints: ['Purge logs', 'Expand volume', 'logrotate'],
        ),
      FailureKind.databaseDeadlock => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Database deadlock / lock wait',
          symptoms: 'API timeouts on write paths',
          logs: ['deadlock detected', 'Lock wait timeout exceeded'],
          remediationHints: ['Kill blockers', 'Index/query fix', 'retry logic'],
        ),
      FailureKind.networkPartition => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Network partition between tiers',
          symptoms: 'App cannot reach DB intermittently',
          logs: ['Connection reset by peer', 'NACL asymetric deny (sim)'],
          remediationHints: ['Trace path', 'SG both ways', 'MTU/VPN checks'],
        ),
      FailureKind.dnsPropagation => SimulatedFailure(
          id: id,
          kind: k,
          title: 'DNS propagation / misrecord',
          symptoms: 'Some users hit old IP',
          logs: ['dig: ANSWER old A record', 'TTL 3600 still cached'],
          remediationHints: ['Lower TTL pre-change', 'verify records', 'flush resolvers'],
        ),
      FailureKind.memoryExhaustion => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Memory exhaustion / OOM',
          symptoms: 'Process killed; restarts',
          logs: ['Out of memory: Kill process', 'oom_reaper'],
          remediationHints: ['Raise limits', 'fix leak', 'scale mem'],
        ),
      FailureKind.packetLoss => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Packet loss on path',
          symptoms: 'Intermittent timeouts',
          logs: ['ping: 12% packet loss', 'retransmits rising'],
          remediationHints: ['mtr/traceroute', 'AZ path', 'provider ticket'],
        ),
      FailureKind.certificateMismatch => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Certificate name mismatch',
          symptoms: 'SSL_ERROR_BAD_CERT_DOMAIN',
          logs: ['subject does not match host', 'SNI missing'],
          remediationHints: ['Correct SAN', 'SNI config', 'listener host header'],
        ),
      FailureKind.kernelPanic => SimulatedFailure(
          id: id,
          kind: k,
          title: 'Kernel panic',
          symptoms: 'Instance unreachable until reboot',
          logs: ['Kernel panic - not syncing', 'stack trace (sim)'],
          remediationHints: ['Console output', 'replace node', 'kernel/driver audit'],
        ),
    };
  }
}
