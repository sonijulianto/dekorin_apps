import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/chat_service.dart';
import 'package:dekorin_apps/domain/models/chat_message.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_chat_view.dart';

class ChatInboxView extends ConsumerStatefulWidget {
  const ChatInboxView({super.key});

  @override
  ConsumerState<ChatInboxView> createState() => _ChatInboxViewState();
}

class _ChatInboxViewState extends ConsumerState<ChatInboxView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4EF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          'Diskusi Kolaborasi',
          style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              style: AppTypography.bodyMedium,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari nama klien atau vendor...',
                hintStyle: AppTypography.bodySmall,
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primaryGold,
                  size: 20,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF7F4EF),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primaryGold,
              onRefresh: () async {
                ref.invalidate(chatRoomsProvider);
                ref.invalidate(chatUnreadSummaryProvider);
                await ref.read(chatRoomsProvider.future);
              },
              child: roomsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryGold),
                ),
                error: (err, _) => ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off_outlined,
                            size: 44,
                            color: AppColors.primaryGold,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Gagal memuat daftar diskusi',
                            style: AppTypography.titleSmall,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            err.toString().replaceFirst('Exception: ', ''),
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                data: (rooms) {
                  final filtered = _query.isEmpty
                      ? rooms
                      : rooms.where((r) {
                          final hay =
                              '${r.clientName} ${r.partnerNames.join(' ')} ${r.eventLabel}'
                                  .toLowerCase();
                          return hay.contains(_query);
                        }).toList();

                  if (filtered.isEmpty) {
                    return ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 64,
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: const BoxDecoration(
                                  color: AppColors.goldLight,
                                  shape: BoxShape.circle,
                                ),
                                child: SvgPicture.asset(
                                  'assets/icons/chat-arrow-grow.svg',
                                  width: 34,
                                  height: 34,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.primaryGold,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _query.isEmpty
                                    ? 'Belum Ada Diskusi Kolaborasi'
                                    : 'Diskusi tidak ditemukan',
                                style: AppTypography.titleMedium,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _query.isEmpty
                                    ? 'Room diskusi otomatis muncul saat undangan kolaborasi antar vendor sudah diterima.'
                                    : 'Coba kata kunci nama klien atau vendor lain.',
                                textAlign: TextAlign.center,
                                style: AppTypography.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(14),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, idx) => _buildRoomCard(filtered[idx]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(ChatRoomSummary room) {
    final eventDateStr = room.eventDateTime != null
        ? DateFormat('dd MMM yyyy', 'id_ID')
            .format(room.eventDateTime!.toLocal())
        : '';
    final lastTimeStr = room.lastMessageAt != null
        ? DateFormat('dd/MM HH:mm').format(room.lastMessageAt!.toLocal())
        : '';

    final subtitleText = room.lastMessagePreview.isNotEmpty
        ? (room.lastSenderName.isNotEmpty
            ? '${room.lastSenderName}: ${room.lastMessagePreview}'
            : room.lastMessagePreview)
        : 'Belum ada pesan · Tap untuk mulai diskusi';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AgendaChatView(
              agendaId: room.agendaId,
              initialClientName: room.clientName,
            ),
          ),
        ).then((_) {
          ref.invalidate(chatRoomsProvider);
          ref.invalidate(chatUnreadSummaryProvider);
        });
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: room.unreadCount > 0
                ? AppColors.primaryGold.withValues(alpha: 0.5)
                : const Color(0xFFEBE5DC),
          ),
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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/chat-arrow-grow.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryGold,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.clientName,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastTimeStr.isNotEmpty)
                        Text(
                          lastTimeStr,
                          style: AppTypography.caption.copyWith(fontSize: 10),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (eventDateStr.isNotEmpty || room.partnerNames.isNotEmpty)
                    Text(
                      [
                        if (eventDateStr.isNotEmpty) 'Acara $eventDateStr',
                        if (room.partnerNames.isNotEmpty)
                          room.partnerNames.join(', '),
                      ].join(' · '),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.secondaryGold,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitleText,
                          style: AppTypography.bodySmall.copyWith(
                            fontWeight: room.unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: room.unreadCount > 0
                                ? AppColors.textDark
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (room.unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            room.unreadCount > 99
                                ? '99+'
                                : '${room.unreadCount}',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
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
