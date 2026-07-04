class Loan {
  const Loan({
    required this.id,
    required this.equipmentId,
    required this.equipmentName,
    required this.equipmentCode,
    required this.borrowerName,
    required this.borrowerCode,
    required this.quantity,
    required this.loanDate,
    required this.dueDate,
    required this.returnedAt,
    required this.status,
    required this.notes,
  });

  final int id;
  final int equipmentId;
  final String equipmentName;
  final String equipmentCode;
  final String borrowerName;
  final String borrowerCode;
  final int quantity;
  final DateTime loanDate;
  final DateTime dueDate;
  final DateTime? returnedAt;
  final String status;
  final String notes;

  bool get isActive => status == 'active';
  bool get isOverdue => isActive && dueDate.isBefore(DateTime.now());

  factory Loan.fromJson(Map<String, dynamic> json) => Loan(
    id: json['id'] as int,
    equipmentId: json['equipmentId'] as int,
    equipmentName: json['equipmentName'] as String,
    equipmentCode: json['equipmentCode'] as String,
    borrowerName: json['borrowerName'] as String,
    borrowerCode: json['borrowerCode'] as String,
    quantity: json['quantity'] as int,
    loanDate: DateTime.parse(json['loanDate'] as String),
    dueDate: DateTime.parse(json['dueDate'] as String),
    returnedAt: json['returnedAt'] == null
        ? null
        : DateTime.parse((json['returnedAt'] as String).replaceFirst(' ', 'T')),
    status: json['status'] as String,
    notes: (json['notes'] as String?) ?? '',
  );
}

class LoanInput {
  const LoanInput({
    required this.equipmentId,
    required this.borrowerName,
    required this.borrowerCode,
    required this.quantity,
    required this.loanDate,
    required this.dueDate,
    required this.notes,
  });

  final int equipmentId;
  final String borrowerName;
  final String borrowerCode;
  final int quantity;
  final DateTime loanDate;
  final DateTime dueDate;
  final String notes;

  String _date(DateTime value) => value.toIso8601String().split('T').first;

  Map<String, dynamic> toJson() => {
    'equipmentId': equipmentId,
    'borrowerName': borrowerName,
    'borrowerCode': borrowerCode,
    'quantity': quantity,
    'loanDate': _date(loanDate),
    'dueDate': _date(dueDate),
    'notes': notes,
  };
}
