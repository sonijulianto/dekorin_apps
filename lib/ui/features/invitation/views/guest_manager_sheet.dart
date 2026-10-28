import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/services/invitation_service.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_generator_view.dart';

class GuestManagerSheet extends ConsumerStatefulWidget {
  const GuestManagerSheet({super.key, required this.invitation});

  final InvitationItem invitation;

  @override
  ConsumerState<GuestManagerSheet> createState() => _GuestManagerSheetState();
}

class _GuestManagerSheetState extends ConsumerState<GuestManagerSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _guestNameController = TextEditingController();
  final _phoneController = TextEditingController();

  List<InvitationWishItem>? _wishes;
  bool _isLoadingWishes = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _fetchWishes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _guestNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _fetchWishes() async {
    setState(() => _isLoadingWishes = true);
    final wishes = await ref.read(invitationServiceProvider).getWishes(widget.invitation.id);
    if (mounted) {
      setState(() {
        _wishes = wishes;
        _isLoadingWishes = false;
      });
    }
  }

  String _getGeneratedUrl() {
    return ApiEndpoint.getInvitationWebUrl(widget.invitation.slug, _guestNameController.text.trim());
  }

  String _getWhatsAppMessage(String guestName, String url) {
    final title = widget.invitation.title.isNotEmpty
        ? widget.invitation.title
        : '${widget.invitation.groomNickname} & ${widget.invitation.brideNickname}';

    final targetName = guestName.isNotEmpty ? guestName : 'Bapak/Ibu/Saudara/i';

    return '''Kepada Yth.
$targetName

Tanpa mengurangi rasa hormat, perkenankan kami mengundang Bapak/Ibu/Saudara/i untuk hadir dan memberikan doa restu pada momen bahagia kami:

💍 *$title*

Untuk melihat detail rangkaian acara & lokasi, silakan buka tautan undangan digital resmi berikut:
🔗 $url

Merupakan suatu kehormatan dan kebahagiaan bagi kami apabila Bapak/Ibu/Saudara/i berkenan hadir.

Terima kasih banyak atas perhatian dan doa restunya.
Salam hangat kami,
*${widget.invitation.groomNickname} & ${widget.invitation.brideNickname}*''';
  }

  Future<void> _sendWhatsApp() async {
    final guestName = _guestNameController.text.trim();
    final url = _getGeneratedUrl();
    final message = _getWhatsAppMessage(guestName, url);

    String rawPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (rawPhone.startsWith('0')) {
      rawPhone = '62${rawPhone.substring(1)}';
    }

    final encodedMsg = Uri.encodeComponent(message);
    Uri waUri;
    if (rawPhone.isNotEmpty) {
      waUri = Uri.parse('https://wa.me/$rawPhone?text=$encodedMsg');
    } else {
      waUri = Uri.parse('https://wa.me/?text=$encodedMsg');
    }

    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tidak dapat membuka WhatsApp',
              style: AppTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Sheet
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kelola Undangan & Tamu', style: AppTypography.titleMedium),
                    Text(widget.invitation.title, style: AppTypography.caption.copyWith(color: AppColors.primaryGold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryGold,
            unselectedLabelColor: AppColors.textLight,
            indicatorColor: AppColors.primaryGold,
            tabs: [
              Tab(
                icon: SvgPicture.asset(
                  'assets/icons/share.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    _tabController.index == 0 ? AppColors.primaryGold : AppColors.textLight,
                    BlendMode.srcIn,
                  ),
                ),
                text: 'Bagikan Undangan',
              ),
              const Tab(icon: Icon(Icons.menu_book, size: 20), text: 'Buku Tamu / RSVP'),
            ],
          ),

          Expanded(
            child: TabBarView(controller: _tabController, children: [_buildShareTab(), _buildWishesTab()]),
          ),
        ],
      ),
    );
  }

  Widget _buildShareTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nama Tamu yang Dituju', style: AppTypography.labelLarge),
          const SizedBox(height: 6),
          DekorinTextField(
            controller: _guestNameController,
            hint: 'Contoh: Bapak Soni & Partner',
            prefixIcon: Icons.person_outline,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          Text('Nomor WhatsApp (Opsional)', style: AppTypography.labelLarge),
          const SizedBox(height: 6),
          DekorinTextField(
            controller: _phoneController,
            hint: 'Contoh: 08123456789 (bisa dikosongkan)',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // Box Link Personal
          Text('Tautan Undangan Khusus Tamu', style: AppTypography.labelLarge),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.goldLight.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getGeneratedUrl(),
                    style: AppTypography.caption.copyWith(color: AppColors.textDark, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/copy-alt.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                  ),
                  tooltip: 'Salin Link',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _getGeneratedUrl()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Tautan undangan berhasil disalin!',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                        ),
                        duration: Duration(milliseconds: 1500),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Actions Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _sendWhatsApp,
              icon: SvgPicture.asset(
                'assets/icons/wa.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
              label: Text(
                'Kirim Undangan via WhatsApp',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InvitationGeneratorView(invitation: widget.invitation)),
                );
              },
              icon: const Icon(Icons.bolt, color: Colors.white, size: 20),
              label: Text(
                'Buka Generator Undangan Lengkap',
                style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryGold,
                side: const BorderSide(color: AppColors.primaryGold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final uri = Uri.parse(_getGeneratedUrl());
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              icon: const Icon(Icons.open_in_browser, size: 18),
              label: Text(
                'Buka Website di Browser',
                style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishesTab() {
    if (_isLoadingWishes) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGold));
    }

    if (_wishes == null || _wishes!.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchWishes,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 40),
            Icon(Icons.mark_email_read_outlined, size: 60, color: AppColors.textLight.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Center(child: Text('Belum ada ucapan & doa yang masuk dari tamu.', style: AppTypography.bodyMedium)),
          ],
        ),
      );
    }

    // Statistik kehadiran
    int hadirCount = _wishes!.where((w) => w.attendance == 'hadir').length;
    int tidakHadirCount = _wishes!.where((w) => w.attendance == 'tidak_hadir').length;
    int raguCount = _wishes!.where((w) => w.attendance == 'ragu').length;

    return RefreshIndicator(
      onRefresh: _fetchWishes,
      child: Column(
        children: [
          // Stat Bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.goldLight.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Hadir', '$hadirCount', Colors.green.shade700),
                _buildStatItem('Tidak Hadir', '$tidakHadirCount', Colors.red.shade700),
                _buildStatItem('Ragu', '$raguCount', Colors.orange.shade800),
                _buildStatItem('Total', '${_wishes!.length}', AppColors.textDark),
              ],
            ),
          ),

          // List Ucapan
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _wishes!.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final wish = _wishes![index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(wish.guestName, style: AppTypography.titleSmall),
                          _buildAttendanceBadge(wish.attendance),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(wish.message, style: AppTypography.bodySmall),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 16, color: color),
        ),
        Text(label, style: AppTypography.caption),
      ],
    );
  }

  Widget _buildAttendanceBadge(String attendance) {
    Color bg;
    Color text;
    String label;

    switch (attendance) {
      case 'hadir':
        bg = const Color(0xFFD1E7DD);
        text = const Color(0xFF0F5132);
        label = 'Hadir';
        break;
      case 'tidak_hadir':
        bg = const Color(0xFFF8D7DA);
        text = const Color(0xFF842029);
        label = 'Tidak Hadir';
        break;
      default:
        bg = const Color(0xFFFFF3CD);
        text = const Color(0xFF664D03);
        label = 'Ragu-ragu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
