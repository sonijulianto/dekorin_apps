import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/core/widgets/dekorin_text_field.dart';

enum MessageTemplateType {
  formal,
  casual,
  family,
  custom,
}

class InvitationGeneratorView extends StatefulWidget {
  const InvitationGeneratorView({super.key, required this.invitation});

  final InvitationItem invitation;

  @override
  State<InvitationGeneratorView> createState() => _InvitationGeneratorViewState();
}

class _InvitationGeneratorViewState extends State<InvitationGeneratorView> {
  final _recipientController = TextEditingController();
  final _phoneController = TextEditingController();
  final _customTemplateController = TextEditingController();

  MessageTemplateType _selectedTemplateType = MessageTemplateType.formal;

  String _copiedStatus = 'Salin Teks';
  bool _isCopiedLink = false;

  // Daftar nama tamu cepat dalam sesi ini
  final List<Map<String, dynamic>> _quickGuestList = [];
  final _quickGuestInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customTemplateController.text = '''Assalamu'alaikum Wr. Wb.

Kepada Yth.
[NAMA]

Tanpa mengurangi rasa hormat, perkenankan kami mengundang Anda pada:
*[JUDUL]*

Detail info & link undangan:
[LINK]

Terima kasih banyak atas perhatian dan doa restunya.
Wassalamu'alaikum Wr. Wb.''';
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _phoneController.dispose();
    _customTemplateController.dispose();
    _quickGuestInputController.dispose();
    super.dispose();
  }

  /// Membuat URL undangan dinamis persis seperti logika di Family Invitation
  String _generateInvitationUrl(String recipient) {
    String baseUrl = ApiEndpoint.getInvitationWebUrl(widget.invitation.slug);
    if (recipient.trim().isEmpty) return baseUrl;

    String modified = recipient.trim().replaceAll(' ', '_');
    // Ganti "dan" atau "&" dengan "-"
    modified = modified.replaceAll(RegExp(r'\b(dan|&)\b', caseSensitive: false), '-');
    if (modified.contains('_-_')) {
      modified = modified.replaceAll('_-_', '-');
    }

    return '$baseUrl?to=$modified';
  }

  String _getInvitationTitle() {
    if (widget.invitation.title.isNotEmpty) {
      return widget.invitation.title;
    }
    if (widget.invitation.eventType == 'khitan') {
      return 'Tasyakuran Khitanan ${widget.invitation.childNickname.isNotEmpty ? widget.invitation.childNickname : widget.invitation.childName}';
    }
    return '${widget.invitation.groomNickname} & ${widget.invitation.brideNickname}';
  }

  String _getCoupleOrHost() {
    if (widget.invitation.eventType == 'khitan') {
      return widget.invitation.groomParents.isNotEmpty
          ? widget.invitation.groomParents
          : 'Keluarga Besar';
    }
    return '${widget.invitation.groomNickname} & ${widget.invitation.brideNickname}';
  }

  String _generateMessageText() {
    final recipient = _recipientController.text.trim();
    final targetName = recipient.isNotEmpty ? recipient : 'Bapak/Ibu/Saudara/i';
    final url = _generateInvitationUrl(recipient);
    final title = _getInvitationTitle();
    final couple = _getCoupleOrHost();

    switch (_selectedTemplateType) {
      case MessageTemplateType.formal:
        return '''Assalamu'alaikum Wr. Wb. & Bismillahirahmanirrahim.

Kepada Yth.
$targetName

Tanpa mengurangi rasa hormat, perkenankan kami mengundang Bapak/Ibu/Saudara/i untuk menghadiri acara kami:

💍 *$title*

Berikut tautan undangan kami, untuk info lengkap dan konfirmasi kehadiran dapat mengunjungi:
🔗 $url

Merupakan suatu kebahagiaan dan kehormatan bagi kami apabila Bapak/Ibu/Saudara/i berkenan untuk hadir dan memberikan doa restu.
Mohon maaf perihal undangan hanya dibagikan melalui pesan digital ini.

Terima kasih banyak atas perhatian dan doa restunya.
Wassalamu'alaikum Wr. Wb.

Salam hangat kami,
*$couple*''';

      case MessageTemplateType.casual:
        return '''Halo $targetName! 👋

Kabar bahagia untuk kita semua. Dengan penuh rasa syukur dan sukacita, kami ingin mengundang kamu untuk hadir dan merayakan momen bahagia kami:

✨ *$title*

Untuk melihat detail rangkaian acara, waktu, lokasi peta, dan galeri foto, silakan buka link undangan berikut:
👉 $url

Kehadiran dan doa restu dari kamu sangat berarti untuk kami. Sampai jumpa di hari bahagia nanti!

Salam hangat,
*$couple*''';

      case MessageTemplateType.family:
        return '''Assalamu'alaikum Wr. Wb.

Kepada Yth.
Keluarga Besar / $targetName

Dengan memohon rahmat dan ridho Allah SWT, perkenankan kami mengundang Bapak/Ibu/Saudara/i sekalian untuk hadir pada momen penuh berkah:

🕌 *$title*

Tautan undangan resmi keluarga:
🔗 $url

Doa restu dan kehadiran Bapak/Ibu/Saudara/i merupakan kehormatan yang sangat besar bagi keluarga kami.

Terima kasih atas perhatian dan kasih sayangnya.
Wassalamu'alaikum Wr. Wb.

Hormat kami sekeluarga,
*$couple*''';

      case MessageTemplateType.custom:
        String text = _customTemplateController.text;
        text = text.replaceAll('[NAMA]', targetName);
        text = text.replaceAll('[LINK]', url);
        text = text.replaceAll('[link]', url);
        text = text.replaceAll('[JUDUL]', title);
        text = text.replaceAll('[judul]', title);
        text = text.replaceAll('[PENGANTIN]', couple);
        return text;
    }
  }

  Future<void> _sendWhatsApp() async {
    final message = _generateMessageText();
    final encodedMsg = Uri.encodeComponent(message);

    String rawPhone = _phoneController.text.trim().replaceAll(RegExp(r'\D'), '');
    if (rawPhone.startsWith('0')) {
      rawPhone = '62${rawPhone.substring(1)}';
    }

    Uri waUri;
    if (rawPhone.isNotEmpty) {
      waUri = Uri.parse('https://wa.me/$rawPhone?text=$encodedMsg');
    } else {
      waUri = Uri.parse('https://wa.me/?text=$encodedMsg');
    }

    if (await canLaunchUrl(waUri)) {
      await launchUrl(waUri, mode: LaunchMode.externalApplication);
      // Tandai di list jika ada
      final currentName = _recipientController.text.trim();
      if (currentName.isNotEmpty) {
        setState(() {
          final idx = _quickGuestList.indexWhere((g) => g['name'] == currentName);
          if (idx != -1) {
            _quickGuestList[idx]['sent'] = true;
          }
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka WhatsApp')),
        );
      }
    }
  }

  void _copyMessage() {
    final message = _generateMessageText();
    Clipboard.setData(ClipboardData(text: message));
    setState(() => _copiedStatus = 'Tersalin! ✅');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Teks undangan berhasil disalin ke clipboard!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1500),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copiedStatus = 'Salin Teks');
    });
  }

  void _copyLinkOnly() {
    final url = _generateInvitationUrl(_recipientController.text.trim());
    Clipboard.setData(ClipboardData(text: url));
    setState(() => _isCopiedLink = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tautan undangan berhasil disalin!'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: 1500),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopiedLink = false);
    });
  }

  void _addQuickGuest() {
    final name = _quickGuestInputController.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _quickGuestList.add({
        'name': name,
        'sent': false,
      });
      _quickGuestInputController.clear();
      if (_recipientController.text.isEmpty) {
        _recipientController.text = name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tmpl = InvitationTemplate.getById(widget.invitation.template);
    final primaryColor = tmpl['primaryColor'] as Color;
    final currentUrl = _generateInvitationUrl(_recipientController.text.trim());
    final messagePreview = _generateMessageText();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Generator Undangan WA', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner Info Undangan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGold.withValues(alpha: 0.15),
                  AppColors.goldLight,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.invitation.coverImage.isNotEmpty
                      ? Image.network(
                          widget.invitation.coverImage.startsWith('http')
                              ? widget.invitation.coverImage
                              : '${ApiEndpoint.webFormBaseUrl}${widget.invitation.coverImage}',
                          width: 55,
                          height: 55,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildPlaceholder(),
                        )
                      : _buildPlaceholder(),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getInvitationTitle(),
                        style: AppTypography.titleSmall.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tmpl['name'] as String,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '/${widget.invitation.slug}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. INPUT DATA TAMU
          _buildCard(
            title: '1. Data Tamu Penerima',
            icon: Icons.person_pin_outlined,
            children: [
              Text('Nama Tamu / Undangan', style: AppTypography.labelLarge),
              const SizedBox(height: 6),
              Stack(
                alignment: Alignment.centerRight,
                children: [
                  DekorinTextField(
                    controller: _recipientController,
                    hint: 'Contoh: Bapak Hendra & Keluarga',
                    prefixIcon: Icons.person_outline,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_recipientController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                        onPressed: () => setState(() => _recipientController.clear()),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Nomor WhatsApp (Opsional)', style: AppTypography.labelLarge),
              const SizedBox(height: 6),
              DekorinTextField(
                controller: _phoneController,
                hint: 'Contoh: 08123456789 (kosongkan jika memilih kontak nanti)',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),

              // Box Link Dinamis
              Text('Tautan Personal Tamu', style: AppTypography.labelLarge),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.goldLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentUrl,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isCopiedLink ? Icons.check : Icons.copy,
                        color: AppColors.primaryGold,
                        size: 20,
                      ),
                      tooltip: 'Salin Tautan',
                      onPressed: _copyLinkOnly,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. PILIHAN TEMPLATE PESAN
          _buildCard(
            title: '2. Format Teks Pesan',
            icon: Icons.chat_bubble_outline,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildTemplateChoiceChip(
                      label: 'Formal (Santun)',
                      type: MessageTemplateType.formal,
                    ),
                    const SizedBox(width: 8),
                    _buildTemplateChoiceChip(
                      label: 'Sahabat (Kasual)',
                      type: MessageTemplateType.casual,
                    ),
                    const SizedBox(width: 8),
                    _buildTemplateChoiceChip(
                      label: 'Keluarga',
                      type: MessageTemplateType.family,
                    ),
                    const SizedBox(width: 8),
                    _buildTemplateChoiceChip(
                      label: 'Custom Teks',
                      type: MessageTemplateType.custom,
                    ),
                  ],
                ),
              ),
              if (_selectedTemplateType == MessageTemplateType.custom) ...[
                const SizedBox(height: 14),
                Text('Format Teks Kustom Anda:', style: AppTypography.labelLarge),
                const SizedBox(height: 6),
                DekorinTextField(
                  controller: _customTemplateController,
                  hint: 'Tulis template teks undangan di sini...',
                  maxLines: 8,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '💡 Gunakan tag [NAMA] untuk nama tamu dan [LINK] untuk tautan undangan.',
                    style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // 3. LIVE PREVIEW PESAN
          _buildCard(
            title: '3. Preview Teks Undangan',
            icon: Icons.visibility_outlined,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: SelectableText(
                  messagePreview,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.6,
                    color: Color(0xFF1E293B),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryGold,
                        side: const BorderSide(color: AppColors.primaryGold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _copyMessage,
                      icon: const Icon(Icons.copy, size: 18),
                      label: Text(_copiedStatus, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: AppColors.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(currentUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.open_in_browser, size: 18),
                      label: const Text('Buka Web', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Tombol Kirim WhatsApp Utama (dengan aset wa.svg)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _sendWhatsApp,
                  icon: SvgPicture.asset(
                    'assets/icons/wa.svg',
                    width: 22,
                    height: 22,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  label: const Text(
                    'Kirim Langsung via WhatsApp',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. DAFTAR TAMU CEPAT (BULK / QUICK LIST)
          _buildCard(
            title: '4. Daftar Tamu Cepat (Opsional)',
            icon: Icons.checklist_rtl_outlined,
            children: [
              Text(
                'Tambahkan beberapa nama tamu untuk membagikan satu per satu dengan mudah:',
                style: AppTypography.caption,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _quickGuestInputController,
                      decoration: InputDecoration(
                        hintText: 'Ketik nama tamu lalu klik Tambah...',
                        hintStyle: AppTypography.caption,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onSubmitted: (_) => _addQuickGuest(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _addQuickGuest,
                    child: const Text('Tambah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              if (_quickGuestList.isNotEmpty) ...[
                const SizedBox(height: 14),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _quickGuestList.length,
                  separatorBuilder: (_, _) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final guest = _quickGuestList[index];
                    final isSent = guest['sent'] == true;
                    final isCurrent = _recipientController.text == guest['name'];

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: isSent
                            ? Colors.green.shade100
                            : AppColors.goldLight,
                        child: Icon(
                          isSent ? Icons.check : Icons.person,
                          size: 18,
                          color: isSent ? Colors.green.shade700 : AppColors.primaryGold,
                        ),
                      ),
                      title: Text(
                        guest['name'] as String,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? AppColors.primaryGold : AppColors.textDark,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Text(
                                'Terkirim',
                                style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.bold),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primaryGold),
                            tooltip: 'Pilih Tamu Ini',
                            onPressed: () {
                              setState(() {
                                _recipientController.text = guest['name'] as String;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            tooltip: 'Hapus',
                            onPressed: () {
                              setState(() {
                                _quickGuestList.removeAt(index);
                              });
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildTemplateChoiceChip({
    required String label,
    required MessageTemplateType type,
  }) {
    final isSelected = _selectedTemplateType == type;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedTemplateType = type);
        }
      },
      selectedColor: AppColors.primaryGold,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textDark,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryGold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(color: AppColors.primaryGold),
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.dividerColor),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 55,
      height: 55,
      color: AppColors.goldLight,
      child: const Icon(Icons.mail_outline, color: AppColors.primaryGold, size: 28),
    );
  }
}
