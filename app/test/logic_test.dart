import 'package:flutter_test/flutter_test.dart';
import 'package:myspot/core/utils/time_ago.dart';
import 'package:myspot/data/repositories/post_repository.dart';
import 'package:myspot/features/notifications/push_service.dart';

void main() {
  group('pushTargetPath', () {
    test('routes message / engagement / follow payloads', () {
      expect(pushTargetPath({'type': 'message', 'conversationId': 'c1'}),
          '/chat/c1');
      expect(pushTargetPath({'type': 'like', 'postId': 'p1'}), '/post/p1');
      expect(pushTargetPath({'type': 'comment', 'postId': 'p2'}), '/post/p2');
      expect(pushTargetPath({'type': 'mention', 'postId': 'p3'}), '/post/p3');
      expect(pushTargetPath({'type': 'follow', 'actorUid': 'u1'}), '/u/u1');
    });

    test('returns null for unknown or incomplete payloads', () {
      expect(pushTargetPath({'type': 'system'}), isNull);
      expect(pushTargetPath({'type': 'message', 'conversationId': ''}), isNull);
      expect(pushTargetPath(const {}), isNull);
    });
  });

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
