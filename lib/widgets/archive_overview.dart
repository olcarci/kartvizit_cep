import 'package:flutter/material.dart';

import '../models/archived_card.dart';
import '../services/card_archive_service.dart';
import 'tech_background.dart';
import '../screens/reminder_dialog.dart';

class ArchiveOverview extends StatefulWidget {
  final CardArchiveService service;
  final int revision;
  final ValueChanged<ArchivedCard> onOpen;
  final VoidCallback onArchive;
  final VoidCallback onFavorites;
  final VoidCallback onReminders;
  const ArchiveOverview({
    super.key,
    required this.service,
    required this.revision,
    required this.onOpen,
    required this.onArchive,
    required this.onFavorites,
    required this.onReminders,
  });
  @override
  State<ArchiveOverview> createState() => _ArchiveOverviewState();
}

class _ArchiveOverviewState extends State<ArchiveOverview> {
  late Future<List<ArchivedCard>> _cards;
  @override
  void initState() {
    super.initState();
    _cards = widget.service.loadCards();
  }

  @override
  void didUpdateWidget(covariant ArchiveOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revision != oldWidget.revision ||
        widget.service != oldWidget.service) {
      _cards = widget.service.loadCards();
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ArchivedCard>>(
    future: _cards,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TechPanel(
          child: Column(
            children: [
              const Text('Kartvizit özeti yüklenemedi.'),
              TextButton(
                onPressed: () => setState(() {
                  _cards = widget.service.loadCards();
                }),
                child: const Text('Tekrar dene'),
              ),
            ],
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final cards = snapshot.data!;
      final favorites = cards.where((card) => card.isFavorite).toList();
      final reminders =
          cards
              .where(
                (card) => card.reminder != null && !card.reminder!.completed,
              )
              .toList()
            ..sort((a, b) => a.reminder!.dueAt.compareTo(b.reminder!.dueAt));
      final tagCount = cards.expand((card) => card.tags).toSet().length;
      Widget cardTile(ArchivedCard card) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          child: Icon(
            card.isFavorite ? Icons.star_rounded : Icons.person_outline,
          ),
        ),
        title: Text(
          card.data.name.isNotEmpty
              ? card.data.name
              : card.data.company.isNotEmpty
              ? card.data.company
              : 'İsimsiz kartvizit',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          [
            card.data.company,
            card.data.title,
          ].where((s) => s.isNotEmpty).join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => widget.onOpen(card),
      );
      return TechPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bağlantılarına genel bakış',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: Text('${cards.length} kartvizit'),
                  onPressed: widget.onArchive,
                  avatar: const Icon(Icons.contacts_outlined, size: 18),
                ),
                ActionChip(
                  label: Text('${favorites.length} favori'),
                  onPressed: widget.onFavorites,
                  avatar: const Icon(Icons.star_outline, size: 18),
                ),
                Chip(
                  label: Text('$tagCount etiket'),
                  avatar: const Icon(Icons.label_outline, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (reminders.isNotEmpty) ...[
              const Text(
                'Takip bekleyenler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              for (final card in reminders.take(3))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.notifications_outlined,
                    color: card.reminder!.dueAt.isBefore(DateTime.now())
                        ? const Color(0xFF8A692F)
                        : const Color(0xFF174B40),
                  ),
                  title: Text(
                    card.data.name.isEmpty ? card.data.company : card.data.name,
                  ),
                  subtitle: Text(
                    '${card.reminder!.title}\n${reminderDate(card.reminder!.dueAt)}',
                  ),
                  onTap: () => widget.onOpen(card),
                ),
              TextButton(
                onPressed: widget.onReminders,
                child: Text('Tüm takipleri gör (${reminders.length})'),
              ),
              const Divider(),
            ],
            if (cards.isEmpty)
              const Text(
                'İlk kartvizitini tara. Son eklenen kişiler ve favorilerin burada görünsün.',
              ),
            if (favorites.isNotEmpty) ...[
              const Text(
                'Favorilerin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              ...favorites.take(3).map(cardTile),
              const Divider(),
            ],
            if (cards.isNotEmpty) ...[
              const Text(
                'Son eklenenler',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              ...cards.take(3).map(cardTile),
              TextButton(
                onPressed: widget.onArchive,
                child: const Text('Tüm kartvizitleri gör'),
              ),
            ],
          ],
        ),
      );
    },
  );
}

