import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/models/user_model.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/team/view_models/team_view_model.dart';

class ManageTeamView extends ConsumerStatefulWidget {
  const ManageTeamView({super.key});

  @override
  ConsumerState<ManageTeamView> createState() => _ManageTeamViewState();
}

class _ManageTeamViewState extends ConsumerState<ManageTeamView> {
  String _selectedRoleFilter = 'all'; // 'all', 'owner', 'admin', 'crew'

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(globalAuthProvider).value;
    final teamState = ref.watch(teamViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text('Kelola Tim & Karyawan', style: AppTypography.titleLarge),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context, currentUser?.isOwner ?? false),
        backgroundColor: AppColors.primaryGold,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: Text(currentUser?.isOwner == true ? 'Tambah Anggota' : 'Tambah Staff', style: AppTypography.button),
      ),
      body: teamState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryGold)),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed),
                const SizedBox(height: 12),
                Text(
                  'Gagal memuat tim: $err',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(teamViewModelProvider.notifier).refresh(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGold),
                  child: Text('Coba Lagi', style: AppTypography.button),
                ),
              ],
            ),
          ),
        ),
        data: (members) {
          final owners = members.where((m) => m.role.toLowerCase() == 'owner').toList();
          final admins = members.where((m) => m.role.toLowerCase() == 'admin').toList();
          final crew = members.where((m) => m.role.toLowerCase() == 'crew').toList();

          final filteredMembers = _selectedRoleFilter == 'all'
              ? members
              : members.where((m) => m.role.toLowerCase() == _selectedRoleFilter).toList();

          return RefreshIndicator(
            onRefresh: () => ref.read(teamViewModelProvider.notifier).refresh(),
            color: AppColors.primaryGold,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              children: [
                // Info Perusahaan Banner
                if (currentUser?.companyName.isNotEmpty ?? false) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderLight),
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
                          child: const Icon(Icons.business, color: AppColors.primaryGold),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentUser!.companyName,
                                style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (currentUser.companyAddress.isNotEmpty)
                                Text(
                                  currentUser.companyAddress,
                                  style: AppTypography.caption.copyWith(color: AppColors.textLight),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Role Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Owner',
                        count: owners.length,
                        color: Colors.purple,
                        icon: Icons.workspace_premium,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Admin',
                        count: admins.length,
                        color: AppColors.primaryGold,
                        icon: Icons.admin_panel_settings,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildSummaryCard(
                        title: 'Crew / Staff',
                        count: crew.length,
                        color: Colors.blue,
                        icon: Icons.engineering,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua (${members.length})', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Owner (${owners.length})', 'owner'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Admin (${admins.length})', 'admin'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Crew (${crew.length})', 'crew'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Members List
                if (filteredMembers.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.group_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada anggota pada kategori ini',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  ...filteredMembers.map(
                    (member) => _buildMemberTile(
                      context,
                      member,
                      currentUser?.id ?? '',
                      currentUser?.isOwner ?? false,
                      currentUser?.isAdmin ?? false,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required int count, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            count.toString(),
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold, color: color),
          ),
          Text(title, style: AppTypography.caption.copyWith(color: AppColors.textLight)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedRoleFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: isSelected ? AppColors.primaryGold : AppColors.textLight,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.goldLight,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? AppColors.primaryGold : AppColors.borderLight),
      onSelected: (_) {
        setState(() {
          _selectedRoleFilter = value;
        });
      },
    );
  }

  Widget _buildMemberTile(BuildContext context, UserModel member, String currentUserId, bool isOwner, bool isAdmin) {
    final isMe = member.id == currentUserId;
    final role = member.role.toLowerCase();

    Color roleColor;
    String roleLabel;
    IconData roleIcon;

    if (role == 'owner') {
      roleColor = Colors.purple;
      roleLabel = 'Owner';
      roleIcon = Icons.workspace_premium;
    } else if (role == 'admin') {
      roleColor = AppColors.primaryGold;
      roleLabel = 'Admin';
      roleIcon = Icons.admin_panel_settings;
    } else {
      roleColor = Colors.blue;
      roleLabel = 'Crew / Staff';
      roleIcon = Icons.engineering;
    }

    // Permission checks:
    // - Owner can edit all, delete other admins and crew (cannot delete self).
    // - Admin can only edit and delete crew.
    final canEdit = isOwner || (isAdmin && role == 'crew');
    final canDelete = !isMe && (isOwner || (isAdmin && role == 'crew'));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: roleColor.withValues(alpha: 0.12),
            child: Icon(roleIcon, color: roleColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.fullName,
                        style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          'Saya',
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_android, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(
                      member.phone.isNotEmpty ? member.phone : '-',
                      style: AppTypography.caption.copyWith(color: AppColors.textLight, fontFamily: 'monospace'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleLabel,
                    style: AppTypography.caption.copyWith(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          if (canEdit || canDelete) ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: AppColors.textLight),
              onSelected: (val) {
                if (val == 'edit') {
                  _showEditMemberDialog(context, member, isOwner);
                } else if (val == 'delete') {
                  _confirmDeleteMember(context, member);
                }
              },
              itemBuilder: (context) => [
                if (canEdit)
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          'assets/icons/edit.svg',
                          width: 18,
                          height: 18,
                          colorFilter: const ColorFilter.mode(AppColors.textDark, BlendMode.srcIn),
                        ),
                        const SizedBox(width: 8),
                        Text('Edit Anggota', style: AppTypography.labelLarge),
                      ],
                    ),
                  ),
                if (canDelete)
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.errorRed, size: 18),
                        SizedBox(width: 8),
                        Text('Hapus Anggota', style: AppTypography.bodyMedium.copyWith(color: AppColors.errorRed)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Dialog Tambah Anggota ───────────────────────────────────────────

  void _showAddMemberDialog(BuildContext context, bool isOwner) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = isOwner ? 'admin' : 'crew';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tambah Anggota Tim', style: AppTypography.titleMedium),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Nama Lengkap
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap *',
                        hintText: 'Contoh: Ahmad Lapangan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // No. WhatsApp / HP
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'No. WhatsApp / HP (ID Login) *',
                        hintText: '081234567890',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone_android_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Password Awal
                    TextField(
                      controller: passCtrl,
                      decoration: InputDecoration(
                        labelText: 'Password Awal *',
                        hintText: 'Minimal 6 karakter',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Role Picker
                    Text('Pilih Role / Jabatan:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    if (isOwner) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleSelectOption(
                              label: 'Owner',
                              desc: 'Co-Owner',
                              role: 'owner',
                              color: Colors.purple,
                              selected: selectedRole == 'owner',
                              onTap: () => setModalState(() => selectedRole = 'owner'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRoleSelectOption(
                              label: 'Admin',
                              desc: 'Kantor / CS',
                              role: 'admin',
                              color: AppColors.primaryGold,
                              selected: selectedRole == 'admin',
                              onTap: () => setModalState(() => selectedRole = 'admin'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRoleSelectOption(
                              label: 'Crew',
                              desc: 'Lapangan',
                              role: 'crew',
                              color: Colors.blue,
                              selected: selectedRole == 'crew',
                              onTap: () => setModalState(() => selectedRole = 'crew'),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Admin hanya bisa buat Crew
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Role terkunci: Admin hanya memiliki izin untuk menambahkan akun Crew / Staf Lapangan.',
                                style: AppTypography.bodySmall.copyWith(fontSize: 12, color: Colors.blue),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          final phone = phoneCtrl.text.trim();
                          final pass = passCtrl.text.trim();

                          if (name.isEmpty || phone.isEmpty || pass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Harap lengkapi semua kolom wajib',
                                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                ),
                              ),
                            );
                            return;
                          }

                          if (pass.length < 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Password minimal 6 karakter',
                                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                ),
                              ),
                            );
                            return;
                          }

                          try {
                            await ref
                                .read(teamViewModelProvider.notifier)
                                .createMember(
                                  fullName: name,
                                  phone: phone,
                                  password: pass,
                                  role: selectedRole,
                                  email: emailCtrl.text.trim(),
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Anggota $name berhasil ditambahkan!',
                                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal: $e',
                                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.errorRed,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Simpan Anggota Baru',
                          style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoleSelectOption({
    required String label,
    required String desc,
    required String role,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? color : Colors.grey.shade300, width: selected ? 2.0 : 1.0),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: AppTypography.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: selected ? color : AppColors.textDark,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              style: AppTypography.caption.copyWith(fontSize: 10, color: selected ? color : AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialog Edit Anggota ─────────────────────────────────────────────

  void _showEditMemberDialog(BuildContext context, UserModel member, bool isOwner) {
    final nameCtrl = TextEditingController(text: member.fullName);
    final phoneCtrl = TextEditingController(text: member.phone);
    final passCtrl = TextEditingController();
    String selectedRole = member.role.toLowerCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Anggota Tim', style: AppTypography.titleMedium),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Lengkap *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'No. WhatsApp / HP *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.phone_android_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: passCtrl,
                      decoration: InputDecoration(
                        labelText: 'Reset Password (Opsional)',
                        hintText: 'Biarkan kosong jika tidak diubah',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.lock_reset),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (isOwner) ...[
                      Text('Ubah Role / Jabatan:', style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildRoleSelectOption(
                              label: 'Owner',
                              desc: 'Co-Owner',
                              role: 'owner',
                              color: Colors.purple,
                              selected: selectedRole == 'owner',
                              onTap: () => setModalState(() => selectedRole = 'owner'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRoleSelectOption(
                              label: 'Admin',
                              desc: 'Kantor / CS',
                              role: 'admin',
                              color: AppColors.primaryGold,
                              selected: selectedRole == 'admin',
                              onTap: () => setModalState(() => selectedRole = 'admin'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildRoleSelectOption(
                              label: 'Crew',
                              desc: 'Lapangan',
                              role: 'crew',
                              color: Colors.blue,
                              selected: selectedRole == 'crew',
                              onTap: () => setModalState(() => selectedRole = 'crew'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryGold,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          try {
                            await ref
                                .read(teamViewModelProvider.notifier)
                                .updateMember(
                                  id: member.id,
                                  fullName: nameCtrl.text.trim(),
                                  phone: phoneCtrl.text.trim(),
                                  password: passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : null,
                                  role: selectedRole,
                                );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Data anggota berhasil diperbarui!',
                                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Gagal: $e',
                                    style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                                  ),
                                  backgroundColor: AppColors.errorRed,
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          'Simpan Perubahan',
                          style: AppTypography.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Konfirmasi Hapus Anggota ───────────────────────────────────────

  void _confirmDeleteMember(BuildContext context, UserModel member) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Anggota Tim?', style: AppTypography.h3),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun "${member.fullName}"? Tindakan ini tidak dapat dibatalkan.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppTypography.labelLarge.copyWith(color: AppColors.primaryGold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(teamViewModelProvider.notifier).deleteMember(member.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Akun ${member.fullName} berhasil dihapus',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Gagal menghapus: $e',
                        style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                      ),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                }
              }
            },
            child: Text('Hapus', style: AppTypography.bodyMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
