import 'package:flutter/material.dart';
import '../models/template.dart';
import '../widgets/person_list_item.dart';

class CreateTemplateScreen extends StatefulWidget {
  final Function addTemplate;
  final Function deleteTemplate;
  final Template? initialTemplate;

  CreateTemplateScreen(this.addTemplate, this.deleteTemplate, {this.initialTemplate});

  @override
  _CreateTemplateScreenState createState() => _CreateTemplateScreenState();
}

class _CreateTemplateScreenState extends State<CreateTemplateScreen> {
  final _formKey = GlobalKey<FormState>();
  List<String> _names = [];
  final _nameController = TextEditingController();
  final _templateNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialTemplate != null) {
      _names = List.from(widget.initialTemplate!.names);
      _templateNameController.text = widget.initialTemplate!.name;
    }
  }

  void _addName() {
    if (_nameController.text.isNotEmpty) {
      setState(() {
        _names.add(_nameController.text);
        _nameController.clear();
      });
    }
  }

  void _removeName(int index) {
    setState(() {
      _names.removeAt(index);
    });
  }

  void _saveTemplate() {
    if (_formKey.currentState!.validate()) {
      if (_names.isNotEmpty) {
        Template newTemplate = Template(
          id: widget.initialTemplate?.id ?? DateTime.now().toString(),
          name: _templateNameController.text,
          names: List.from(_names),
        );

        widget.addTemplate(newTemplate);
        Navigator.of(context).pop();
      }
    }
  }

  void _deleteTemplate() {
    if (widget.initialTemplate != null) {
      widget.deleteTemplate(widget.initialTemplate!.id);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialTemplate != null
            ? 'Şablonu Düzenle'
            : 'Şablon Oluştur'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _templateNameController,
                decoration: InputDecoration(labelText: 'Şablon Adı'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir şablon adı girin';
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Kişi Adı'),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addName,
                  ),
                ],
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _names.length,
                  itemBuilder: (ctx, index) {
                    return PersonListItem(
                      name: _names[index],
                      onRemove: () => _removeName(index),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _saveTemplate,
                child: Text(widget.initialTemplate != null
                    ? 'Kaydet'
                    : 'Şablonu Kaydet'),
              ),
              if (widget.initialTemplate != null)
              SizedBox(height: 10,),
              ElevatedButton(
                onPressed: _deleteTemplate,
                child: Text('Şablonu Sil'),
                style: ElevatedButton.styleFrom(iconColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
