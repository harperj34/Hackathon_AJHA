import 'package:flutter/material.dart';
import 'theme.dart';
import 'models.dart';
import 'event_detail.dart';
import 'discover_see_all.dart';
import 'category_events.dart';

class DiscoverTab extends StatelessWidget {
  const DiscoverTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Discover',
                    style: TextStyle(
                      color: UniverseColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "What's happening on campus today",
                    style: TextStyle(
                      color: UniverseColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Trending section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    '🔥 Trending',
                    style: TextStyle(
                      color: UniverseColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const DiscoverSeeAll(),
                        transitionsBuilder: (_, animation, __, child) =>
                        SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(1.0, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation, 
                            curve: Curves.easeOut,
                            )),
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
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                itemCount: sampleEvents.length,
                itemBuilder: (context, index) {
                  final event = sampleEvents[index];
                  final info = categoryInfo[event.category]!;
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EventDetailPage(event: event),
                      ),
                    ),
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        border: Border.all(color: UniverseColors.borderColor),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 8,
                            offset: Offset(0, 2),
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
                              height: 110,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 110,
                                color: info.color.withOpacity(0.2),
                                child: Icon(
                                  info.icon,
                                  color: info.color,
                                  size: 36,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                Text(
                                  event.location,
                                  style: const TextStyle(
                                    color: UniverseColors.textLight,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: info.color,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${event.attendees} going',
                                      style: TextStyle(
                                        color: info.color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
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
              child: const Text(
                'Browse by Category',
                style: TextStyle(
                  color: UniverseColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
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
                EventCategory.values.map((cat) {
                  final info = categoryInfo[cat]!;
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: [
                          info.color.withOpacity(0.2),
                          info.color.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: info.color.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => CategoryEvents(category: cat),
                          transitionsBuilder: (_, animation, __, child) => SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1.0, 0.0),
                              end: Offset.zero,).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                              child: child,
                            )
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
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
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
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
