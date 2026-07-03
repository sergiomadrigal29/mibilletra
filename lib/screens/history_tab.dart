import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../models/categorias_static.dart';
import 'add_movimiento_screen.dart';

IconData _iconForCategoria(String nombre) {
  final ingreso = ingresoCategorias.where((c) => c.nombre == nombre).firstOrNull;
  if (ingreso != null) return ingreso.icono;
  final gasto = gastoCategorias.where((c) => c.nombre == nombre).firstOrNull;
  if (gasto != null) return gasto.icono;
  return Icons.receipt_long_outlined;
}

class HistoryTab extends StatefulWidget {
  final VoidCallback? onCambio;

  const HistoryTab({super.key, this.onCambio});

  @override
  State<HistoryTab> createState() => HistoryTabState();
}

class HistoryTabState extends State<HistoryTab> {
  List<Map<String, dynamic>> _movimientos = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarMovimientos();
  }

  void recargar() => _cargarMovimientos();

  Future<void> _cargarMovimientos() async {
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
          .select('id_usuario')
          .eq('id_auth_user', idAuthUser)
          .maybeSingle();

      if (usuarioResult == null) {
        setState(() {
          _error = 'Usuario no encontrado en la base de datos.';
          _loading = false;
        });
        return;
      }

      final data = await supabase.client
          .from('movimiento')
          .select('*, categoria(nombre), tipo_movimiento(nombre)')
          .eq('id_usuario', (usuarioResult['id_usuario'] as int?) ?? 0)
          .order('fecha', ascending: false);

      if (!mounted) return;
      setState(() {
        _movimientos = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar: ${e.toString()}';
        _loading = false;
      });
    }
  }

  Future<void> _eliminarMovimiento(Map<String, dynamic> m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Text('Eliminar movimiento'),
        content: Text(
          '¿Eliminar "${m['descripcion'] ?? (m['categoria'] as Map?)?['nombre'] ?? 'este movimiento'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final supabase = SupabaseService.instance;
      await supabase.client
          .from('movimiento')
          .delete()
          .eq('id_movimiento', (m['id_movimiento'] as int?) ?? 0);
      _cargarMovimientos();
      widget.onCambio?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _mostrarOpciones(Map<String, dynamic> m) {
    final esIngreso = (m['id_tipo'] as int?) == 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildOpcion(
              icon: Icons.edit_outlined,
              texto: 'Editar',
              color: AppTheme.primary,
              onTap: () async {
                Navigator.pop(ctx);
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddMovimientoScreen(
                      idTipo: esIngreso ? 1 : 2,
                      movimientoExistente: m,
                    ),
                  ),
                );
                if (result == true) {
                  _cargarMovimientos();
                  widget.onCambio?.call();
                }
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            _buildOpcion(
              icon: Icons.delete_outlined,
              texto: 'Eliminar',
              color: AppTheme.error,
              onTap: () {
                Navigator.pop(ctx);
                _eliminarMovimiento(m);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpcion({
    required IconData icon,
    required String texto,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Text(
              texto,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
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
                onPressed: _cargarMovimientos,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_movimientos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppTheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay movimientos registrados',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarMovimientos,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        itemCount: _movimientos.length + 1,
        itemBuilder: (context, index) {
          if (index == _movimientos.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Fin del historial',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }
          final m = _movimientos[index];
          final fecha = DateTime.tryParse(m['fecha']?.toString() ?? '');
          final mes = fecha != null ? DateFormat('MMMM yyyy').format(fecha) : '';
          final showHeader = index == 0 ||
              (fecha != null &&
                  _movimientos.length > index - 1 &&
                  _movimientos[index - 1]['fecha']?.toString().substring(0, 7) !=
                      m['fecha']?.toString().substring(0, 7));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader && mes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 16, bottom: 8),
                  child: Text(
                    mes.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.outline,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
              _buildMovementTile(m),
            ],
          );
        },
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

    return GestureDetector(
      onTap: () => _mostrarOpciones(m),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
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
                      DateFormat('d MMM yyyy').format(fecha),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
