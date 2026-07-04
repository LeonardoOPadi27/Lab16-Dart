class Equipment {
  const Equipment({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.location,
    required this.totalQuantity,
    required this.availableQuantity,
    required this.status,
    required this.description,
  });

  final int id;
  final String name;
  final String code;
  final String category;
  final String location;
  final int totalQuantity;
  final int availableQuantity;
  final String status;
  final String description;

  int get borrowedQuantity => totalQuantity - availableQuantity;
  bool get canBeLoaned => status == 'available' && availableQuantity > 0;

  factory Equipment.fromJson(Map<String, dynamic> json) => Equipment(
    id: json['id'] as int,
    name: json['name'] as String,
    code: json['code'] as String,
    category: json['category'] as String,
    location: json['location'] as String,
    totalQuantity: json['totalQuantity'] as int,
    availableQuantity: json['availableQuantity'] as int,
    status: json['status'] as String,
    description: (json['description'] as String?) ?? '',
  );
}

class EquipmentInput {
  const EquipmentInput({
    required this.name,
    required this.code,
    required this.category,
    required this.location,
    required this.totalQuantity,
    required this.status,
    required this.description,
  });

  final String name;
  final String code;
  final String category;
  final String location;
  final int totalQuantity;
  final String status;
  final String description;

  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
    'category': category,
    'location': location,
    'totalQuantity': totalQuantity,
    'status': status,
    'description': description,
  };
}
