import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';

/// Dialog interaktif untuk memotong (crop) foto menjadi rasio potrait (default 3:4).
/// Memungkinkan user menggeser (pan) foto ke kiri/kanan/atas/bawah serta memperbesar (zoom),
/// sehingga foto landscape yang diunggah dapat disesuaikan agar wajah mempelai tidak terpotong.
class PortraitCropDialog extends StatefulWidget {
  final PickedImageData image;
  final double aspectRatio;
  final String title;
  final String subtitle;

  const PortraitCropDialog({
    super.key,
    required this.image,
    this.aspectRatio = 3 / 4,
    this.title = 'Sesuaikan Foto (Potrait)',
    this.subtitle = 'Geser foto ke kiri/kanan atau perbesar agar pas di bingkai',
  });

  /// Helper statis untuk menampilkan dialog dan mengembalikan [PickedImageData] hasil crop (atau null jika dibatalkan).
  static Future<PickedImageData?> show(
    BuildContext context, {
    required PickedImageData image,
    double aspectRatio = 3 / 4,
    String title = 'Sesuaikan Foto (Potrait)',
    String subtitle = 'Geser foto ke kiri/kanan atau perbesar agar pas di bingkai',
  }) {
    return showDialog<PickedImageData?>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (ctx) => PortraitCropDialog(
        image: image,
        aspectRatio: aspectRatio,
        title: title,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<PortraitCropDialog> createState() => _PortraitCropDialogState();
}

class _PortraitCropDialogState extends State<PortraitCropDialog> {
  ui.Image? _rawImage;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;

  // Transformasi interaktif
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  // State awal gesture saat mulai drag/pinch
  double _startScale = 1.0;
  Offset _startOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.image.bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _rawImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal memuat foto: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _resetTransform() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  /// Menghitung batasan pan maksimum agar gambar selalu menutupi area crop
  Offset _clampOffset(Offset candidate, Size viewportSize, double baseScale, double currentZoom) {
    if (_rawImage == null) return Offset.zero;

    final imgW = _rawImage!.width.toDouble();
    final imgH = _rawImage!.height.toDouble();

    final currentW = imgW * baseScale * currentZoom;
    final currentH = imgH * baseScale * currentZoom;

    final maxPanX = ((currentW - viewportSize.width) / 2).clamp(0.0, double.infinity);
    final maxPanY = ((currentH - viewportSize.height) / 2).clamp(0.0, double.infinity);

    return Offset(
      candidate.dx.clamp(-maxPanX, maxPanX),
      candidate.dy.clamp(-maxPanY, maxPanY),
    );
  }

  Future<void> _onApplyCrop(Size viewportSize, double baseScale) async {
    if (_rawImage == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final rawW = _rawImage!.width.toDouble();
      final rawH = _rawImage!.height.toDouble();

      final totalScale = baseScale * _scale;

      // Hitung ukuran crop dalam koordinat piksel gambar asli
      final cropWidth = (viewportSize.width / totalScale).clamp(1.0, rawW);
      final cropHeight = (viewportSize.height / totalScale).clamp(1.0, rawH);

      // Hitung koordinat kiri-atas (srcLeft, srcTop) gambar asli
      final centerSrcX = (rawW / 2) - (_offset.dx / totalScale);
      final centerSrcY = (rawH / 2) - (_offset.dy / totalScale);

      final srcLeft = (centerSrcX - (cropWidth / 2)).clamp(0.0, rawW - cropWidth);
      final srcTop = (centerSrcY - (cropHeight / 2)).clamp(0.0, rawH - cropHeight);

      final srcRect = Rect.fromLTWH(srcLeft, srcTop, cropWidth, cropHeight);

      // Resolusi target berkualitas tinggi (1080px lebar, tinggi menyesuaikan rasio)
      const targetWidth = 1080;
      final targetHeight = (1080 / widget.aspectRatio).round();
      final dstRect = Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble());

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint()..filterQuality = FilterQuality.high;

      canvas.drawImageRect(_rawImage!, srcRect, dstRect, paint);
      final picture = recorder.endRecording();
      final croppedUiImage = await picture.toImage(targetWidth, targetHeight);
      final byteData = await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        throw Exception('Gagal mengonversi gambar hasil potong');
      }

      final croppedImage = PickedImageData(
        bytes: byteData.buffer.asUint8List(),
        filename: 'crop_portrait_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      if (mounted) {
        Navigator.of(context).pop(croppedImage);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memotong foto: $e', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    // Hitung ukuran viewport crop potrait (misal lebar 280px atau max 80% layar)
    final double maxVpWidth = (screenSize.width * 0.78).clamp(240.0, 320.0);
    final double maxVpHeight = screenSize.height * 0.48;

    double vpWidth = maxVpWidth;
    double vpHeight = vpWidth / widget.aspectRatio;

    if (vpHeight > maxVpHeight) {
      vpHeight = maxVpHeight;
      vpWidth = vpHeight * widget.aspectRatio;
    }

    final viewportSize = Size(vpWidth, vpHeight);

    // Hitung base scale agar gambar memenuhi (cover) viewport pada zoom 1.0
    double baseScale = 1.0;
    if (_rawImage != null) {
      final imgW = _rawImage!.width.toDouble();
      final imgH = _rawImage!.height.toDouble();
      final scaleX = viewportSize.width / imgW;
      final scaleY = viewportSize.height / imgH;
      baseScale = scaleX > scaleY ? scaleX : scaleY;
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.crop_outlined, color: AppColors.primaryGold, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.titleSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: AppTypography.caption.copyWith(color: AppColors.textLight, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primaryGold, size: 22),
                    tooltip: 'Reset Posisi',
                    onPressed: _resetTransform,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(null),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2E2E2E), height: 1),

            // 2. Area Crop & Viewport
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: _isLoading
                    ? const SizedBox(
                        height: 240,
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryGold),
                        ),
                      )
                    : _errorMessage != null
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: viewportSize.width,
                              height: viewportSize.height,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: Border.all(color: AppColors.primaryGold, width: 2),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primaryGold.withValues(alpha: 0.35),
                                    blurRadius: 18,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  // Gesture area untuk Pan & Zoom
                                  Positioned.fill(
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onScaleStart: (details) {
                                        _startScale = _scale;
                                        _startOffset = _offset;
                                      },
                                      onScaleUpdate: (details) {
                                        setState(() {
                                          _scale = (_startScale * details.scale).clamp(1.0, 3.5);
                                          final candidateOffset = _startOffset + details.focalPointDelta;
                                          _offset = _clampOffset(candidateOffset, viewportSize, baseScale, _scale);
                                        });
                                      },
                                      child: CustomPaint(
                                        painter: _ImageCropPainter(
                                          image: _rawImage!,
                                          baseScale: baseScale,
                                          scale: _scale,
                                          offset: _offset,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Overlay Grid Rule-of-Thirds & Corner Brackets
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: CustomPaint(
                                        painter: _GridAndCornerPainter(),
                                      ),
                                    ),
                                  ),

                                  // Loading overlay saat memproses hasil potong
                                  if (_isProcessing)
                                    Positioned.fill(
                                      child: Container(
                                        color: Colors.black54,
                                        child: Center(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const CircularProgressIndicator(color: AppColors.primaryGold),
                                              const SizedBox(height: 12),
                                              Text(
                                                'Memproses foto potrait...',
                                                style: AppTypography.caption.copyWith(color: Colors.white),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
              ),
            ),

            // 3. Kontrol Zoom Slider & Petunjuk
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_outlined, color: AppColors.primaryGold, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Geser foto ke kiri / kanan untuk menyesuaikan',
                          style: AppTypography.caption.copyWith(color: AppColors.goldLight, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.zoom_out, color: Colors.white70, size: 20),
                        onPressed: () {
                          setState(() {
                            _scale = (_scale - 0.2).clamp(1.0, 3.5);
                            _offset = _clampOffset(_offset, viewportSize, baseScale, _scale);
                          });
                        },
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primaryGold,
                            inactiveTrackColor: const Color(0xFF3A3A3A),
                            thumbColor: AppColors.primaryGold,
                            overlayColor: AppColors.primaryGold.withValues(alpha: 0.2),
                            trackHeight: 3,
                          ),
                          child: Slider(
                            value: _scale,
                            min: 1.0,
                            max: 3.5,
                            onChanged: (val) {
                              setState(() {
                                _scale = val;
                                _offset = _clampOffset(_offset, viewportSize, baseScale, _scale);
                              });
                            },
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.zoom_in, color: Colors.white70, size: 20),
                        onPressed: () {
                          setState(() {
                            _scale = (_scale + 0.2).clamp(1.0, 3.5);
                            _offset = _clampOffset(_offset, viewportSize, baseScale, _scale);
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2E2E2E), height: 1),

            // 4. Tombol Aksi Bawah
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF4A4A4A)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isProcessing ? null : () => Navigator.of(context).pop(null),
                      child: Text(
                        'Batal',
                        style: AppTypography.button.copyWith(color: Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGold,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: (_isProcessing || _isLoading || _rawImage == null)
                          ? null
                          : () => _onApplyCrop(viewportSize, baseScale),
                      icon: const Icon(Icons.check, color: Colors.white, size: 18),
                      label: Text(
                        'Gunakan Foto Ini',
                        style: AppTypography.button.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter untuk merender gambar asli dengan transformasi pan dan zoom di dalam viewport
class _ImageCropPainter extends CustomPainter {
  final ui.Image image;
  final double baseScale;
  final double scale;
  final Offset offset;

  _ImageCropPainter({
    required this.image,
    required this.baseScale,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rawW = image.width.toDouble();
    final rawH = image.height.toDouble();

    final totalScale = baseScale * scale;
    final displayW = rawW * totalScale;
    final displayH = rawH * totalScale;

    final left = (size.width - displayW) / 2 + offset.dx;
    final top = (size.height - displayH) / 2 + offset.dy;

    final dstRect = Rect.fromLTWH(left, top, displayW, displayH);
    final srcRect = Rect.fromLTWH(0, 0, rawW, rawH);

    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _ImageCropPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.baseScale != baseScale ||
        oldDelegate.image != image;
  }
}

/// Painter untuk menggambar garis panduan Rule-of-Thirds dan siku sudut (corner brackets)
class _GridAndCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Rule of thirds lines
    final x1 = size.width / 3;
    final x2 = (size.width * 2) / 3;
    final y1 = size.height / 3;
    final y2 = (size.height * 2) / 3;

    canvas.drawLine(Offset(x1, 0), Offset(x1, size.height), gridPaint);
    canvas.drawLine(Offset(x2, 0), Offset(x2, size.height), gridPaint);
    canvas.drawLine(Offset(0, y1), Offset(size.width, y1), gridPaint);
    canvas.drawLine(Offset(0, y2), Offset(size.width, y2), gridPaint);

    // Corner brackets emas di ke-4 sudut
    final cornerPaint = Paint()
      ..color = AppColors.primaryGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    const cornerLen = 16.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLen, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLen), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLen, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLen), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLen, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLen), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLen, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLen), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
