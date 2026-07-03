import 'package:flutter/material.dart';
import 'add_movimiento_screen.dart';
import 'home_tab.dart';
import 'history_tab.dart';
import 'profile_tab.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';

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
    final isCompact = context.isCompactWidth;
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
      bottomNavigationBar: _buildBottomNav(isCompact),
      floatingActionButton: _currentIndex == 0 ? _buildFab(isCompact) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBottomNav(bool isCompact) {
    final items = [
      ('Inicio', Icons.home_outlined, Icons.home),
      ('Historial', Icons.history_outlined, Icons.history),
      ('Perfil', Icons.person_outlined, Icons.person),
    ];

    final hPad = isCompact ? 12.0 : 20.0;

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
          padding: EdgeInsets.fromLTRB(hPad, 8, hPad, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              final isActive = _currentIndex == i;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onTabTapped(i),
                child: AnimatedContainer(
                  duration: AppAnimation.normal,
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 14 : 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.secondaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadius.full),
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
                        Flexible(
                          child: Text(
                            items[i].$1,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.onSecondaryContainer,
                            ),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildFab(bool isCompact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'income',
          mini: isCompact,
          backgroundColor: AppTheme.primaryContainer,
          foregroundColor: AppTheme.onPrimaryContainer,
          onPressed: () => _navegarAddMovimiento(1),
          child: const Icon(Icons.add, size: 28),
        ),
        SizedBox(height: isCompact ? 8 : 12),
        FloatingActionButton(
          heroTag: 'expense',
          mini: isCompact,
          backgroundColor: AppTheme.errorContainer,
          foregroundColor: AppTheme.onErrorContainer,
          onPressed: () => _navegarAddMovimiento(2),
          child: const Icon(Icons.remove, size: 28),
        ),
      ],
    );
  }
}
