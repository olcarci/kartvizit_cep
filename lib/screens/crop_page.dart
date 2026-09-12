import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import '../widgets/vivid_button.dart';

class CropSelection {
  final Uint8List? bytes;
  const CropSelection.original() : bytes = null;
  const CropSelection.cropped(this.bytes);
}

class CropPage extends StatefulWidget {
  final String imagePath;
  final Future<Uint8List> Function()? imageLoader;
  const CropPage({super.key, required this.imagePath, this.imageLoader});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  final _controller = CropController();
  late final Future<Uint8List> _image;
  bool _ready = false;
  bool _cropping = false;

  @override
  void initState() {
    super.initState();
    _image = widget.imageLoader?.call() ?? _loadImage();
  }

  Future<Uint8List> _loadImage() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    // Normalize supported phone image formats into PNG for the crop backend.
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) throw StateError('Image conversion failed');
        return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  void _onCropped(CropResult result) {
    if (!mounted) return;
    if (result is CropSuccess) {
      Navigator.of(context).pop(CropSelection.cropped(result.croppedImage));
    } else {
      setState(() { _cropping = false; _ready = true; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Kırpma tamamlanamadı. Tekrar deneyin veya kırpmadan devam edin.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_cropping,
    child: Scaffold(
      appBar: AppBar(title: const Text('Kartviziti kırp')),
      body: SafeArea(child: Column(children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Köşeleri kartvizitin kenarlarına sürükle. Tüm yazılar çerçevenin içinde kalsın.'),
        ),
        Expanded(child: FutureBuilder<Uint8List>(
          future: _image,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Bu fotoğraf kırpma ekranında açılamadı. Kırpmadan devam edebilir veya başka bir fotoğraf seçebilirsin.'),
              ));
            }
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Crop(
              image: snapshot.data!,
              controller: _controller,
              interactive: false,
              fixCropRect: false,
              initialRectBuilder: InitialRectBuilder.withBuilder((viewport, image) =>
                Rect.fromCenter(center: image.center,
                  width: image.width * 0.75, height: image.height * 0.75)),
              cornerDotBuilder: (size, alignment) => Container(
                width: size, height: size,
                decoration: BoxDecoration(
                  color: const Color(0xFF006C62),
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.open_with, color: Colors.white, size: 20),
              ),
              baseColor: const Color(0xFF182321),
              maskColor: const Color(0x99000000),
              progressIndicator: const Center(child: CircularProgressIndicator()),
              onCropped: _onCropped,
              onStatusChanged: (status) {
                // Package callbacks may run during the child's build.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _ready = status == CropStatus.ready);
                });
              },
              ),
            );
          },
        )),
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          VividButton(
            onPressed: _ready && !_cropping ? () {
              setState(() => _cropping = true);
              _controller.crop();
            } : null,
            icon: Icons.crop,
            label: _cropping ? 'Kırpılıyor…' : 'Kırp ve oku',
          ),
          TextButton(
            onPressed: _cropping ? null : () => Navigator.of(context).pop(const CropSelection.original()),
            child: const Text('Kırpmadan devam et'),
          ),
        ])),
      ])),
    ),
  );
}
