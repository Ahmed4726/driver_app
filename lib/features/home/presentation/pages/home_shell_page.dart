import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import 'dashboard_page.dart';
import 'earnings_page.dart';
import 'settings_page.dart';
import 'trips_page.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key, this.initialTab = 0, this.initialTripMode = TripPageMode.list});

  final int initialTab;
  final TripPageMode initialTripMode;

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  late int _selectedIndex;
  late TripPageMode _tripMode;

  static const _titles = [
    'Home',
    'Trips',
    'Earnings',
    'Settings',
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTab.clamp(0, 3);
    _tripMode = widget.initialTripMode;
  }

  List<Widget> get _pages {
    return [
      const DashboardPage(),
      TripsPage(
        key: ValueKey('trips-$_tripMode'),
        initialMode: _tripMode,
        onBackToTrips: _showTripsList,
      ),
      const EarningsPage(),
      const SettingsPage(),
    ];
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      _showTripsList();
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _showTripsList() {
    setState(() {
      _selectedIndex = 1;
      _tripMode = TripPageMode.list;
    });
  }

  void _showCreateTrip() {
    setState(() {
      _selectedIndex = 1;
      _tripMode = TripPageMode.create;
    });
  }

  @override
  Widget build(BuildContext context) {
    final showProfileActions = _selectedIndex == 0 || _selectedIndex == 3;
    final showBackToTrips = _selectedIndex == 1 && _tripMode == TripPageMode.create;

    return Scaffold(
      appBar: AppBar(
        title: Text(showBackToTrips ? 'Create Trip' : _titles[_selectedIndex]),
        backgroundColor: AppColors.primary,
        leading: showBackToTrips
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back to trips',
                onPressed: _showTripsList,
              )
            : showProfileActions
                ? IconButton(
                    icon: const Icon(Icons.person),
                    tooltip: 'Profile',
                    onPressed: () => context.go(RouteNames.profile),
                  )
                : null,
        actions: showBackToTrips
            ? null
            : [
                if (_selectedIndex == 1 && _tripMode == TripPageMode.list)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Create trip',
                      onPressed: _showCreateTrip,
                    ),
                  ),
                if (showProfileActions)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.primary),
                        tooltip: 'Logout',
                        onPressed: () {
                          context.read<AuthBloc>().add(LogoutRequested());
                        },
                      ),
                    ),
                  ),
              ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt),
            label: 'Trips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
