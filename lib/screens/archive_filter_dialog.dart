import 'package:flutter/material.dart';

import '../services/archive_query.dart';

class ArchiveFilters {
  final ArchiveSort sort;
  final ReminderFilter reminders;
  final String? company;
  final DateTimeRange? dates;
  const ArchiveFilters({
    this.sort = ArchiveSort.newest,
    this.reminders = ReminderFilter.all,
    this.company,
    this.dates,
  });
  bool get active =>
      company != null || dates != null || reminders != ReminderFilter.all;
}

class ArchiveFilterDialog extends StatefulWidget {
  final ArchiveFilters filters;
  final List<String> companies;
  const ArchiveFilterDialog({
    super.key,
    required this.filters,
    required this.companies,
  });
  @override
  State<ArchiveFilterDialog> createState() => _ArchiveFilterDialogState();
}

class _ArchiveFilterDialogState extends State<ArchiveFilterDialog> {
  late ArchiveSort _sort = widget.filters.sort;
  late ReminderFilter _reminders = widget.filters.reminders;
  late String? _company = widget.companies.contains(widget.filters.company)
      ? widget.filters.company
      : null;
  late DateTimeRange? _dates = widget.filters.dates;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Filtrele ve sırala'),
    content: SizedBox(
      width: 450,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<ArchiveSort>(
              initialValue: _sort,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Sıralama'),
              items: [
                for (final entry in {
                  ArchiveSort.newest: 'En yeni önce',
                  ArchiveSort.oldest: 'En eski önce',
                  ArchiveSort.name: 'Ad soyad A–Z',
                  ArchiveSort.company: 'Şirket A–Z',
                }.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() => _sort = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _company ?? '',
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Şirket'),
              items: [
                const DropdownMenuItem(value: '', child: Text('Tüm şirketler')),
                for (final company in widget.companies)
                  DropdownMenuItem(
                    value: company,
                    child: Text(company, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => _company = value == '' ? null : value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReminderFilter>(
              initialValue: _reminders,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Hatırlatma durumu'),
              items: [
                for (final entry in {
                  ReminderFilter.all: 'Tümü',
                  ReminderFilter.pending: 'Takip bekleyen',
                  ReminderFilter.overdue: 'Zamanı geçen',
                  ReminderFilter.completed: 'Tamamlanan',
                }.entries)
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
              ],
              onChanged: (value) => setState(() => _reminders = value!),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                _dates == null
                    ? 'Eklenme tarihi aralığı'
                    : '${_dates!.start.day}.${_dates!.start.month}.${_dates!.start.year} – ${_dates!.end.day}.${_dates!.end.month}.${_dates!.end.year}',
              ),
              onPressed: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(1970),
                  lastDate: DateTime(DateTime.now().year + 5, 12, 31),
                  initialDateRange: _dates,
                  helpText: 'Kartın eklenme tarihi',
                  saveText: 'Seç',
                  cancelText: 'Vazgeç',
                );
                if (mounted && range != null) setState(() => _dates = range);
              },
            ),
            if (_dates != null)
              TextButton(
                onPressed: () => setState(() => _dates = null),
                child: const Text('Tarih aralığını temizle'),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, const ArchiveFilters()),
        child: const Text('Sıfırla'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Vazgeç'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(
          context,
          ArchiveFilters(
            sort: _sort,
            company: _company,
            dates: _dates,
            reminders: _reminders,
          ),
        ),
        child: const Text('Uygula'),
      ),
    ],
  );
}
