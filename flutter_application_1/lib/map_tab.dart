import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'theme.dart';
import 'models.dart';

class HeatPoint {
  final LatLng position;
  final double intensity; // 0.0 – 1.0
  const HeatPoint(this.position, this.intensity);
}

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

  static const double _kCollapsed = 0.20;
  static const double _kPreview = 0.38;
  static const double _kExpanded = 0.85;

  bool get _hideFloatingMapControls => _sheetExtent >= (_kExpanded - 0.01);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
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
          if (_placementMode && !_pinLifted) setState(() => _pinLifted = true);
        }
        if (event is MapEventMoveEnd) {
          if (_placementMode && _pinLifted) setState(() => _pinLifted = false);
          if (_placementMode) _reverseGeocode(_mapController.camera.center);
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
    });
    _sheetController.animateTo(
      _kCollapsed,
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

  @override
  void dispose() {
    _mapEventSub?.cancel();
    _mapController.dispose();
    _sheetController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    for (final t in _expiryTimers) {
      t.cancel();
    }
    super.dispose();
  }

  Widget _buildTransportChip() {
    const teal = Color(0xFF009688);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _showTransport = !_showTransport),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _showTransport ? teal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.directions_bus_rounded,
                size: 13,
                color: _showTransport ? Colors.white : teal,
              ),
              const SizedBox(width: 5),
              Text(
                'Bus',
                style: TextStyle(
                  color: _showTransport
                      ? Colors.white
                      : UniverseColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Heatmap helpers ────────────────────────────────────────────────────────

  List<HeatPoint> get _heatPoints {
    final pts = <HeatPoint>[];
    for (final e in sampleEvents) {
      final intensity = (e.attendees / 200.0).clamp(0.0, 1.0);
      pts.add(HeatPoint(e.position, intensity));
    }
    return pts;
  }

  Color _heatColor(double intensity) {
    if (intensity < 0.4) {
      return Color.lerp(
        const Color(0x556C63FF),
        const Color(0x88A855F7),
        intensity / 0.4,
      )!;
    }
    return Color.lerp(
      const Color(0x88A855F7),
      const Color(0xAAFF7AD9),
      (intensity - 0.4) / 0.6,
    )!;
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
    // sit at the same y-position — identical gap from the panel.
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
        ? screenHeight // off screen — hidden
        : (sheetTop - controlsGap - fabHeight).clamp(
            safeTop + 12,
            screenHeight,
          );

    return Stack(
      children: [
        // ── Light Map ──────────────────────────────────────
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
            ),
            // ── Heatmap blobs (above base map, below pins) ─────────────────
            if (_showHeatmap)
              MarkerLayer(
                markers: _heatPoints.map((pt) {
                  final radius = 60.0 + pt.intensity * 40.0;
                  return Marker(
                    point: pt.position,
                    width: radius * 2,
                    height: radius * 2,
                    child: CustomPaint(
                      size: Size(radius * 2, radius * 2),
                      painter: _HeatBlobPainter(
                        color: _heatColor(pt.intensity),
                        intensity: pt.intensity,
                      ),
                    ),
                  );
                }).toList(),
              ),
            // ── Event pins (primary interactive layer) ─────────────────────
            MarkerLayer(
              markers: _filteredEvents
                  .where((event) => categoryInfo[event.category] != null)
                  .map((event) {
                    final info = categoryInfo[event.category]!;
                    final isSelected = _selectedEvent?.id == event.id;
                    final showLabel = _currentZoom >= 16.5;
                    final double pinW = isSelected ? 34.0 : 28.0;
                    final double pinH = isSelected ? 44.0 : 36.0;
                    return Marker(
                      point: event.position,
                      width: showLabel ? 90.0 : pinW,
                      height: showLabel ? pinH + 20.0 : pinH,
                      alignment: Alignment.topCenter,
                      rotate: true,
                      child: GestureDetector(
                        onTap: () => _onPinTap(event),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: showLabel ? 90.0 : pinW,
                          height: showLabel ? pinH + 20.0 : pinH,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (showLabel)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: _PinLabel(
                                    text: event.title,
                                    color: info.color,
                                  ),
                                ),
                              _MapPin(
                                color: info.color,
                                icon: info.icon,
                                isSelected: isSelected,
                                width: pinW,
                                height: pinH,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
            // Study spot markers — invisible when zoomed-out, smoothly scale up,
            // and show normal size when filtered or at building zoom.
            MarkerLayer(
              markers: _filteredStudySpots
                  .where((s) {
                    const minVisibleZoom = 18.2;
                    if (_activeFilter == EventCategory.study) return true;
                    return _currentZoom >= minVisibleZoom;
                  })
                  .where((_) => categoryInfo[EventCategory.study] != null)
                  .map((spot) {
                    final info = categoryInfo[EventCategory.study]!;
                    const double minVisibleZoom = 18.2;
                    const double normalZoom =
                        19.0; // use map max zoom as full-size

                    final bool forcedNormal =
                        _activeFilter == EventCategory.study;
                    final bool showLabel = _currentZoom >= normalZoom;

                    double scale;
                    if (forcedNormal) {
                      scale = 1.0;
                    } else if (_currentZoom <= minVisibleZoom) {
                      scale = 0.0;
                    } else if (_currentZoom >= normalZoom) {
                      scale = 1.0;
                    } else {
                      scale =
                          (_currentZoom - minVisibleZoom) /
                          (normalZoom - minVisibleZoom);
                    }

                    const double baseW = 28.0;
                    const double baseH = 36.0;
                    const double minW = 12.0;
                    const double minH = 16.0;

                    final double pinW = (minW + (baseW - minW) * scale).clamp(
                      minW,
                      baseW,
                    );
                    final double pinH = (minH + (baseH - minH) * scale).clamp(
                      minH,
                      baseH,
                    );

                    return Marker(
                      point: spot.position,
                      width: showLabel ? 90.0 : pinW,
                      height: showLabel ? pinH + 20.0 : pinH,
                      alignment: Alignment.topCenter,
                      rotate: true,
                      child: GestureDetector(
                        onTap: () => _onStudyPinTap(spot),
                        behavior: HitTestBehavior.opaque,
                        child: SizedBox(
                          width: showLabel ? 90.0 : pinW,
                          height: showLabel ? pinH + 20.0 : pinH,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              if (showLabel)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: _PinLabel(
                                    text: spot.title,
                                    color: info.color,
                                  ),
                                ),
                              _MapPin(
                                color: info.color,
                                icon: info.icon,
                                isSelected: _selectedStudySpot?.id == spot.id,
                                width: pinW,
                                height: pinH,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
            if (_showTransport)
              MarkerLayer(
                markers: sampleBusStops.map((stop) {
                  final showLabel = _currentZoom >= 16.0;
                  return Marker(
                    point: stop.position,
                    width: showLabel ? 80.0 : 36.0,
                    height: showLabel ? 54.0 : 36.0,
                    alignment: Alignment.topCenter,
                    rotate: true,
                    child: _BusStopPin(stop: stop, showLabel: showLabel),
                  );
                }).toList(),
              ),
          ],
        ),

        // ── Search Bar + Filter Chips (opaque underlay, top-pinned) ────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF5F6FA),
              border: Border(
                bottom: BorderSide(color: Color(0x18000000), width: 0.5),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Collapsible: title + search bar ────────────────────────────
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
                                      'Live Campus Map',
                                      style: UniverseTextStyles.displayLarge
                                          .copyWith(fontSize: 26),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () {},
                                      child: Container(
                                        width: 38,
                                        height: 38,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Color(0x14000000),
                                              blurRadius: 8,
                                              offset: Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.tune_rounded,
                                          size: 18,
                                          color: UniverseColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // iOS-style search bar
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  0,
                                ),
                                child: Container(
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(14),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0x1A000000),
                                        blurRadius: 12,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
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

                  // ── iOS-style filter chips ──────────────────────────────────────
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
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  size: 16,
                                  color: UniverseColors.iosSysGray,
                                ),
                              ),
                            ),
                          ),
                        ...EventCategory.values.map((cat) {
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
                                  color: isActive ? info.color : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x14000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      info.icon,
                                      size: 13,
                                      color: isActive
                                          ? Colors.white
                                          : info.color,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      info.label,
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.white
                                            : UniverseColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        _buildTransportChip(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),

        // ── Bottom Draggable Panel ─────────────────────────
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _kCollapsed,
          minChildSize: 0.10,
          maxChildSize: _kExpanded,
          snap: true,
          snapSizes: const [_kCollapsed, _kPreview, _kExpanded],
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: _selectedStudySpot != null
                  ? _buildStudySpotPanel(scrollController, _selectedStudySpot!)
                  : _selectedEvent == null
                  ? _buildHappeningNow(scrollController)
                  : _buildEventPanel(scrollController, _selectedEvent!),
            );
          },
        ),

        // ── Map controls (right side) — heatmap + zoom
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
                  _MapControlButton(
                    onTap: () => setState(() => _showHeatmap = !_showHeatmap),
                    active: _showHeatmap,
                    activeColor: UniverseColors.accentPink,
                    child: const Icon(Icons.whatshot_rounded, size: 20),
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    onTap: () => _animateCameraTo(
                      _mapController.camera.center,
                      (_mapController.camera.zoom + 1).clamp(15.6, 19.0),
                    ),
                    child: const Icon(Icons.add_rounded, size: 20),
                  ),
                  const SizedBox(height: 4),
                  _MapControlButton(
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

        // ── Create post/pin FAB (floats above the panel)
        Positioned(
          left: 16,
          top: addPinTop,
          child: IgnorePointer(
            ignoring: _hideFloatingMapControls || _placementMode,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 180),
              opacity: (_hideFloatingMapControls || _placementMode) ? 0 : 1,
              child: FloatingActionButton(
                backgroundColor: UniverseColors.accent,
                onPressed: () {
                  setState(() {
                    _placementMode = true;
                    _pinLifted = false;
                  });
                  // Collapse the bottom sheet so it doesn't overlap controls
                  _sheetController.animateTo(
                    _kCollapsed,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                  );
                },
                child: const Icon(Icons.add_location_alt_rounded),
              ),
            ),
          ),
        ),

        // ── Pin placement mode overlay ──────────────────────────────────────
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
            child: const IgnorePointer(
              child: Center(child: _PlacementBanner()),
            ),
          ),
          IgnorePointer(
            child: Center(child: _PlacementPin(lifted: _pinLifted)),
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
                        _showPinCustomizationSheet();
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
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // REVERSE GEOCODING
  // ═══════════════════════════════════════════════════

  Future<void> _reverseGeocode(LatLng pos) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${pos.latitude}&lon=${pos.longitude}&format=json&zoom=18&addressdetails=1',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'UniverseMonashApp/1.0'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addr = data['address'] as Map<String, dynamic>?;
        String label;
        if (addr != null) {
          final road = addr['road'] as String?;
          final number = addr['house_number'] as String?;
          final suburb =
              (addr['suburb'] ?? addr['city_district'] ?? addr['neighbourhood'])
                  as String?;
          if (road != null && number != null) {
            label = '$number $road';
          } else if (road != null) {
            label = suburb != null ? '$road, $suburb' : road;
          } else if (suburb != null) {
            label = suburb;
          } else {
            label =
                (data['display_name'] as String?)?.split(',').first.trim() ??
                'Monash Clayton Campus';
          }
        } else {
          label =
              (data['display_name'] as String?)?.split(',').first.trim() ??
              'Monash Clayton Campus';
        }
        setState(() => _pendingPinAddress = label);
      }
    } catch (_) {
      // keep existing label on network error
    }
  }

  // ═══════════════════════════════════════════════════
  // PIN CREATION — place + customise flow
  // ═══════════════════════════════════════════════════

  void _showPinCustomizationSheet() {
    final center = _mapController.camera.center;
    EventCategory? selectedCategory;
    final titleCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: _pendingPinAddress);
    final Set<String> amenities = {};
    String busyLevel = 'Quiet';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.78,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, sc) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: UniverseColors.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      Text(
                        'Drop a Pin',
                        style: UniverseTextStyles.sectionHeader,
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: UniverseColors.bgPage,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: UniverseColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: sc,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    children: [
                      // ── Category picker
                      const Text(
                        'Category',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: EventCategory.values.map((cat) {
                          final info = categoryInfo[cat]!;
                          final sel = selectedCategory == cat;
                          return GestureDetector(
                            onTap: () => setSheet(() => selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: sel
                                    ? info.color
                                    : info.color.withOpacity(0.09),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: sel ? info.color : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    info.icon,
                                    size: 14,
                                    color: sel ? Colors.white : info.color,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    info.label,
                                    style: TextStyle(
                                      color: sel ? Colors.white : info.color,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),
                      // ── Title
                      const Text(
                        'Title',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SheetTextField(
                        controller: titleCtrl,
                        hint: selectedCategory == null
                            ? "What's happening here?"
                            : categoryInfo[selectedCategory]!.label,
                        icon: Icons.title_rounded,
                      ),
                      const SizedBox(height: 14),
                      // ── Location
                      const Text(
                        'Location',
                        style: TextStyle(
                          color: UniverseColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _SheetTextField(
                        controller: locationCtrl,
                        hint: 'Building, room or area',
                        icon: Icons.location_on_rounded,
                      ),
                      // ── Study-spot extras
                      if (selectedCategory == EventCategory.study) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Amenities',
                          style: TextStyle(
                            color: UniverseColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final a in [
                              'Power Outlets',
                              'Whiteboard',
                              'Quiet',
                              'Aircon',
                              'Natural Light',
                            ])
                              GestureDetector(
                                onTap: () => setSheet(() {
                                  if (amenities.contains(a)) {
                                    amenities.remove(a);
                                  } else {
                                    amenities.add(a);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 130),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: amenities.contains(a)
                                        ? UniverseColors.accent
                                        : UniverseColors.bgPage,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    a,
                                    style: TextStyle(
                                      color: amenities.contains(a)
                                          ? Colors.white
                                          : UniverseColors.textSecondary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Busyness',
                          style: TextStyle(
                            color: UniverseColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            for (final level in ['Quiet', 'Moderate', 'Busy'])
                              Expanded(
                                child: GestureDetector(
                                  onTap: () =>
                                      setSheet(() => busyLevel = level),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 130),
                                    margin: EdgeInsets.only(
                                      right: level != 'Busy' ? 8 : 0,
                                    ),
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: busyLevel == level
                                          ? UniverseColors.accent
                                          : UniverseColors.bgPage,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        level,
                                        style: TextStyle(
                                          color: busyLevel == level
                                              ? Colors.white
                                              : UniverseColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      // ── Drop Pin button
                      GestureDetector(
                        onTap: () {
                          final cat = selectedCategory;
                          final title = titleCtrl.text.trim();
                          if (cat == null || title.isEmpty) return;
                          Navigator.of(ctx).pop();
                          _createPin(
                            cat,
                            title,
                            locationCtrl.text.trim(),
                            center,
                          );
                        },
                        child: Container(
                          height: 52,
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
                                blurRadius: 16,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_location_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Drop Pin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _createPin(
    EventCategory category,
    String title,
    String location,
    LatLng position,
  ) {
    final id = 'u${DateTime.now().millisecondsSinceEpoch}';
    final loc = location.isEmpty ? 'Campus' : location;
    if (category == EventCategory.study) {
      setState(() {
        sampleStudySpots.add(
          StudySpot(id: id, title: title, location: loc, position: position),
        );
      });
    } else {
      final ev = CampusEvent(
        id: id,
        title: title,
        subtitle: 'You',
        location: loc,
        time: 'Now',
        imageUrl: '',
        category: category,
        position: position,
        attendees: 0,
      );
      setState(() {
        sampleEvents.add(ev);
        _tempExpiry[id] = DateTime.now().add(const Duration(hours: 2));
      });
      _scheduleExpiry(id, const Duration(hours: 2));
    }
    _animateCameraTo(position, 17.5);
  }

  // ═══════════════════════════════════════════════════
  // PANEL A — "Happening Now" (default, no pin selected)
  // ═══════════════════════════════════════════════════
  Widget _buildHappeningNow(ScrollController scrollController) {
    return CustomScrollView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DragHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'Happening Now',
                      style: UniverseTextStyles.sectionHeader,
                    ),
                    const Spacer(),
                    Text(
                      '${_filteredEvents.length} events',
                      style: const TextStyle(
                        color: UniverseColors.textLight,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 118,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _filteredEvents.length,
                  itemBuilder: (context, i) => _HappeningCard(
                    event: _filteredEvents[i],
                    onTap: () => _onPinTap(_filteredEvents[i]),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(
                height: 1,
                thickness: 1,
                color: UniverseColors.divider,
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'All Events',
                  style: UniverseTextStyles.sectionHeader.copyWith(
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (ctx, i) => _EventRow(
              event: _filteredEvents[i],
              onTap: () => _onPinTap(_filteredEvents[i]),
            ),
            childCount: _filteredEvents.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // PANEL B — Event preview + full details on swipe up
  // ═══════════════════════════════════════════════════
  Widget _buildEventPanel(
    ScrollController scrollController,
    CampusEvent event,
  ) {
    final info = categoryInfo[event.category]!;
    return CustomScrollView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DragHandle(),

                // Category pill + close button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(info.icon, size: 13, color: info.color),
                          const SizedBox(width: 5),
                          Text(
                            info.label,
                            style: TextStyle(
                              color: info.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _dismissPreview,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: UniverseColors.bgPage,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: UniverseColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Preview card ─────────────────────────
                Container(
                  height: 108,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: UniverseColors.borderColor),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 12,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(18),
                        ),
                        child: Image.network(
                          event.imageUrl,
                          width: 108,
                          height: 108,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 108,
                            height: 108,
                            color: info.color.withOpacity(0.1),
                            child: Icon(info.icon, color: info.color, size: 36),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.title,
                                style: const TextStyle(
                                  color: UniverseColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              _MiniRow(
                                icon: Icons.location_on_rounded,
                                label: event.location,
                              ),
                              const SizedBox(height: 3),
                              _MiniRow(
                                icon: Icons.access_time_rounded,
                                label: event.time,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                const Center(
                  child: Text(
                    '↑  Swipe up for full details',
                    style: TextStyle(
                      color: UniverseColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: UniverseColors.divider,
                ),
                const SizedBox(height: 20),

                // ── Full details (visible on swipe up) ───
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(
                    event.imageUrl,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 200,
                      color: info.color.withOpacity(0.1),
                      child: Icon(info.icon, size: 60, color: info.color),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: UniverseColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hosted by ${event.subtitle}',
                  style: const TextStyle(
                    color: UniverseColors.textLight,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: event.time,
                  iconColor: UniverseColors.accent,
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.location_on_rounded,
                  label: event.location,
                  iconColor: UniverseColors.accentBlue,
                ),
                const SizedBox(height: 10),
                _DetailRow(
                  icon: Icons.people_rounded,
                  label: '${event.attendees} people going',
                  iconColor: UniverseColors.accentOrange,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Friends Going',
                  style: TextStyle(
                    color: UniverseColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _FriendAvatar(
                      initials: 'AJ',
                      name: 'Alex',
                      color: UniverseColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _FriendAvatar(
                      initials: 'MK',
                      name: 'Maya',
                      color: UniverseColors.accentPink,
                    ),
                    const SizedBox(width: 12),
                    _FriendAvatar(
                      initials: 'RS',
                      name: 'Ryan',
                      color: UniverseColors.accentBlue,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '+${event.attendees - 3} more',
                      style: const TextStyle(
                        color: UniverseColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Community verification (crowd-reported pins only) ────────
                if (_tempExpiry.containsKey(event.id)) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFE0A0),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Is this still accurate?',
                          style: TextStyle(
                            color: Color(0xFF8B6000),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _confirmations[event.id] =
                                      (_confirmations[event.id] ?? 0) + 1,
                                ),
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF22C55E,
                                    ).withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle_outline_rounded,
                                        color: Color(0xFF22C55E),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Still there (${_confirmations[event.id] ?? 0})',
                                        style: const TextStyle(
                                          color: Color(0xFF22C55E),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _outdatedVotes[event.id] =
                                      (_outdatedVotes[event.id] ?? 0) + 1,
                                ),
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFEF4444,
                                    ).withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.cancel_outlined,
                                        color: Color(0xFFEF4444),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Gone (${_outdatedVotes[event.id] ?? 0})',
                                        style: const TextStyle(
                                          color: Color(0xFFEF4444),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Like / Save / Share ──────────────────────────────────────
                Row(
                  children: [
                    _ActionButton(
                      icon: _likedItems.contains(event.id)
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _likedItems.contains(event.id)
                          ? const Color(0xFFFF4D6D)
                          : UniverseColors.textMuted,
                      label: _likedItems.contains(event.id) ? 'Liked' : 'Like',
                      onTap: () => setState(() {
                        if (_likedItems.contains(event.id)) {
                          _likedItems.remove(event.id);
                        } else {
                          _likedItems.add(event.id);
                          _dislikedItems.remove(event.id);
                        }
                      }),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: _savedItems.contains(event.id)
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: _savedItems.contains(event.id)
                          ? UniverseColors.accent
                          : UniverseColors.textMuted,
                      label: _savedItems.contains(event.id) ? 'Saved' : 'Save',
                      onTap: () => setState(() {
                        if (_savedItems.contains(event.id)) {
                          _savedItems.remove(event.id);
                        } else {
                          _savedItems.add(event.id);
                        }
                      }),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.share_rounded,
                      color: UniverseColors.textMuted,
                      label: 'Share',
                      onTap: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Going / Not Going
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isGoing = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: _isGoing
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF6C63FF),
                                      Color(0xFF3D8BFF),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: _isGoing ? null : Colors.white,
                            border: _isGoing
                                ? null
                                : Border.all(color: UniverseColors.accent),
                            boxShadow: _isGoing
                                ? const [
                                    BoxShadow(
                                      color: Color(0x446C63FF),
                                      blurRadius: 12,
                                      offset: Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              _isGoing ? '✓  Going' : 'Going',
                              style: TextStyle(
                                color: _isGoing
                                    ? Colors.white
                                    : UniverseColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isGoing = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 50,
                          decoration: BoxDecoration(
                            color: !_isGoing
                                ? UniverseColors.bgPage
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: UniverseColors.borderColor,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'Not Going',
                              style: TextStyle(
                                color: UniverseColors.textMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudySpotPanel(
    ScrollController scrollController,
    StudySpot spot,
  ) {
    final info = categoryInfo[EventCategory.study]!;
    return CustomScrollView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _DragHandle(),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(info.icon, size: 13, color: info.color),
                          const SizedBox(width: 5),
                          Text(
                            info.label,
                            style: TextStyle(
                              color: info.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedStudySpot = null);
                        _dismissPreview();
                      },
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: UniverseColors.bgPage,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: UniverseColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  spot.title,
                  style: const TextStyle(
                    color: UniverseColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                _MiniRow(icon: Icons.location_on_rounded, label: spot.location),
                const SizedBox(height: 20),
                const Text(
                  'This study spot does not expire and has no attendance controls.',
                  style: TextStyle(
                    color: UniverseColors.textLight,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 220),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: UniverseColors.borderColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

/// Google Maps-style teardrop pin drawn with CustomPaint.
class _MapPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;
  final double width;
  final double height;

  const _MapPin({
    required this.color,
    required this.icon,
    required this.width,
    required this.height,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _MapPinPainter(color: color, isSelected: isSelected),
      child: SizedBox(
        width: width,
        height: height,
        child: Align(
          alignment: const Alignment(0, -0.18),
          child: Icon(icon, color: Colors.white, size: width * 0.44),
        ),
      ),
    );
  }
}

class _MapPinPainter extends CustomPainter {
  final Color color;
  final bool isSelected;

  const _MapPinPainter({required this.color, this.isSelected = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final tipY = h;
    final shoulderY = h * 0.68;
    final topInset = w * 0.07;
    final sideInset = w * 0.08;

    // Smooth teardrop with a rounded head and a centered pointed tail.
    final path = ui.Path()
      ..moveTo(cx, topInset)
      ..cubicTo(
        w - sideInset,
        topInset,
        w - sideInset * 0.3,
        h * 0.42,
        cx + w * 0.26,
        shoulderY,
      )
      ..quadraticBezierTo(cx + w * 0.12, h * 0.86, cx, tipY)
      ..quadraticBezierTo(cx - w * 0.12, h * 0.86, cx - w * 0.26, shoulderY)
      ..cubicTo(sideInset * 0.3, h * 0.42, sideInset, topInset, cx, topInset)
      ..close();

    // Shadow
    canvas.drawShadow(path, const Color(0x55000000), isSelected ? 5 : 3, false);

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Subtle top highlight to keep the pin looking crisp without changing the palette.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.27),
        width: w * 0.58,
        height: h * 0.34,
      ),
      Paint()
        ..color = Colors.white.withOpacity(isSelected ? 0.16 : 0.10)
        ..style = PaintingStyle.fill,
    );

    // White ring when selected
    if (isSelected) {
      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_MapPinPainter old) =>
      old.color != color || old.isSelected != isSelected;
}

/// Compact card shown in the "Happening Now" horizontal carousel.
class _HappeningCard extends StatelessWidget {
  final CampusEvent event;
  final VoidCallback onTap;

  const _HappeningCard({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[event.category]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: UniverseColors.borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: Image.network(
                event.imageUrl,
                width: 90,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 90,
                  color: info.color.withOpacity(0.1),
                  child: Icon(info.icon, color: info.color),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: UniverseColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.subtitle,
                      style: const TextStyle(
                        color: UniverseColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _MiniRow(
                      icon: Icons.location_on_rounded,
                      label: event.location,
                    ),
                    const SizedBox(height: 2),
                    _MiniRow(
                      icon: Icons.access_time_rounded,
                      label: event.time.split(', ').last,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${event.attendees}',
                  style: TextStyle(
                    color: info.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// List row shown in expanded "All Events" section.
class _EventRow extends StatelessWidget {
  final CampusEvent event;
  final VoidCallback onTap;

  const _EventRow({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[event.category]!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: UniverseColors.borderColor),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  event.imageUrl,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    color: info.color.withOpacity(0.1),
                    child: Icon(info.icon, color: info.color),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: UniverseColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${event.location} · ${event.time}',
                      style: const TextStyle(
                        color: UniverseColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: info.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${event.attendees}',
                  style: TextStyle(
                    color: info.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: UniverseColors.textLight),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: UniverseColors.textLight,
              fontSize: 11,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: const TextStyle(
              color: UniverseColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  final String initials;
  final String name;
  final Color color;

  const _FriendAvatar({
    required this.initials,
    required this.name,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(color: UniverseColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

/// Small label shown above a pin when zoom ≥ 16.5.
class _PinLabel extends StatelessWidget {
  final String text;
  final Color color;

  const _PinLabel({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 86),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: UniverseColors.borderColor, width: 0.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Bus stop pin for the public transport layer.
class _BusStopPin extends StatelessWidget {
  final BusStop stop;
  final bool showLabel;

  const _BusStopPin({required this.stop, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    const teal = Color(0xFF009688);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                stop.nextArrival,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: teal,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}

/// Soft radial gradient blob rendered for the heatmap layer.
class _HeatBlobPainter extends CustomPainter {
  final Color color;
  final double intensity;

  const _HeatBlobPainter({required this.color, required this.intensity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..shader = ui.Gradient.radial(
        center,
        radius,
        [color, color.withOpacity(0.0)],
        [0.0, 1.0],
      );
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_HeatBlobPainter old) =>
      old.color != color || old.intensity != intensity;
}

/// Reusable circular map control button (zoom +/-, heatmap toggle, etc.)
class _MapControlButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final bool active;
  final Color activeColor;

  const _MapControlButton({
    required this.onTap,
    required this.child,
    this.active = false,
    this.activeColor = UniverseColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? activeColor : UniverseColors.borderColor,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: IconTheme(
          data: IconThemeData(
            color: active ? activeColor : UniverseColors.textMuted,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PLACEMENT MODE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Instruction banner shown while the user is placing a pin.
class _PlacementBanner extends StatelessWidget {
  const _PlacementBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.62),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Move the map to position your pin',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Animated pin shown fixed at the centre of the screen during placement mode.
class _PlacementPin extends StatelessWidget {
  final bool lifted;
  const _PlacementPin({required this.lifted});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(bottom: lifted ? 14 : 0),
          child: const _MapPin(
            color: UniverseColors.accent,
            icon: Icons.add_rounded,
            width: 36,
            height: 46,
          ),
        ),
        // Drop shadow under pin — expands while being dragged
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: lifted ? 22 : 14,
          height: lifted ? 6 : 4,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.22),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET HELPER WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Compact text field for use inside the pin customisation sheet.
class _SheetTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _SheetTextField({
    required this.controller,
    required this.hint,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: UniverseColors.bgPage,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: UniverseColors.iosSysGray),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(
                color: UniverseColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.0,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(
                  color: UniverseColors.iosSysGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Small icon + label action button used in the event detail panel.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: UniverseColors.bgPage,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
