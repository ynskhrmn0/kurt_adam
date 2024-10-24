class Role {
  final String id;
  final String name;
  final String description;
  bool isEnabled;

  Role({
    required this.id,
    required this.name,
    required this.description,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isEnabled': isEnabled,
    };
  }

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}