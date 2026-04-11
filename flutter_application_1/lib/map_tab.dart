import 'dart:async';
import 'dart:convert';
import 'dart:math' show pow;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';
import 'models.dart';
import 'map/services/event_service.dart';
import 'map/services/geo_service.dart';
import 'map/widgets/map_markers.dart';
import 'map/widgets/heatmap_layer.dart';
import 'map/widgets/map_controls.dart';
import 'map/widgets/sheet_widgets.dart';
import 'map/panels/signal_panel.dart';
import 'map/panels/happening_now_panel.dart';
import 'map/panels/event_detail_panel.dart';
import 'map/panels/place_panel.dart';
import 'map/panels/study_spot_panel.dart';
import 'map/sheets/signal_customization_sheet.dart';
import 'map/sheets/pin_customization_sheet.dart';

class MapTab extends StatefulWidget {
  const MapTab({super.key});

  @override
  State<MapTab> createState() => _MapTabState();
}

class _MapTabState extends State<MapTab> with TickerProviderStateMixin {
  late final MapController _mapController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.90);

  EventCategory? _activeFilter;
  CampusEvent? _selectedEvent;
  StudySpot? _selectedStudySpot;
  bool _isGoing = false;
  String _searchQuery = '';
  bool _showTransport = false;
  bool _showHeatmap = false;
  double _currentZoom = 15.5;
  bool _headerCollapsed = false;
  double _sheetExtent = _kCollapsed;
  bool _placementMode = false;
  bool _signalPlacementMode = false;
  bool _pinLifted = false;
  final Map<String, int> _confirmations = {};
  final Map<String, int> _outdatedVotes = {};
  final Set<String> _savedItems = {};
  final Set<String> _likedItems = {};
  final Set<String> _dislikedItems = {};
  String _pendingPinAddress = 'Monash Clayton Campus';
  StreamSubscription<MapEvent>? _mapEventSub;
  final Map<String, DateTime> _tempExpiry = {};
  final List<Timer> _expiryTimers = [];

  // â”€â”€ Signal state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  CampusSignal? _selectedSignal;
  CampusPlace? _selectedPlace;
  bool _addMenuOpen = false;
  bool _showPlaces = false;
  DateTime? _lastSignalDropTime;
  static const Duration _signalCooldown = Duration(minutes: 5);
  static const Duration _signalLifetime = Duration(minutes: 30);
  AnimationController? _signalPulseController;
  Timer? _countdownTimer;

  static const double _kCollapsed = 0.20;
  static const double _kPreview = 0.38;
  static const double _kExpanded = 0.85;

  bool get _hideFloatingMapControls => _sheetExtent >= (_kExpanded - 0.01);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _signalPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    _sheetController.addListener(() {
      if (!mounted || !_sheetController.isAttached) return;
      final extent = _sheetController.size.clamp(0.10, _kExpanded);
      if ((extent - _sheetExtent).abs() > 0.005) {
        setState(() => _sheetExtent = extent);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapEventSub = _mapController.mapEventStream.listen((event) {
        if (!mounted) return;
        if (event is MapEventMoveStart || event is MapEventScrollWheelZoom) {
          if (!_headerCollapsed) setState(() => _headerCollapsed = true);
          if ((_placementMode || _signalPlacementMode) && !_pinLifted)
            setState(() => _pinLifted = true);
        }
        if (event is MapEventMoveEnd) {
          if ((_placementMode || _signalPlacementMode) && _pinLifted)
            setState(() => _pinLifted = false);
          if (_placementMode || _signalPlacementMode)
            _reverseGeocode(_mapController.camera.center);
        }
        final z = _mapController.camera.zoom;
        if ((z - _currentZoom).abs() > 0.08) {
          setState(() => _currentZoom = z);
        }
      });
    });
  }

  List<CampusEvent> get _filteredEvents {
    // Remove expired temporary events first
    final now = DateTime.now();
    final expired = _tempExpiry.entries
        .where((e) => e.value.isBefore(now))
        .map((e) => e.key)
        .toList();
    if (expired.isNotEmpty) {
      for (final id in expired) {
        sampleEvents.removeWhere((ev) => ev.id == id);
        _tempExpiry.remove(id);
      }
    }

    return sampleEvents.where((e) {
      final matchesFilter =
          _activeFilter == null || e.category == _activeFilter;
      final matchesSearch =
          _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.location.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.subtitle.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  List<StudySpot> get _filteredStudySpots {
    return sampleStudySpots.where((s) {
      final matchesFilter =
          _activeFilter == null || _activeFilter == EventCategory.study;
      final matchesSearch =
          _searchQuery.isEmpty ||
          s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void _onFilterTap(EventCategory cat) {
    setState(() {
      _activeFilter = _activeFilter == cat ? null : cat;
      _selectedEvent = null;
      _selectedStudySpot = null;
      _showPlaces = false;
    });
    _sheetController.animateTo(
      _kCollapsed,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onDragHandleTap() {
    if (!_sheetController.isAttached) return;
    final next = _sheetExtent < _kPreview - 0.01 ? _kPreview : _kExpanded;
    _sheetController.animateTo(
      next,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onPinTap(CampusEvent event) {
    setState(() {
      _selectedEvent = event;
      _selectedStudySpot = null;
      _isGoing = false;
    });
    _animateCameraTo(event.position, 17.0);
    _sheetController.animateTo(
      _kPreview,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _onStudyPinTap(StudySpot spot) {
    setState(() {
      _selectedStudySpot = spot;
      _selectedEvent = null;
      _isGoing = false;
    });
    _animateCameraTo(spot.position, 17.0);
    _sheetController.animateTo(
      _kPreview,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _dismissPreview() {
    setState(() {
      _selectedEvent = null;
      _selectedStudySpot = null;
      _selectedSignal = null;
      _selectedPlace = null;
    });
    _sheetController.animateTo(
      _kCollapsed,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  /// Smooth easeInOut camera pan + zoom animation (~350 ms).
  void _animateCameraTo(LatLng target, double targetZoom) {
    final startLat = _mapController.camera.center.latitude;
    final startLng = _mapController.camera.center.longitude;
    final startZoom = _mapController.camera.zoom;
    final controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    final animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );
    animation.addListener(() {
      if (!mounted) {
        controller.dispose();
        return;
      }
      final t = animation.value;
      _mapController.move(
        LatLng(
          startLat + (target.latitude - startLat) * t,
          startLng + (target.longitude - startLng) * t,
        ),
        startZoom + (targetZoom - startZoom) * t,
      );
    });
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });
    controller.forward();
  }

  void _onPageChanged(int index) {
    if (index < _filteredEvents.length) {
      _animateCameraTo(_filteredEvents[index].position, 16.0);
    }
  }

  void _scheduleExpiry(String id, Duration duration) {
    final timer = Timer(duration, () {
      if (!mounted) return;
      setState(() {
        sampleEvents.removeWhere((e) => e.id == id);
        _tempExpiry.remove(id);
      });
    });
    _expiryTimers.add(timer);
  }

  void _addTemporaryEvent(
    EventCategory category,
    String title,
    String location,
  ) {
    final center =
        _mapController.camera.center ?? const LatLng(-37.9110, 145.1335);
    final id = 't${DateTime.now().millisecondsSinceEpoch}';
    final ev = CampusEvent(
      id: id,
      title: title,
      subtitle: 'User',
      location: location.isEmpty ? 'Campus' : location,
      time: 'Now',
      imageUrl: '',
      category: category,
      position: center,
      attendees: 0,
    );
    setState(() {
      sampleEvents.add(ev);
      _tempExpiry[id] = DateTime.now().add(const Duration(hours: 2));
    });
    _scheduleExpiry(id, const Duration(hours: 2));
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  // DROP A SIGNAL
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  bool get _canDropSignal {
    if (_lastSignalDropTime == null) return true;
    return DateTime.now().difference(_lastSignalDropTime!) >= _signalCooldown;
  }

  Duration get _signalCooldownRemaining {
    if (_lastSignalDropTime == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastSignalDropTime!);
    final remaining = _signalCooldown - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void _onSignalPinTap(CampusSignal signal) {
    setState(() {
      _selectedSignal = signal;
      _selectedEvent = null;
      _selectedStudySpot = null;
    });
    _animateCameraTo(signal.position, 17.0);
    _sheetController.animateTo(
      _kPreview,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _dropSignal(
    String message,
    SignalCategory category,
    LatLng position, {
    String? imageUrl,
    String? notes,
  }) {
    final now = DateTime.now();
    final id = 'sig_${now.millisecondsSinceEpoch}';
    final signal = CampusSignal(
      id: id,
      message: message,
      category: category,
      position: position,
      createdAt: now,
      expiresAt: now.add(_signalLifetime),
      imageUrl: imageUrl,
      notes: notes,
    );
    setState(() {
      activeSignals.add(signal);
      _lastSignalDropTime = now;
      _selectedSignal = signal;
      _selectedEvent = null;
      _selectedStudySpot = null;
    });
    // Schedule removal
    final timer = Timer(_signalLifetime, () {
      if (!mounted) return;
      setState(() {
        activeSignals.removeWhere((s) => s.id == id);
        if (_selectedSignal?.id == id) _selectedSignal = null;
      });
    });
    _expiryTimers.add(timer);
    _animateCameraTo(position, 17.5);
    _sheetController.animateTo(
      _kPreview,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.sensors_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Signal sent to nearby students!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _signalPulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final sheetTop = screenHeight * (1 - _sheetExtent);

    // Confirm bar always anchored to screen bottom; SafeArea inside handles nav bar.
    const confirmBarHeight = 50.0;
    const confirmBarBottom = 0.0;
    // Controls column is ~132 px tall. Keep a 16 px breathing gap above the panel.
    const controlsHeight = 132.0;
    const controlsGap = 16.0;
    const fabHeight = 56.0; // standard FloatingActionButton size
    // Both widgets use (sheetTop - controlsGap - ownHeight) so their bottom edges
    // sit at the same y-position â€” identical gap from the panel.
    final mapControlsTop = _placementMode
        ? (screenHeight -
                  safeBottom -
                  confirmBarHeight -
                  controlsGap -
                  controlsHeight)
              .clamp(safeTop + 12, screenHeight)
        : (sheetTop - controlsGap - controlsHeight).clamp(
            safeTop + 12,
            screenHeight,
          );
    final addPinTop = _placementMode
        ? screenHeight // off screen â€” hidden
        : (sheetTop - controlsGap - fabHeight).clamp(
            safeTop + 12,
            screenHeight,
          );

    return Stack(
      children: [
        // â”€â”€ Light Map â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        FlutterMap(
          mapController: _mapController,
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
              if (_selectedEvent != null) _dismissPreview();
            },
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.universe.app',
              // Slight desaturation for a refined, editorial map feel
              tileBuilder: (context, tileWidget, tile) => ColorFiltered(
                colorFilter: const ColorFilter.matrix([
                  0.88, 0.10, 0.02, 0, 6,
                  0.04, 0.90, 0.06, 0, 6,
                  0.04, 0.10, 0.86, 0, 10,
                  0, 0, 0, 1, 0,
                ]),
                child: tileWidget,
              ),
            ),
            // â”€â”€ Heatmap blobs (above base map, below pins) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_showHeatmap && !_showPlaces)
              HeatmapLayer(
                points: GeoService.buildHeatPoints(
                  events: sampleEvents,
                  signals: activeSignals,
                  studySpots: sampleStudySpots,
                  isEventLive: EventService.isEventLive,
                ),
                zoom: _currentZoom,
              ),
            // â”€â”€ Event pins (primary interactive layer) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (!_showPlaces)
              MarkerLayer(
                markers: _filteredEvents
                    .where((event) => categoryInfo[event.category] != null)
                    .map((event) {
                      final info = categoryInfo[event.category]!;
                      final isSelected = _selectedEvent?.id == event.id;
                      final isLive = EventService.isEventLive(event);
                      final countdown = EventService.getCountdown(event);
                      final hasCountdown = countdown != null;
                      // Show title label whenever zoomed in enough OR countdown is active
                      final showLabel = (_currentZoom >= 16.5) && !isLive;
                      final double pinW = isSelected ? 34.0 : 28.0;
                      final double pinH = isSelected ? 44.0 : 36.0;
                      // Extra height: title (18) + countdown (22) when countdown
                      // is active (title always shows alongside countdown).
                      final double extraH = hasCountdown
                          ? 42.0
                          : (showLabel ? 20.0 : 0.0);
                      final double markerW = isLive
                          ? 70.0
                          : (showLabel || hasCountdown ? 90.0 : pinW);
                      final double markerH = isLive ? 72.0 : pinH + extraH;

                      Widget pinWidget = MapEventPin(
                        color: info.color,
                        icon: info.icon,
                        isSelected: isSelected,
                        width: pinW,
                        height: pinH,
                      );
                      if (isLive) {
                        // Pulse ring drawn via Clip.none + Positioned so it never
                        // affects layout size (prevents the pin from jumping).
                        pinWidget = AnimatedBuilder(
                          animation: _signalPulseController!,
                          builder: (_, child) {
                            final t = _signalPulseController!.value;
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
                                    // Centre the ring on the pin head
                                    left: pinW / 2 - pulseRadius,
                                    top: pinH * 0.28 - pulseRadius,
                                    child: Container(
                                      width: pulseRadius * 2,
                                      height: pulseRadius * 2,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: info.color.withOpacity(
                                          pulseOpacity,
                                        ),
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
                          onTap: () => _onPinTap(event),
                          behavior: HitTestBehavior.opaque,
                          child: SizedBox(
                            width: markerW,
                            height: markerH,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Title: always show when label is active OR countdown is showing
                                if (showLabel || hasCountdown)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: PinLabel(
                                      text: event.title,
                                      color: info.color,
                                    ),
                                  ),
                                // Countdown: below title
                                if (hasCountdown)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: CountdownBadge(
                                      text: EventService.formatCountdown(countdown!),
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
              ),
            // â”€â”€ Place clusters (zoomed out) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_showPlaces && _currentZoom < 15.5)
              MarkerLayer(
                markers: GeoService.computeClusters(campusPlaces, _currentZoom).map((
                  cluster,
                ) {
                  final isSingle = cluster.places.length == 1;
                  return Marker(
                    point: cluster.center,
                    width: 44,
                    height: 44,
                    rotate: true,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        final targetZoom = (_currentZoom + 2.0).clamp(
                          0.0,
                          18.0,
                        );
                        _animateCameraTo(cluster.center, targetZoom);
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
                            ? Icon(
                                cluster.places.first.icon,
                                size: 20,
                                color: Colors.white,
                              )
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
              ),
            // â”€â”€ Permanent places layer (zoomed in) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (_currentZoom >= 15.5 && _showPlaces)
              MarkerLayer(
                markers: campusPlaces.map((place) {
                  final isSelected = _selectedPlace?.id == place.id;
                  final showLabel = isSelected || _currentZoom >= 16.5;
                  return Marker(
                    point: place.position,
                    width: showLabel ? 200 : 34,
                    height: 34,
                    rotate: true,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPlace = place;
                          _selectedEvent = null;
                          _selectedStudySpot = null;
                          _selectedSignal = null;
                        });
                        _animateCameraTo(place.position, 17.5);
                        _sheetController.animateTo(
                          _kPreview,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOut,
                        );
                      },
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Circle icon â€” anchored at the lat/lng point
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
                          // Label bubble â€” shown for selected place or when zoomed in
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
                                      style: TextStyle(
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
                                          style: TextStyle(
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
              ),
            // Study spot markers â€” circles, not teardrop pins.
            if (!_showPlaces)
              MarkerLayer(
                markers: _filteredStudySpots.map((spot) {
                  final color = categoryInfo[EventCategory.study]!.color;
                  final bool isSelected = _selectedStudySpot?.id == spot.id;
                  final double size = isSelected ? 36.0 : 28.0;
                  final bool showLabel = _currentZoom >= 16.5;
                  final double markerW = showLabel ? 90.0 : size;
                  final double markerH = showLabel ? size + 18.0 : size;

                  return Marker(
                    point: spot.position,
                    width: markerW,
                    height: markerH,
                    alignment: Alignment.topCenter,
                    rotate: true,
                    child: GestureDetector(
                      onTap: () => _onStudyPinTap(spot),
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
                                child: PinLabel(
                                  text: spot.title,
                                  color: color,
                                ),
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
              ),
            // Bus stops hidden until transport feature is implemented
            if (false) // ignore: dead_code
              MarkerLayer(
                markers: sampleBusStops.map((stop) {
                  final showLabel = _currentZoom >= 16.0;
                  return Marker(
                    point: stop.position,
                    width: showLabel ? 80.0 : 36.0,
                    height: showLabel ? 54.0 : 36.0,
                    alignment: Alignment.topCenter,
                    rotate: true,
                    child: BusStopPin(stop: stop, showLabel: showLabel),
                  );
                }).toList(),
              ),
            // â”€â”€ Signal pins layer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            if (activeSignals.isNotEmpty && !_showPlaces)
              MarkerLayer(
                markers: activeSignals.map((signal) {
                  final meta = signalCategoryMeta[signal.category]!;
                  final isSelected = _selectedSignal?.id == signal.id;
                  return Marker(
                    point: signal.position,
                    width: 50.0,
                    height: 50.0,
                    alignment: Alignment.topCenter,
                    rotate: true,
                    child: GestureDetector(
                      onTap: () => _onSignalPinTap(signal),
                      behavior: HitTestBehavior.opaque,
                      child: SignalPin(
                        color: meta.color,
                        icon: meta.icon,
                        isSelected: isSelected,
                        pulseController: _signalPulseController!,
                        imageUrl: signal.imageUrl,
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),

        // â”€â”€ Search Bar + Filter Chips (glass header, top-pinned) â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: UniverseColors.glassWhite,
                  border: const Border(
                    bottom: BorderSide(color: Color(0x14000000), width: 0.5),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // â”€â”€ Collapsible: title + search bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    alignment: Alignment.topCenter,
                    child: _headerCollapsed
                        ? const SizedBox.shrink()
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Page title row
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  12,
                                  16,
                                  6,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Discover',
                                      style: UniverseTextStyles.displayLarge,
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.80),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: UniverseColors.borderColor,
                                            width: 0.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.tune_rounded,
                                          size: 16,
                                          color: UniverseColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Search bar â€” glass pill
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  0,
                                ),
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.85),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                    border: Border.all(
                                      color: UniverseColors.borderColor,
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.search_rounded,
                                        size: 18,
                                        color: UniverseColors.iosSysGray,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          onChanged: (v) =>
                                              setState(() => _searchQuery = v),
                                          style: const TextStyle(
                                            color: UniverseColors.textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w400,
                                            height: 1.0,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Search',
                                            hintStyle: const TextStyle(
                                              color: UniverseColors.iosSysGray,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w400,
                                              height: 1.0,
                                            ),
                                            isDense: true,
                                            border: InputBorder.none,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      if (_searchQuery.isNotEmpty)
                                        GestureDetector(
                                          onTap: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                          child: Container(
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            width: 18,
                                            height: 18,
                                            decoration: const BoxDecoration(
                                              color: UniverseColors.iosSysGray2,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),

                  // â”€â”€ iOS-style filter chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        // When header is collapsed, show a restore search chip
                        if (_headerCollapsed)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _headerCollapsed = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.80),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: UniverseColors.borderColor,
                                    width: 0.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  size: 15,
                                  color: UniverseColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ...EventCategory.values
                            .where((cat) => categoryInfo.containsKey(cat))
                            .map((cat) {
                              final info = categoryInfo[cat]!;
                              final isActive = _activeFilter == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: GestureDetector(
                                  onTap: () => _onFilterTap(cat),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? info.color.withOpacity(0.10)
                                          : Colors.white.withOpacity(0.80),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isActive
                                            ? info.color.withOpacity(0.30)
                                            : UniverseColors.borderColor,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          info.icon,
                                          size: 13,
                                          color: isActive
                                              ? info.color
                                              : UniverseColors.textMuted,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          info.label,
                                          style: TextStyle(
                                            color: isActive
                                                ? info.color
                                                : UniverseColors.textSecondary,
                                            fontSize: 13,
                                            fontWeight: isActive
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            })
                            .toList(),
                        // _buildTransportChip(), // hidden until transport is implemented
                        // â”€â”€ Restaurants filter chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _showPlaces = !_showPlaces),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _showPlaces
                                    ? const Color(0xFFFF7043).withOpacity(0.10)
                                    : Colors.white.withOpacity(0.80),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _showPlaces
                                      ? const Color(0xFFFF7043).withOpacity(0.30)
                                      : UniverseColors.borderColor,
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 13,
                                    color: _showPlaces
                                        ? const Color(0xFFFF7043)
                                        : UniverseColors.textMuted,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Restaurants',
                                    style: TextStyle(
                                      color: _showPlaces
                                          ? const Color(0xFFFF7043)
                                          : UniverseColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: _showPlaces
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
            ),
          ),
        ),

        // â”€â”€ Bottom Draggable Panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _kCollapsed,
          minChildSize: 0.10,
          maxChildSize: _kExpanded,
          snap: true,
          snapSizes: const [_kCollapsed, _kPreview, _kExpanded],
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                child: Container(
                  decoration: BoxDecoration(
                    color: UniverseColors.glassWhite,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    border: Border.all(
                      color: UniverseColors.glassBorder,
                      width: 0.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 32,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  child: _selectedSignal != null
                      ? SignalPanel(
                          scrollController: scrollController,
                          signal: _selectedSignal!,
                          onDragHandleTap: _onDragHandleTap,
                          onDismiss: _dismissPreview,
                          onRemoveSignal: () {
                            final sigId = _selectedSignal!.id;
                            setState(() {
                              activeSignals.removeWhere((s) => s.id == sigId);
                            });
                            _dismissPreview();
                          },
                        )
                      : _selectedPlace != null
                      ? PlacePanel(
                          scrollController: scrollController,
                          place: _selectedPlace!,
                          onDragHandleTap: _onDragHandleTap,
                          onDismiss: () {
                            setState(() => _selectedPlace = null);
                            _dismissPreview();
                          },
                        )
                      : _selectedStudySpot != null
                      ? StudySpotPanel(
                          scrollController: scrollController,
                          spot: _selectedStudySpot!,
                          onDragHandleTap: _onDragHandleTap,
                          onDismiss: () {
                            setState(() => _selectedStudySpot = null);
                            _dismissPreview();
                          },
                        )
                      : _selectedEvent == null
                      ? HappeningNowPanel(
                          scrollController: scrollController,
                          events: _filteredEvents,
                          pageController: _pageController,
                          onEventTap: _onPinTap,
                          onPageChanged: _onPageChanged,
                          onDragHandleTap: _onDragHandleTap,
                        )
                      : EventDetailPanel(
                          scrollController: scrollController,
                          event: _selectedEvent!,
                          isGoing: _isGoing,
                          isLiked: _likedItems.contains(_selectedEvent!.id),
                          isSaved: _savedItems.contains(_selectedEvent!.id),
                          isCommunityPin: _tempExpiry.containsKey(_selectedEvent!.id),
                          confirmCount: _confirmations[_selectedEvent!.id] ?? 0,
                          outdatedCount: _outdatedVotes[_selectedEvent!.id] ?? 0,
                          onDragHandleTap: _onDragHandleTap,
                          onDismiss: _dismissPreview,
                          onGoingChanged: (v) => setState(() => _isGoing = v),
                          onLikeToggle: () => setState(() {
                            if (_likedItems.contains(_selectedEvent!.id)) {
                              _likedItems.remove(_selectedEvent!.id);
                            } else {
                              _likedItems.add(_selectedEvent!.id);
                              _dislikedItems.remove(_selectedEvent!.id);
                            }
                          }),
                          onSaveToggle: () => setState(() {
                            if (_savedItems.contains(_selectedEvent!.id)) {
                              _savedItems.remove(_selectedEvent!.id);
                            } else {
                              _savedItems.add(_selectedEvent!.id);
                            }
                          }),
                          onConfirm: () => setState(
                            () => _confirmations[_selectedEvent!.id] =
                                (_confirmations[_selectedEvent!.id] ?? 0) + 1,
                          ),
                          onOutdated: () => setState(
                            () => _outdatedVotes[_selectedEvent!.id] =
                                (_outdatedVotes[_selectedEvent!.id] ?? 0) + 1,
                          ),
                        ),
                ),
              ),
            );
          },
        ),

        // â”€â”€ Map controls (right side) â€” heatmap + zoom
        Positioned(
          right: 16,
          top: mapControlsTop,
          child: IgnorePointer(
            ignoring: _hideFloatingMapControls,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: _hideFloatingMapControls ? 0 : 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MapControlButton(
                    onTap: () => setState(() => _showHeatmap = !_showHeatmap),
                    active: _showHeatmap,
                    activeColor: UniverseColors.accentPink,
                    child: const Icon(Icons.whatshot_rounded, size: 20),
                  ),
                  const SizedBox(height: 8),
                  MapControlButton(
                    onTap: () => _animateCameraTo(
                      _mapController.camera.center,
                      (_mapController.camera.zoom + 1).clamp(15.6, 19.0),
                    ),
                    child: const Icon(Icons.add_rounded, size: 20),
                  ),
                  const SizedBox(height: 4),
                  MapControlButton(
                    onTap: () => _animateCameraTo(
                      _mapController.camera.center,
                      (_mapController.camera.zoom - 1).clamp(15.6, 19.0),
                    ),
                    child: const Icon(Icons.remove_rounded, size: 20),
                  ),
                ],
              ),
            ),
          ),
        ),

        // â”€â”€ Pin placement mode overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_placementMode) ...[
          const IgnorePointer(
            child: ColoredBox(
              color: Color(0x14000000),
              child: SizedBox.expand(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 24,
            right: 24,
            child: IgnorePointer(child: Center(child: PlacementBanner())),
          ),
          IgnorePointer(
            child: Center(child: PlacementPin(lifted: _pinLifted)),
          ),
          Positioned(
            bottom: confirmBarBottom,
            left: 20,
            right: 20,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _placementMode = false;
                        _pinLifted = false;
                      }),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: UniverseColors.borderColor),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: UniverseColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _placementMode = false;
                          _pinLifted = false;
                        });
                        PinCustomizationSheet.show(
                          context,
                          center: _mapController.camera.center,
                          pendingAddress: _pendingPinAddress,
                          onCreate: _createPin,
                        );
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF3D8BFF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x446C63FF),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Confirm Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // â”€â”€ Signal placement mode overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (_signalPlacementMode) ...[
          const IgnorePointer(
            child: ColoredBox(
              color: Color(0x14000000),
              child: SizedBox.expand(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 70,
            left: 24,
            right: 24,
            child: IgnorePointer(
              child: Center(
                child: PlacementBanner(
                  text: 'Move the map to position your signal',
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: PlacementPin(
                lifted: _pinLifted,
                color: const Color(0xFFFF7AD9),
                icon: Icons.sensors_rounded,
              ),
            ),
          ),
          Positioned(
            bottom: confirmBarBottom,
            left: 20,
            right: 20,
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _signalPlacementMode = false;
                        _pinLifted = false;
                      }),
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: UniverseColors.borderColor),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 12,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: UniverseColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: () {
                        final pos = _mapController.camera.center;
                        setState(() {
                          _signalPlacementMode = false;
                          _pinLifted = false;
                        });
                        SignalCustomizationSheet.show(
                          context,
                          position: pos,
                          pendingAddress: _pendingPinAddress,
                          onDrop: _dropSignal,
                        );
                      },
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFFFF7AD9)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x44FF7AD9),
                              blurRadius: 12,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Set Signal Location',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // â”€â”€ Add menu items â€” anchored above the + button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          left: 16,
          top: addPinTop - 130,
          child: IgnorePointer(
            ignoring:
                !_addMenuOpen ||
                _hideFloatingMapControls ||
                _placementMode ||
                _signalPlacementMode,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity:
                  (_addMenuOpen &&
                      !_hideFloatingMapControls &&
                      !_placementMode &&
                      !_signalPlacementMode)
                  ? 1.0
                  : 0.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // â”€â”€ Quick Signal option â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AddMenuOption(
                      label: 'Quick Signal',
                      icon: Icons.sensors_rounded,
                      color: _canDropSignal
                          ? const Color(0xFFFF7AD9)
                          : UniverseColors.iosSysGray2,
                      onTap: () {
                        setState(() {
                          _addMenuOpen = false;
                        });
                        if (!_canDropSignal) {
                          final rem = _signalCooldownRemaining;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'You can drop another signal in ${rem.inMinutes}m ${rem.inSeconds % 60}s',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: const Color(0xFF6C63FF),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              duration: const Duration(seconds: 3),
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _signalPlacementMode = true;
                          _pinLifted = false;
                          _headerCollapsed = true;
                        });
                        _reverseGeocode(_mapController.camera.center);
                      },
                    ),
                  ),
                  // â”€â”€ Create Event option â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AddMenuOption(
                      label: 'Create Event',
                      icon: Icons.add_location_alt_rounded,
                      color: UniverseColors.accent,
                      onTap: () {
                        setState(() {
                          _addMenuOpen = false;
                          _placementMode = true;
                          _pinLifted = false;
                        });
                        _sheetController.animateTo(
                          _kCollapsed,
                          duration: const Duration(milliseconds: 320),
                          curve: Curves.easeOut,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // â”€â”€ + / Ã— button â€” always at addPinTop, never shifts â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Positioned(
          left: 16,
          top: addPinTop,
          child: IgnorePointer(
            ignoring:
                _hideFloatingMapControls ||
                _placementMode ||
                _signalPlacementMode,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity:
                  (_hideFloatingMapControls ||
                      _placementMode ||
                      _signalPlacementMode)
                  ? 0
                  : 1,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _addMenuOpen = !_addMenuOpen;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _addMenuOpen
                        ? const Color(0xFF2D2D2D)
                        : UniverseColors.accent,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x44000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: AnimatedRotation(
                    turns: _addMenuOpen ? 0.125 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _addMenuOpen ? Icons.close_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  // ═══════════════════════════════════════════════════
  // REVERSE GEOCODING
  // ═══════════════════════════════════════════════════

  Future<void> _reverseGeocode(LatLng pos) async {
    final label = await GeoService.reverseGeocode(pos);
    if (mounted) setState(() => _pendingPinAddress = label);
  }

  void _createPin(
    EventCategory category,
    String title,
    String location,
    LatLng position, {
    String? imageUrl,
  }) {
    final id = 'u${DateTime.now().millisecondsSinceEpoch}';
    final loc = location.isEmpty ? 'Campus' : location;
    if (category == EventCategory.study) {
      final spot = StudySpot(
        id: id,
        title: title,
        location: loc,
        position: position,
      );
      setState(() {
        sampleStudySpots.add(spot);
        _selectedStudySpot = spot;
        _selectedEvent = null;
      });
    } else {
      final ev = CampusEvent(
        id: id,
        title: title,
        subtitle: 'You',
        location: loc,
        time: 'Now',
        imageUrl: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : '',
        category: category,
        position: position,
        attendees: 0,
      );
      setState(() {
        sampleEvents.add(ev);
        _tempExpiry[id] = DateTime.now().add(const Duration(hours: 2));
        _selectedEvent = ev;
        _selectedStudySpot = null;
      });
      _scheduleExpiry(id, const Duration(hours: 2));
    }
    _animateCameraTo(position, 17.5);
    _sheetController.animateTo(
      _kPreview,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Pin dropped!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        backgroundColor: UniverseColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }
}

