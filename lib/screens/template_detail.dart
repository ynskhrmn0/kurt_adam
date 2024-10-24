import 'package:flutter/material.dart';
import '../models/template.dart';
import '../widgets/role_management_dialog.dart';
import '../widgets/shared_preferences.dart';
import 'create_template_screen.dart';
import 'game_screen.dart';

class TemplateDetailScreen extends StatefulWidget {
  final Template template;
  final Function deleteTemplate;

  TemplateDetailScreen({required this.template, required this.deleteTemplate});

  @override
  _TemplateDetailScreenState createState() => _TemplateDetailScreenState();
}

class _TemplateDetailScreenState extends State<TemplateDetailScreen> {
  final TemplateManager _templateManager = TemplateManager();

  late List<bool> _selected;
  bool _selectAll = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _selected = List.generate(widget.template.names.length, (index) => false);
  }

  void _toggleSelectAll(bool value) {
    setState(() {
      _selectAll = value;
      _selected = List.generate(widget.template.names.length, (index) => value);
    });
  }

  void _startGame() {
    final selectedPlayers = widget.template.names
        .asMap()
        .entries
        .where((entry) => _selected[entry.key])
        .map((entry) => entry.value)
        .toList();

    if (selectedPlayers.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('En az 4 oyuncu seçmelisiniz!')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => GameScreen(
          template: widget.template,
          selectedPlayers: selectedPlayers,
        ),
      ),
    );
  }

  void _toggleEditing() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _editTemplate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CreateTemplateScreen(
          // addTemplate fonksiyonunu burada tanımlıyoruz
          (Template updatedTemplate) {
            setState(() {
              widget.template.names
                ..clear()
                ..addAll(updatedTemplate.names);
              widget.template.name = updatedTemplate.name;
              _selected =
                  List.generate(widget.template.names.length, (index) => false);
            });
            _saveTemplate(); // Template'i kaydet
          },
          widget
              .deleteTemplate, // deleteTemplate fonksiyonunu doğrudan geçiriyoruz
          initialTemplate: widget.template,
        ),
      ),
    );
  }

  Future<void> _saveTemplate() async {
    List<Template> templates = await _templateManager.loadTemplates();
    for (int i = 0; i < templates.length; i++) {
      if (templates[i].id == widget.template.id) {
        templates[i] = widget.template;
        break;
      }
    }
    await _templateManager.saveTemplates(templates);
  }

  void _deletePerson(int index) {
    setState(() {
      widget.template.names.removeAt(index);
      _selected.removeAt(index);
    });
    _saveTemplate();
  }

  void _deleteTemplate() {
    widget.deleteTemplate(widget.template.id);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.name),
        actions: [
          IconButton(
            icon: Icon(Icons.people_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => RoleManagementDialog(
                  template: widget.template,
                  onRolesUpdated: (roles) {
                    setState(() {
                      widget.template.enabledRoles = roles;
                    });
                    _saveTemplate();
                  },
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _toggleEditing,
          ),
          IconButton(
            icon: Icon(Icons.play_arrow),
            onPressed: _startGame,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text('Hepsini Seç'),
                Switch(
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                ),
              ],
            ),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.all(16.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  childAspectRatio: 3,
                ),
                itemCount: widget.template.names.length,
                itemBuilder: (ctx, index) {
                  return GestureDetector(
                    onTap: () {
                      if (!_isEditing) {
                        setState(() {
                          _selected[index] = !_selected[index];
                        });
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selected[index] ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              widget.template.names[index],
                              style:
                                  TextStyle(color: Colors.white, fontSize: 30),
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              right: 8.0,
                              top: 8.0,
                              child: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePerson(index),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: _editTemplate,
                  child: Text('Detaylı Düzenle'),
                ),
              ),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: _deleteTemplate,
                  child: Text('Şablonu Sil'),
                  style: ElevatedButton.styleFrom(iconColor: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
