import 'package:flutter/material.dart';
import 'theme.dart';
import 'models.dart';
import 'event_detail.dart';
 
class CategoryEvents extends StatelessWidget {
  final EventCategory category;
 
  const CategoryEvents({super.key, required this.category});
 
  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[category]!;
 
    final sortedEvents = [...sampleEvents]
      ..retainWhere((e) => e.category == category)
      ..sort((a, b) => b.attendees.compareTo(a.attendees));
 
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(info.icon, color: info.color, size: 22),
            const SizedBox(width: 8),
            Text(
              info.label,
              style: const TextStyle(
                color: UniverseColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: sortedEvents.isEmpty
          ? Center(
              child: Text(
                'No ${info.label} events right now',
                style: const TextStyle(
                  color: UniverseColors.textMuted,
                  fontSize: 15,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: sortedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final event = sortedEvents[index];
 
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 12),
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