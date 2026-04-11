import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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

class _MapTabState extends State<MapTab> {
  final MapController _mapController = MapController();
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final TextEditingController _searchController = TextEditingController();
  final PageController _pageController = PageController(viewportFraction: 0.90);

  EventCategory? _activeFilter;
  CampusEvent? _selectedEvent;
  bool _isGoing = false;
  String _searchQuery = '';
  bool _showTransport = false;
  bool _showHeatmap = false;
  double _currentZoom = 15.5;
  StreamSubscription<MapEvent>? _mapEventSub;

  static const double _kCollapsed = 0.20;
  static const double _kPreview = 0.38;
  static const double _kExpanded = 0.85;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapEventSub = _mapController.mapEventStream.listen((_) {
        if (!mounted) return;
        final z = _mapController.camera.zoom;
        if ((z - _currentZoom).abs() > 0.08) {
          setState(() => _currentZoom = z);
        }
      });
    });
  }

  List<CampusEvent> get _filteredEvents {
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

  void _onFilterTap(EventCategory cat) {
    setState(() {
      _activeFilter = _activeFilter == cat ? null : cat;
      _selectedEvent = null;
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
      _isGoing = false;
    });
    _mapController.move(event.position, 17.0);
    _sheetController.animateTo(
      _kPreview,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _dismissPreview() {
    setState(() => _selectedEvent = null);
    _sheetController.animateTo(
      _kCollapsed,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    if (index < _filteredEvents.length) {
      _mapController.move(_filteredEvents[index].position, 16.0);
    }
  }

  @override
  void dispose() {
    _mapEventSub?.cancel();
    _mapController.dispose();
    _sheetController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildTransportChip() {
    const teal = Color(0xFF009688);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _showTransport = !_showTransport),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _showTransport ? teal : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _showTransport ? teal : UniverseColors.borderColor,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
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
                  fontWeight: FontWeight.w600,
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
    return Stack(
      children: [
        // ── Light Map ──────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(-37.9110, 145.1335),
            initialZoom: 15.5,
            minZoom: 13.5,
            maxZoom: 19.0,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: LatLngBounds(
                const LatLng(-37.895, 145.115),
                const LatLng(-37.932, 145.156),
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
                markers: _filteredEvents.map((event) {
                final info = categoryInfo[event.category]!;
                final isSelected = _selectedEvent?.id == event.id;
                final showLabel = _currentZoom >= 16.5;
                final double pinW = isSelected ? 34.0 : 28.0;
                final double pinH = isSelected ? 44.0 : 36.0;
                return Marker(
                  point: event.position,
                  width: showLabel ? 90.0 : pinW,
                  height: showLabel ? pinH + 20.0 : pinH,
                  alignment: Alignment.bottomCenter,
                  child: GestureDetector(
                    onTap: () => _onPinTap(event),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                );
              }).toList(),
            ),
            if (_showTransport)
              MarkerLayer(
                markers: sampleBusStops.map((stop) {
                  final showLabel = _currentZoom >= 16.0;
                  return Marker(
                    point: stop.position,
                    width: showLabel ? 80.0 : 36.0,
                    height: showLabel ? 54.0 : 36.0,
                    alignment: Alignment.bottomCenter,
                    child: _BusStopPin(stop: stop, showLabel: showLabel),
                  );
                }).toList(),
              ),
          ],
        ),

        // ── Search Bar + Filter Chips ──────────────────────
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 16,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(
                      color: UniverseColors.textPrimary,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search buildings, events, clubs...',
                      hintStyle: const TextStyle(
                        color: UniverseColors.textLight,
                        fontSize: 15,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: UniverseColors.textLight,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: UniverseColors.textLight,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    ...EventCategory.values.map((cat) {
                    final info = categoryInfo[cat]!;
                    final isActive = _activeFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _onFilterTap(cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isActive ? info.color : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isActive
                                  ? info.color
                                  : UniverseColors.borderColor,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0A000000),
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
                                color: isActive ? Colors.white : info.color,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                info.label,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : UniverseColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
            ],
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: _selectedEvent == null
                  ? _buildHappeningNow(scrollController)
                  : _buildEventPanel(scrollController, _selectedEvent!),
            );
          },
        ),

        // ── Map controls (bottom-right) ─────────────────────────────────────
        Positioned(
          right: 16,
          bottom: MediaQuery.of(context).size.height * _kCollapsed + 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Heatmap toggle
              _MapControlButton(
                onTap: () => setState(() => _showHeatmap = !_showHeatmap),
                active: _showHeatmap,
                activeColor: UniverseColors.accentPink,
                child: const Icon(Icons.whatshot_rounded, size: 20),
              ),
              const SizedBox(height: 8),
              // Zoom in
              _MapControlButton(
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  (_mapController.camera.zoom + 1).clamp(13.5, 19.0),
                ),
                child: const Icon(Icons.add_rounded, size: 20),
              ),
              const SizedBox(height: 4),
              // Zoom out
              _MapControlButton(
                onTap: () => _mapController.move(
                  _mapController.camera.center,
                  (_mapController.camera.zoom - 1).clamp(13.5, 19.0),
                ),
                child: const Icon(Icons.remove_rounded, size: 20),
              ),
            ],
          ),
        ),
      ],
    );
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
                    const Text(
                      'Happening Now',
                      style: TextStyle(
                        color: UniverseColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'All Events',
                  style: TextStyle(
                    color: UniverseColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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
                            color: _isGoing
                                ? UniverseColors.accent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: UniverseColors.accent),
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
    final tipY = h - 1;
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
      ..cubicTo(
        sideInset * 0.3,
        h * 0.42,
        sideInset,
        topInset,
        cx,
        topInset,
      )
      ..close();

    // Shadow
    canvas.drawShadow(
      path,
      const Color(0x55000000),
      isSelected ? 5 : 3,
      false,
    );

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
