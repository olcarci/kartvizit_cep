import '../models/archived_card.dart';

enum ArchiveSort { newest, oldest, name, company }

enum ReminderFilter { all, pending, overdue, completed }

String searchKey(String value) {
  var result = value.replaceAll('İ', 'i').replaceAll('I', 'i').toLowerCase();
  for (final entry in {
    'ç': 'c',
    'ğ': 'g',
    'ı': 'i',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
  }.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result.trim();
}

// Compare Turkish letters in alphabetic order without an OS locale dependency.
int compareTurkish(String a, String b) {
  const alphabet = 'abcçdefgğhıijklmnoöprsştuüvyz';
  String lower(String s) =>
      s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase().trim();
  final aa = lower(a).runes.toList(), bb = lower(b).runes.toList();
  for (var i = 0; i < aa.length && i < bb.length; i++) {
    int rank(int rune) {
      final index = alphabet.indexOf(String.fromCharCode(rune));
      return index < 0 ? rune + 100 : index;
    }

    final diff = rank(aa[i]).compareTo(rank(bb[i]));
    if (diff != 0) return diff;
  }
  return aa.length.compareTo(bb.length);
}

List<ArchivedCard> queryCards(
  List<ArchivedCard> source, {
  String query = '',
  bool favoritesOnly = false,
  String? tag,
  String? company,
  DateTime? from,
  DateTime? to,
  ReminderFilter reminders = ReminderFilter.all,
  ArchiveSort sort = ArchiveSort.newest,
  DateTime? now,
}) {
  final key = searchKey(query);
  final clock = now ?? DateTime.now();
  final result = source.where((card) {
    final date = card.createdAt.toLocal();
    final reminder = card.reminder;
    if (favoritesOnly && !card.isFavorite ||
        tag != null && !card.tags.contains(tag) ||
        company != null && card.data.company != company) {
      return false;
    }
    if (from != null &&
        date.isBefore(DateTime(from.year, from.month, from.day))) {
      return false;
    }
    if (to != null && !date.isBefore(DateTime(to.year, to.month, to.day + 1))) {
      return false;
    }
    if (reminders == ReminderFilter.pending &&
        (reminder == null || reminder.completed)) {
      return false;
    }
    if (reminders == ReminderFilter.overdue &&
        (reminder == null ||
            reminder.completed ||
            reminder.dueAt.isAfter(clock))) {
      return false;
    }
    if (reminders == ReminderFilter.completed &&
        (reminder == null || !reminder.completed)) {
      return false;
    }
    return key.isEmpty ||
        searchKey(
          [
            card.data.name,
            card.data.company,
            card.data.title,
            card.data.email,
            card.data.address,
            ...card.data.phones,
            ...card.tags,
            card.notes,
            reminder?.title ?? '',
          ].join(' '),
        ).contains(key);
  }).toList();
  String name(ArchivedCard card) =>
      card.data.name.isEmpty ? card.data.company : card.data.name;
  result.sort((a, b) {
    final comparison = switch (sort) {
      ArchiveSort.newest => b.createdAt.compareTo(a.createdAt),
      ArchiveSort.oldest => a.createdAt.compareTo(b.createdAt),
      ArchiveSort.name => compareTurkish(name(a), name(b)),
      ArchiveSort.company => compareTurkish(a.data.company, b.data.company),
    };
    return comparison != 0 ? comparison : a.id.compareTo(b.id);
  });
  return result;
}
