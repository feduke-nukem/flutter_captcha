import 'package:flutter_captcha/src/angle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Angle', () {
    test('Angle.all', () {
      expect(Angle.all().length, 4);
    });

    test('Angle.isSolved', () {
      expect(Angle.zero().isSolved, true);
      expect(Angle.quarter().isSolved, false);
      expect(Angle.third().isSolved, false);
      expect(Angle.half().isSolved, false);
    });

    test('Angle.hashCode', () {
      expect(Angle.zero().hashCode == Angle.zero().hashCode, isTrue);
      expect(Angle.quarter().hashCode == Angle.quarter().hashCode, isTrue);
      expect(Angle.third().hashCode == Angle.third().hashCode, isTrue);
      expect(Angle.half().hashCode == Angle.half().hashCode, isTrue);
    });

    test('Angle.==', () {
      expect(Angle.zero() == Angle.zero(), isTrue);
      expect(Angle.quarter() == Angle.quarter(), isTrue);
      expect(Angle.third() == Angle.third(), isTrue);
      expect(Angle.half() == Angle.half(), isTrue);
    });

    test('sum two quarters => equals Angle.half', () {
      expect(Angle.quarter() + Angle.quarter(), equals(Angle.half()));
    });

    test('multiply two quarters => equals Angle.half', () {
      expect((Angle.half() * 4).value, equals(2));
      expect((Angle.half() * 4).absoluteValue, equals(0));
    });
  });
}
