import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/equipment.dart';
import '../../data/models/loan.dart';
import '../../data/services/api_service.dart';
import '../widgets/page_header.dart';
import '../widgets/state_views.dart';
import '../widgets/status_pill.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key, required this.api});
  final ApiService api;

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  List<Loan> _loans = [];
  List<Equipment> _equipment = [];
  bool _loading = true;
  String? _error;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.getLoans(status: _filter),
        widget.api.getEquipment(),
      ]);
      if (!mounted) return;
      setState(() {
        _loans = results[0] as List<Loan>;
        _equipment = results[1] as List<Equipment>;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([Loan? loan]) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          LoanFormSheet(api: widget.api, equipment: _equipment, loan: loan),
    );
    if (saved == true) {
      await _load();
      if (mounted) {
        showAppSnackBar(
          context,
          loan == null ? 'Préstamo registrado.' : 'Préstamo actualizado.',
        );
      }
    }
  }

  Future<void> _markReturned(Loan loan) async {
    final confirmed = await confirmAction(
      context,
      title: 'Confirmar devolución',
      message:
          'Se devolverán ${loan.quantity} unidad(es) de ${loan.equipmentName} al inventario.',
      confirmLabel: 'Registrar devolución',
    );
    if (!confirmed) return;
    try {
      await widget.api.returnLoan(loan.id);
      await _load();
      if (mounted) showAppSnackBar(context, 'Devolución registrada.');
    } on ApiException catch (error) {
      if (mounted) showAppSnackBar(context, error.message, isError: true);
    }
  }

  Future<void> _delete(Loan loan) async {
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar registro',
      message: '¿Deseas eliminar este préstamo del historial?',
      confirmLabel: 'Eliminar',
      destructive: true,
    );
    if (!confirmed) return;
    try {
      await widget.api.deleteLoan(loan.id);
      await _load();
      if (mounted) showAppSnackBar(context, 'Registro eliminado.');
    } on ApiException catch (error) {
      if (mounted) showAppSnackBar(context, error.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _equipment.any((item) => item.canBeLoaned)
            ? () => _openForm()
            : null,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo préstamo'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
                sliver: SliverList.list(
                  children: [
                    const PageHeader(
                      eyebrow: 'Movimientos',
                      title: 'Préstamos',
                      subtitle: 'Controla entregas, fechas y devoluciones.',
                    ),
                    const SizedBox(height: 20),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: '', label: Text('Todos')),
                        ButtonSegment(value: 'active', label: Text('Activos')),
                        ButtonSegment(
                          value: 'returned',
                          label: Text('Devueltos'),
                        ),
                      ],
                      selected: {_filter},
                      showSelectedIcon: false,
                      onSelectionChanged: (value) {
                        setState(() => _filter = value.first);
                        _load();
                      },
                    ),
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
              else if (_loans.isEmpty)
                SliverFillRemaining(
                  child: MessageView(
                    icon: Icons.assignment_outlined,
                    title: 'Sin préstamos',
                    message: _filter.isEmpty
                        ? 'Los préstamos que registres aparecerán aquí.'
                        : 'No hay movimientos con este estado.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: SliverList.separated(
                    itemCount: _loans.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, index) {
                      final loan = _loans[index];
                      return LoanCard(
                        loan: loan,
                        onEdit: () => _openForm(loan),
                        onReturn: () => _markReturned(loan),
                        onDelete: () => _delete(loan),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.loan,
    required this.onEdit,
    required this.onReturn,
    required this.onDelete,
  });
  final Loan loan;
  final VoidCallback onEdit;
  final VoidCallback onReturn;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = loan.isOverdue
        ? ('Vencido', StatusType.danger)
        : loan.isActive
        ? ('Activo', StatusType.warning)
        : ('Devuelto', StatusType.success);
    final date = DateFormat('dd/MM/yyyy');

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
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.handshake_outlined,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.equipmentName,
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
                        '${loan.equipmentCode}  •  ${loan.quantity} unidad(es)',
                        style: const TextStyle(
                          color: Colors.blueGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'return') onReturn();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => [
                    if (loan.isActive) ...[
                      const PopupMenuItem(
                        value: 'return',
                        child: ListTile(
                          leading: Icon(
                            Icons.assignment_turned_in_outlined,
                            color: AppColors.success,
                          ),
                          title: Text('Devolver'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    if (!loan.isActive)
                      const PopupMenuItem(
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
                const Icon(
                  Icons.person_outline_rounded,
                  color: AppColors.blue,
                  size: 19,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    loan.borrowerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Text(
                  loan.borrowerCode,
                  style: const TextStyle(color: Colors.blueGrey, fontSize: 12),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 13),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(
                  child: _DateInfo(
                    label: 'Entrega',
                    value: date.format(loan.loanDate),
                  ),
                ),
                Expanded(
                  child: _DateInfo(
                    label: loan.isActive ? 'Devolver' : 'Devuelto',
                    value: date.format(loan.returnedAt ?? loan.dueDate),
                  ),
                ),
                StatusPill(label: status.$1, type: status.$2),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  const _DateInfo({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.blueGrey, fontSize: 10)),
      const SizedBox(height: 3),
      Text(
        value,
        style: const TextStyle(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    ],
  );
}

class LoanFormSheet extends StatefulWidget {
  const LoanFormSheet({
    super.key,
    required this.api,
    required this.equipment,
    this.loan,
  });
  final ApiService api;
  final List<Equipment> equipment;
  final Loan? loan;

  @override
  State<LoanFormSheet> createState() => _LoanFormSheetState();
}

class _LoanFormSheetState extends State<LoanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _borrowerName;
  late final TextEditingController _borrowerCode;
  late final TextEditingController _quantity;
  late final TextEditingController _notes;
  int? _equipmentId;
  late DateTime _loanDate;
  late DateTime _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final loan = widget.loan;
    final available = widget.equipment
        .where((item) => item.canBeLoaned)
        .toList();
    _equipmentId =
        loan?.equipmentId ?? (available.isEmpty ? null : available.first.id);
    _borrowerName = TextEditingController(text: loan?.borrowerName ?? '');
    _borrowerCode = TextEditingController(text: loan?.borrowerCode ?? '');
    _quantity = TextEditingController(text: loan?.quantity.toString() ?? '1');
    _notes = TextEditingController(text: loan?.notes ?? '');
    _loanDate = loan?.loanDate ?? DateTime.now();
    _dueDate = loan?.dueDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _borrowerName.dispose();
    _borrowerCode.dispose();
    _quantity.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool dueDate}) async {
    final initial = dueDate ? _dueDate : _loanDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: dueDate
          ? _loanDate
          : DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (selected == null) return;
    setState(() {
      if (dueDate) {
        _dueDate = selected;
      } else {
        _loanDate = selected;
        if (_dueDate.isBefore(selected)) _dueDate = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _equipmentId == null) return;
    setState(() => _saving = true);
    try {
      if (widget.loan == null) {
        await widget.api.createLoan(
          LoanInput(
            equipmentId: _equipmentId!,
            borrowerName: _borrowerName.text.trim(),
            borrowerCode: _borrowerCode.text.trim(),
            quantity: int.parse(_quantity.text),
            loanDate: _loanDate,
            dueDate: _dueDate,
            notes: _notes.text.trim(),
          ),
        );
      } else {
        await widget.api.updateLoan(widget.loan!.id, {
          'borrowerName': _borrowerName.text.trim(),
          'borrowerCode': _borrowerCode.text.trim(),
          'dueDate': _dueDate.toIso8601String().split('T').first,
          'notes': _notes.text.trim(),
        });
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
    final editMode = widget.loan != null;
    final available = widget.equipment
        .where((item) => item.canBeLoaned)
        .toList();
    final date = DateFormat('dd/MM/yyyy');

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
                editMode ? 'Editar préstamo' : 'Nuevo préstamo',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Registra al responsable y la fecha de devolución.',
                style: TextStyle(color: Colors.blueGrey),
              ),
              const SizedBox(height: 22),
              if (editMode)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Equipo',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  child: Text(
                    widget.loan!.equipmentName,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: _equipmentId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Equipo',
                    prefixIcon: Icon(Icons.inventory_2_outlined),
                  ),
                  items: available
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.id,
                          child: Text(
                            '${item.name} (${item.availableQuantity})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _equipmentId = value),
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _borrowerName,
                validator: _required,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Responsable',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _borrowerCode,
                      validator: _required,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: 'Código'),
                    ),
                  ),
                  if (!editMode) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            (int.tryParse(value ?? '') ?? 0) < 1
                            ? 'Cantidad inválida'
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad',
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (!editMode) ...[
                    Expanded(
                      child: _DateButton(
                        label: 'Fecha de entrega',
                        value: date.format(_loanDate),
                        onTap: () => _pickDate(dueDate: false),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _DateButton(
                      label: 'Fecha de devolución',
                      value: date.format(_dueDate),
                      onTap: () => _pickDate(dueDate: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                minLines: 2,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Observaciones (opcional)',
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
                    editMode ? 'Guardar cambios' : 'Registrar préstamo',
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

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      child: Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ),
  );
}
