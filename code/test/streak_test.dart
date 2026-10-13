import 'package:flutter_test/flutter_test.dart';
import 'package:coach_app/checkin/checkin.dart';
import 'package:coach_app/home/today_tab.dart';

CheckIn _on(int day) => CheckIn(
  datum: DateTime(2026, 10, day),
  training: 'a',
  ernaehrung: 'b',
  schlaf: 'c',
  mindset: 'd',
);

void main() {
  final today = DateTime(2026, 10, 12, 20);

  test('counts days in a row up to today', () {
    expect(checkInStreak([_on(10), _on(11), _on(12)], today), 3);
  });

  test('a gap ends the row', () {
    expect(checkInStreak([_on(8), _on(10), _on(11), _on(12)], today), 3);
  });

  test('no check-in yet today keeps yesterday\'s row', () {
    expect(checkInStreak([_on(10), _on(11)], today), 2);
    expect(checkInStreak([], today), 0);
  });

  test('last seven days, today last', () {
    expect(lastSevenDays([_on(6), _on(12)], today), [
      true,
      false,
      false,
      false,
      false,
      false,
      true,
    ]);
  });
}
