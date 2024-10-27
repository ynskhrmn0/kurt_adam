import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'screens/template_detail.dart';
import 'models/template.dart';
import 'screens/create_template_screen.dart';
import 'widgets/roles_info_dialog.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kurt Adam Oyunu',
      theme: ThemeData.dark(),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Template> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  void _loadTemplates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> templatesString = prefs.getStringList('templates') ?? [];
    setState(() {
      _templates = templatesString
          .map(
              (templateString) => Template.fromJson(jsonDecode(templateString)))
          .toList();
    });
  }

  void _saveTemplates() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> templatesString =
        _templates.map((template) => jsonEncode(template.toJson())).toList();
    await prefs.setStringList('templates', templatesString);
  }

  void _addTemplate(Template template) {
    setState(() {
      _templates.add(template);
    });
    _saveTemplates();
  }

  void _editTemplate(Template updatedTemplate) {
    setState(() {
      final index =
          _templates.indexWhere((tpl) => tpl.id == updatedTemplate.id);
      if (index != -1) {
        _templates[index] = updatedTemplate;
      }
    });
    _saveTemplates();
  }

  void _deleteTemplate(String templateId) {
    setState(() {
      _templates.removeWhere((tpl) => tpl.id == templateId);
    });
    _saveTemplates();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kurt Adam Oyunu'),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => RolesInfoDialog(),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _templates.length,
        itemBuilder: (ctx, index) {
          return ListTile(
            title: Text(_templates[index].name),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => TemplateDetailScreen(
                    template: _templates[index],
                    deleteTemplate: _deleteTemplate,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => CreateTemplateScreen(
                _addTemplate,
                _editTemplate,
              ),
            ),
          );
        },
      ),
    );
  }
}
