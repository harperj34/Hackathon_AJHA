import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'theme.dart';
import 'models.dart';
import 'event_detail.dart';

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
  final PageController _pageController = PageController(viewportFraction: 0.85);

  EventCategory? _activeFilter;
  CampusEvent? _selectedEvent;
  String _searchQuery = '';

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

  void _onFilterTap(EventCategory category) {
    setState(() {
      _activeFilter = _activeFilter == category ? null : category;
      _selectedEvent = null;
    });
  }

  void _onPinTap(CampusEvent event) {
    setState(() {
      _selectedEvent = event;
    });
    _mapController.move(event.position, 17.0);
    _sheetController.animateTo(
      0.35,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _onPageChanged(int index) {
    if (index < _filteredEvents.length) {
      final event = _filteredEvents[index];
      setState(() => _selectedEvent = event);
      _mapController.move(event.position, 16.5);
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    _sheetController.dispose();
    _searchController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- MAP ---
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(-37.9110, 145.1335),
            initialZoom: 15.5,
            onTap: (_, _) => setState(() => _selectedEvent = null),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.universe.app',
            ),
            MarkerLayer(
              markers: _filteredEvents.map((event) {
                final info = categoryInfo[event.category]!;
                final isSelected = _selectedEvent?.id == event.id;
                return Marker(
                  point: event.position,
                  width: isSelected ? 56 : 44,
                  height: isSelected ? 56 : 44,
                  child: GestureDetector(
                    onTap: () => _onPinTap(event),
                    child: _GlowingPin(
                      color: info.color,
                      icon: info.icon,
                      isSelected: isSelected,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        // --- SEARCH BAR + FILTER CHIPS ---
        SafeArea(
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C2E).withOpacity(0.92),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: UniverseColors.royalBlue.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Search buildings, events, clubs...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: UniverseColors.cyanBlue,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Colors.white38,
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
              // Filter chips
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: EventCategory.values.map((cat) {
                    final info = categoryInfo[cat]!;
                    final isActive = _activeFilter == cat;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: isActive,
                        label: Text(info.label),
                        avatar: Icon(
                          info.icon,
                          size: 16,
                          color: isActive ? Colors.white : info.color,
                        ),
                        labelStyle: TextStyle(
                          color: isActive ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        backgroundColor: const Color(
                          0xFF1C1C2E,
                        ).withOpacity(0.85),
                        selectedColor: info.color.withOpacity(0.7),
                        side: BorderSide(
                          color: isActive
                              ? info.color
                              : Colors.white.withOpacity(0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) => _onFilterTap(cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // --- BOTTOM DRAGGABLE PANEL ---
        DraggableScrollableSheet(
          controller: _sheetController,
          initialChildSize: 0.18,
          minChildSize: 0.08,
          maxChildSize: 0.75,
          snap: true,
          snapSizes: const [0.18, 0.45, 0.75],
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: UniverseColors.royalBlue.withOpacity(0.12),
                    blurRadius: 30,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: CustomScrollView(
                controller: scrollController,
                slivers: [
                  // Drag handle
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Panel header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              ShaderMask(
                                shaderCallback: (rect) => UniverseColors
                                    .cosmicGradient
                                    .createShader(rect),
                                child: const Text(
                                  '✦ ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Text(
                                'Happening Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '${_filteredEvents.length} events',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  // Horizontal event carousel (visible when partially expanded)
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 180,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: _filteredEvents.length,
                        itemBuilder: (context, index) {
                          final event = _filteredEvents[index];
                          return _EventPreviewCard(
                            event: event,
                            isSelected: _selectedEvent?.id == event.id,
                            onTap: () => _onPinTap(event),
                          );
                        },
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Divider
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          const Text(
                            'All Events',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Swipe up for more',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 8)),

                  // Full event list (visible when fully expanded)
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final event = _filteredEvents[index];
                      return _EventListTile(
                        event: event,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => EventDetailPage(event: event),
                            ),
                          );
                        },
                      );
                    }, childCount: _filteredEvents.length),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// --- Glowing Map Pin Widget ---
class _GlowingPin extends StatelessWidget {
  final Color color;
  final IconData icon;
  final bool isSelected;

  const _GlowingPin({
    required this.color,
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSelected ? 48.0 : 40.0;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow
        Container(
          width: size + 12,
          height: size + 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isSelected ? 0.6 : 0.35),
                blurRadius: isSelected ? 24 : 14,
                spreadRadius: isSelected ? 4 : 1,
              ),
            ],
          ),
        ),
        // Pin body
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(isSelected ? 0.9 : 0.5),
              width: isSelected ? 3 : 2,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: isSelected ? 22 : 18),
        ),
      ],
    );
  }
}

// --- Event Preview Card (horizontal carousel) ---
class _EventPreviewCard extends StatelessWidget {
  final CampusEvent event;
  final bool isSelected;
  final VoidCallback onTap;

  const _EventPreviewCard({
    required this.event,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[event.category]!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailPage(event: event)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF22223A),
          border: isSelected
              ? Border.all(color: info.color.withOpacity(0.6), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: (isSelected ? info.color : Colors.black).withOpacity(
                isSelected ? 0.25 : 0.3,
              ),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Event image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(20),
              ),
              child: Image.network(
                event.imageUrl,
                width: 120,
                height: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  width: 120,
                  color: info.color.withOpacity(0.3),
                  child: Icon(info.icon, color: info.color, size: 40),
                ),
              ),
            ),
            // Event info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        info.label,
                        style: TextStyle(
                          color: info.color,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 13,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          event.time.split(', ').last,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
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
  }
}

// --- Event List Tile (full expanded list) ---
class _EventListTile extends StatelessWidget {
  final CampusEvent event;
  final VoidCallback onTap;

  const _EventListTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[event.category]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: const Color(0xFF22223A),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    event.imageUrl,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 60,
                      height: 60,
                      color: info.color.withOpacity(0.2),
                      child: Icon(info.icon, color: info.color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${event.location} · ${event.time}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Attendees
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: info.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${event.attendees}',
                        style: TextStyle(
                          color: info.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'going',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
