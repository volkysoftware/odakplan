import 'package:flutter/material.dart';

class AddPlanSheet extends StatefulWidget {
  const AddPlanSheet({super.key, required this.onSave});

  final void Function(String name, int minutes) onSave;

  @override
  State<AddPlanSheet> createState() => _AddPlanSheetState();
}

class _AddPlanSheetState extends State<AddPlanSheet> {
  final _nameController = TextEditingController();
  int _minutes = 25;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Yeni Kart',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Ad',
              hintText: 'Matematik, Kitap, İngilizce...',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _minutes,
            items: const [
              DropdownMenuItem(value: 15, child: Text('15 dk')),
              DropdownMenuItem(value: 25, child: Text('25 dk')),
              DropdownMenuItem(value: 30, child: Text('30 dk')),
              DropdownMenuItem(value: 45, child: Text('45 dk')),
              DropdownMenuItem(value: 60, child: Text('60 dk')),
            ],
            onChanged: (v) => setState(() => _minutes = v ?? 25),
            decoration: const InputDecoration(labelText: 'Süre'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) return;
              widget.onSave(_nameController.text.trim(), _minutes);
              Navigator.pop(context);
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}
