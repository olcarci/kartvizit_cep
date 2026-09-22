import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/archived_card.dart';
import '../models/card_reminder.dart';
import 'card_archive_service.dart';

abstract class ReminderNotifications {
  Future<bool> requestPermission();
  Future<Set<int>> pendingIds();
  Future<void> schedule(
    int id,
    String cardId,
    String person,
    CardReminder reminder,
  );
  Future<void> cancel(int id);
}

class LocalReminderNotifications implements ReminderNotifications {
  static final instance = LocalReminderNotifications();
  final openedCard = ValueNotifier<String?>(null);
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;
  bool get supported => Platform.isAndroid || Platform.isIOS;

  Future<void> initialize() =>
      _initialization ??= _initialize().catchError((Object e) {
        _initialization = null;
        throw e;
      });

  Future<void> _initialize() async {
    if (!supported) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          openedCard.value = response.payload,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      openedCard.value = launch!.notificationResponse?.payload;
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!supported) return false;
    await initialize();
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: false, sound: true) ??
        false;
  }

  @override
  Future<Set<int>> pendingIds() async {
    await initialize();
    if (!supported) return {};
    return (await _plugin.pendingNotificationRequests())
        .map((item) => item.id)
        .toSet();
  }

  @override
  Future<void> schedule(
    int id,
    String cardId,
    String person,
    CardReminder reminder,
  ) async {
    await initialize();
    if (!supported) throw UnsupportedError('Mobil bildirimler desteklenmiyor.');
    await _plugin.zonedSchedule(
      id: id,
      title: person,
      body: reminder.title,
      scheduledDate: tz.TZDateTime.from(reminder.dueAt.toUtc(), tz.UTC),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'contact_followups',
          'Kişi hatırlatmaları',
          channelDescription: 'Kartvizitlere bağlı takip hatırlatmaları',
          importance: Importance.high,
          priority: Priority.high,
          visibility: NotificationVisibility.private,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: cardId,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    if (supported) await _plugin.cancel(id: id);
  }
}

class ReminderSaveResult {
  final ArchivedCard card;
  final String? warning;
  ReminderSaveResult(this.card, this.warning);
}

class ReminderService {
  final CardArchiveService archive;
  final ReminderNotifications notifications;
  final DateTime Function() now;
  static Future<void> _operations = Future.value();
  ReminderService(
    this.archive, {
    ReminderNotifications? notifications,
    DateTime Function()? now,
  }) : notifications = notifications ?? LocalReminderNotifications.instance,
       now = now ?? DateTime.now;

  Future<T> _exclusive<T>(Future<T> Function() action) {
    final result = _operations.then((_) => action());
    _operations = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  Future<void> _restoreNotification(ArchivedCard card) async {
    final reminder = card.reminder;
    if (reminder == null ||
        reminder.completed ||
        reminder.notificationId == null ||
        !reminder.dueAt.isAfter(now())) {
      return;
    }
    await notifications.schedule(
      reminder.notificationId!,
      card.id,
      card.data.name.isNotEmpty ? card.data.name : card.data.company,
      reminder,
    );
  }

  // Repair an interrupted save/delete without asking for permission on launch.
  // Imported reminders have no notification ID and are deliberately excluded.
  Future<void> reconcile() => _exclusive(() async {
    final cards = await archive.loadCards();
    final active = cards
        .where(
          (card) =>
              card.reminder != null &&
              !card.reminder!.completed &&
              card.reminder!.notificationId != null &&
              card.reminder!.dueAt.isAfter(now()),
        )
        .toList();
    final pending = await notifications.pendingIds();
    final valid = active.map((card) => card.reminder!.notificationId!).toSet();
    for (final id in pending.difference(valid)) {
      await notifications.cancel(id);
    }
    for (final card in active) {
      if (!pending.contains(card.reminder!.notificationId)) {
        await _restoreNotification(card);
      }
    }
  });

  Future<ReminderSaveResult> save(
    String cardId,
    String title,
    DateTime dueAt,
  ) => _exclusive(() async {
    if (title.trim().isEmpty || title.trim().length > 160) {
      throw ArgumentError('1–160 karakterlik bir hatırlatma yazın.');
    }
    if (!dueAt.isAfter(now())) {
      throw ArgumentError('Gelecekte bir tarih ve saat seçin.');
    }
    final cards = await archive.loadCards();
    final card = cards.firstWhere((card) => card.id == cardId);
    final old = card.reminder;
    if (old?.notificationId != null) {
      await notifications.cancel(old!.notificationId!);
    }
    final reminder = CardReminder(title: title.trim(), dueAt: dueAt);
    final ArchivedCard saved;
    try {
      saved = await archive.updateReminder(cardId, reminder);
    } catch (_) {
      await _restoreNotification(card);
      rethrow;
    }
    // Save the follow-up even when OS permission is denied, and say so explicitly.
    try {
      if (!await notifications.requestPermission()) {
        return ReminderSaveResult(
          saved,
          'Hatırlatma kaydedildi; bildirim izni kapalı. Telefon ayarlarından izin verip hatırlatmayı yeniden kaydedin.',
        );
      }
      final pending = await notifications.pendingIds();
      if (pending.length >= 60) {
        return ReminderSaveResult(
          saved,
          'Hatırlatma kaydedildi; 60 planlı bildirim sınırına ulaşıldı. Bir hatırlatmayı tamamlayıp yeniden kaydedin.',
        );
      }
      final used = {
        ...pending,
        ...cards.map((card) => card.reminder?.notificationId).whereType<int>(),
      };
      var id = 1;
      while (used.contains(id)) {
        id++;
      }
      await notifications.schedule(
        id,
        cardId,
        card.data.name.isNotEmpty ? card.data.name : card.data.company,
        reminder,
      );
      try {
        final updated = await archive.updateReminder(
          cardId,
          CardReminder(title: reminder.title, dueAt: dueAt, notificationId: id),
        );
        return ReminderSaveResult(updated, null);
      } catch (_) {
        await notifications.cancel(id);
        rethrow;
      }
    } catch (_) {
      return ReminderSaveResult(
        saved,
        'Hatırlatma kaydedildi ancak bildirim kurulamadı. Yeniden kaydetmeyi deneyin.',
      );
    }
  });

  Future<ArchivedCard> finish(String cardId, {bool remove = false}) =>
      _exclusive(() async {
        final cards = await archive.loadCards();
        final current = cards.firstWhere((card) => card.id == cardId);
        final reminder = current.reminder;
        if (reminder?.notificationId != null) {
          await notifications.cancel(reminder!.notificationId!);
        }
        try {
          return await archive.updateReminder(
            cardId,
            remove ? null : reminder?.withoutNotification(completed: true),
          );
        } catch (_) {
          await _restoreNotification(current);
          rethrow;
        }
      });

  Future<void> deleteCard(ArchivedCard card) => _exclusive(() async {
    final current = (await archive.loadCards())
        .where((item) => item.id == card.id)
        .firstOrNull;
    if (current?.reminder?.notificationId != null) {
      await notifications.cancel(current!.reminder!.notificationId!);
    }
    try {
      await archive.deleteCard(card);
    } catch (_) {
      if (current != null) await _restoreNotification(current);
      rethrow;
    }
  });
}
