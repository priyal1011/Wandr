import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'pincushion_distortion.dart';

class MainScaffold extends StatefulWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _getSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/trip/create')) return 1;
    if (location.startsWith('/memories')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.push('/trip/create');
        break;
      case 2:
        context.go('/memories');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    // Apply shader animation only when entering the Memories tab (index 2)
    return Animate(
      effects: [
        if (selectedIndex == 2)
          CustomEffect(
            begin: 1.5, // High distortion
            end: 0.0, // Crystal clear
            duration: 800.ms,
            curve: Curves.easeOutQuart,
            builder: (context, value, child) =>
                PincushionDistortion(distortionAmount: value, child: child),
          ),
      ],
      child: ScreenTypeLayout.builder(
        mobile: (context) => _MobileScaffold(
          selectedIndex: selectedIndex,
          onItemTapped: (index) => _onItemTapped(index, context),
          child: widget.child,
        ),
        tablet: (context) => _DesktopScaffold(
          selectedIndex: selectedIndex,
          onItemTapped: (index) => _onItemTapped(index, context),
          child: widget.child,
        ),
      ),
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const _MobileScaffold({
    required this.child,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          height: 72,
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(36),
            // boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withValues(alpha: 0.2),
            //     blurRadius: 10,
            //     spreadRadius: 2,
            //     offset: const Offset(0, 10),
            //   ),
            // ],
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.explore_outlined,
                label: 'Trips',
                isSelected: selectedIndex == 0,
                onTap: () => onItemTapped(0),
              ),
              _NavItem(
                icon: Icons.add_circle_outline,
                label: 'Create',
                isSelected: selectedIndex == 1,
                onTap: () => onItemTapped(1),
              ),
              _NavItem(
                icon: Icons.auto_awesome_mosaic_outlined,
                label: 'Memories',
                isSelected: selectedIndex == 2,
                onTap: () => onItemTapped(2),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isSelected: selectedIndex == 3,
                onTap: () => onItemTapped(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
              size: 26,
            ),
            if (isSelected) ...[
              const Gap(4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DesktopScaffold extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final Function(int) onItemTapped;

  const _DesktopScaffold({
    required this.child,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onItemTapped,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            indicatorColor: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.1),
            selectedIconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.primary,
            ),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Icon(
                Icons.travel_explore,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.explore_outlined),
                label: Text('Trips'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                label: Text('Create'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.auto_awesome_mosaic_outlined),
                label: Text('Memories'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
