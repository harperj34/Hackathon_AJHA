import 'dart:convert';
import 'dart:math' show pow;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../models.dart';

/// A geographic cluster of [CampusPlace] objects used at low zoom levels.
class PlaceCluster {
  final LatLng center;
  final List<CampusPlace> places;
  const PlaceCluster({required this.center, required this.places});
}

/// A weighted heat-map point used by the heatmap layer.
class HeatPoint {
  final LatLng position;
  final double intensity; // 0.0 – 1.0
  const HeatPoint(this.position, this.intensity);
}

/// Stateless geographic utilities: clustering, heat-point generation,
/// and reverse geocoding.
class GeoService {
  GeoService._();

  /// Groups [places] into geographic clusters for zoom levels below the
  /// individual-pin threshold. Grid cell size scales with zoom so clusters
  /// naturally break apart as the user zooms in.
  static List<PlaceCluster> computeClusters(
    List<CampusPlace> places,
    double zoom,
  ) {
    final cellSize = 0.005 * pow(2.0, (15.5 - zoom).clamp(0.0, 6.0));
    final Map<String, List<CampusPlace>> cells = {};
    for (final place in places) {
      final cx = (place.position.longitude / cellSize).floor();
      final cy = (place.position.latitude / cellSize).floor();
      cells.putIfAbsent('$cx,$cy', () => []).add(place);
    }
    return cells.values.map((group) {
      final lat =
          group.map((p) => p.position.latitude).reduce((a, b) => a + b) /
          group.length;
      final lng =
          group.map((p) => p.position.longitude).reduce((a, b) => a + b) /
          group.length;
      return PlaceCluster(center: LatLng(lat, lng), places: group);
    }).toList();
  }

  /// Builds weighted [HeatPoint] objects from current events, signals,
  /// and study spots.
  static List<HeatPoint> buildHeatPoints({
    required List<CampusEvent> events,
    required List<CampusSignal> signals,
    required List<StudySpot> studySpots,
    required bool Function(CampusEvent) isEventLive,
  }) {
    final pts = <HeatPoint>[];
    for (final e in events) {
      final attendeeScore = (e.attendees / 150.0).clamp(0.0, 1.0);
      final liveBonus = isEventLive(e) ? 0.25 : 0.0;
      final intensity = (attendeeScore * 0.85 + 0.15 + liveBonus).clamp(
        0.0,
        1.0,
      );
      pts.add(HeatPoint(e.position, intensity));
    }
    for (final s in signals) {
      pts.add(HeatPoint(s.position, 0.45));
    }
    for (final sp in studySpots) {
      pts.add(HeatPoint(sp.position, 0.12));
    }
    return pts;
  }

  /// Performs a reverse-geocode lookup via Nominatim and returns a
  /// human-readable location label. Falls back to [fallback] on any error.
  static Future<String> reverseGeocode(
    LatLng pos, {
    String fallback = 'Monash Clayton Campus',
  }) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}&format=json&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'UniverseMonashApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        if (addr != null) {
          final road = addr['road'] as String?;
          final number = addr['house_number'] as String?;
          final suburb =
              (addr['suburb'] ?? addr['city_district'] ?? addr['neighbourhood'])
                  as String?;
          if (road != null && number != null) return '$number $road';
          if (road != null) return suburb != null ? '$road, $suburb' : road;
          if (suburb != null) return suburb;
        }
        final display = (data['display_name'] as String?)
            ?.split(',')
            .first
            .trim();
        return display ?? fallback;
      }
    } catch (_) {
      // Network or parse error — fall through to fallback.
    }
    return fallback;
  }
}
