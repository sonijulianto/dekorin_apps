import 'package:flutter/material.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';

/// Kotak placeholder dengan efek kilau/shimmer animasi untuk status loading.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.baseColor,
    this.highlightColor,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );

    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    if (!bindingName.contains('TestWidgetsFlutterBinding')) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? const Color(0xFFE5DDD3);
    final highlight = widget.highlightColor ?? const Color(0xFFFAF7F2);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: const Alignment(-1.4, -0.2),
              end: const Alignment(1.4, 0.2),
              stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
              colors: [
                base,
                base,
                highlight,
                base,
                base,
              ],
              transform: _SlidingGradientTransform(slidePercent: _controller.value),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2.5 - 1.25), 0.0, 0.0);
  }
}

/// Shimmer loading skeleton yang merefleksikan layout dan ukuran Dashboard secara presisi.
class DashboardShimmerLoading extends StatelessWidget {
  const DashboardShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth * 0.58).clamp(215.0, 260.0);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 96),
      children: [
        // 1. Header Profil & Notifikasi Shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const ShimmerBox(
                width: 46,
                height: 46,
                borderRadius: BorderRadius.all(Radius.circular(23)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerBox(
                      width: 70,
                      height: 12,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    SizedBox(height: 6),
                    ShimmerBox(
                      width: 130,
                      height: 18,
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ShimmerBox(
                width: 44,
                height: 44,
                borderRadius: BorderRadius.all(Radius.circular(22)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Hero Summary Card Shimmer (Bronze / Gold Luxury Card)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0.0, 0.42, 0.72, 1.0],
                colors: [
                  Color(0xFF5C3D1E),
                  Color(0xFFB3854B),
                  Color(0xFF8F6431),
                  Color(0xFF4F3317),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF5C3D1E).withValues(alpha: 0.25),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Segmented Control Tabs Placeholder
                  const ShimmerBox(
                    width: double.infinity,
                    height: 36,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    baseColor: Color(0x33FFFFFF),
                    highlightColor: Color(0x66FFFFFF),
                  ),
                  const SizedBox(height: 14),

                  // Header title "Keuntungan" Placeholder
                  const ShimmerBox(
                    width: 180,
                    height: 13,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    baseColor: Color(0x33FFFFFF),
                    highlightColor: Color(0x66FFFFFF),
                  ),
                  const SizedBox(height: 6),

                  // Navigator Periode Placeholder
                  const ShimmerBox(
                    width: 120,
                    height: 14,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    baseColor: Color(0x2EFFFFFF),
                    highlightColor: Color(0x66FFFFFF),
                  ),
                  const SizedBox(height: 8),

                  // Nominal Keuntungan Placeholder
                  const ShimmerBox(
                    width: 200,
                    height: 32,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    baseColor: Color(0x2EFFFFFF),
                    highlightColor: Color(0x66FFFFFF),
                  ),
                  const SizedBox(height: 18),

                  // 3 Tiles Ringkasan Placeholder (Pendapatan, Pengeluaran, Agenda)
                  Row(
                    children: const [
                      Expanded(
                        flex: 11,
                        child: _DashboardHeroMetricShimmerTile(),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 11,
                        child: _DashboardHeroMetricShimmerTile(),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        flex: 8,
                        child: _DashboardHeroMetricShimmerTile(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // 2b. Banner Asisten Dekorin AI Shimmer
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E241C), Color(0xFF453528)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryGold.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryGold, AppColors.secondaryGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      ShimmerBox(
                        width: 140,
                        height: 14,
                        borderRadius: BorderRadius.all(Radius.circular(4)),
                        baseColor: Color(0x33FFFFFF),
                        highlightColor: Color(0x66FFFFFF),
                      ),
                      SizedBox(height: 6),
                      ShimmerBox(
                        width: double.infinity,
                        height: 11,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                        baseColor: Color(0x22FFFFFF),
                        highlightColor: Color(0x44FFFFFF),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 26),

        // 3. Section Booking Mendatang Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(
                width: 160,
                height: 19,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              ShimmerBox(
                width: 50,
                height: 14,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Carousel Booking Mendatang Shimmer
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _DashboardBookingShimmerCard(width: cardWidth),
              const SizedBox(width: 12),
              _DashboardBookingShimmerCard(width: cardWidth),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 4. Section Pengeluaran Terkini Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(
                width: 150,
                height: 19,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              ShimmerBox(
                width: 60,
                height: 14,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Daftar Pengeluaran Terkini Shimmer Items
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: const [
              _DashboardExpenseShimmerItem(),
              SizedBox(height: 10),
              _DashboardExpenseShimmerItem(),
              SizedBox(height: 10),
              _DashboardExpenseShimmerItem(),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardHeroMetricShimmerTile extends StatelessWidget {
  const _DashboardHeroMetricShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              ShimmerBox(
                width: 14,
                height: 14,
                borderRadius: BorderRadius.all(Radius.circular(3)),
                baseColor: Color(0x33FFFFFF),
                highlightColor: Color(0x66FFFFFF),
              ),
              SizedBox(width: 4),
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 11,
                  borderRadius: BorderRadius.all(Radius.circular(3)),
                  baseColor: Color(0x33FFFFFF),
                  highlightColor: Color(0x66FFFFFF),
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          ShimmerBox(
            width: double.infinity,
            height: 14,
            borderRadius: BorderRadius.all(Radius.circular(4)),
            baseColor: Color(0x2EFFFFFF),
            highlightColor: Color(0x66FFFFFF),
          ),
        ],
      ),
    );
  }
}

class _DashboardBookingShimmerCard extends StatelessWidget {
  const _DashboardBookingShimmerCard({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ),
              SizedBox(width: 8),
              ShimmerBox(
                width: 48,
                height: 18,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const ShimmerBox(
            width: 90,
            height: 13,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 8),
          const ShimmerBox(
            width: 140,
            height: 12,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0EAE1)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ShimmerBox(
                width: 80,
                height: 14,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              ShimmerBox(
                width: 65,
                height: 14,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardExpenseShimmerItem extends StatelessWidget {
  const _DashboardExpenseShimmerItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDE8E1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const ShimmerBox(
            width: 38,
            height: 38,
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(
                  width: 130,
                  height: 14,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
                SizedBox(height: 6),
                ShimmerBox(
                  width: 80,
                  height: 11,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const ShimmerBox(
            width: 75,
            height: 15,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

/// Shimmer loading skeleton yang merefleksikan daftar kartu agenda secara presisi.
class AgendaShimmerLoading extends StatelessWidget {
  const AgendaShimmerLoading({
    super.key,
    this.itemCount = 6,
  });

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 80,
      ),
      itemCount: itemCount,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) => const _AgendaShimmerCard(),
    );
  }
}

class _AgendaShimmerCard extends StatelessWidget {
  const _AgendaShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppTheme.primaryGold.withValues(alpha: 0.5),
                width: 4,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand badge placeholder
                    const ShimmerBox(
                      width: 65,
                      height: 15,
                      borderRadius: BorderRadius.all(Radius.circular(5)),
                    ),
                    const SizedBox(height: 8),
                    // Client name and phone
                    Row(
                      children: const [
                        ShimmerBox(
                          width: 110,
                          height: 16,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        SizedBox(width: 8),
                        ShimmerBox(
                          width: 85,
                          height: 13,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Date row with calendar icon placeholder
                    Row(
                      children: const [
                        ShimmerBox(
                          width: 14,
                          height: 14,
                          borderRadius: BorderRadius.all(Radius.circular(3)),
                        ),
                        SizedBox(width: 8),
                        ShimmerBox(
                          width: 150,
                          height: 12,
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ShimmerBox(
                width: 16,
                height: 16,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
