import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ezer_fresh/src/core/providers/user_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseUserCreatedAt', () {
    test('parses Firestore timestamps', () {
      final date = DateTime.utc(2026, 6, 19, 7, 30);

      expect(parseUserCreatedAt(Timestamp.fromDate(date))?.toUtc(), date);
    });

    test('parses legacy ISO strings', () {
      final date = DateTime.utc(2026, 6, 19, 7, 30);

      expect(parseUserCreatedAt(date.toIso8601String()), date);
    });

    test('returns null for invalid or missing values', () {
      expect(parseUserCreatedAt('not-a-date'), isNull);
      expect(parseUserCreatedAt(null), isNull);
    });
  });
}
