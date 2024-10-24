import 'dart:convert'; // JSON işlemleri için
import 'package:shared_preferences/shared_preferences.dart';
import '../models/template.dart';

class TemplateManager {
  static const String _key = 'templates';

  Future<void> saveTemplates(List<Template> templates) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonTemplates = templates.map((template) => json.encode(template.toJson())).toList();
    await prefs.setStringList(_key, jsonTemplates);
  }

  Future<List<Template>> loadTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? jsonTemplates = prefs.getStringList(_key);
    if (jsonTemplates != null) {
      return jsonTemplates.map((jsonTemplate) => Template.fromJson(json.decode(jsonTemplate))).toList();
    }
    return [];
  }
}

