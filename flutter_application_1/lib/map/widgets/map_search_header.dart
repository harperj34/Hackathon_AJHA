import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../models.dart';

/// Glass search bar + category filter chips pinned to the top of the map.
class MapSearchHeader extends StatelessWidget {
  final bool headerCollapsed;
  final String searchQuery;
  final TextEditingController searchController;
  final EventCategory? activeFilter;
  final bool showPlaces;
  final VoidCallback onRestoreHeader;
  final void Function(EventCategory) onFilterTap;
  final void Function(bool) onShowPlacesChanged;
  final void Function(String) onSearchChanged;

  const MapSearchHeader({
    super.key,
    required this.headerCollapsed,
    required this.searchQuery,
    required this.searchController,
    required this.activeFilter,
    required this.showPlaces,
    required this.onRestoreHeader,
    required this.onFilterTap,
    required this.onShowPlacesChanged,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: UniverseColors.glassWhite,
              border: const Border(
                bottom: BorderSide(color: Color(0x14000000), width: 0.5),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCollapsibleSection(),
                  const SizedBox(height: 10),
                  _buildFilterChips(),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsibleSection() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      alignment: Alignment.topCenter,
      child: headerCollapsed
          ? const SizedBox.shrink()
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTitleRow(),
                _buildSearchBar(),
              ],
            ),
    );
  }

  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Discover', style: UniverseTextStyles.displayLarge),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.80),
                shape: BoxShape.circle,
                border: Border.all(
                  color: UniverseColors.borderColor,
                  width: 0.5,
                ),
              ),
              child: const Icon(
                Icons.tune_rounded,
                size: 16,
                color: UniverseColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: UniverseColors.borderColor, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: 10),
            const Icon(
              Icons.search_rounded,
              size: 18,
              color: UniverseColors.iosSysGray,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(
                  color: UniverseColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  height: 1.0,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    color: UniverseColors.iosSysGray,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    height: 1.0,
                  ),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  searchController.clear();
                  onSearchChanged('');
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: UniverseColors.iosSysGray2,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          if (headerCollapsed) _buildRestoreSearchChip(),
          ...EventCategory.values
              .where((cat) => categoryInfo.containsKey(cat))
              .map((cat) => _buildCategoryChip(cat)),
          _buildRestaurantsChip(),
        ],
      ),
    );
  }

  Widget _buildRestoreSearchChip() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onRestoreHeader,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: UniverseColors.borderColor, width: 0.5),
          ),
          child: const Icon(
            Icons.search_rounded,
            size: 15,
            color: UniverseColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(EventCategory cat) {
    final info = categoryInfo[cat]!;
    final isActive = activeFilter == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onFilterTap(cat),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? info.color.withOpacity(0.10)
                : Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? info.color.withOpacity(0.30)
                  : UniverseColors.borderColor,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                info.icon,
                size: 13,
                color: isActive ? info.color : UniverseColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                info.label,
                style: TextStyle(
                  color: isActive ? info.color : UniverseColors.textSecondary,
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantsChip() {
    const orangeColor = Color(0xFFFF7043);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onShowPlacesChanged(!showPlaces),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: showPlaces
                ? orangeColor.withOpacity(0.10)
                : Colors.white.withOpacity(0.80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: showPlaces
                  ? orangeColor.withOpacity(0.30)
                  : UniverseColors.borderColor,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 13,
                color: showPlaces ? orangeColor : UniverseColors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                'Restaurants',
                style: TextStyle(
                  color:
                      showPlaces ? orangeColor : UniverseColors.textSecondary,
                  fontSize: 13,
                  fontWeight:
                      showPlaces ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
