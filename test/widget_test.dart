import 'package:cloudamned/data/content/roadmap_content.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app content catalog is production-scale', () {
    expect(RoadmapContent.modules.length, 20);
    expect(RoadmapContent.allLabs.length, greaterThan(120));
  });
}
