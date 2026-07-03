import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

import '../models/categorias_static.dart';

IconData _iconForCategoria(String nombre) {
  final ingreso = ingresoCategorias.where((c) => c.nombre == nombre).firstOrNull;
  if (ingreso != null) return ingreso.icono;
  final gasto = gastoCategorias.where((c) => c.nombre == nombre).firstOrNull;
  if (gasto != null) return gasto.icono;
  return Icons.receipt_long_outlined;
}

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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final saldo = _totalIngresos - _totalGastos;
    final totalGastos = _gastosPorCategoria.values.fold<double>(0, (a, b) => a + b);
    final pctGastos = totalGastos > 0 ? (_totalGastos / (_totalIngresos + _totalGastos) * 100) : 0.0;

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 48, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, $_nombreUsuario',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Resumen del mes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildBalanceCard(saldo, pctGastos),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Ingresos',
                    _totalIngresos,
                    AppTheme.primary,
                    Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Gastos',
                    _totalGastos,
                    AppTheme.error,
                    Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Distribución de gastos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Últimos movimientos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_ultimosMovimientos.length >= 5)
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      'Ver todos',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppTheme.secondary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ..._ultimosMovimientos.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildMovementTile(m),
            )),
            if (_ultimosMovimientos.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No hay movimientos este mes',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double saldo, double pctGastos) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'C\$${NumberFormat('#,##0.00').format(saldo)}',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: saldo >= 0 ? AppTheme.primary : AppTheme.error,
                  height: 1,
                ),
              ),
              if (_totalIngresos + _totalGastos > 0) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: pctGastos <= 70
                        ? AppTheme.primaryFixed
                        : AppTheme.errorContainer,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pctGastos <= 70 ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: pctGastos <= 70
                            ? AppTheme.primary
                            : AppTheme.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(100 - pctGastos).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: pctGastos <= 70
                              ? AppTheme.primary
                              : AppTheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String titulo,
    double monto,
    Color color,
    IconData icono,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
        border: Border(
          left: BorderSide(color: color, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                titulo,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'C\$${NumberFormat('#,##0.00').format(monto)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (_gastosPorCategoria.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Row(
        children: [
          SizedBox(
            height: 140,
            width: 140,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
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
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _gastosPorCategoria.entries
                  .toList()
                  .asMap()
                  .entries
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              e.value.key,
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${((e.value.value / _gastosPorCategoria.values.fold<double>(0, (a, b) => a + b)) * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppTheme.onSurfaceVariant,
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
      ),
    );
  }

  Widget _buildMovementTile(Map<String, dynamic> m) {
    final monto = ((m['monto'] as num?) ?? 0).toDouble();
    final idTipo = (m['id_tipo'] as int?) ?? 1;
    final esIngreso = idTipo == 1;
    final catNombre =
        (m['categoria'] as Map<String, dynamic>?)?['nombre'] as String? ??
            'General';
    final descripcion = m['descripcion'] as String?;
    final fecha = DateTime.tryParse(m['fecha']?.toString() ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: esIngreso
                  ? AppTheme.primaryFixed
                  : AppTheme.tertiaryFixed,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _iconForCategoria(catNombre),
              color: esIngreso ? AppTheme.primary : AppTheme.tertiary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion ?? catNombre,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  catNombre,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${esIngreso ? '+' : '-'}C\$${NumberFormat('#,##0.00').format(monto)}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: esIngreso ? AppTheme.primary : AppTheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (fecha != null)
                Text(
                  DateFormat('d MMM').format(fecha),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
