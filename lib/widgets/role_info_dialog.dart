import 'package:flutter/material.dart';
import '../models/role.dart';

class RoleInfoDialog extends StatelessWidget {
  final Role role;

  const RoleInfoDialog({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(role.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(role.description),
          ],
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