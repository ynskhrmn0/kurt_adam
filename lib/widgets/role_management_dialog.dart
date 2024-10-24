import 'package:flutter/material.dart';
import '../models/template.dart';
import '../services/role_service.dart';

class RoleManagementDialog extends StatefulWidget {
  final Template template;
  final Function(Map<String, bool>) onRolesUpdated;

  const RoleManagementDialog({
    Key? key,
    required this.template,
    required this.onRolesUpdated,
  }) : super(key: key);

  @override
  _RoleManagementDialogState createState() => _RoleManagementDialogState();
}

class _RoleManagementDialogState extends State<RoleManagementDialog> {
  late Map<String, bool> _enabledRoles;

  @override
  void initState() {
    super.initState();
    _enabledRoles = Map.from(widget.template.enabledRoles);
    // Varsayılan değerleri ayarla
    for (var role in RoleService.defaultRoles) {
      if (!_enabledRoles.containsKey(role.id)) {
        _enabledRoles[role.id] = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rolleri Yönet'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoleService.defaultRoles.map((role) =>
            CheckboxListTile(
              title: Text(role.name),
              value: _enabledRoles[role.id] ?? true,
              onChanged: (bool? value) {
                if (value != null) {
                  setState(() {
                    _enabledRoles[role.id] = value;
                  });
                }
              },
            ),
          ).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            widget.onRolesUpdated(_enabledRoles);
            Navigator.of(context).pop();
          },
          child: Text('Kaydet'),
        ),
      ],
    );
  }
}