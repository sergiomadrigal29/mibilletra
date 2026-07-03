import 'package:flutter/material.dart';
import '../models/categorias_static.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/state_views.dart';

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: grupos.map((grupo) {
        final cats = categorias.where((c) => c.grupo == grupo).toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppElevation.level1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm + 6,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    grupo.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.outline,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                ...cats.map((cat) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm + 2,
                  ),
                  child: Row(
                    children: [
                      CategoryIcon(
                        icon: cat.icono,
                        backgroundColor: esIngreso
                            ? AppTheme.primaryFixed
                            : AppTheme.tertiaryFixed,
                        iconColor: esIngreso ? AppTheme.primary : AppTheme.tertiary,
                        size: 40,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        cat.nombre,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
