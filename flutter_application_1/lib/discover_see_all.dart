import 'package:flutter/material.dart';
import 'theme.dart';
 
class DiscoverSeeAll extends StatelessWidget {
  const DiscoverSeeAll({super.key});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              size: 18,
              color: UniverseColors.textPrimary,
            ),
            ),
          ),
          title: const Text(
            '🔥 Trending',
            style: TextStyle(
              color: UniverseColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          '🔥 Trending',
          style: TextStyle(
            fontSize: 32, fontWeight: FontWeight.bold),
            ),
            ),
        );
  }
}