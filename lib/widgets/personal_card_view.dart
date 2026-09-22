import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/personal_card.dart';

class PersonalCardView extends StatelessWidget {
  static const colors = [
    Color(0xFF133A54),
    Color(0xFF3C2862),
    Color(0xFF145348),
  ];
  final PersonalCard card;
  const PersonalCardView({super.key, required this.card});
  @override
  Widget build(BuildContext context) {
    final data = card.data;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
          color: const Color(0xFF163044),
          fontSize: 16,
          height: 1.4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: colors[card.theme],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            if (card.avatarPath != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(card.avatarPath!),
                    width: 76,
                    height: 76,
                    fit: BoxFit.contain,
                    errorBuilder: (_, error, stack) => const Icon(
                      Icons.person_outline,
                      size: 64,
                      color: Color(0xFF163044),
                    ),
                  ),
                ),
              ),
            Text(
              data.name.isEmpty ? data.company : data.name,
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.bold,
                color: colors[card.theme],
              ),
            ),
            if (data.title.isNotEmpty) Text(data.title),
            if (data.company.isNotEmpty && data.name.isNotEmpty)
              Text(
                data.company,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 16),
            for (final value in [
              ...data.phones,
              data.email,
              data.website,
              data.address,
            ])
              if (value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(value),
                ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: QrImageView(
                    data: card.qrData,
                    version: QrVersions.auto,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    padding: const EdgeInsets.all(20),
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                    semanticsLabel: 'İletişim bilgilerimin QR kodu',
                  ),
                ),
              ),
            ),
            const Center(
              child: Text(
                'Rehbere eklemek için QR kodu okutun',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Color(0xFF455A64)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
