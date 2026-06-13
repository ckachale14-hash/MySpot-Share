import 'package:flutter_test/flutter_test.dart';
import 'package:myspot/core/utils/time_ago.dart';
import 'package:myspot/data/repositories/post_repository.dart';

void main() {
  group('parseEntities', () {
    test('extracts lowercased, de-duplicated hashtags and mentions', () {
      final r = parseEntities('Big #Win today #win @Founder thanks @founder #growth');
      expect(r.hashtags, ['win', 'growth']);
      expect(r.mentionHandles, ['founder']);
    });

    test('returns empty lists when there are no entities', () {
      final r = parseEntities('just a plain sentence');
      expect(r.hashtags, isEmpty);
      expect(r.mentionHandles, isEmpty);
    });
  });

  group('timeAgo', () {
    test('formats recent and older times compactly', () {
      final now = DateTime.now();
      expect(timeAgo(now), 'now');
      expect(timeAgo(now.subtract(const Duration(minutes: 5))), '5m');
      expect(timeAgo(now.subtract(const Duration(hours: 3))), '3h');
      expect(timeAgo(now.subtract(const Duration(days: 2))), '2d');
      expect(timeAgo(now.subtract(const Duration(days: 14))), '2w');
    });

    test('null is an empty string', () {
      expect(timeAgo(null), '');
    });
  });
}
