import 'package:flutter/material.dart';
import 'add_movimiento_screen.dart';
import 'home_tab.dart';
import 'history_tab.dart';
import 'profile_tab.dart';
import '../theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final _homeKey = GlobalKey<HomeTabState>();
  final _historyKey = GlobalKey<HistoryTabState>();
  final _profileKey = GlobalKey<ProfileTabState>();

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  void _recargarTabs() {
    _homeKey.currentState?.recargar();
    _historyKey.currentState?.recargar();
    _profileKey.currentState?.recargar();
  }

  Future<void> _navegarAddMovimiento(int idTipo) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddMovimientoScreen(idTipo: idTipo),
      ),
    );
    if (result == true) {
      _recargarTabs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeTab(key: _homeKey),
          HistoryTab(key: _historyKey, onCambio: _recargarTabs),
          ProfileTab(key: _profileKey),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _currentIndex == 0 ? _buildFab() : null,
    );
  }

  Widget _buildBottomNav() {
    final items = [
      ('Inicio', Icons.home_outlined, Icons.home),
      ('Historial', Icons.history_outlined, Icons.history),
      ('Perfil', Icons.person_outlined, Icons.person),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final isActive = _currentIndex == i;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onTabTapped(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.secondaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isActive ? items[i].$3 : items[i].$2,
                        size: 22,
                        color: isActive
                            ? AppTheme.onSecondaryContainer
                            : AppTheme.onSurfaceVariant,
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        Text(
                          items[i].$1,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.onSecondaryContainer,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'income',
          backgroundColor: AppTheme.primaryContainer,
          foregroundColor: AppTheme.onPrimaryContainer,
          onPressed: () => _navegarAddMovimiento(1),
          child: const Icon(Icons.add, size: 28),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'expense',
          backgroundColor: AppTheme.errorContainer,
          foregroundColor: AppTheme.onErrorContainer,
          onPressed: () => _navegarAddMovimiento(2),
          child: const Icon(Icons.remove, size: 28),
        ),
      ],
    );
  }
}
