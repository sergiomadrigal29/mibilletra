import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../models/categorias_static.dart';
import 'app_card.dart';
import 'amount_text.dart';

IconData _iconForCategoria(String nombre) {
  final ingreso = ingresoCategorias.where((c) => c.nombre == nombre).firstOrNull;
  if (ingreso != null) return ingreso.icono;
  final gasto = gastoCategorias.where((c) => c.nombre == nombre).firstOrNull;
  if (gasto != null) return gasto.icono;
  return Icons.receipt_long_outlined;
}

class MovementTile extends StatelessWidget {
  final Map<String, dynamic> movimiento;
  final VoidCallback? onTap;
  final bool compact;

  const MovementTile({
    super.key,
    required this.movimiento,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final monto = ((movimiento['monto'] as num?) ?? 0).toDouble();
    final idTipo = (movimiento['id_tipo'] as int?) ?? 1;
    final esIngreso = idTipo == 1;
    final catNombre =
        (movimiento['categoria'] as Map<String, dynamic>?)?['nombre']
                as String? ??
            'General';
    final descripcion = movimiento['descripcion'] as String?;
    final fecha = DateTime.tryParse(movimiento['fecha']?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        elevation: AppElevation.level0,
        onTap: onTap,
        child: Row(
          children: [
            _buildIcon(context, esIngreso, catNombre),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    descripcion ?? catNombre,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    catNombre,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AmountText(
                  amount: monto,
                  positiveColor: AppTheme.primary,
                  negativeColor: AppTheme.error,
                  showSign: true,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (fecha != null && !compact)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      DateFormat('d MMM yyyy').format(fecha),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context, bool esIngreso, String catNombre) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: esIngreso ? AppTheme.primaryFixed : AppTheme.tertiaryFixed,
        shape: BoxShape.circle,
      ),
      child: Icon(
        _iconForCategoria(catNombre),
        color: esIngreso ? AppTheme.primary : AppTheme.tertiary,
        size: 22,
      ),
    );
  }
}
