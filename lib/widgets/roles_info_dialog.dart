import 'package:flutter/material.dart';
import '../services/role_service.dart';
import 'role_info_dialog.dart';

class RolesInfoDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Roller'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: RoleService.defaultRoles.map((role) => 
            ListTile(
              title: Text(role.name),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (context) => RoleInfoDialog(role: role),
                );
              },
            ),
          ).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Kapat'),
        ),
      ],
    );
  }
}