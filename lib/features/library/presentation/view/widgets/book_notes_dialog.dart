import 'package:flutter/material.dart';

class BookNotesDialog extends StatefulWidget {
  final String initialNotes;

  const BookNotesDialog({super.key, this.initialNotes = ''});

  @override
  State<BookNotesDialog> createState() => _BookNotesDialogState();
}

class _BookNotesDialogState extends State<BookNotesDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Book Notes'),
      content: TextField(
        controller: _controller,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Add your notes here...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
