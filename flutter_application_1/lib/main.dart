import 'package:flutter/material.dart';
import 'home.dart';
import 'map.dart';
import 'profile.dart';
 
void main() {
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 89, 183, 58)),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
 
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
 
  final String title;
 
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
 
class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
 
  static const List<Widget> _pages = <Widget>[
    HomePage(),
    MapPage(),
    ProfilePage(),
  ];
 
  static const List<String> _pageTitles = <String>[
    'Home',
    'Map',
    'Profile',
  ];
 
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(_pageTitles[_selectedIndex]),
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
