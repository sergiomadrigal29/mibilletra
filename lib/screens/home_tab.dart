import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/app_card.dart';
import '../widgets/amount_text.dart';
import '../widgets/movement_tile.dart';
import '../widgets/state_views.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  String _nombreUsuario = '';
  double _totalIngresos = 0;
  double _totalGastos = 0;
  List<Map<String, dynamic>> _ultimosMovimientos = [];
  Map<String, double> _gastosPorCategoria = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void recargar() => _cargarDatos();

  Future<void> _cargarDatos() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supabase = SupabaseService.instance;
      final user = supabase.currentUser;
      if (user == null) return;

      final idAuthUser = user.id;

      final usuarioResult = await supabase.client
          .from('usuario')
          .select('id_usuario, nombre')
          .eq('id_auth_user', idAuthUser)
          .maybeSingle();

      if (usuarioResult == null) {
        setState(() {
          _error = 'Usuario no encontrado en la base de datos.\nVerifica que el registro se haya completado correctamente.';
          _loading = false;
        });
        return;
      }

      final idUsuario = (usuarioResult['id_usuario'] as int?) ?? 0;
      final nombre = usuarioResult['nombre'] as String? ?? 'Usuario';

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final movimientos = await supabase.client
          .from('movimiento')
          .select('*, categoria(nombre), tipo_movimiento(nombre)')
          .eq('id_usuario', idUsuario)
          .gte('fecha', startOfMonth.toIso8601String())
          .order('fecha', ascending: false);

      double ingresos = 0;
      double gastos = 0;
      Map<String, double> gastosCat = {};

      final movs = List<Map<String, dynamic>>.from(movimientos);
      for (final m in movs) {
        final monto = ((m['monto'] as num?) ?? 0).toDouble();
        final idTipo = (m['id_tipo'] as int?) ?? 1;
        if (idTipo == 1) {
          ingresos += monto;
        } else {
          gastos += monto;
          final cat =
              (m['categoria'] as Map<String, dynamic>?)?['nombre'] as String? ??
                  'Sin categoría';
          gastosCat[cat] = (gastosCat[cat] ?? 0) + monto;
        }
      }

      if (!mounted) return;
      setState(() {
        _nombreUsuario = nombre;
        _totalIngresos = ingresos;
        _totalGastos = gastos;
        _ultimosMovimientos = movs.take(5).toList();
        _gastosPorCategoria = gastosCat;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar datos: ${e.toString()}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _cargarDatos);

    final saldo = _totalIngresos - _totalGastos;
    final totalGastos = _gastosPorCategoria.values.fold<double>(0, (a, b) => a + b);
    final pctGastos = totalGastos > 0 ? (_totalGastos / (_totalIngresos + _totalGastos) * 100) : 0.0;

    final topPadding = MediaQuery.of(context).padding.top;

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.xl,
          topPadding + AppSpacing.sm,
          AppSpacing.xl,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.xl),
            _buildBalanceCard(context, saldo, pctGastos),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Ingresos',
                    _totalIngresos,
                    AppTheme.primary,
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildSummaryCard(
                    context,
                    'Gastos',
                    _totalGastos,
                    AppTheme.error,
                    Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(title: 'Distribución de gastos'),
            const SizedBox(height: AppSpacing.lg),
            _buildChart(context),
            const SizedBox(height: AppSpacing.xxl),
            SectionHeader(
              title: 'Últimos movimientos',
              actionLabel: _ultimosMovimientos.length >= 5 ? 'Ver todos' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._ultimosMovimientos.map((m) => MovementTile(movimiento: m)),
            if (_ultimosMovimientos.isEmpty)
              EmptyView(
                icon: Icons.receipt_long_outlined,
                message: 'No hay movimientos este mes',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $_nombreUsuario',
          style: Theme.of(context).textTheme.headlineLarge,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Resumen del mes',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(BuildContext context, double saldo, double pctGastos) {
    return AppCard.elevated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AmountText(
                amount: saldo,
                positiveColor: AppTheme.primary,
                negativeColor: AppTheme.error,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  height: 1,
                ),
              ),
              if (_totalIngresos + _totalGastos > 0) ...[
                const SizedBox(width: AppSpacing.md),
                _buildHealthBadge(context, pctGastos),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBadge(BuildContext context, double pctGastos) {
    final isHealthy = pctGastos <= 70;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: isHealthy ? AppTheme.primaryFixed : AppTheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHealthy ? Icons.trending_up : Icons.trending_down,
            size: AppIconSize.xs,
            color: isHealthy ? AppTheme.primary : AppTheme.error,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${(100 - pctGastos).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: isHealthy ? AppTheme.primary : AppTheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String titulo,
    double monto,
    Color color,
    IconData icono,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      border: Border(left: BorderSide(color: color, width: 4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: AppIconSize.sm, color: color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                titulo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AmountText(
            amount: monto,
            positiveColor: color,
            negativeColor: color,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    if (_gastosPorCategoria.isEmpty) {
      return AppCard.elevated(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: AppIconSize.display,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sin gastos registrados',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final colores = [
      AppTheme.primary,
      AppTheme.secondary,
      AppTheme.tertiary,
      AppTheme.error,
      AppTheme.onSurfaceVariant,
      AppTheme.primaryFixedDim,
    ];

    return AppCard.elevated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final chartSize = constraints.maxWidth * 0.35;
          return Row(
            children: [
              SizedBox(
                height: chartSize.clamp(100, 180),
                width: chartSize.clamp(100, 180),
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: chartSize * 0.28,
                    sections: _gastosPorCategoria.entries
                        .toList()
                        .asMap()
                        .entries
                        .map(
                          (e) => PieChartSectionData(
                            value: e.value.value,
                            color: colores[e.key % colores.length],
                            radius: 30,
                            title: '',
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _gastosPorCategoria.entries
                      .toList()
                      .asMap()
                      .entries
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colores[e.key % colores.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  e.value.key,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Text(
                                  '${((e.value.value / _gastosPorCategoria.values.fold<double>(0, (a, b) => a + b)) * 100).toStringAsFixed(0)}%',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppTheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
