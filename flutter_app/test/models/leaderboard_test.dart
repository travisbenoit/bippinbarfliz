import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/screens/leaderboard/leaderboard_screen.dart';

void main() {
  // ── LeaderboardEntry ────────────────────────────────────────────────────────

  group('LeaderboardEntry', () {
    test('constructs with all required fields', () {
      final entry = LeaderboardEntry(
        userId: 'user-1',
        userName: 'Alice',
        totalXp: 1200,
        currentStreak: 5,
        totalCheckins: 18,
      );

      expect(entry.userId, 'user-1');
      expect(entry.userName, 'Alice');
      expect(entry.avatarUrl, isNull);
      expect(entry.totalXp, 1200);
      expect(entry.currentStreak, 5);
      expect(entry.totalCheckins, 18);
    });

    test('optional avatarUrl can be set', () {
      final entry = LeaderboardEntry(
        userId: 'user-2',
        userName: 'Bob',
        avatarUrl: 'https://example.com/avatar.jpg',
        totalXp: 300,
        currentStreak: 1,
        totalCheckins: 3,
      );
      expect(entry.avatarUrl, 'https://example.com/avatar.jpg');
    });

    test('zero values are valid', () {
      final entry = LeaderboardEntry(
        userId: 'user-3',
        userName: 'New User',
        totalXp: 0,
        currentStreak: 0,
        totalCheckins: 0,
      );
      expect(entry.totalXp, 0);
      expect(entry.currentStreak, 0);
      expect(entry.totalCheckins, 0);
    });
  });

  // ── UserChallenge ───────────────────────────────────────────────────────────

  group('UserChallenge', () {
    UserChallenge makeChallenge({
      String status = 'active',
      int progress = 0,
      int requirementCount = 5,
      int xpReward = 100,
    }) {
      return UserChallenge(
        id: 'uc-1',
        challengeId: 'first_checkin',
        status: status,
        progress: progress,
        challengeName: 'First Check-in',
        challengeDescription: 'Check in to any bar',
        xpReward: xpReward,
        requirementCount: requirementCount,
        challengeType: '',
      );
    }

    test('constructs with all fields correctly', () {
      final c = makeChallenge(status: 'active', progress: 2, requirementCount: 5);
      expect(c.id, 'uc-1');
      expect(c.challengeId, 'first_checkin');
      expect(c.status, 'active');
      expect(c.progress, 2);
      expect(c.requirementCount, 5);
      expect(c.xpReward, 100);
    });

    group('progress ratio', () {
      test('is 0.0 when no progress', () {
        final c = makeChallenge(progress: 0, requirementCount: 5);
        final ratio = c.requirementCount > 0
            ? (c.progress / c.requirementCount).clamp(0.0, 1.0)
            : 0.0;
        expect(ratio, 0.0);
      });

      test('is 1.0 when completed', () {
        final c = makeChallenge(progress: 5, requirementCount: 5);
        final ratio = (c.progress / c.requirementCount).clamp(0.0, 1.0);
        expect(ratio, 1.0);
      });

      test('is clamped to 1.0 even if progress exceeds target', () {
        final c = makeChallenge(progress: 99, requirementCount: 5);
        final ratio = (c.progress / c.requirementCount).clamp(0.0, 1.0);
        expect(ratio, 1.0);
      });

      test('is 0.0 when requirementCount is zero (guard)', () {
        final c = makeChallenge(progress: 3, requirementCount: 0);
        final ratio = c.requirementCount > 0
            ? (c.progress / c.requirementCount).clamp(0.0, 1.0)
            : 0.0;
        expect(ratio, 0.0);
      });
    });

    group('status values', () {
      for (final status in ['active', 'completed', 'expired', 'locked']) {
        test('status "$status" is accepted without error', () {
          expect(() => makeChallenge(status: status), returnsNormally);
        });
      }

      test('completed challenge contributes to XP sum', () {
        final challenges = [
          makeChallenge(status: 'completed', xpReward: 50),
          makeChallenge(status: 'completed', xpReward: 150),
          makeChallenge(status: 'active', xpReward: 200),
        ];

        final earned = challenges
            .where((c) => c.status == 'completed')
            .fold<int>(0, (sum, c) => sum + c.xpReward);

        expect(earned, 200);
      });

      test('active challenge does not contribute to XP sum', () {
        final challenges = [
          makeChallenge(status: 'active', xpReward: 500),
        ];
        final earned = challenges
            .where((c) => c.status == 'completed')
            .fold<int>(0, (sum, c) => sum + c.xpReward);
        expect(earned, 0);
      });
    });
  });

  // ── Leaderboard ranking logic ────────────────────────────────────────────────

  group('Leaderboard ranking', () {
    final entries = [
      LeaderboardEntry(userId: 'a', userName: 'Alice', totalXp: 900, currentStreak: 3, totalCheckins: 10),
      LeaderboardEntry(userId: 'b', userName: 'Bob',   totalXp: 600, currentStreak: 1, totalCheckins: 6),
      LeaderboardEntry(userId: 'c', userName: 'Carol', totalXp: 300, currentStreak: 0, totalCheckins: 2),
    ];

    test('entries sorted by XP descending puts highest first', () {
      final sorted = [...entries]
        ..sort((a, b) => b.totalXp.compareTo(a.totalXp));
      expect(sorted.first.userName, 'Alice');
      expect(sorted.last.userName, 'Carol');
    });

    test('can locate current user in entry list', () {
      const myId = 'b';
      final mine = entries.firstWhere((e) => e.userId == myId);
      expect(mine.userName, 'Bob');
    });

    test('returns null-safe when user is not in list', () {
      LeaderboardEntry? myEntry;
      try {
        myEntry = entries.firstWhere((e) => e.userId == 'unknown-id');
      } catch (_) {
        myEntry = null;
      }
      expect(myEntry, isNull);
    });
  });
}
