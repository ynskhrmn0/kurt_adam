
class Template {
  String id;
  String name;
  List<String> names;
  Map<String, bool> enabledRoles; // Her rolün durumunu tutacak

  Template({
    required this.id,
    required this.name,
    required this.names,
    Map<String, bool>? enabledRoles,
  }) : this.enabledRoles = enabledRoles ?? {};

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'names': names,
      'enabledRoles': enabledRoles,
    };
  }

  factory Template.fromJson(Map<String, dynamic> json) {
    return Template(
      id: json['id'],
      name: json['name'],
      names: List<String>.from(json['names']),
      enabledRoles: Map<String, bool>.from(json['enabledRoles'] ?? {}),
    );
  }
}