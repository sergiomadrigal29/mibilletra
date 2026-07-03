import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'add_movimiento_screen.dart';
import '../widgets/movement_tile.dart';
import '../widgets/state_views.dart';

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
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Eliminar movimiento'),
        content: Text(
          '¿Eliminar "${m['descripcion'] ?? (m['categoria'] as Map?)?['nombre'] ?? 'este movimiento'}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppSemantics.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text(AppSemantics.delete),
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
            borderRadius: BorderRadius.circular(AppRadius.sm),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
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
            const SizedBox(height: AppSpacing.xl),
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
            const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
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
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm + 2),
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
            const SizedBox(width: AppSpacing.sm + 2),
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
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _cargarMovimientos);

    if (_movimientos.isEmpty) {
      return EmptyView(
        icon: Icons.receipt_long_outlined,
        message: 'No hay movimientos registrados',
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarMovimientos,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        itemCount: _movimientos.length + 1,
        itemBuilder: (context, index) {
          if (index == _movimientos.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
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
                  padding: const EdgeInsets.only(left: AppSpacing.xs, top: AppSpacing.lg, bottom: AppSpacing.sm),
                  child: Text(
                    mes.toUpperCase(),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppTheme.outline,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
              MovementTile(
                movimiento: m,
                onTap: () => _mostrarOpciones(m),
              ),
            ],
          );
        },
      ),
    );
  }
}
