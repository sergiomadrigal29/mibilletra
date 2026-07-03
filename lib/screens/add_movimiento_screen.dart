import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/movimiento.dart';
import '../models/categorias_static.dart';
import '../theme/app_theme.dart';

class AddMovimientoScreen extends StatefulWidget {
  final int idTipo;
  final Map<String, dynamic>? movimientoExistente;

  const AddMovimientoScreen({
    super.key,
    required this.idTipo,
    this.movimientoExistente,
  });

  @override
  State<AddMovimientoScreen> createState() => _AddMovimientoScreenState();
}

class _AddMovimientoScreenState extends State<AddMovimientoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  CategoriaData? _categoriaSeleccionada;
  bool _loading = false;
  bool get _esEdicion => widget.movimientoExistente != null;

  @override
  void initState() {
    super.initState();
    if (_esEdicion) {
      final m = widget.movimientoExistente!;
      _montoController.text = ((m['monto'] as num?) ?? 0).toString();
      _descripcionController.text = m['descripcion'] as String? ?? '';
      final idCat = m['id_categoria'] as int?;
      if (idCat != null) {
        _categoriaSeleccionada = findCategoriaById(idCat);
      }
    }
  }

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoriaSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una categoría')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final supabase = SupabaseService.instance;
      final user = supabase.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      if (_esEdicion) {
        await supabase.client
            .from('movimiento')
            .update({
              'id_categoria': _categoriaSeleccionada!.id,
              'monto': double.parse(_montoController.text.trim()),
              'descripcion': _descripcionController.text.trim().isEmpty
                  ? null
                  : _descripcionController.text.trim(),
            })
            .eq('id_movimiento', (widget.movimientoExistente!['id_movimiento'] as int?) ?? 0);
      } else {
        final usuarioData = await supabase.client
            .from('usuario')
            .select('id_usuario')
            .eq('id_auth_user', user.id)
            .maybeSingle();

        if (usuarioData == null) {
          throw Exception('Usuario no encontrado en la base de datos.');
        }

        final movimiento = Movimiento(
          idUsuario: (usuarioData['id_usuario'] as int?) ?? 0,
          idCategoria: _categoriaSeleccionada!.id,
          idTipo: widget.idTipo,
          monto: double.parse(_montoController.text.trim()),
          descripcion: _descripcionController.text.trim().isEmpty
              ? null
              : _descripcionController.text.trim(),
        );

        await supabase.client.from('movimiento').insert(movimiento.toMap());
      }

      if (!mounted) return;
      Navigator.pop(context, true);
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
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _seleccionarCategoria() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final grupos = getGruposByTipo(widget.idTipo);
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.idTipo == 1 ? 'Categoría de ingreso' : 'Categoría de gasto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: grupos.map((grupo) {
                        final cats = getCategoriasByGrupo(widget.idTipo, grupo);
                        return _buildGrupoCategoria(ctx, grupo, cats);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrupoCategoria(BuildContext ctx, String grupo, List<CategoriaData> cats) {
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
            ...cats.map((cat) => InkWell(
              onTap: () {
                setState(() => _categoriaSeleccionada = cat);
                Navigator.pop(ctx);
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: widget.idTipo == 1
                            ? AppTheme.primaryFixed
                            : AppTheme.tertiaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        cat.icono,
                        size: 22,
                        color: widget.idTipo == 1
                            ? AppTheme.primary
                            : AppTheme.tertiary,
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
              ),
            )),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esIngreso = widget.idTipo == 1;
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_esEdicion
            ? 'Editar ${esIngreso ? 'ingreso' : 'gasto'}'
            : esIngreso
                ? 'Registrar ingreso'
                : 'Registrar gasto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: esIngreso
                        ? AppTheme.primaryFixed
                        : AppTheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    esIngreso ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 40,
                    color: esIngreso ? AppTheme.primary : AppTheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Monto',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _montoController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.primary,
                ),
                decoration: const InputDecoration(
                  hintText: 'C\$ 0.00',
                  border: InputBorder.none,
                  filled: false,
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresa el monto';
                  final monto = double.tryParse(v);
                  if (monto == null || monto <= 0) return 'Monto inválido';
                  return null;
                },
              ),
              const SizedBox(height: 32),
              Text(
                'Categoría',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _seleccionarCategoria,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      if (_categoriaSeleccionada != null) ...[
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: esIngreso
                                ? AppTheme.primaryFixed
                                : AppTheme.tertiaryFixed,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _categoriaSeleccionada!.icono,
                            size: 18,
                            color: esIngreso ? AppTheme.primary : AppTheme.tertiary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _categoriaSeleccionada!.nombre,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ] else ...[
                        Icon(
                          Icons.category_outlined,
                          color: AppTheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Seleccionar categoría',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.outlineVariant,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Descripción (opcional)',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Agrega una descripción...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.outlineVariant),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _loading ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: esIngreso ? AppTheme.primary : AppTheme.error,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check, size: 20),
                          const SizedBox(width: 8),
                          Text(_esEdicion
                              ? 'Actualizar'
                              : esIngreso
                                  ? 'Guardar ingreso'
                                  : 'Guardar gasto'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
