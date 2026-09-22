import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/contact_links.dart';
import 'tech_background.dart';

class ContactQuickActions extends StatefulWidget {
  final List<TextEditingController> fields;
  final Future<bool> Function(Uri)? opener;
  const ContactQuickActions({super.key, required this.fields, this.opener});

  @override
  State<ContactQuickActions> createState() => _ContactQuickActionsState();
}

class _ContactQuickActionsState extends State<ContactQuickActions> {
  bool _opening = false;
  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      field.addListener(_changed);
    }
  }

  @override
  void didUpdateWidget(covariant ContactQuickActions oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields) {
      for (final field in oldWidget.fields) {
        field.removeListener(_changed);
      }
      for (final field in widget.fields) {
        field.addListener(_changed);
      }
    }
  }

  @override
  void dispose() {
    for (final field in widget.fields) {
      field.removeListener(_changed);
    }
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  String _value(int i) => widget.fields[i].text.trim();
  List<String> _phones() => [3, 7, 8]
      .expand((i) => _value(i).split('\n'))
      .map(ContactLinks.phone)
      .whereType<String>()
      .toSet()
      .toList();

  Future<void> _open(Uri uri) async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final opened =
          await (widget.opener?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
      if (!opened) throw StateError('Unavailable');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Açılamadı. İlgili uygulamanın kurulu olduğunu ve kartvizit bilgisini kontrol edin.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _phoneAction(bool whatsapp) async {
    final numbers = _phones();
    if (numbers.isEmpty) return;
    final selected = numbers.length == 1
        ? numbers.first
        : await showDialog<String>(
            context: context,
            builder: (context) => SimpleDialog(
              title: Text(
                whatsapp ? 'WhatsApp numarası seç' : 'Aranacak numarayı seç',
              ),
              children: [
                for (final number in numbers)
                  SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, number),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(number),
                    ),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Vazgeç'),
                ),
              ],
            ),
          );
    if (!mounted || selected == null) return;
    await _open(
      whatsapp
          ? ContactLinks.whatsapp(selected)
          : Uri(scheme: 'tel', path: selected),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phones = _phones();
    final email = ContactLinks.email(_value(4));
    final website = ContactLinks.website(_value(5));
    Widget button(String label, IconData icon, VoidCallback? action) =>
        OutlinedButton.icon(
          onPressed: _opening ? null : action,
          icon: Icon(icon, size: 21),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        );
    return TechPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı işlemler',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kartvizitteki iletişim bilgileriyle rehbere kaydetmeden ulaşın.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              button(
                'Ara',
                Icons.call_outlined,
                phones.isEmpty ? null : () => _phoneAction(false),
              ),
              button(
                'WhatsApp’tan yaz',
                Icons.chat_outlined,
                phones.isEmpty ? null : () => _phoneAction(true),
              ),
              button(
                'E-posta gönder',
                Icons.mail_outline,
                email == null ? null : () => _open(email),
              ),
              button(
                'Web sitesini aç',
                Icons.language,
                website == null ? null : () => _open(website),
              ),
              button(
                'Adresi haritada göster',
                Icons.map_outlined,
                _value(6).isEmpty
                    ? null
                    : () => _open(
                        ContactLinks.map(_value(6), apple: Platform.isIOS),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Eksik veya geçersiz bilgi bulunan işlemler pasiftir.',
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
