import 'package:flutter/material.dart';

import '../models/archived_card.dart';
import '../services/card_archive_service.dart';
import 'reminder_dialog.dart';

class RemindersPage extends StatefulWidget {
  final CardArchiveService service;
  final Future<void> Function(ArchivedCard) onOpen;
  final VoidCallback onArchive;
  const RemindersPage({
    super.key,
    required this.service,
    required this.onOpen,
    required this.onArchive,
  });
  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends State<RemindersPage> {
  late Future<List<ArchivedCard>> _cards = widget.service.loadCards();
  bool _completed = false;
  void _reload() => setState(() { _cards = widget.service.loadCards(); });
  Future<void> _open(ArchivedCard card) async {
    await widget.onOpen(card);
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hatırlatmalar')),
    body: FutureBuilder<List<ArchivedCard>>(
      future: _cards,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: TextButton(
              onPressed: _reload,
              child: const Text('Yüklenemedi · Tekrar dene'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cards =
            snapshot.data!
                .where(
                  (c) =>
                      c.reminder != null && c.reminder!.completed == _completed,
                )
                .toList()
              ..sort((a, b) => a.reminder!.dueAt.compareTo(b.reminder!.dueAt));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Bir kişiye hatırlatma eklemek için kartvizitini açıp “Hatırlatma ekle” düğmesini kullanın.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onArchive,
              icon: const Icon(Icons.person_add_alt),
              label: const Text('Hatırlatma için kişi seç'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Bekleyenler'),
                  selected: !_completed,
                  onSelected: (_) => setState(() => _completed = false),
                ),
                ChoiceChip(
                  label: const Text('Tamamlananlar'),
                  selected: _completed,
                  onSelected: (_) => setState(() => _completed = true),
                ),
              ],
            ),
            if (cards.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  _completed ? 'Tamamlanmış hatırlatma yok.' : 'Henüz bekleyen hatırlatma yok. İlk takibinizi planlamak için bir kişi seçin.',
                ),
              ),
            for (final card in cards)
              Card(
                child: ListTile(
                  leading: Icon(
                    _completed ? Icons.task_alt : Icons.notifications_outlined,
                  ),
                  title: Text(
                    card.data.name.isNotEmpty
                        ? card.data.name
                        : card.data.company.isNotEmpty
                        ? card.data.company
                        : 'İsimsiz kartvizit',
                  ),
                  subtitle: Text(
                    '${card.reminder!.title}\n${reminderDate(card.reminder!.dueAt)}${!_completed && card.reminder!.dueAt.isBefore(DateTime.now()) ? '\nZamanı geçti' : ''}${!_completed && card.reminder!.notificationId == null ? '\nBildirim kurulmadı · Kişi profilinden yeniden kaydedin' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _open(card),
                ),
              ),
          ],
        );
      },
    ),
  );
}
