import 'package:flutter/material.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_template_preview_view.dart';

/// Screen untuk memilih template / tema desain undangan digital.
///
/// Memungkinkan pencarian template dan filter berdasarkan kategori acara
/// sehingga layar pembuatan undangan tetap ringkas dan rapi meskipun
/// jumlah template terus bertambah di masa depan.
class InvitationTemplatePickerView extends StatefulWidget {
  const InvitationTemplatePickerView({
    super.key,
    this.initialTemplateId,
    this.categoryFilter,
  });

  final String? initialTemplateId;
  final String? categoryFilter;

  @override
  State<InvitationTemplatePickerView> createState() =>
      _InvitationTemplatePickerViewState();
}

class _InvitationTemplatePickerViewState
    extends State<InvitationTemplatePickerView> {
  late TextEditingController _searchController;
  String _searchQuery = '';
  late String _selectedCategory;
  late String _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedCategory = widget.categoryFilter ?? 'all';
    _selectedTemplateId = widget.initialTemplateId ?? InvitationTemplate.ta17;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openTemplatePreview(String templateId, String templateName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InvitationTemplatePreviewView(
          templateId: templateId,
          templateName: templateName,
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getFilteredTemplates() {
    return InvitationTemplate.all.where((tmpl) {
      // 1. Filter Kategori Acara
      if (_selectedCategory != 'all') {
        final tmplCat = tmpl['category'] as String?;
        final supported = tmpl['supportedCategories'] as List?;
        final matchesCat = (tmplCat == _selectedCategory) ||
            (supported != null && supported.contains(_selectedCategory));
        if (!matchesCat) return false;
      }

      // 2. Filter Search Query
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final name = (tmpl['name'] as String? ?? '').toLowerCase();
        final tag = (tmpl['tag'] as String? ?? '').toLowerCase();
        final desc = (tmpl['description'] as String? ?? '').toLowerCase();
        final id = (tmpl['id'] as String? ?? '').toLowerCase();
        if (!name.contains(q) &&
            !tag.contains(q) &&
            !desc.contains(q) &&
            !id.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = _getFilteredTemplates();

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Pilih Desain Template',
          style: AppTypography.titleLarge,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Search & Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Pencarian
                TextField(
                  controller: _searchController,
                  style: AppTypography.bodyMedium,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari template (nama, gaya, warna)...',
                    hintStyle: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textLight,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.primaryGold,
                      size: 20,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textLight,
                              size: 18,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.backgroundLight,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderLight),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryGold,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Horizontal Filter Chips Kategori Acara
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(
                        id: 'all',
                        label: '✨ Semua Template',
                        isSelected: _selectedCategory == 'all',
                      ),
                      ...InvitationEventCategory.getAvailableCategories().map((cat) {
                        final catId = cat['id'] as String;
                        final isSelected = _selectedCategory == catId;
                        return _buildCategoryChip(
                          id: catId,
                          label: '${cat['icon']} ${cat['shortName']}',
                          isSelected: isSelected,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Daftar Template
          Expanded(
            child: filteredTemplates.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredTemplates.length,
                    itemBuilder: (context, index) {
                      final tmpl = filteredTemplates[index];
                      final isSelected = _selectedTemplateId == tmpl['id'];
                      return _buildTemplateItemCard(tmpl, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String id,
    required String label,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedCategory = id;
          });
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.goldLight : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.secondaryGold : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTemplateItemCard(Map<String, dynamic> tmpl, bool isSelected) {
    final primaryColor = tmpl['primaryColor'] as Color;
    final secondaryColor = tmpl['secondaryColor'] as Color;
    final bgColor = tmpl['backgroundColor'] as Color;
    final accentColor = tmpl['accentColor'] as Color;
    final tmplId = tmpl['id'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected ? AppColors.primaryGold : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? AppColors.primaryGold.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openTemplatePreview(
            tmplId,
            tmpl['name'] as String? ?? 'Preview Template',
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Palet Warna & Status Badge / Preview Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Visual Color Swatch
                    Row(
                      children: [
                        _buildColorCircle(primaryColor),
                        const SizedBox(width: 4),
                        _buildColorCircle(secondaryColor),
                        const SizedBox(width: 4),
                        _buildColorCircle(accentColor),
                        const SizedBox(width: 4),
                        _buildColorCircle(bgColor, hasBorder: true),
                        const SizedBox(width: 10),
                        Text(
                          tmpl['tag'] as String? ?? '',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.secondaryGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),

                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primaryGold),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 13,
                              color: AppColors.primaryGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Terpilih',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.secondaryGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: () => _openTemplatePreview(
                          tmplId,
                          tmpl['name'] as String? ?? 'Preview Template',
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primaryGold.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.remove_red_eye_outlined,
                                size: 12,
                                color: AppColors.primaryGold,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Preview',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.secondaryGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Template Name
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _getTemplateEmoji(tmplId),
                        style: AppTypography.bodyLarge.copyWith(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tmpl['name'] as String,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Kategori: ${tmpl['categoryName'] ?? 'Pernikahan'}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textLight,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Description
                Text(
                  tmpl['description'] as String? ?? '',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDark.withValues(alpha: 0.8),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons: View Preview (In-App) & Gunakan Template
                Row(
                  children: [
                    // Tombol View Preview In-App
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 42,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.primaryGold,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                          ),
                          onPressed: () => _openTemplatePreview(
                            tmplId,
                            tmpl['name'] as String? ?? 'Preview Template',
                          ),
                          icon: const Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: AppColors.primaryGold,
                          ),
                          label: Text(
                            'Lihat Preview',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.secondaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tombol Pilih Desain
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 42,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isSelected
                                ? AppColors.primaryGold
                                : AppColors.goldLight,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryGold
                                    : AppColors.borderLight,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedTemplateId = tmplId;
                            });
                            Navigator.pop(context, tmplId);
                          },
                          icon: Icon(
                            isSelected ? Icons.check_circle : Icons.arrow_forward,
                            size: 15,
                            color: isSelected
                                ? Colors.white
                                : AppColors.secondaryGold,
                          ),
                          label: Text(
                            isSelected ? 'Sedang Dipakai' : 'Pilih Desain',
                            style: AppTypography.caption.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.secondaryGold,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorCircle(Color color, {bool hasBorder = false}) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: hasBorder
            ? Border.all(color: AppColors.borderLight, width: 1)
            : null,
      ),
    );
  }

  String _getTemplateEmoji(String id) {
    switch (id) {
      case 'ta17':
        return '💙';
      case 'jawa3':
        return '🤎';
      case 'ta3':
        return '🌸';
      case 'pn4':
        return '🖤';
      default:
        return '✨';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.goldLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.palette_outlined,
                size: 32,
                color: AppColors.primaryGold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Template Tidak Ditemukan',
              style: AppTypography.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              _selectedCategory != 'all'
                  ? 'Belum ada template khusus untuk kategori ini. Template saat ini tersedia untuk kategori Pernikahan.'
                  : 'Tidak ada template yang cocok dengan pencarian "$_searchQuery".',
              textAlign: TextAlign.center,
              style: AppTypography.caption,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGold,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedCategory = 'all';
                });
              },
              child: Text(
                'Tampilkan Semua Template',
                style: AppTypography.button.copyWith(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
