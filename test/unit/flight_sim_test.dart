import 'package:cloudamned/simulation/career/career_rank.dart';
import 'package:cloudamned/simulation/career/discovery_engine.dart';
import 'package:cloudamned/simulation/career/flight_sim_controller.dart';
import 'package:cloudamned/simulation/career/project_generator.dart';
import 'package:cloudamned/simulation/failure/failure_engine.dart';
import 'package:cloudamned/simulation/well_architected/wa_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('project generator creates unique customers', () {
    final g = ProjectGenerator(42);
    final a = g.generate();
    final b = g.generate();
    expect(a.id, isNot(b.id));
    expect(a.customerName, isNotEmpty);
    expect(a.budgetMonthly, greaterThan(0));
  });

  test('discovery tracks critical coverage', () {
    final p = ProjectGenerator(1).generate();
    final d = DiscoveryEngine()..start(p);
    expect(d.coverage, 0);
    d.ask('What is the monthly budget envelope?');
    expect(d.askedIds.contains('budget'), isTrue);
    expect(d.coverage, greaterThan(0));
  });

  test('career rank promotes with xp', () {
    final p = CareerProgression();
    expect(p.rank, CareerRank.graduateEngineer);
    p.addXp(500);
    expect(p.rank, CareerRank.cloudEngineer);
  });

  test('failure engine injects and resolves', () {
    final f = FailureEngine(1);
    final x = f.inject(FailureKind.sslExpiration);
    expect(f.active, isNotEmpty);
    f.resolve(x.id);
    expect(f.active, isEmpty);
    expect(f.history, isNotEmpty);
  });

  test('well-architected scorer rewards multi-az private data', () {
    final s = WellArchitectedScorer();
    final weak = s.score(
      components: {'EC2'},
      multiAz: false,
      privateData: false,
      backups: false,
      monitoring: false,
      leastPrivilege: false,
      encryption: false,
      costTags: false,
      asgOrServerless: false,
      sustainabilityNotes: false,
    );
    final strong = s.score(
      components: {'ALB', 'ASG', 'Multi-AZ', 'Private subnet', 'WAF', 'CloudTrail', 'KMS'},
      multiAz: true,
      privateData: true,
      backups: true,
      monitoring: true,
      leastPrivilege: true,
      encryption: true,
      costTags: true,
      asgOrServerless: true,
      sustainabilityNotes: true,
    );
    expect(strong.overall, greaterThan(weak.overall));
  });

  test('flight controller generates project and injects failure', () {
    final flight = FlightSimController();
    final p = flight.generateProject();
    expect(p.customerName, isNotEmpty);
    final fail = flight.injectFailure();
    expect(fail.title, isNotEmpty);
    expect(flight.forensics.bundles()['Alerts'], isNotEmpty);
  });
}
