import 'package:flutter/material.dart';

class PersonListItem extends StatelessWidget {
  final String name;
  final VoidCallback onRemove;

  PersonListItem({
    required this.name,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      trailing: IconButton(
        icon: Icon(Icons.delete),
        onPressed: onRemove,
      ),
    );
  }
}
