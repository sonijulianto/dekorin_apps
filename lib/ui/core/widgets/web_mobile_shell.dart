import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';

/// Pembungkus tampilan aplikasi saat dijalankan di Flutter Web layar lebar (Desktop/Laptop).
///
/// Pada layar sempit (HP/Mobile Browser atau APK Android/iOS), widget ini meneruskan
/// [child] secara penuh (edge-to-edge). Pada layar desktop (`> 560px`), seluruh aplikasi
/// (termasuk Navigator, Dialog, dan BottomSheet) dipusatkan dalam frame mobile selebar
/// maksimal `480px` agar tampilan 100% identik dengan aplikasi mobile tanpa overflow.
class WebMobileShell extends StatelessWidget {
  const WebMobileShell({
    super.key,
    required this.child,
    @visibleForTesting this.forceWebFrame = false,
  });

  final Widget child;
  final bool forceWebFrame;

  static const double _desktopBreakpoint = 560;
  static const double _mobileFrameWidth = 480;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && !forceWebFrame) return child;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= _desktopBreakpoint) {
          return child;
        }

        final double verticalMargin = constraints.maxHeight >= 760 ? 16.0 : 0.0;
        final double frameHeight =
            (constraints.maxHeight - (verticalMargin * 2)).clamp(0.0, constraints.maxHeight);
        final double cornerRadius = verticalMargin > 0 ? 24.0 : 0.0;
        final mediaQuery = MediaQuery.of(context);

        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFF6F1EA),
                Color(0xFFE8DFD2),
              ],
            ),
          ),
          alignment: Alignment.center,
          child: Container(
            width: _mobileFrameWidth,
            height: frameHeight,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight,
              borderRadius: BorderRadius.circular(cornerRadius),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.25),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 36,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(cornerRadius),
              child: MediaQuery(
                data: mediaQuery.copyWith(
                  size: Size(_mobileFrameWidth, frameHeight),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}
