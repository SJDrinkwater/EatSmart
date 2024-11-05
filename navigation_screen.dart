import 'package:flutter/material.dart';
import 'package:eat_smart/navigation_screens/got_some_spare.dart'; // Import GotSomeSpareScreen
import 'package:eat_smart/navigation_screens/home_screen.dart';
import 'package:eat_smart/navigation_screens/recipes_screen.dart';
import 'package:eat_smart/navigation_screens/shoppinglist_screen.dart';
import 'package:eat_smart/navigation_screens/settings_screen.dart';

class NavigationScreen extends StatefulWidget {
  final int userId;

  const NavigationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 2;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      GotSomeSpareScreen(),
      RecipesScreen(userId: widget.userId),
      HomeScreen(userId: widget.userId),
      ShoppingListScreen(userId: widget.userId),
      SettingsScreen(userId: widget.userId),
    ];

    return Scaffold(
  body: _screens[_currentIndex],
  bottomNavigationBar: BottomNavigationBar(
    currentIndex: _currentIndex,
    selectedItemColor: Colors.teal[900],
    unselectedItemColor: Colors.grey,
    backgroundColor: Colors.white,
    elevation: 5, 
    type: BottomNavigationBarType.fixed, 
    onTap: (index) {
      setState(() {
        _currentIndex = index;
      });
    },
    items: [
      BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Search',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.local_dining),
        label: 'Recipes',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: 'Cart',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ),
    ],
    selectedLabelStyle: TextStyle(fontFamily: 'MyFontText'), 
    unselectedLabelStyle: TextStyle(fontFamily: 'MyFontText'), 
  ),
);

  }
}
