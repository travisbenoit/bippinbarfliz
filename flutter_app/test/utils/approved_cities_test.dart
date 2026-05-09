import 'package:flutter_test/flutter_test.dart';
import 'package:barfliz/utils/approved_cities.dart';

void main() {
  group('CityBounds.contains', () {
    const darwin = CityBounds(
      name: 'Darwin', north: -12.35, south: -12.55, west: 130.75, east: 131.05,
    );
    const miami = CityBounds(
      name: 'Miami', north: 25.87, south: 25.70, west: -80.35, east: -80.12,
    );
    const ftl = CityBounds(
      name: 'Fort Lauderdale', north: 26.20, south: 26.08, west: -80.22, east: -80.08,
    );

    group('Darwin', () {
      test('city centre is inside bounds', () {
        expect(darwin.contains(-12.4634, 130.8456), isTrue);
      });

      test('north boundary is inclusive', () {
        expect(darwin.contains(-12.35, 130.90), isTrue);
      });

      test('south boundary is inclusive', () {
        expect(darwin.contains(-12.55, 130.90), isTrue);
      });

      test('west boundary is inclusive', () {
        expect(darwin.contains(-12.46, 130.75), isTrue);
      });

      test('east boundary is inclusive', () {
        expect(darwin.contains(-12.46, 131.05), isTrue);
      });

      test('point just north of bounds is outside', () {
        expect(darwin.contains(-12.34, 130.90), isFalse);
      });

      test('point just south of bounds is outside', () {
        expect(darwin.contains(-12.56, 130.90), isFalse);
      });

      test('Miami coordinates are not inside Darwin', () {
        expect(darwin.contains(25.77, -80.19), isFalse);
      });
    });

    group('Miami', () {
      test('downtown Miami is inside bounds', () {
        expect(miami.contains(25.77, -80.19), isTrue);
      });

      test('South Beach is inside bounds', () {
        expect(miami.contains(25.79, -80.13), isTrue);
      });

      test('point above north boundary is outside', () {
        expect(miami.contains(25.88, -80.20), isFalse);
      });

      test('point below south boundary is outside', () {
        expect(miami.contains(25.69, -80.20), isFalse);
      });

      test('point east of east boundary is outside', () {
        expect(miami.contains(25.77, -80.11), isFalse);
      });

      test('Darwin coordinates are not inside Miami', () {
        expect(miami.contains(-12.46, 130.84), isFalse);
      });
    });

    group('Fort Lauderdale', () {
      test('downtown Fort Lauderdale is inside bounds', () {
        expect(ftl.contains(26.12, -80.14), isTrue);
      });

      test('Las Olas area is inside bounds', () {
        expect(ftl.contains(26.119, -80.136), isTrue);
      });

      test('point above north boundary is outside', () {
        expect(ftl.contains(26.21, -80.14), isFalse);
      });

      test('point below south boundary is outside', () {
        expect(ftl.contains(26.07, -80.14), isFalse);
      });

      test('Miami coordinates are not inside Fort Lauderdale', () {
        expect(ftl.contains(25.77, -80.19), isFalse);
      });
    });
  });

  group('cityForLocation', () {
    test('returns Darwin for Darwin centre', () {
      expect(cityForLocation(-12.4634, 130.8456), 'Darwin');
    });

    test('returns Miami for downtown Miami', () {
      expect(cityForLocation(25.77, -80.19), 'Miami');
    });

    test('returns Fort Lauderdale for Las Olas', () {
      expect(cityForLocation(26.119, -80.136), 'Fort Lauderdale');
    });

    test('returns null for New York', () {
      expect(cityForLocation(40.71, -74.00), isNull);
    });

    test('returns null for London', () {
      expect(cityForLocation(51.50, -0.12), isNull);
    });

    test('returns null for Sydney (not approved despite being AU)', () {
      expect(cityForLocation(-33.87, 151.21), isNull);
    });

    test('returns null for Orlando FL (wrong Florida city)', () {
      expect(cityForLocation(28.54, -81.38), isNull);
    });

    test('returns null for 0,0 null-island', () {
      expect(cityForLocation(0.0, 0.0), isNull);
    });

    // Boundary: gap between Miami and Fort Lauderdale (26.00 is in neither)
    test('returns null for lat between Miami and Fort Lauderdale', () {
      expect(cityForLocation(26.00, -80.20), isNull);
    });
  });

  group('approvedCities list', () {
    test('contains exactly 3 cities', () {
      expect(approvedCities.length, 3);
    });

    test('first entry is Darwin', () {
      expect(approvedCities[0].name, 'Darwin');
    });

    test('second entry is Miami', () {
      expect(approvedCities[1].name, 'Miami');
    });

    test('third entry is Fort Lauderdale', () {
      expect(approvedCities[2].name, 'Fort Lauderdale');
    });

    test('no two cities share the same bounding box', () {
      for (var i = 0; i < approvedCities.length; i++) {
        for (var j = i + 1; j < approvedCities.length; j++) {
          final a = approvedCities[i];
          final b = approvedCities[j];
          // Boxes with different hemispheres can't overlap
          final latOverlap = a.south <= b.north && b.south <= a.north;
          final lngOverlap = a.west <= b.east && b.west <= a.east;
          expect(
            latOverlap && lngOverlap,
            isFalse,
            reason: '${a.name} and ${b.name} must not overlap',
          );
        }
      }
    });
  });
}
