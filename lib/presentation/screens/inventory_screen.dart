import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/equipment.dart';
import '../../data/services/api_service.dart';
import '../widgets/page_header.dart';
import '../widgets/state_views.dart';
import '../widgets/status_pill.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  List<Equipment> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget.api.getEquipment(
        search: _searchController.text.trim(),
      );
      if (mounted) setState(() => _items = items);
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _openForm([Equipment? item]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EquipmentFormSheet(api: widget.api, equipment: item),
    );
    if (saved == true) {
      await _load();
      if (mounted) {
        showAppSnackBar(
          context,
          item == null ? 'Equipo registrado.' : 'Equipo actualizado.',
        );
      }
    }
  }

  Future<void> _delete(Equipment item) async {
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar equipo',
      message:
          '¿Deseas eliminar ${item.name}? Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.api.deleteEquipment(item.id);
      await _load();
      if (mounted) showAppSnackBar(context, 'Equipo eliminado.');
    } on ApiException catch (error) {
      if (mounted) showAppSnackBar(context, error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo equipo'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
                sliver: SliverList.list(
                  children: [
                    const PageHeader(
                      eyebrow: 'Inventario',
                      title: 'Equipos',
                      subtitle: 'Administra existencias y disponibilidad.',
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchController,
                      onChanged: _onSearch,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nombre, código o categoría',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  _load();
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (_loading)
                const SliverFillRemaining(child: LoadingView())
              else if (_error != null)
                SliverFillRemaining(
                  child: MessageView(
                    icon: Icons.cloud_off_rounded,
                    title: 'Sin conexión',
                    message: _error!,
                    onAction: _load,
                  ),
                )
              else if (_items.isEmpty)
                SliverFillRemaining(
                  child: MessageView(
                    icon: Icons.inventory_2_outlined,
                    title: 'No encontramos equipos',
                    message: _searchController.text.isEmpty
                        ? 'Registra el primer equipo del laboratorio.'
                        : 'Prueba con otro término de búsqueda.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: _items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) => EquipmentCard(
                      equipment: _items[index],
                      onEdit: () => _openForm(_items[index]),
                      onDelete: () => _delete(_items[index]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class EquipmentCard extends StatelessWidget {
  const EquipmentCard({
    super.key,
    required this.equipment,
    required this.onEdit,
    required this.onDelete,
  });

  final Equipment equipment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final (label, type) = switch (equipment.status) {
      'maintenance' => ('Mantenimiento', StatusType.warning),
      'inactive' => ('Inactivo', StatusType.neutral),
      _ when equipment.availableQuantity == 0 => (
        'Sin stock',
        StatusType.danger,
      ),
      _ => ('Disponible', StatusType.success),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.devices_other_rounded,
                    color: AppColors.blue,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        equipment.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${equipment.code}  •  ${equipment.category}',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: AppColors.danger,
                        ),
                        title: Text('Eliminar'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StatusPill(label: label, type: type),
                const Spacer(),
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.blueGrey,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    equipment.location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.blueGrey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: equipment.totalQuantity == 0
                    ? 0
                    : equipment.availableQuantity / equipment.totalQuantity,
                minHeight: 7,
                backgroundColor: const Color(0xFFE9EEF6),
                valueColor: AlwaysStoppedAnimation(
                  type == StatusType.danger ? AppColors.danger : AppColors.blue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${equipment.availableQuantity} disponibles',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${equipment.borrowedQuantity} prestados • ${equipment.totalQuantity} total',
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EquipmentFormSheet extends StatefulWidget {
  const EquipmentFormSheet({super.key, required this.api, this.equipment});
  final ApiService api;
  final Equipment? equipment;

  @override
  State<EquipmentFormSheet> createState() => _EquipmentFormSheetState();
}

class _EquipmentFormSheetState extends State<EquipmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _category;
  late final TextEditingController _location;
  late final TextEditingController _quantity;
  late final TextEditingController _description;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final item = widget.equipment;
    _name = TextEditingController(text: item?.name ?? '');
    _code = TextEditingController(text: item?.code ?? '');
    _category = TextEditingController(text: item?.category ?? '');
    _location = TextEditingController(text: item?.location ?? '');
    _quantity = TextEditingController(
      text: item?.totalQuantity.toString() ?? '1',
    );
    _description = TextEditingController(text: item?.description ?? '');
    _status = item?.status ?? 'available';
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _code,
      _category,
      _location,
      _quantity,
      _description,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final input = EquipmentInput(
      name: _name.text.trim(),
      code: _code.text.trim(),
      category: _category.text.trim(),
      location: _location.text.trim(),
      totalQuantity: int.parse(_quantity.text),
      status: _status,
      description: _description.text.trim(),
    );
    try {
      if (widget.equipment == null) {
        await widget.api.createEquipment(input);
      } else {
        await widget.api.updateEquipment(widget.equipment!.id, input);
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) showAppSnackBar(context, error.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? value) => value == null || value.trim().length < 3
      ? 'Ingresa al menos 3 caracteres'
      : null;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                widget.equipment == null ? 'Nuevo equipo' : 'Editar equipo',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Completa la información del inventario.',
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _name,
                validator: _required,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.devices_other_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _code,
                      validator: _required,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Código'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _quantity,
                      keyboardType: TextInputType.number,
                      validator: (value) => (int.tryParse(value ?? '') ?? 0) < 1
                          ? 'Cantidad inválida'
                          : null,
                      decoration: const InputDecoration(labelText: 'Cantidad'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _category,
                validator: _required,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _location,
                validator: _required,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Ubicación',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  prefixIcon: Icon(Icons.tune_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'available',
                    child: Text('Disponible'),
                  ),
                  DropdownMenuItem(
                    value: 'maintenance',
                    child: Text('Mantenimiento'),
                  ),
                  DropdownMenuItem(value: 'inactive', child: Text('Inactivo')),
                ],
                onChanged: (value) => setState(() => _status = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    widget.equipment == null
                        ? 'Registrar equipo'
                        : 'Guardar cambios',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
