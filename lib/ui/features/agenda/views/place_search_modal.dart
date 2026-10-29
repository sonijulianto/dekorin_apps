import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:dekorin_apps/config/theme/app_colors.dart';
import 'package:dekorin_apps/config/theme/app_typography.dart';
import 'package:dekorin_apps/data/services/place_search_service.dart';

/// Modal bottom sheet untuk mencari tempat / venue acara secara interaktif
/// dengan rekomendasi otomatis (autocomplete).
class PlaceSearchModal extends StatefulWidget {
  const PlaceSearchModal({super.key, this.initialQuery = ''});

  final String initialQuery;

  /// Membuka modal pencarian tempat
  static Future<PlaceSearchResult?> show(BuildContext context, {String initialQuery = ''}) {
    return showModalBottomSheet<PlaceSearchResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlaceSearchModal(initialQuery: initialQuery),
    );
  }

  @override
  State<PlaceSearchModal> createState() => _PlaceSearchModalState();
}

class _PlaceSearchModalState extends State<PlaceSearchModal> {
  late final TextEditingController _searchController;
  Timer? _debounceTimer;
  List<PlaceSearchResult> _results = [];
  bool _isLoading = false;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentQuery = widget.initialQuery.trim();
    if (_currentQuery.length >= 2) {
      _performSearch(_currentQuery);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    final query = value.trim();
    if (query == _currentQuery) return;

    if (query.length < 2) {
      setState(() {
        _currentQuery = query;
        _results = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _currentQuery = query;
      _isLoading = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isLoading = true);
    try {
      final list = await PlaceSearchService.searchPlaces(query);
      if (mounted && query == _currentQuery) {
        setState(() {
          _results = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted && query == _currentQuery) {
        setState(() {
          _results = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchExternalGoogleMaps(String query) async {
    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    final uri = Uri.parse(mapsUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.85),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset('assets/icons/google-maps-icon.webp', width: 22, height: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cari Tempat & Lokasi Acara',
                    style: AppTypography.titleMedium.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textLight, size: 22),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ketik nama hotel, gedung, venue, atau jalan untuk melihat rekomendasi langsung:',
              style: AppTypography.bodySmall.copyWith(fontSize: 12, color: AppColors.textLight),
            ),
          ),
          const SizedBox(height: 12),

          // Input field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onQueryChanged,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Contoh: Hotel Santika, Gedung Serbaguna...',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textLight, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGold, size: 22),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryGold),
                        ),
                      )
                    else if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.textLight, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onQueryChanged('');
                        },
                      ),
                  ],
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.borderLight),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Content Area (Results / Suggestions)
          Expanded(
            child: _buildContentArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    if (_currentQuery.length < 2) {
      return _buildEmptyStateSuggestions();
    }

    if (_isLoading && _results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryGold),
            const SizedBox(height: 12),
            Text('Mencari lokasi...', style: AppTypography.bodySmall.copyWith(color: AppColors.textLight)),
          ],
        ),
      );
    }

    if (_results.isEmpty) {
      return _buildNoResultsView();
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _results.length + 1,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 48),
      itemBuilder: (context, index) {
        if (index == _results.length) {
          // Bottom tile: manual external search fallback
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: InkWell(
              onTap: () => _launchExternalGoogleMaps(_currentQuery),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Image.asset('assets/icons/google-maps-icon.webp', width: 20, height: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Tidak menemukan tempat yang dicari?', style: AppTypography.caption.copyWith(color: Colors.blue.shade900)),
                          Text(
                            'Buka "$_currentQuery" di Google Maps',
                            style: AppTypography.bodySmall.copyWith(color: Colors.blue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.open_in_new, size: 16, color: Colors.blue),
                  ],
                ),
              ),
            ),
          );
        }

        final item = _results[index];
        return InkWell(
          onTap: () => Navigator.pop(context, item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/marker.svg',
                    width: 20,
                    height: 20,
                    colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      if (item.address.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          item.address,
                          style: AppTypography.caption.copyWith(color: AppColors.textLight, height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyStateSuggestions() {
    final suggestions = ['Hotel Santika', 'Gedung Serbaguna', 'Balai Kartini', 'Puri Begawan'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contoh Pencarian Cepat:',
            style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textLight),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return ActionChip(
                avatar: const Icon(Icons.search, size: 14, color: AppColors.primaryGold),
                label: Text(s, style: AppTypography.bodySmall.copyWith(color: AppColors.textDark)),
                backgroundColor: AppColors.goldLight,
                side: BorderSide(color: AppColors.primaryGold.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onPressed: () {
                  _searchController.text = s;
                  _onQueryChanged(s);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                shape: BoxShape.circle,
              ),
              child: SvgPicture.asset(
                'assets/icons/marker.svg',
                width: 32,
                height: 32,
                colorFilter: const ColorFilter.mode(AppColors.primaryGold, BlendMode.srcIn),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Tidak menemukan tempat untuk\n"$_currentQuery"',
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            const SizedBox(height: 6),
            Text(
              'Anda tetap bisa menggunakan teks ini sebagai alamat acara atau mencari via Google Maps.',
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: AppColors.textLight),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final manualResult = PlaceSearchResult(
                        name: _currentQuery,
                        address: '',
                        latitude: 0,
                        longitude: 0,
                        mapsUrl: 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_currentQuery)}',
                      );
                      Navigator.pop(context, manualResult);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primaryGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Gunakan Teks Ini', style: AppTypography.bodySmall.copyWith(color: AppColors.primaryGold, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchExternalGoogleMaps(_currentQuery),
                    icon: Image.asset('assets/icons/google-maps-icon.webp', width: 16, height: 16),
                    label: Text('Buka Maps', style: AppTypography.button.copyWith(fontSize: 13, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGold,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
