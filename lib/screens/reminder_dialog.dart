import 'package:flutter/material.dart';

import '../models/archived_card.dart';
import '../services/reminder_service.dart';

String reminderDate(DateTime date) {
  final d = date.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
}

class ReminderDialog extends StatefulWidget {
  final ArchivedCard card;
  final ReminderService service;
  const ReminderDialog({super.key, required this.card, required this.service});
  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  late final _title = TextEditingController(
    text: widget.card.reminder?.title ?? 'İletişime geç',
  );
  late DateTime _due =
      widget.card.reminder?.dueAt.isAfter(DateTime.now()) == true
      ? widget.card.reminder!.dueAt
      : DateTime.now().add(const Duration(hours: 1));
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final now = DateTime.now();
    final last = DateTime(now.year + 5, 12, 31);
    final date = await showDatePicker(
      context: context,
      initialDate: _due.isBefore(now)
          ? now
          : _due.isAfter(last)
          ? last
          : _due,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: last,
      helpText: 'Hatırlatma tarihi',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );
    if (!mounted || date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_due),
      helpText: 'Hatırlatma saati',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );
    if (mounted && time != null) {
      setState(
        () => _due = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ),
      );
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.service.save(
        widget.card.id,
        _title.text,
        _due,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (error) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = error is ArgumentError
              ? error.message.toString()
              : 'Hatırlatma kaydedilemedi. Tekrar deneyin.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: const Text('Takip hatırlatması'),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _title,
                enabled: !_saving,
                maxLength: 160,
                decoration: const InputDecoration(
                  labelText: 'Ne yapacaksınız?',
                  hintText: 'Ara, teklif gönder, görüşme yap…',
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _saving ? null : _pick,
                icon: const Icon(Icons.event),
                label: Text(reminderDate(_due)),
              ),
              const SizedBox(height: 12),
              const Text(
                'Saat telefonunuzun yerel saatine göredir. Android pil tasarrufu bildirimi geciktirebilir. Kişi başına bir takip hatırlatması tutulur.',
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Kaydediliyor…' : 'Hatırlatmayı kaydet'),
        ),
      ],
    ),
  );
}
