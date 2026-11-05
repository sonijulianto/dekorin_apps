import 'dart:io';

import 'package:flutter/material.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';

class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.afterImageUrl,
    this.beforeImageFile,
    this.beforeImageUrl = '',
    this.height = 380,
    this.onTapFullscreen,
  });

  final String afterImageUrl;
  final File? beforeImageFile;
  final String beforeImageUrl;
  final double height;
  final VoidCallback? onTapFullscreen;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _splitFraction = 0.5;

  void _updateSplit(double localDx, double maxWidth) {
    if (maxWidth <= 0) return;
    setState(() {
      _splitFraction = (localDx / maxWidth).clamp(0.04, 0.96);
    });
  }

  Widget _buildBeforeImage() {
    if (widget.beforeImageFile != null) {
      return Image.file(
        widget.beforeImageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }
    if (widget.beforeImageUrl.isNotEmpty) {
      return Image.network(
        widget.beforeImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _buildFallbackBox('Foto Asli'),
      );
    }
    return _buildFallbackBox('Foto Asli');
  }

  Widget _buildFallbackBox(String label) {
    return Container(
      color: const Color(0xFFEDE8E0),
      alignment: Alignment.center,
      child: Text(label, style: AppTypography.bodySmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final dividerX = maxW * _splitFraction;

            return GestureDetector(
              onHorizontalDragDown: (d) => _updateSplit(d.localPosition.dx, maxW),
              onHorizontalDragUpdate: (d) => _updateSplit(d.localPosition.dx, maxW),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Layer Bawah (Penuh): Hasil Simulasi AI (Sesudah)
                  Image.network(
                    widget.afterImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: AppColors.goldLight,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(
                          color: AppColors.primaryGold,
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => _buildFallbackBox('Gagal memuat hasil AI'),
                  ),

                  // Layer Atas (Terpotong Kiri): Foto Referensi Asli (Sebelum)
                  ClipRect(
                    clipper: _LeftWidthClipper(dividerX),
                    child: _buildBeforeImage(),
                  ),

                  // Label Kiri Atas: SEBELUM
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SEBELUM (ASLI)',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                  // Label Kanan Atas: SESUDAH (AI)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGold.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'SIMULASI AI',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                  // Watermark Bawah Kiri
                  Positioned(
                    bottom: 10,
                    left: 10,
                    right: widget.onTapFullscreen != null ? 54 : 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Simulasi Visual AI • Geser garis tengah untuk membandingkan',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),

                  // Tombol Fullscreen Kanan Bawah
                  if (widget.onTapFullscreen != null)
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Material(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          onTap: widget.onTapFullscreen,
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(7),
                            child: Icon(
                              Icons.fullscreen_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Garis Pembatas Vertikal + Handle Geser Emas
                  Positioned(
                    top: 0,
                    bottom: 0,
                    left: (dividerX - 18).clamp(0.0, maxW - 36),
                    width: 36,
                    child: IgnorePointer(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 2.5,
                            color: Colors.white,
                          ),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.primaryGold,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.compare_arrows_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LeftWidthClipper extends CustomClipper<Rect> {
  final double clipWidth;
  _LeftWidthClipper(this.clipWidth);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, clipWidth, size.height);
  }

  @override
  bool shouldReclip(covariant _LeftWidthClipper oldClipper) {
    return oldClipper.clipWidth != clipWidth;
  }
}
