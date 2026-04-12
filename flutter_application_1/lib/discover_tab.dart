import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'theme.dart';
import 'models.dart';
import 'event_detail.dart';
import 'discover_see_all.dart';
import 'category_events.dart';
import 'events_service.dart';

class DiscoverTab extends StatelessWidget {
  const DiscoverTab({super.key});

  @override
  Widget build(BuildContext context) {
    final featured = sampleEvents.first;
    final featuredInfo = categoryInfo[featured.category]!;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // ── Page header ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Discover', style: UniverseTextStyles.displayLarge),
                  const SizedBox(height: 4),
                  const Text(
                    "What's happening on campus today",
                    style: TextStyle(
                      color: UniverseColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Featured Today hero card ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: UniverseColors.accent,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Featured Today',
                        style: UniverseTextStyles.sectionHeader,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(event: featured),
                      ),
                    ),
                    child: Container(
                      height: 214,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              featured.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: featuredInfo.color.withOpacity(0.25),
                                child: Icon(
                                  featuredInfo.icon,
                                  size: 64,
                                  color: featuredInfo.color,
                                ),
                              ),
                            ),
                            // Dark gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.72),
                                  ],
                                  stops: const [0.35, 1.0],
                                ),
                              ),
                            ),
                            // Bottom text
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: featuredInfo.color,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          featuredInfo.icon,
                                          size: 11,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          featuredInfo.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    featured.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      height: 1.2,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${featured.subtitle}  ·  ${featured.time}',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.82),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Attendee badge top-right
                            Positioned(
                              top: 14,
                              right: 14,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.46),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.people_rounded,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${featured.attendees} going',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 28)),

          // ── Trending section ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 18,
                        color: Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        'Trending',
                        style: UniverseTextStyles.sectionHeader,
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const DiscoverSeeAll(),
                        transitionsBuilder: (_, animation, __, child) => SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                          child: child,
                        ),
                      ),
                    ),
                    child: const Text(
                      'See all',
                      style: TextStyle(
                        color: UniverseColors.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 252,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                itemCount: EventsService.currentEvents.length,
                itemBuilder: (context, index) {
                  final event = EventsService.currentEvents[index];
                  final info = categoryInfo[event.category]!;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(event: event),
                      ),
                    ),
                    child: Container(
                      width: 202,
                      margin: const EdgeInsets.only(right: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 12,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            child: Image.network(
                              event.imageUrl,
                              height: 132,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 132,
                                color: info.color.withOpacity(0.18),
                                child: Icon(
                                  info.icon,
                                  color: info.color,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 11,
                                      color: UniverseColors.textLight,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      event.time.split(', ').last,
                                      style: const TextStyle(
                                        color: UniverseColors.textLight,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Text(
                                      '·',
                                      style: TextStyle(
                                        color: UniverseColors.textLight,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        event.location,
                                        style: const TextStyle(
                                          color: UniverseColors.textLight,
                                          fontSize: 11,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // Categories grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Browse by Category',
                style: UniverseTextStyles.sectionHeader,
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.7,
              ),
              delegate: SliverChildListDelegate(
                EventCategory.values.map((cat) => _CategoryCard(category: cat)).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final EventCategory category;

  const _CategoryCard({required this.category, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[category]!;
    final width = MediaQuery.of(context).size.width;
    final int maxPhotos = width < 360 ? 2 : (width < 600 ? 3 : 4);
    final images = sampleEvents.where((e) => e.category == category).map((e) => e.imageUrl).take(maxPhotos).toList();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [info.color.withOpacity(0.2), info.color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: info.color.withOpacity(0.15), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => CategoryEvents(category: category),
                transitionsBuilder: (_, animation, __, child) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: double.infinity,
              width: double.infinity,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(info.icon, color: info.color, size: 28),
                        const SizedBox(height: 8),
                        Text(
                          info.label,
                          style: const TextStyle(
                            color: UniverseColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (images.isNotEmpty)
                      Positioned(top: 12, right: 12, child: _buildPhotoFan(images, info.color, info.icon, width)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoFan(List<String> urls, Color color, IconData icon, double deviceWidth) {
    final double photoSize = deviceWidth < 360 ? 44 : (deviceWidth < 600 ? 54 : 64);
    final double overlap = photoSize * 0.65;
    final double fanWidth = photoSize + (urls.length - 1) * overlap;

    return SizedBox(
      width: fanWidth,
      height: photoSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < urls.length; i++)
            Positioned(
              right: i * overlap,
              child: Transform.rotate(
                angle: ((i - (urls.length - 1) / 2) * 6) * math.pi / 180,
                alignment: Alignment.center,
                child: Container(
                  width: photoSize,
                  height: photoSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 6, offset: Offset(0, 2))],
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      urls[i],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: color.withOpacity(0.12), child: Icon(icon, color: color)),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CategoryListPage extends StatelessWidget {
  final EventCategory category;

  const CategoryListPage({required this.category, super.key});

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[category]!;
    final isStudy = category == EventCategory.study;
    final items = isStudy ? sampleStudySpots : sampleEvents.where((e) => e.category == category).toList();
    return Scaffold(
      appBar: AppBar(title: Text(info.label), backgroundColor: Colors.white, foregroundColor: UniverseColors.textPrimary, elevation: 1),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (ctx, i) {
          if (isStudy) {
            final s = items[i] as dynamic;
            return ListTile(
              leading: Container(width: 56, height: 56, decoration: BoxDecoration(color: info.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(info.icon, color: info.color)),
              title: Text(s.title, style: const TextStyle(color: UniverseColors.textPrimary, fontWeight: FontWeight.w700)),
              subtitle: Text(s.location, style: const TextStyle(color: UniverseColors.textLight)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudySpotDetailPage(spot: s))),
            );
          } else {
            final e = items[i] as CampusEvent;
            return ListTile(
              leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(e.imageUrl, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (_,__,___)=> Container(width:56, height:56, color: info.color.withOpacity(0.12), child: Icon(info.icon, color: info.color)))),
              title: Text(e.title, style: const TextStyle(color: UniverseColors.textPrimary, fontWeight: FontWeight.w700)),
              subtitle: Text('${e.location} · ${e.time}', style: const TextStyle(color: UniverseColors.textLight)),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailPage(event: e))),
            );
          }
        },
        separatorBuilder: (_, __) => const Divider(height: 16),
        itemCount: items.length,
      ),
    );
  }
}

class StudySpotDetailPage extends StatelessWidget {
  final StudySpot spot;

  const StudySpotDetailPage({required this.spot, super.key});

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[EventCategory.study]!;
    return Scaffold(
      appBar: AppBar(title: const Text('Study Spot'), backgroundColor: Colors.white, foregroundColor: UniverseColors.textPrimary, elevation: 1),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(height: 180, decoration: BoxDecoration(color: info.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Center(child: Icon(info.icon, size: 48, color: info.color))),
          const SizedBox(height: 16),
          Text(spot.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: UniverseColors.textPrimary)),
          const SizedBox(height: 8),
          Text(spot.location, style: const TextStyle(color: UniverseColors.textLight)),
          const SizedBox(height: 20),
          const Text('This study spot is permanent and has no attendance controls.', style: TextStyle(color: UniverseColors.textLight)),
        ]),
      ),
    );
  }
}
