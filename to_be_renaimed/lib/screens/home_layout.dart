import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/data_repository.dart';
import 'home/home_screen.dart';
import 'recipes/recipes_screen.dart';
import 'refrigerator/refrigerator_screen.dart';
import 'shopping/shopping_list_screen.dart';
import 'profile/profile_screen.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({Key? key}) : super(key: key);

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> {
  int _currentIndex = 0;
  bool _isRefreshing = false;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RecipesScreen(),
    const RefrigeratorScreen(),
    const ShoppingListScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final dataRepository = Provider.of<DataRepository>(context);

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Рецепты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: 'Холодильник',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Покупки',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
      // Add a refresh button in the app bar that appears when scrolling up
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton(
        mini: true,
        onPressed: () {
          _refreshData();
        },
        child: _isRefreshing
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.refresh),
      ) : null,
    );
  }

  Future<void> _refreshData() async {
    final dataRepository = Provider.of<DataRepository>(context, listen: false);

    setState(() {
      _isRefreshing = true;
    });

    try {
      await dataRepository.refreshAllData();

      // Если мы успешно обновили данные
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Данные успешно обновлены'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // В случае ошибки
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления данных: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRefreshing = false;
      });
    }
  }
}