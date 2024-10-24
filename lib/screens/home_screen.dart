import 'package:flutter/material.dart';
import '../widgets/shared_preferences.dart';
import '../models/template.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Template> _templates = [];
  final TemplateManager _templateManager = TemplateManager();

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final templates = await _templateManager.loadTemplates();
    setState(() {
      _templates.addAll(templates);
    });
  }

  Future<void> _saveTemplates() async {
    await _templateManager.saveTemplates(_templates);
  }

  // Yeni şablon oluşturma ve kaydetme yöntemleri
  void _addTemplate(Template template) {
    setState(() {
      _templates.add(template);
    });
    _saveTemplates(); // Kaydet
    _templateManager.saveTemplates(_templates);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Şablonlar'),
      ),
      body: ListView.builder(
        itemCount: _templates.length,
        itemBuilder: (ctx, index) {
          return ListTile(
            title: Text(_templates[index].name),
            onTap: () {
              // Şablona gitme
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yeni şablon oluşturma
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

