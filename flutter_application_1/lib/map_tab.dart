import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'theme.dart';
import 'models.dart';
import 'events_service.dart';
import 'events_service.dart';
import 'map/services/geo_service.dart';
import 'map/widgets/map_controls.dart';
import 'map/widgets/map_layer_stack.dart';
import 'map/widgets/map_search_header.dart';
import 'map/widgets/placement_overlay.dart';
import 'map/widgets/add_pin_fab.dart';
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

  // ═══════════════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════════════

  @override
  void initState() {
    //adding a refresh every 60 seconds to remove expired events
    Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
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
        if ((z - _currentZoom).abs() > 0.08) setState(() => _currentZoom = z);
      });
    });
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    _countdownTimer?.cancel();
    _signalPulseController?.dispose();
    _sheetController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    for (final t in _expiryTimers) {
      t.cancel();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════
  // FILTERED DATA GETTERS
  // ═══════════════════════════════════════════════════

  List<CampusEvent> get _filteredEvents {
    final now = DateTime.now();
    final expired = _tempExpiry.entries
        .where((e) => e.value.isBefore(now))
        .map((e) => e.key)
        .toList();
    for (final id in expired) {
      sampleEvents.removeWhere((ev) => ev.id == id);
      _tempExpiry.remove(id);
    }
    return EventsService.currentEvents.where((e) {
      final matchesFilter =
          _activeFilter == null || e.category == _activeFilter;
      final matchesSearch = _searchQuery.isEmpty ||
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
      final matchesSearch = _searchQuery.isEmpty ||
          s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          s.location.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  // ═══════════════════════════════════════════════════
  // EVENT HANDLERS
  // ═══════════════════════════════════════════════════

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

  void _onPlaceTap(CampusPlace place) {
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
      if (!mounted) { controller.dispose(); return; }
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

  // ═══════════════════════════════════════════════════
  // SIGNAL
  // ═══════════════════════════════════════════════════

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
        content: const Row(children: [
          Icon(Icons.sensors_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Signal sent to nearby students!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ]),
        backgroundColor: const Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  // ── Heatmap helpers ────────────────────────────────────────────────────────

  List<HeatPoint> get _heatPoints {
    final pts = <HeatPoint>[];
    for (final e in EventsService.currentEvents) {
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
  // ═══════════════════════════════════════════════════
  // REVERSE GEOCODING
  // ═══════════════════════════════════════════════════

  Future<void> _reverseGeocode(LatLng pos) async {
    final label = await GeoService.reverseGeocode(pos);
    if (mounted) setState(() => _pendingPinAddress = label);
  Future<void> _reverseGeocode(LatLng pos) async {
    final label = await GeoService.reverseGeocode(pos);
    if (mounted) setState(() => _pendingPinAddress = label);
  }

  // ═══════════════════════════════════════════════════
  // PIN CREATION
  // ═══════════════════════════════════════════════════

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
      final spot = StudySpot(id: id, title: title, location: loc, position: position);
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
        content: const Row(children: [
          Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text(
            'Pin dropped!',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ]),
        backgroundColor: UniverseColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final sheetTop = screenHeight * (1 - _sheetExtent);

    const confirmBarHeight = 50.0;
    const confirmBarBottom = 0.0;
    const controlsHeight = 132.0;
    const controlsGap = 16.0;
    const fabHeight = 56.0;

    final mapControlsTop = _placementMode
        ? (screenHeight - safeBottom - confirmBarHeight - controlsGap - controlsHeight)
            .clamp(safeTop + 12, screenHeight)
        : (sheetTop - controlsGap - controlsHeight).clamp(safeTop + 12, screenHeight);

    final addPinTop = _placementMode
        ? screenHeight
        : (sheetTop - controlsGap - fabHeight).clamp(safeTop + 12, screenHeight);

    return Stack(
      children: [
        // ── Full-screen map with all marker layers ─────────────────────────
        MapLayerStack(
          mapController: _mapController,
          filteredEvents: _filteredEvents,
          filteredStudySpots: _filteredStudySpots,
          showHeatmap: _showHeatmap,
          showPlaces: _showPlaces,
          currentZoom: _currentZoom,
          selectedEventId: _selectedEvent?.id,
          selectedStudySpotId: _selectedStudySpot?.id,
          selectedPlaceId: _selectedPlace?.id,
          selectedSignalId: _selectedSignal?.id,
          signalPulseController: _signalPulseController!,
          onEventTap: _onPinTap,
          onStudySpotTap: _onStudyPinTap,
          onSignalTap: _onSignalPinTap,
          onPlaceTap: _onPlaceTap,
          onAnimateCameraTo: _animateCameraTo,
          onDismissPreview: _dismissPreview,
        ),

        // ── Glass search + filter header ────────────────────────────────────
        MapSearchHeader(
          headerCollapsed: _headerCollapsed,
          searchQuery: _searchQuery,
          searchController: _searchController,
          activeFilter: _activeFilter,
          showPlaces: _showPlaces,
          onRestoreHeader: () => setState(() => _headerCollapsed = false),
          onFilterTap: _onFilterTap,
          onShowPlacesChanged: (v) => setState(() => _showPlaces = v),
          onSearchChanged: (v) => setState(() => _searchQuery = v),
        ),

        // ── Bottom draggable panel ──────────────────────────────────────────
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: _kCollapsed,
          minChildSize: 0.10,
          maxChildSize: _kExpanded,
          snap: true,
          snapSizes: const [_kCollapsed, _kPreview, _kExpanded],
          builder: (context, scrollController) =>
              _buildBottomSheet(scrollController),
        ),

        // ── Map controls (right side) ───────────────────────────────────────
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

        // ── Placement mode overlays (pin + signal) ─────────────────────────
        PlacementModeOverlay(
          placementMode: _placementMode,
          signalPlacementMode: _signalPlacementMode,
          pinLifted: _pinLifted,
          confirmBarBottom: confirmBarBottom,
          onCancelPin: () =>
              setState(() { _placementMode = false; _pinLifted = false; }),
          onConfirmPin: () {
            setState(() { _placementMode = false; _pinLifted = false; });
            PinCustomizationSheet.show(
              context,
              center: _mapController.camera.center,
              pendingAddress: _pendingPinAddress,
              onCreate: _createPin,
            );
          },
          onCancelSignal: () =>
              setState(() { _signalPlacementMode = false; _pinLifted = false; }),
          onConfirmSignal: () {
            final pos = _mapController.camera.center;
            setState(() { _signalPlacementMode = false; _pinLifted = false; });
            SignalCustomizationSheet.show(
              context,
              position: pos,
              pendingAddress: _pendingPinAddress,
              onDrop: _dropSignal,
            );
          },
        ),

        // ── FAB + add menu ─────────────────────────────────────────────────
        AddPinFab(
          addPinTop: addPinTop,
          addMenuOpen: _addMenuOpen,
          hideFloating: _hideFloatingMapControls,
          placementMode: _placementMode,
          signalPlacementMode: _signalPlacementMode,
          canDropSignal: _canDropSignal,
          cooldownRemaining: _signalCooldownRemaining,
          onToggleMenu: () => setState(() => _addMenuOpen = !_addMenuOpen),
          onCreateEvent: () {
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
          onQuickSignal: () {
            setState(() {
              _addMenuOpen = false;
              _signalPlacementMode = true;
              _pinLifted = false;
              _headerCollapsed = true;
            });
            _reverseGeocode(_mapController.camera.center);
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  // BOTTOM SHEET
  // ═══════════════════════════════════════════════════

  Widget _buildBottomSheet(ScrollController scrollController) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          decoration: BoxDecoration(
            color: UniverseColors.glassWhite,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: UniverseColors.glassBorder, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 32,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: _buildPanelContent(scrollController),
        ),
      ),
    );
  }

  Widget _buildPanelContent(ScrollController scrollController) {
    if (_selectedSignal != null) {
      return SignalPanel(
        scrollController: scrollController,
        signal: _selectedSignal!,
        onDragHandleTap: _onDragHandleTap,
        onDismiss: _dismissPreview,
        onRemoveSignal: () {
          final sigId = _selectedSignal!.id;
          setState(() => activeSignals.removeWhere((s) => s.id == sigId));
          _dismissPreview();
        },
      );
    }
    if (_selectedPlace != null) {
      return PlacePanel(
        scrollController: scrollController,
        place: _selectedPlace!,
        onDragHandleTap: _onDragHandleTap,
        onDismiss: () {
          setState(() => _selectedPlace = null);
          _dismissPreview();
        },
      );
    }
    if (_selectedStudySpot != null) {
      return StudySpotPanel(
        scrollController: scrollController,
        spot: _selectedStudySpot!,
        onDragHandleTap: _onDragHandleTap,
        onDismiss: () {
          setState(() => _selectedStudySpot = null);
          _dismissPreview();
        },
      );
    }
    if (_selectedEvent == null) {
      return HappeningNowPanel(
        scrollController: scrollController,
        events: _filteredEvents,
        pageController: _pageController,
        onEventTap: _onPinTap,
        onPageChanged: _onPageChanged,
        onDragHandleTap: _onDragHandleTap,
      );
    }
    return EventDetailPanel(
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
    );
  }
}
