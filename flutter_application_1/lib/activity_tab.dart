import 'package:flutter/material.dart';
import 'theme.dart';
import 'models.dart';
import 'session_state.dart';
import 'events_service.dart';

enum _ActivityFilter { mine, friends, both }

class ActivityTab extends StatefulWidget {
  const ActivityTab({super.key});

  @override
  State<ActivityTab> createState() => _ActivityTabState();
}

class _ActivityTabState extends State<ActivityTab> {
  _ActivityFilter _filter = _ActivityFilter.both;

  // Combine going events + my created events + active signals,
  // sorted by created_at (signals) or position in list (events)
  List<_ActivityItem> get _items {
    final items = <_ActivityItem>[];

    if (_filter == _ActivityFilter.friends) {
      // Friends-only — no friends system yet
      return [];
    }

    if (_filter == _ActivityFilter.mine || _filter == _ActivityFilter.both) {
      // Events user is going to
      for (final event in EventsService.currentEvents) {
        if (SessionState.isGoing(event.id)) {
          items.add(_ActivityItem(
            type: _ItemType.going,
            event: event,
            timestamp: DateTime.now(), // session only, no real timestamp
            label: 'You\'re going',
          ));
        }
      }

      // User's own created pins
      for (final event in SessionState.myCreatedEvents) {
        items.add(_ActivityItem(
          type: _ItemType.myPin,
          event: event,
          timestamp: DateTime.now(),
          label: 'Your pin',
        ));
      }

      // Active signals
      for (final signal in activeSignals) {
        if (!signal.isExpired) {
          items.add(_ActivityItem(
            type: _ItemType.signal,
            signal: signal,
            timestamp: signal.createdAt,
            label: 'Your signal',
          ));
        }
      }
    }

    // Sort by timestamp descending (newest first)
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Activity', style: UniverseTextStyles.displayLarge),
                const SizedBox(height: 4),
                const Text(
                  'Your campus activity this session',
                  style: TextStyle(
                    color: UniverseColors.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Filter chips ─────────────────────────
                Row(
                  children: [
                    _FilterChip(
                      label: 'Both',
                      isActive: _filter == _ActivityFilter.both,
                      onTap: () =>
                          setState(() => _filter = _ActivityFilter.both),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Mine',
                      isActive: _filter == _ActivityFilter.mine,
                      onTap: () =>
                          setState(() => _filter = _ActivityFilter.mine),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Friends',
                      isActive: _filter == _ActivityFilter.friends,
                      onTap: () =>
                          setState(() => _filter = _ActivityFilter.friends),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Content ──────────────────────────────────────
          Expanded(
            child: _filter == _ActivityFilter.friends
                ? _buildFriendsEmpty()
                : items.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) =>
                            _buildItem(items[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(_ActivityItem item) {
    if (item.type == _ItemType.signal && item.signal != null) {
      return _SignalActivityCard(signal: item.signal!);
    }
    if (item.event != null) {
      return _EventActivityCard(
        event: item.event!,
        label: item.label,
        type: item.type,
      );
    }
    return const SizedBox();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_outlined,
            size: 52,
            color: UniverseColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'Nothing here yet',
            style: TextStyle(
              color: UniverseColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'RSVP to events or drop a pin\nto see your activity here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: UniverseColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 52,
            color: UniverseColors.textLight,
          ),
          const SizedBox(height: 16),
          const Text(
            'No friends yet',
            style: TextStyle(
              color: UniverseColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add friends from your Profile\nto see their activity here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: UniverseColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model for activity items ─────────────────────────────────────────────

enum _ItemType { going, myPin, signal }

class _ActivityItem {
  final _ItemType type;
  final CampusEvent? event;
  final CampusSignal? signal;
  final DateTime timestamp;
  final String label;

  _ActivityItem({
    required this.type,
    this.event,
    this.signal,
    required this.timestamp,
    required this.label,
  });
}

// ── Card widgets ──────────────────────────────────────────────────────────────

class _EventActivityCard extends StatelessWidget {
  final CampusEvent event;
  final String label;
  final _ItemType type;

  const _EventActivityCard({
    required this.event,
    required this.label,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    final info = categoryInfo[event.category]!;
    final isGoing = type == _ItemType.going;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UniverseColors.borderColor),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isGoing ? Icons.check_circle_rounded : Icons.location_on_rounded,
              color: info.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: info.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: UniverseColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${event.location} · ${event.time}',
                  style: const TextStyle(
                    color: UniverseColors.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Attendees badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: info.color.withValues(alpha: 0.10),
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
        ],
      ),
    );
  }
}

class _SignalActivityCard extends StatelessWidget {
  final CampusSignal signal;

  const _SignalActivityCard({required this.signal});

  @override
  Widget build(BuildContext context) {
    final meta = signalCategoryMeta[signal.category]!;
    final remaining = signal.timeRemaining;
    final minsLeft = remaining.inMinutes;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: UniverseColors.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.sensors_rounded, color: meta.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Your signal · ${meta.label}',
                    style: TextStyle(
                      color: meta.color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  signal.message,
                  style: const TextStyle(
                    color: UniverseColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  'Expires in $minsLeft min · ${signal.timeAgoLabel}',
                  style: const TextStyle(
                    color: UniverseColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? UniverseColors.accent : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? UniverseColors.accent : UniverseColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : UniverseColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}