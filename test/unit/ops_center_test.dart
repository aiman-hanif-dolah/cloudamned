import 'package:cloudamned/simulation/ops/incident_catalog.dart';
import 'package:cloudamned/simulation/ops/ops_center_engine.dart';
import 'package:cloudamned/simulation/ops/ops_interview.dart';
import 'package:cloudamned/simulation/ops/runbook_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incident catalog generates tickets with investigation steps', () {
    final t = IncidentCatalog.generate();
    expect(t.number, startsWith('OPS'));
    expect(t.investigationSteps, isNotEmpty);
    expect(t.correctRootCause, isNotEmpty);
  });

  test('runbook catalog is non-empty', () {
    expect(RunbookCatalog.all.length, greaterThan(15));
    expect(RunbookCatalog.byId('rb-restart-service'), isNotNull);
  });

  test('ops center assign and evidence flow', () {
    final ops = OpsCenterEngine();
    final n = ops.queue.first.number;
    ops.assign(n);
    final t = ops.byNumber(n)!;
    expect(t.assignedEngineer, isNotEmpty);
    ops.collectEvidence(n, 'monitoring_dashboard');
    ops.collectEvidence(n, 'security_groups');
    expect(ops.byNumber(n)!.evidenceCollected.length, 2);
  });

  test('ops interview grades structured answers higher', () {
    final q = OpsInterviewBank.questions.first;
    final weak = OpsInterviewBank.grade(q, 'idk restart it');
    final strong = OpsInterviewBank.grade(
      q,
      'First check instance state and status checks, then security group for port 22, '
      'routes and public IP, then key pair. Prefer SSM over opening SSH widely.',
    );
    expect(strong.overall, greaterThan(weak.overall));
  });
}
