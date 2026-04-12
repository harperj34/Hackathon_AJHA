import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../theme.dart';
import '../../models.dart';
import '../services/event_service.dart';
import '../services/geo_service.dart';
import 'map_markers.dart';
import 'heatmap_layer.dart';

/// The full-screen FlutterMap with all marker layers.
/// Receives filtered data and callbacks from [_MapTabState].
class MapLayerStack extends StatelessWidget {
  final MapController mapController;
  final List<CampusEvent> filteredEvents;
  final List<StudySpot> filteredStudySpots;
  final bool showHeatmap;
  final bool showPlaces;
  final double currentZoom;
  final String? selectedEventId;
  final String? selectedStudySpotId;
  final String? selectedPlaceId;
  final String? selectedSignalId;
  final AnimationController signalPulseController;
  final void Function(CampusEvent) onEventTap;
  final void Function(StudySpot) onStudySpotTap;
  final void Function(CampusSignal) onSignalTap;
  final void Function(CampusPlace) onPlaceTap;
  final void Function(LatLng, double) onAnimateCameraTo;
  final VoidCallback onDismissPreview;

  const MapLayerStack({
    super.key,
    required this.mapController,
    required this.filteredEvents,
    required this.filteredStudySpots,
    required this.showHeatmap,
    required this.showPlaces,
    required this.currentZoom,
    required this.selectedEventId,
    required this.selectedStudySpotId,
    required this.selectedPlaceId,
    required this.selectedSignalId,
    required this.signalPulseController,
    required this.onEventTap,
    required this.onStudySpotTap,
    required this.onSignalTap,
    required this.onPlaceTap,
    required this.onAnimateCameraTo,
    required this.onDismissPreview,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: const LatLng(-37.9110, 145.13398),
        initialZoom: 16.2,
        minZoom: 14.5,
        maxZoom: 19.0,
        cameraConstraint: CameraConstraint.containCenter(
          bounds: LatLngBounds(
            const LatLng(-37.922, 145.120),
            const LatLng(-37.900, 145.148),
          ),
        ),
        onTap: (_, __) {
          if (selectedEventId != null) onDismissPreview();
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.universe.app',
          tileBuilder: (context, tileWidget, tile) => ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.88, 0.10, 0.02, 0, 6,
              0.04, 0.90, 0.06, 0, 6,
              0.04, 0.10, 0.86, 0, 10,
              0,    0,    0,    1, 0,
            ]),
            child: tileWidget,
          ),
        ),
        if (showHeatmap && !showPlaces)
          HeatmapLayer(
            points: GeoService.buildHeatPoints(
              events: sampleEvents,
              signals: activeSignals,
              studySpots: sampleStudySpots,
              isEventLive: EventService.isEventLive,
            ),
            zoom: currentZoom,
          ),
        if (!showPlaces) _buildEventMarkers(),
        if (showPlaces && currentZoom < 15.5) _buildClusterMarkers(context),
        if (currentZoom >= 15.5 && showPlaces) _buildPlaceMarkers(),
        if (!showPlaces) _buildStudySpotMarkers(),
        // ignore: dead_code
        if (false) _buildBusStopMarkers(),
        if (activeSignals.isNotEmpty && !showPlaces) _buildSignalMarkers(),
      ],
    );
  }

  // ── Event pins ────────────────────────────────────────────────────────────

  MarkerLayer _buildEventMarkers() {
    return MarkerLayer(
      markers: filteredEvents
          .where((event) => categoryInfo[event.category] != null)
          .map((event) {
            final info = categoryInfo[event.category]!;
            final isSelected = selectedEventId == event.id;
            final isLive = EventService.isEventLive(event);
            final countdown = EventService.getCountdown(event);
            final hasCountdown = countdown != null;
            final showLabel = (currentZoom >= 16.5) && !isLive;
            final double pinW = isSelected ? 34.0 : 28.0;
            final double pinH = isSelected ? 44.0 : 36.0;
            final double extraH =
                hasCountdown ? 42.0 : (showLabel ? 20.0 : 0.0);
            final double markerW =
                isLive ? 70.0 : (showLabel || hasCountdown ? 90.0 : pinW);
            final double markerH = isLive ? 72.0 : pinH + extraH;

            Widget pinWidget = MapEventPin(
              color: info.color,
              icon: info.icon,
              isSelected: isSelected,
              width: pinW,
              height: pinH,
            );

            if (isLive) {
              pinWidget = AnimatedBuilder(
                animation: signalPulseController,
                builder: (_, child) {
                  final t = signalPulseController.value;
                  final pulseRadius = pinW * 0.5 + t * (pinW * 0.55);
                  final pulseOpacity = (1.0 - t) * 0.45;
                  return SizedBox(
                    width: pinW,
                    height: pinH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.topCenter,
                      children: [
                        Positioned(
                          left: pinW / 2 - pulseRadius,
                          top: pinH * 0.28 - pulseRadius,
                          child: Container(
                            width: pulseRadius * 2,
                            height: pulseRadius * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: info.color.withOpacity(pulseOpacity),
                            ),
                          ),
                        ),
                        child!,
                      ],
                    ),
                  );
                },
                child: pinWidget,
              );
            }

            return Marker(
              point: event.position,
              width: markerW,
              height: markerH,
              alignment: Alignment.topCenter,
              rotate: true,
              child: GestureDetector(
                onTap: () => onEventTap(event),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: markerW,
                  height: markerH,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (showLabel || hasCountdown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: PinLabel(text: event.title, color: info.color),
                        ),
                      if (hasCountdown)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: CountdownBadge(
                            text: EventService.formatCountdown(countdown),
                            color: info.color,
                          ),
                        ),
                      pinWidget,
                    ],
                  ),
                ),
              ),
            );
          })
          .toList(),
    );
  }

  // ── Place clusters (zoomed out) ───────────────────────────────────────────

  MarkerLayer _buildClusterMarkers(BuildContext context) {
    return MarkerLayer(
      markers: GeoService.computeClusters(campusPlaces, currentZoom).map((cluster) {
        final isSingle = cluster.places.length == 1;
        return Marker(
          point: cluster.center,
          width: 44,
          height: 44,
          rotate: true,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {
              final targetZoom = (currentZoom + 2.0).clamp(0.0, 18.0);
              onAnimateCameraTo(cluster.center, targetZoom);
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: UniverseColors.accent,
                shape: BoxShape.circle,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: isSingle
                  ? Icon(cluster.places.first.icon, size: 20, color: Colors.white)
                  : Center(
                      child: Text(
                        '${cluster.places.length}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Permanent places (zoomed in) ──────────────────────────────────────────

  MarkerLayer _buildPlaceMarkers() {
    return MarkerLayer(
      markers: campusPlaces.map((place) {
        final isSelected = selectedPlaceId == place.id;
        final showLabel = isSelected || currentZoom >= 16.5;
        return Marker(
          point: place.position,
          width: showLabel ? 200 : 34,
          height: 34,
          rotate: true,
          alignment: Alignment.topCenter,
          child: GestureDetector(
            onTap: () => onPlaceTap(place),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? UniverseColors.accent
                          : UniverseColors.borderColor,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? UniverseColors.accent.withOpacity(0.25)
                            : const Color(0x22000000),
                        blurRadius: isSelected ? 8 : 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    place.icon,
                    size: 17,
                    color: isSelected
                        ? UniverseColors.accent
                        : const Color(0xFF888888),
                  ),
                ),
                if (showLabel)
                  Positioned(
                    left: 38,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: UniverseColors.accent,
                          width: 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: UniverseColors.textPrimary,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                size: 9,
                                color: Color(0xFFFFB800),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                place.rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: UniverseColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Study spot markers ────────────────────────────────────────────────────

  MarkerLayer _buildStudySpotMarkers() {
    return MarkerLayer(
      markers: filteredStudySpots.map((spot) {
        final color = categoryInfo[EventCategory.study]!.color;
        final bool isSelected = selectedStudySpotId == spot.id;
        final double size = isSelected ? 36.0 : 28.0;
        final bool showLabel = currentZoom >= 16.5;
        final double markerW = showLabel ? 90.0 : size;
        final double markerH = showLabel ? size + 18.0 : size;

        return Marker(
          point: spot.position,
          width: markerW,
          height: markerH,
          alignment: Alignment.topCenter,
          rotate: true,
          child: GestureDetector(
            onTap: () => onStudySpotTap(spot),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: markerW,
              height: markerH,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (showLabel)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: PinLabel(text: spot.title, color: color),
                    ),
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: Colors.white,
                        width: isSelected ? 3 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.40),
                          blurRadius: isSelected ? 12 : 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: isSelected ? 18 : 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Bus stop markers (hidden) ─────────────────────────────────────────────

  MarkerLayer _buildBusStopMarkers() {
    return MarkerLayer(
      markers: sampleBusStops.map((stop) {
        final showLabel = currentZoom >= 16.0;
        return Marker(
          point: stop.position,
          width: showLabel ? 80.0 : 36.0,
          height: showLabel ? 54.0 : 36.0,
          alignment: Alignment.topCenter,
          rotate: true,
          child: BusStopPin(stop: stop, showLabel: showLabel),
        );
      }).toList(),
    );
  }

  // ── Signal pins ───────────────────────────────────────────────────────────

  MarkerLayer _buildSignalMarkers() {
    return MarkerLayer(
      markers: activeSignals.map((signal) {
        final meta = signalCategoryMeta[signal.category]!;
        final isSelected = selectedSignalId == signal.id;
        return Marker(
          point: signal.position,
          width: 50.0,
          height: 50.0,
          alignment: Alignment.topCenter,
          rotate: true,
          child: GestureDetector(
            onTap: () => onSignalTap(signal),
            behavior: HitTestBehavior.opaque,
            child: SignalPin(
              color: meta.color,
              icon: meta.icon,
              isSelected: isSelected,
              pulseController: signalPulseController,
              imageUrl: signal.imageUrl,
            ),
          ),
        );
      }).toList(),
    );
  }
}
