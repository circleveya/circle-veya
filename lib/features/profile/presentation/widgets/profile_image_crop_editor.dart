import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

enum ProfileCropKind { avatar, cover }

class ProfileCropResult {
  const ProfileCropResult({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;

  XFile toXFile() => XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'image/jpeg',
      );
}

/// Öffnet Galerie, danach Crop-Editor (Verschieben/Zoomen).
Future<ProfileCropResult?> pickAndCropProfileImage(
  BuildContext context, {
  required ProfileCropKind kind,
}) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: kind == ProfileCropKind.cover ? 2400 : 1600,
    imageQuality: 92,
  );
  if (picked == null || !context.mounted) return null;

  final bytes = await picked.readAsBytes();
  if (!context.mounted) return null;

  return showProfileImageCropper(
    context,
    imageBytes: bytes,
    kind: kind,
    originalName: picked.name,
  );
}

Future<ProfileCropResult?> showProfileImageCropper(
  BuildContext context, {
  required Uint8List imageBytes,
  required ProfileCropKind kind,
  String? originalName,
}) {
  return Navigator.of(context).push<ProfileCropResult>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ProfileImageCropScreen(
        imageBytes: imageBytes,
        kind: kind,
        originalName: originalName,
      ),
    ),
  );
}

class ProfileImageCropScreen extends StatefulWidget {
  const ProfileImageCropScreen({
    super.key,
    required this.imageBytes,
    required this.kind,
    this.originalName,
  });

  final Uint8List imageBytes;
  final ProfileCropKind kind;
  final String? originalName;

  @override
  State<ProfileImageCropScreen> createState() => _ProfileImageCropScreenState();
}

class _ProfileImageCropScreenState extends State<ProfileImageCropScreen> {
  ui.Image? _decoded;
  String? _error;
  bool _busy = false;

  double _scale = 1;
  Offset _offset = Offset.zero;
  Size? _cropSize;

  /// Aktiver Zeiger für Maus-/Finger-Drag (Web inkl.).
  int? _activePointer;
  Offset? _lastPointerLocal;
  bool _dragging = false;

  /// Cover ~ Banner-Höhe 280 bei typischer Breite → ca. 2.8–3:1; Avatar 1:1
  double get _aspect =>
      widget.kind == ProfileCropKind.avatar ? 1 : 16 / 9;

  bool get _isCircle => widget.kind == ProfileCropKind.avatar;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _decoded?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _decoded = frame.image);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Bild konnte nicht geladen werden');
    }
  }

  Size _baseDisplaySize(Size cropSize, double imageW, double imageH) {
    final imageAspect = imageW / imageH;
    final cropAspect = cropSize.width / cropSize.height;
    if (imageAspect > cropAspect) {
      final h = cropSize.height;
      return Size(h * imageAspect, h);
    }
    final w = cropSize.width;
    return Size(w, w / imageAspect);
  }

  Rect _imageRect(Size cropSize, double imageW, double imageH) {
    final base = _baseDisplaySize(cropSize, imageW, imageH);
    final scaled = Size(base.width * _scale, base.height * _scale);
    final center = Offset(cropSize.width / 2, cropSize.height / 2) + _offset;
    return Rect.fromCenter(
      center: center,
      width: scaled.width,
      height: scaled.height,
    );
  }

  void _clampOffset(Size cropSize, double imageW, double imageH) {
    final rect = _imageRect(cropSize, imageW, imageH);
    var dx = _offset.dx;
    var dy = _offset.dy;

    if (rect.left > 0) dx -= rect.left;
    if (rect.top > 0) dy -= rect.top;
    if (rect.right < cropSize.width) dx += cropSize.width - rect.right;
    if (rect.bottom < cropSize.height) dy += cropSize.height - rect.bottom;

    _offset = Offset(dx, dy);
  }

  Future<void> _confirm(Size cropSize) async {
    final decoded = _decoded;
    if (decoded == null || _busy) return;

    setState(() => _busy = true);
    try {
      final imageW = decoded.width.toDouble();
      final imageH = decoded.height.toDouble();
      final display = _imageRect(cropSize, imageW, imageH);

      final scaleX = imageW / display.width;
      final scaleY = imageH / display.height;

      var srcLeft = (0 - display.left) * scaleX;
      var srcTop = (0 - display.top) * scaleY;
      var srcWidth = cropSize.width * scaleX;
      var srcHeight = cropSize.height * scaleY;

      srcLeft = srcLeft.clamp(0, imageW - 1);
      srcTop = srcTop.clamp(0, imageH - 1);
      srcWidth = srcWidth.clamp(1, imageW - srcLeft);
      srcHeight = srcHeight.clamp(1, imageH - srcTop);

      final raw = widget.imageBytes;
      final src = img.decodeImage(raw);
      if (src == null) {
        throw StateError('decode failed');
      }

      final cropped = img.copyCrop(
        src,
        x: srcLeft.round(),
        y: srcTop.round(),
        width: math.max(1, srcWidth.round()),
        height: math.max(1, srcHeight.round()),
      );

      final outW = widget.kind == ProfileCropKind.avatar ? 512 : 1600;
      final resized = img.copyResize(
        cropped,
        width: outW,
        interpolation: img.Interpolation.cubic,
      );

      final jpg = Uint8List.fromList(
        img.encodeJpg(resized, quality: 88),
      );

      final base = widget.originalName?.replaceAll(RegExp(r'\.[^.]+$'), '') ??
          (widget.kind == ProfileCropKind.avatar ? 'avatar' : 'cover');
      if (!mounted) return;
      Navigator.of(context).pop(
        ProfileCropResult(bytes: jpg, fileName: '$base.jpg'),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zuschneiden fehlgeschlagen')),
      );
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.kind == ProfileCropKind.avatar
        ? 'Profilbild auswählen'
        : 'Banner auswählen';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(title),
        actions: [
          if (_decoded != null)
            TextButton(
              onPressed: _busy || _cropSize == null
                  ? null
                  : () => _confirm(_cropSize!),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Fertig',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Text(_error!, style: const TextStyle(color: Colors.white)),
            )
          : _decoded == null
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final maxW = math.min(constraints.maxWidth - 32, 560.0);
                    final cropW = maxW;
                    final cropH = cropW / _aspect;
                    final cropSize = Size(cropW, cropH);
                    _cropSize = cropSize;
                    final imageW = _decoded!.width.toDouble();
                    final imageH = _decoded!.height.toDouble();

                    return Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: SizedBox(
                              width: cropW,
                              height: cropH,
                              child: ClipRect(
                                child: MouseRegion(
                                  cursor: _dragging
                                      ? SystemMouseCursors.grabbing
                                      : SystemMouseCursors.grab,
                                  child: Listener(
                                    behavior: HitTestBehavior.opaque,
                                    onPointerDown: (event) {
                                      if (_activePointer != null) return;
                                      _activePointer = event.pointer;
                                      _lastPointerLocal = event.localPosition;
                                      setState(() => _dragging = true);
                                    },
                                    onPointerMove: (event) {
                                      if (event.pointer != _activePointer) {
                                        return;
                                      }
                                      final last = _lastPointerLocal;
                                      if (last == null) return;
                                      final delta =
                                          event.localPosition - last;
                                      _lastPointerLocal = event.localPosition;
                                      setState(() {
                                        _offset += delta;
                                        _clampOffset(
                                          cropSize,
                                          imageW,
                                          imageH,
                                        );
                                      });
                                    },
                                    onPointerUp: (event) {
                                      if (event.pointer != _activePointer) {
                                        return;
                                      }
                                      _activePointer = null;
                                      _lastPointerLocal = null;
                                      setState(() => _dragging = false);
                                    },
                                    onPointerCancel: (event) {
                                      if (event.pointer != _activePointer) {
                                        return;
                                      }
                                      _activePointer = null;
                                      _lastPointerLocal = null;
                                      setState(() => _dragging = false);
                                    },
                                    onPointerSignal: (signal) {
                                      if (signal is! PointerScrollEvent) {
                                        return;
                                      }
                                      // Mausrad: zoomen um den Cursor
                                      final zoomFactor = math.exp(
                                        -signal.scrollDelta.dy * 0.0015,
                                      );
                                      setState(() {
                                        final next = (_scale * zoomFactor)
                                            .clamp(1.0, 4.0);
                                        _scale = next;
                                        _clampOffset(
                                          cropSize,
                                          imageW,
                                          imageH,
                                        );
                                      });
                                    },
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CustomPaint(
                                          painter: _CropImagePainter(
                                            image: _decoded!,
                                            imageRect: _imageRect(
                                              cropSize,
                                              imageW,
                                              imageH,
                                            ),
                                          ),
                                        ),
                                        CustomPaint(
                                          painter: _CropOverlayPainter(
                                            isCircle: _isCircle,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            children: [
                              Text(
                                kIsWeb
                                    ? 'Mit der Maus ziehen zum Verschieben · '
                                        'Mausrad oder Slider zum Zoomen'
                                    : 'Ziehen zum Verschieben · '
                                        'Slider zum Zoomen',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.zoom_out,
                                      color: Colors.white70, size: 20),
                                  Expanded(
                                    child: Slider(
                                      value: _scale,
                                      min: 1,
                                      max: 4,
                                      onChanged: (v) {
                                        setState(() {
                                          _scale = v;
                                          _clampOffset(
                                            cropSize,
                                            imageW,
                                            imageH,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  const Icon(Icons.zoom_in,
                                      color: Colors.white70, size: 20),
                                ],
                              ),
                              const SizedBox(height: 8),
                              FilledButton(
                                onPressed: _busy
                                    ? null
                                    : () => _confirm(cropSize),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(48),
                                ),
                                child: Text(
                                  widget.kind == ProfileCropKind.avatar
                                      ? 'Profilbild übernehmen'
                                      : 'Banner übernehmen',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
    );
  }
}

class _CropImagePainter extends CustomPainter {
  _CropImagePainter({
    required this.image,
    required this.imageRect,
  });

  final ui.Image image;
  final Rect imageRect;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: imageRect,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _CropImagePainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.imageRect != imageRect;
}

class _CropOverlayPainter extends CustomPainter {
  _CropOverlayPainter({required this.isCircle});

  final bool isCircle;

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final hole = Path();
    if (isCircle) {
      hole.addOval(Rect.fromLTWH(0, 0, size.width, size.height));
    } else {
      hole.addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );
    }

    final cutout = Path.combine(PathOperation.difference, overlay, hole);
    canvas.drawPath(
      cutout,
      Paint()..color = Colors.black.withValues(alpha: 0.55),
    );

    final border = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    if (isCircle) {
      canvas.drawOval(Rect.fromLTWH(1, 1, size.width - 2, size.height - 2), border);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(1, 1, size.width - 2, size.height - 2),
          const Radius.circular(12),
        ),
        border,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropOverlayPainter oldDelegate) =>
      oldDelegate.isCircle != isCircle;
}
