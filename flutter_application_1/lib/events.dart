import 'package:flutter/material.dart';
 
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
 
  @override
  State<EventsPage> createState() => _EventsPageState();
}
 
class _EventsPageState extends State<EventsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
 
  double _dragStartX = 0;
  double _dragDistance = 0;
  bool _isDragging = false;
 
  static const double _swipeThreshold = 100.0;
  static const double _edgeStartZone = 40.0;
 
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(1.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }
 
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
 
  void _onHorizontalDragStart(DragStartDetails details) {
    if (details.globalPosition.dx <= _edgeStartZone) {
      _isDragging = true;
      _dragStartX = details.globalPosition.dx;
    }
  }
 
  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    final screenWidth = MediaQuery.of(context).size.width;
    _dragDistance = details.globalPosition.dx - _dragStartX;
    if (_dragDistance < 0) _dragDistance = 0;
    _controller.value = (_dragDistance / screenWidth).clamp(0.0, 1.0);
  }
 
  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;
 
    final velocity = details.primaryVelocity ?? 0;
 
    if (_dragDistance >= _swipeThreshold || velocity > 800) {
      _controller.forward().then((_) {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    } else {
      _controller.reverse();
    }
    _dragDistance = 0;
  }
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: SlideTransition(
        position: _slideAnimation,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Events'),
          ),
          body: const Center(
            child: Text(
              'Events Page',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}