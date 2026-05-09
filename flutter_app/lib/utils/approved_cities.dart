/// Approved city bounding boxes — only these cities are live in Barfliz.
/// Kept public so the geo-restriction logic can be unit-tested independently
/// of the Radar SDK.
class CityBounds {
  final String name;
  final double north;
  final double south;
  final double west;
  final double east;

  const CityBounds({
    required this.name,
    required this.north,
    required this.south,
    required this.west,
    required this.east,
  });

  bool contains(double lat, double lng) =>
      lat >= south && lat <= north && lng >= west && lng <= east;
}

const approvedCities = [
  CityBounds(name: 'Darwin',          north: -12.35, south: -12.55, west: 130.75, east: 131.05),
  CityBounds(name: 'Miami',           north:  25.87, south:  25.70, west: -80.35, east: -80.12),
  CityBounds(name: 'Fort Lauderdale', north:  26.20, south:  26.08, west: -80.22, east: -80.08),
];

/// Returns the name of the approved city containing [lat]/[lng], or null.
String? cityForLocation(double lat, double lng) {
  for (final city in approvedCities) {
    if (city.contains(lat, lng)) return city.name;
  }
  return null;
}
