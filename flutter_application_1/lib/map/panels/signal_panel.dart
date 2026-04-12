import 'package:flutter/material.dart';
import '../../models.dart';
import '../../theme.dart';
import '../widgets/map_controls.dart';
import '../widgets/map_markers.dart';

/// Bottom-sheet panel shown when the user selects a campus signal pin.
class SignalPanel extends StatelessWidget {
  final ScrollController scrollController;
  final CampusSignal signal;
  final VoidCallback onDragHandleTap;
  final VoidCallback onDismiss;
  final VoidCallback onRemoveSignal;

  const SignalPanel({
    super.key,
    required this.scrollController,
    required this.signal,
    required this.onDragHandleTap,
    required this.onDismiss,
    required this.onRemoveSignal,
  });

  @override
  Widget build(BuildContext context) {
    final meta = signalCategoryMeta[signal.category]!;
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
                DragHandle(onTap: onDragHandleTap),

                // ── Header row ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: meta.color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sensors_rounded,
                            size: 13,
                            color: meta.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Signal · ${meta.label}',
                            style: TextStyle(
                              color: meta.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onDismiss,
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
                const SizedBox(height: 14),

                // ── Message bubble ────────────────────────────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: meta.color.withOpacity(0.18)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(meta.icon, color: meta.color, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          signal.message,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: UniverseColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Meta row — time + expiry ───────────────────────────────
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: UniverseColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      signal.timeAgoLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        color: UniverseColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.timer_outlined,
                      size: 13,
                      color: UniverseColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    SignalCountdown(signal: signal),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Dismiss button ────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: GestureDetector(
                    onTap: onDismiss,
                    child: Container(
                      decoration: BoxDecoration(
                        color: UniverseColors.bgPage,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: UniverseColors.borderColor),
                      ),
                      child: const Center(
                        child: Text(
                          'Dismiss',
                          style: TextStyle(
                            color: UniverseColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Remove Signal button ──────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: GestureDetector(
                    onTap: onRemoveSignal,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEEEE),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFCCCC)),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFEF5350),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Remove Signal',
                              style: TextStyle(
                                color: Color(0xFFEF5350),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
