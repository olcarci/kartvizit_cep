import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../widgets/tech_background.dart';
import '../widgets/vivid_button.dart';

class CropSelection {
  final Uint8List? bytes;
  const CropSelection.original() : bytes = null;
  const CropSelection.cropped(this.bytes);
}

class _LoadedImage {
  final Uint8List bytes;
  final Size size;
  const _LoadedImage({required this.bytes, required this.size});
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

/// Minimal, self-contained crop UI. Earlier versions of this screen used the
/// crop_your_image package, but its internal state (re-derived from
/// MediaQuery on every didChangeDependencies call) was observed to silently
/// diverge from what was visually dragged on screen. Doing the layout,
/// dragging and pixel-cropping ourselves keeps every coordinate conversion
/// in one easily-verified place.
class CropPage extends StatefulWidget {
  final String imagePath;
  final Future<Uint8List> Function()? imageLoader;
  const CropPage({super.key, required this.imagePath, this.imageLoader});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  static const double _handleTouchSize = 44;
  static const double _minCropSize = 40;

  late final Future<_LoadedImage> _image;
  bool _cropping = false;

  // The user's crop selection is kept in normalized image coordinates
  // (0.0..1.0), not in screen pixels. This makes the selection immune to
  // SafeArea/layout/button-size changes that can happen on a real iPhone
  // while the user presses "Kırp ve oku".
  Rect _normalizedCrop = const Rect.fromLTWH(0.01, 0.01, 0.98, 0.98);

  // These two values are only for drawing the preview on screen.
  Rect? _cropRect;
  Rect? _displayRect;
  Size? _lastConstraintsSize;

  @override
  void initState() {
    super.initState();
    _image = _load();
  }

  Future<_LoadedImage> _load() async {
    final bytes = await (widget.imageLoader?.call() ?? _readAsPng());
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        return _LoadedImage(
          bytes: bytes,
          size: Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          ),
        );
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Future<Uint8List> _readAsPng() async {
    final bytes = await File(widget.imagePath).readAsBytes();
    // Normalize supported phone image formats into PNG for the crop preview.
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      try {
        final png = await frame.image.toByteData(
          format: ui.ImageByteFormat.png,
        );
        if (png == null) throw StateError('Image conversion failed');
        return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Rect _fitContain(Size imageSize, Size container) {
    final imageAspect = imageSize.width / imageSize.height;
    final containerAspect = container.width / container.height;
    double width;
    double height;
    if (imageAspect > containerAspect) {
      width = container.width;
      height = width / imageAspect;
    } else {
      height = container.height;
      width = height * imageAspect;
    }
    final left = (container.width - width) / 2;
    final top = (container.height - height) / 2;
    return Rect.fromLTWH(left, top, width, height);
  }

  Rect _cropRectForDisplay(Rect display) {
    return Rect.fromLTWH(
      display.left + (_normalizedCrop.left * display.width),
      display.top + (_normalizedCrop.top * display.height),
      _normalizedCrop.width * display.width,
      _normalizedCrop.height * display.height,
    );
  }

  Rect _normalizeCropRect(Rect crop, Rect display) {
    if (display.isEmpty) return _normalizedCrop;

    final left = ((crop.left - display.left) / display.width).clamp(0.0, 1.0);
    final top = ((crop.top - display.top) / display.height).clamp(0.0, 1.0);
    final right =
        ((crop.right - display.left) / display.width).clamp(0.0, 1.0);
    final bottom =
        ((crop.bottom - display.top) / display.height).clamp(0.0, 1.0);

    return Rect.fromLTRB(left, top, right, bottom);
  }

  void _ensureLayout(Size constraintsSize, Size imageSize) {
    if (_lastConstraintsSize == constraintsSize &&
        _displayRect != null &&
        _cropRect != null) {
      return;
    }

    _lastConstraintsSize = constraintsSize;
    final newDisplay = _fitContain(imageSize, constraintsSize);

    // Re-create the visible crop rectangle from the normalized selection.
    // The screen can relayout freely; the actual selection never changes.
    _displayRect = newDisplay;
    _cropRect = _cropRectForDisplay(newDisplay);
  }

  void _dragCorner(_Corner corner, Offset delta) {
    final bounds = _displayRect;
    final rect = _cropRect;
    if (bounds == null || rect == null) return;
    late final Rect updated;
    switch (corner) {
      case _Corner.topLeft:
        final left = (rect.left + delta.dx).clamp(
          bounds.left,
          rect.right - _minCropSize,
        );
        final top = (rect.top + delta.dy).clamp(
          bounds.top,
          rect.bottom - _minCropSize,
        );
        updated = Rect.fromLTRB(left, top, rect.right, rect.bottom);
      case _Corner.topRight:
        final right = (rect.right + delta.dx).clamp(
          rect.left + _minCropSize,
          bounds.right,
        );
        final top = (rect.top + delta.dy).clamp(
          bounds.top,
          rect.bottom - _minCropSize,
        );
        updated = Rect.fromLTRB(rect.left, top, right, rect.bottom);
      case _Corner.bottomLeft:
        final left = (rect.left + delta.dx).clamp(
          bounds.left,
          rect.right - _minCropSize,
        );
        final bottom = (rect.bottom + delta.dy).clamp(
          rect.top + _minCropSize,
          bounds.bottom,
        );
        updated = Rect.fromLTRB(left, rect.top, rect.right, bottom);
      case _Corner.bottomRight:
        final right = (rect.right + delta.dx).clamp(
          rect.left + _minCropSize,
          bounds.right,
        );
        final bottom = (rect.bottom + delta.dy).clamp(
          rect.top + _minCropSize,
          bounds.bottom,
        );
        updated = Rect.fromLTRB(rect.left, rect.top, right, bottom);
    }
    setState(() {
      _cropRect = updated;
      _normalizedCrop = _normalizeCropRect(updated, bounds);
    });
  }

  // Converts the normalized selection directly into the source image's
  // pixel space. No screen/layout coordinates are involved here, so a
  // relayout caused by SafeArea, button press animation, device rotation,
  // etc. cannot change what will actually be cropped.
  Rect _imageSpaceCropRect(Size imageSize) {
    return Rect.fromLTWH(
      _normalizedCrop.left * imageSize.width,
      _normalizedCrop.top * imageSize.height,
      _normalizedCrop.width * imageSize.width,
      _normalizedCrop.height * imageSize.height,
    );
  }

  Future<void> _cropAndPop(_LoadedImage image) async {
    // Read the crop area before triggering any rebuild (e.g. from
    // setState below), so a stray relayout can't change it out from under
    // us between the tap and the actual crop.
    final area = _imageSpaceCropRect(image.size);
    setState(() => _cropping = true);
    try {
      final cropped = await _cropToArea(image.bytes, area);
      if (!mounted) return;
      Navigator.of(context).pop(CropSelection.cropped(cropped));
    } catch (_) {
      if (!mounted) return;
      setState(() => _cropping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kırpma tamamlanamadı. Tekrar deneyin veya kırpmadan devam edin.',
          ),
        ),
      );
    }
  }

  // Crops [bytes] to [area] (in the source image's own pixel space) using
  // dart:ui directly.
  Future<Uint8List> _cropToArea(Uint8List bytes, Rect area) async {
    final codec = await ui.instantiateImageCodec(bytes);
    try {
      final frame = await codec.getNextFrame();
      final image = frame.image;
      try {
        final imageWidth = image.width.toDouble();
        final imageHeight = image.height.toDouble();
        final srcRect = Rect.fromLTRB(
          area.left.clamp(0, imageWidth),
          area.top.clamp(0, imageHeight),
          (area.left + area.width).clamp(0, imageWidth),
          (area.top + area.height).clamp(0, imageHeight),
        );
        final width = srcRect.width.round().clamp(1, image.width);
        final height = srcRect.height.round().clamp(1, image.height);

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawImageRect(
          image,
          srcRect,
          Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
          Paint(),
        );
        final croppedImage = await recorder.endRecording().toImage(
          width,
          height,
        );
        try {
          final png = await croppedImage.toByteData(
            format: ui.ImageByteFormat.png,
          );
          if (png == null) throw StateError('Crop encoding failed');
          return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
        } finally {
          croppedImage.dispose();
        }
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }
  }

  Widget _cornerHandle(Offset position, _Corner corner) {
    const dotSize = 36.0;
    return Positioned(
      left: position.dx - _handleTouchSize / 2,
      top: position.dy - _handleTouchSize / 2,
      width: _handleTouchSize,
      height: _handleTouchSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => _dragCorner(corner, details.delta),
        child: Center(
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: const Color(0xFF174B40),
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.open_with, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_cropping,
    child: Scaffold(
      appBar: AppBar(title: const Text('Kartviziti kırp')),
      body: TechBackground(
        child: SafeArea(
          child: Column(
            children: [
              const TechPanel(
                margin: EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: EdgeInsets.all(15),
                child: Row(
                  children: [
                    Icon(Icons.crop_free_rounded, color: Color(0xFF174B40)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Köşeleri kartvizitin kenarlarına sürükle. Tüm yazılar çerçevenin içinde kalsın.',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<_LoadedImage>(
                  future: _image,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Bu fotoğraf kırpma ekranında açılamadı. Kırpmadan devam edebilir veya başka bir fotoğraf seçebilirsin.',
                          ),
                        ),
                      );
                    }
                    final image = snapshot.data;
                    if (image == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          _ensureLayout(constraints.biggest, image.size);
                          final display = _displayRect!;
                          final crop = _cropRect!;
                          return Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned.fromRect(
                                rect: display,
                                child: Image.memory(
                                  image.bytes,
                                  fit: BoxFit.fill,
                                ),
                              ),
                              IgnorePointer(
                                child: ClipPath(
                                  clipper: _HoleClipper(crop),
                                  child: Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    color: const Color(0x99000000),
                                  ),
                                ),
                              ),
                              _cornerHandle(crop.topLeft, _Corner.topLeft),
                              _cornerHandle(crop.topRight, _Corner.topRight),
                              _cornerHandle(
                                crop.bottomLeft,
                                _Corner.bottomLeft,
                              ),
                              _cornerHandle(
                                crop.bottomRight,
                                _Corner.bottomRight,
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<_LoadedImage>(
                  future: _image,
                  builder: (context, snapshot) {
                    final image = snapshot.data;
                    return Column(
                      children: [
                        VividButton(
                          onPressed: image != null && !_cropping
                              ? () => _cropAndPop(image)
                              : null,
                          icon: Icons.crop,
                          label: _cropping ? 'Kırpılıyor…' : 'Kırp ve oku',
                        ),
                        TextButton(
                          onPressed: _cropping
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pop(const CropSelection.original()),
                          child: const Text('Kırpmadan devam et'),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _HoleClipper extends CustomClipper<Path> {
  final Rect hole;
  const _HoleClipper(this.hole);

  @override
  Path getClip(Size size) => Path.combine(
    PathOperation.difference,
    Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
    Path()..addRect(hole),
  );

  @override
  bool shouldReclip(covariant _HoleClipper oldClipper) =>
      oldClipper.hole != hole;
}
