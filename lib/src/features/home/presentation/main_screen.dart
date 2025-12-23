import 'package:flutter/material.dart';
import 'package:freelancer_flutter/src/core/constants/app_colors.dart';
import 'package:freelancer_flutter/src/features/home/presentation/home_screen.dart';
import 'package:freelancer_flutter/src/features/home/presentation/services_screen.dart';
import 'package:freelancer_flutter/src/features/home/presentation/profile_screen.dart';
import 'package:freelancer_flutter/src/features/home/presentation/send_proposal_screen.dart';
import 'package:freelancer_flutter/src/features/auth/presentation/auth_selection_screen.dart';
import 'package:freelancer_flutter/src/features/chat/presentation/proposal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainScreen extends StatefulWidget {
  final bool isGuest;
  const MainScreen({super.key, this.isGuest = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    debugPrint('MainScreen initialized. isGuest: ${widget.isGuest}');
    _selectedIndex = widget.isGuest ? 1 : 0; // Default to Services for Guest
    _screens = [
      HomeScreen(isGuest: widget.isGuest),
      const ServicesScreen(),
      if (!widget.isGuest) const SendProposalScreen(), // Hidden for Guest
      if (!widget.isGuest) const ProfileScreen(),      // Hidden for Guest
    ];
    
    // Check for pending actions only if not guest
    if (!widget.isGuest) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkPendingActions();
      });
    }
  }

  Future<void> _checkPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final pendingProposal = prefs.getString('pending_proposal');
    
    if (pendingProposal != null && mounted) {
      // Clear it so it doesn't persist forever
      await prefs.remove('pending_proposal');
      
      // Navigate to proposal screen and wait for it to close
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProposalScreen(proposalContent: pendingProposal),
        ),
      );
      
      // Refresh screens to reflect new data (like new projects)
      if (mounted) {
        setState(() {
          _screens = [
            HomeScreen(isGuest: widget.isGuest),
            const ServicesScreen(),
            if (!widget.isGuest) const SendProposalScreen(),
            if (!widget.isGuest) const ProfileScreen(),
          ];
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (widget.isGuest && index == 2) {
      // Sign In tapped
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthSelectionScreen()),
        (route) => false,
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body content switches based on index
      // WE REMOVED IndexedStack TO FORCE REFRESH ON TAB SWITCH
      // This ensures SendProposalScreen fetches the latest projects (e.g. created via Chat).
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Theme.of(context).disabledColor,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: widget.isGuest 
          ? [
             const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.grid_view),
                activeIcon: Icon(Icons.grid_view_rounded),
                label: 'Services',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.login),
                activeIcon: Icon(Icons.login),
                label: 'Sign In',
              ),
          ]
          : [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.grid_view),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Services',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.send_outlined),
            activeIcon: Icon(Icons.send),
            label: 'Hire',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
