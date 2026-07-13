import 'package:cloudamned/data/content/roadmap_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('roadmap has 20 modules', () {
    expect(RoadmapContent.modules.length, 20);
  });

  test('roadmap has over 120 labs', () {
    expect(RoadmapContent.allLabs.length, greaterThan(120));
  });

  test('lab ids are unique', () {
    final ids = RoadmapContent.allLabs.map((l) => l.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('modules ordered 1..20', () {
    for (var i = 0; i < 20; i++) {
      expect(RoadmapContent.modules[i].order, i + 1);
    }
  });
}
