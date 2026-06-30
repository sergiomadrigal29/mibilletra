import 'package:flutter/material.dart';
import '../models/categorias_static.dart';
import '../theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Categorías'),
          bottom: const TabBar(
            labelColor: AppTheme.onSurface,
            unselectedLabelColor: AppTheme.onSurfaceVariant,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'Ingresos'),
              Tab(text: 'Gastos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(context, ingresoCategorias, true),
            _buildList(context, gastoCategorias, false),
          ],
        ),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<CategoriaData> categorias, bool esIngreso) {
    final grupos = categorias.map((c) => c.grupo).toSet().toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: grupos.map((grupo) {
        final cats = categorias.where((c) => c.grupo == grupo).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Text(
                    grupo.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.outline,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                ...cats.map((cat) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: esIngreso
                              ? AppTheme.primaryFixed
                              : AppTheme.tertiaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          cat.icono,
                          size: 20,
                          color: esIngreso ? AppTheme.primary : AppTheme.tertiary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        cat.nombre,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
