import 'package:cloudamned/data/content/career_projects.dart';
import 'package:cloudamned/data/content/skills_catalog.dart';
import 'package:cloudamned/domain/entities/career_project.dart';
import 'package:cloudamned/simulation/career/career_sim_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ABC Manufacturing project exists', () {
    final p = CareerProjects.byId('proj-abc-mfg');
    expect(p, isNotNull);
    expect(p!.customerName, contains('ABC Manufacturing'));
    expect(p.budgetMonthly, 25000);
    expect(p.currency, 'RM');
    expect(p.timelineWeeks, 6);
  });

  test('lifecycle has 20 steps', () {
    expect(ProjectStep.values.length, 20);
  });

  test('skills catalog has over 100 skills', () {
    expect(SkillsCatalog.baseSkills().length, greaterThan(100));
  });

  test('career engine advances on valid requirements step', () {
    final engine = CareerSimEngine()..startProject('proj-abc-mfg');
    final p = engine.active!;
    final result = engine.submitStep({
      'goals': p.businessGoals,
      'budgetAcknowledged': true,
      'timelineAcknowledged': true,
    });
    expect(result.ok, isTrue);
    expect(engine.currentStepIndex, 1);
  });
}
