import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../widgets/map_controls.dart';
import 'panel_shared.dart';

/// Bottom-sheet panel shown by default (no pin selected).
/// Displays a horizontal "Happening Now" carousel and an "All Events" list.
class HappeningNowPanel extends StatelessWidget {
  final ScrollController scrollController;
  final List<CampusEvent> events;
  final PageController pageController;
  final void Function(CampusEvent event) onEventTap;
  final void Function(int index) onPageChanged;
  final VoidCallback onDragHandleTap;

  const HappeningNowPanel({
    super.key,
    required this.scrollController,
    required this.events,
    required this.pageController,
    required this.onEventTap,
    required this.onPageChanged,
    required this.onDragHandleTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: scrollController,
      physics: const ClampingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DragHandle(onTap: onDragHandleTap),
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
                      '${events.length} events',
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
                  controller: pageController,
                  onPageChanged: onPageChanged,
                  itemCount: events.length,
                  itemBuilder: (context, i) => HappeningCard(
                    event: events[i],
                    onTap: () => onEventTap(events[i]),
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
            (ctx, i) => EventListRow(
              event: events[i],
              onTap: () => onEventTap(events[i]),
            ),
            childCount: events.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}
