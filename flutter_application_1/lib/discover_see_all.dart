import 'package:flutter/material.dart';
import 'theme.dart';
import 'models.dart';
import 'event_detail.dart';
 
class DiscoverSeeAll extends StatelessWidget {
  const DiscoverSeeAll({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: UniverseColors.borderColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: UniverseColors.textPrimary,
              size: 18,
            ),
          ),
        ),
        title: const Text(
          'Trending',
          style: TextStyle(
            color: UniverseColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: sampleEvents.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: UniverseColors.borderColor),
              ),
              child: Row(
                children: [
                  // Icon or image thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      event.imageUrl,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: info.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(info.icon, color: info.color, size: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  // Event details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            color: UniverseColors.textPrimary,
                            fontSize: 21,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          event.location,
                          style: const TextStyle(
                            color: UniverseColors.textLight,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Attendees badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    decoration: BoxDecoration(
                      color: info.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(
                      '${event.attendees} going',
                      style: TextStyle(
                        color: info.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}