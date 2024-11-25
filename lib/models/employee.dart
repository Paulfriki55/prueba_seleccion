class Employee {
  final int? id;
  final String name;
  final String lastName;
  final String cedula;
  final String position;
  final String area;
  final String signature;

  Employee({
    this.id,
    required this.name,
    required this.lastName,
    required this.cedula,
    required this.position,
    required this.area,
    required this.signature,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastName': lastName,
      'cedula': cedula,
      'position': position,
      'area': area,
      'signature': signature,
    };
  }

  static Employee fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      lastName: map['lastName'],
      cedula: map['cedula'],
      position: map['position'],
      area: map['area'],
      signature: map['signature'],
    );
  }
}